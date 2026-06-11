#!/usr/bin/env bash
# hero-deploy.sh — hero-site-deploy 确定性层
# 把项目主页 + 后端程序标准化部署到本机，由一个 Caddy(:10086) 统一对外。
# 子命令: init | add <repo> | regen | autostart | verify | status
#
# 注: bash 3.2 兼容（macOS 自带）。无 declare -A / ${var^^}。
# 测试钩子: 设 HERO_SITE_ROOT 覆盖部署根，避免动真实 /var/www。
set -euo pipefail

DEPLOY_ROOT="${HERO_SITE_ROOT:-/var/www/hero-sites}"
APPS_DIR="$DEPLOY_ROOT/apps"
REGISTRY="$DEPLOY_ROOT/registry.json"
MASTER="$DEPLOY_ROOT/Caddyfile"
PORT="${HERO_SITE_PORT:-10086}"
LA_DIR="$HOME/Library/LaunchAgents"

die()  { echo "❌ $*" >&2; exit 1; }
info() { echo "▸ $*" >&2; }
ok()   { echo "✅ $*" >&2; }

need() { command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"; }

brew_caddyfile() {
  local prefix; prefix="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
  echo "$prefix/etc/Caddyfile"
}

# 探测 caddy 二进制：跑着的 > PATH 上的 > 都没才 brew install。回显路径到 stdout。
detect_caddy() {
  local p
  p="$(ps -axo args= 2>/dev/null | awk '/[c]addy run/{print $1; exit}')"
  if [ -n "$p" ] && [ -x "$p" ]; then echo "$p"; return 0; fi
  if command -v caddy >/dev/null 2>&1; then command -v caddy; return 0; fi
  info "本机无 caddy，brew install caddy ..."
  need brew; brew install caddy >&2
  command -v caddy
}

# 正在运行的 caddy 用的 --config 路径（无则空）。
running_caddy_config() {
  ps -axo args= 2>/dev/null \
    | awk '/[c]addy run/{ for(i=1;i<=NF;i++) if($i=="--config"||$i=="-c"){print $(i+1); exit} }'
}

# 抽出 <file> 中 :PORT { ... } 的内层 body（不含外层大括号），原样回显。
extract_site_body() {
  local file="$1"
  awk -v port=":${PORT}" '
    BEGIN { inb=0; depth=0 }
    {
      if (!inb) {
        if ($0 ~ "^[[:space:]]*" port "[[:space:]]*\\{[[:space:]]*$") { inb=1; depth=1 }
        next
      }
      line=$0; o=gsub(/{/,"{",line); c=gsub(/}/,"}",line)
      if (depth + o - c <= 0) { exit }      # 命中外层闭合，不打印该行，结束
      depth += o - c
      print
    }
  ' "$file"
}

# 合并捕获：首次从“外部”活动 Caddyfile 抽 body 存到 extra.caddy（一次性，不覆盖已存在的）。
# 跳过指向 master 自身的配置，避免自引用。
capture_extra() {
  local extra="$DEPLOY_ROOT/extra.caddy"
  [ -f "$extra" ] && return 0          # 已捕获过，保持不动
  local src; src="$(running_caddy_config)"
  if [ -z "$src" ]; then
    local bf; bf="$(brew_caddyfile)"
    [ -e "$bf" ] && src="$(readlink "$bf" 2>/dev/null || echo "$bf")"
  fi
  [ -n "$src" ] && [ -f "$src" ] || return 0
  # 解析软链后若就是 master，则无外部内容可并
  case "$(cd "$(dirname "$src")" && pwd)/$(basename "$src")" in
    "$MASTER") return 0 ;;
  esac
  local body; body="$(extract_site_body "$src" || true)"
  [ -n "$body" ] || return 0
  {
    echo "# 由 hero-deploy.sh 从既有部署抽取并原样保留: $src"
    echo "$body"
  } > "$extra"
  info "已保留既有 :$PORT 路由到 extra.caddy（源: $src）"
}

# extra.caddy 是否含【顶层】catch-all 默认页（depth 0 的无 matcher handle {）。
# 嵌套在 /tavern 等内部的 handle {} 不算。
extra_has_default() {
  local extra="$DEPLOY_ROOT/extra.caddy"
  [ -f "$extra" ] || return 1
  awk '
    BEGIN { depth=0 }
    /^[[:space:]]*#/ { next }
    {
      if (depth==0 && $0 ~ /^[[:space:]]*handle[[:space:]]*\{[[:space:]]*$/) { found=1 }
      line=$0; o=gsub(/{/,"{",line); c=gsub(/}/,"}",line); depth += o - c
    }
    END { exit (found ? 0 : 1) }
  ' "$extra"
}

# ---------- init ----------
cmd_init() {
  need jq
  if [ -d "$DEPLOY_ROOT" ] && [ -w "$DEPLOY_ROOT" ]; then
    info "部署根已存在且可写: $DEPLOY_ROOT"
  else
    case "$DEPLOY_ROOT" in
      /var/*|/opt/*)
        info "首次创建部署根需 sudo（建目录 + chown 给 $USER）:"
        echo "    sudo mkdir -p '$DEPLOY_ROOT' && sudo chown '$USER' '$DEPLOY_ROOT'" >&2
        sudo mkdir -p "$DEPLOY_ROOT"
        sudo chown "$USER" "$DEPLOY_ROOT"
        ;;
      *) mkdir -p "$DEPLOY_ROOT" ;;
    esac
  fi
  mkdir -p "$APPS_DIR"
  [ -f "$REGISTRY" ] || echo '{"projects":[]}' > "$REGISTRY"
  ok "init 完成: $DEPLOY_ROOT"
}

# ---------- add <repo> ----------
# 注册项目 + 软链 + 重生成 master。低风险，只动部署根。
cmd_add() {
  need jq
  local repo="${1:-}"
  [ -n "$repo" ] || die "用法: hero-deploy.sh add <repo>"
  repo="$(cd "$repo" 2>/dev/null && pwd)" || die "项目目录不存在: ${1:-}"
  local sj="$repo/site/site.json"
  [ -f "$sj" ] || die "缺少 $sj —— 先建页/写清单（见 SKILL.md schema）"
  [ -f "$REGISTRY" ] || die "未初始化，先跑: hero-deploy.sh init"

  # 校验清单
  local name default mount sroot
  name="$(jq -r '.name // empty' "$sj")"
  [ -n "$name" ] || die "site.json 缺 name"
  default="$(jq -r '.default // false' "$sj")"
  mount="$(jq -r '.mount // empty' "$sj")"
  sroot="$(jq -r '.static_root // "site/public"' "$sj")"
  [ -d "$repo/$sroot" ] || die "static_root 不存在: $repo/$sroot"

  if [ "$default" = "true" ]; then
    local cur
    cur="$(jq -r '.projects[] | select(.default==true) | .name' "$REGISTRY")"
    if [ -n "$cur" ] && [ "$cur" != "$name" ]; then
      die "已有默认页 '$cur'，default 全局唯一。先改它的 site.json 或换 name。"
    fi
  else
    [ -n "$mount" ] || die "非默认项目必须有 mount（如 /$name）"
    case "$mount" in /*) : ;; *) die "mount 必须以 / 开头: $mount" ;; esac
  fi

  # 软链 apps/<name> -> repo
  ln -sfn "$repo" "$APPS_DIR/$name"

  # upsert registry：先删同名，再追加
  local backends ts tmp
  backends="$(jq -c '.backends // []' "$sj")"
  ts="$(date +%Y-%m-%dT%H:%M:%S)"
  tmp="$(mktemp)"
  jq --arg name "$name" \
     --argjson default "$default" \
     --arg mount "$mount" \
     --arg repo "$repo" \
     --arg sroot "$sroot" \
     --argjson backends "$backends" \
     --arg ts "$ts" \
     '.projects |= (map(select(.name != $name)) + [{
        name:$name, default:$default,
        mount:(if $mount=="" then null else $mount end),
        repo:$repo, static_root:$sroot, backends:$backends, last_deployed:$ts
      }])' "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"

  ok "已注册 ${name}（default=${default} mount=${mount:-/}）"
  cmd_regen
}

# ---------- regen ----------
# 从 registry 整体生成 master Caddyfile。默认页 handle 永远最后。
cmd_regen() {
  need jq
  [ -f "$REGISTRY" ] || die "未初始化"
  capture_extra                     # 首次把既有部署的 :PORT 路由保留到 extra.caddy
  local tmp; tmp="$(mktemp)"
  {
    echo "# 本文件由 hero-deploy.sh 生成，勿手改。源: $REGISTRY"
    echo ":$PORT {"
    # 非默认项目（有 mount）
    jq -r '.projects[] | select(.default != true) | .name' "$REGISTRY" | while IFS= read -r name; do
      [ -n "$name" ] || continue
      local mount sroot
      mount="$(jq -r --arg n "$name" '.projects[] | select(.name==$n) | .mount' "$REGISTRY")"
      sroot="$(jq -r --arg n "$name" '.projects[] | select(.name==$n) | .static_root' "$REGISTRY")"
      # 裸前缀 -> 带尾斜杠，否则相对静态资源会解析到根而 404（3-token 写法避免首参被当 matcher）
      echo "    redir ${mount} ${mount}/ 301"
      echo "    handle ${mount}/* {"
      echo "        uri strip_prefix ${mount}"
      # backends：反代，先于静态
      jq -c --arg n "$name" '.projects[] | select(.name==$n) | .backends[]?' "$REGISTRY" | while IFS= read -r b; do
        local match port
        match="$(echo "$b" | jq -r '.match')"
        port="$(echo "$b" | jq -r '.port')"
        echo "        handle ${match} {"
        echo "            reverse_proxy 127.0.0.1:${port}"
        echo "        }"
      done
      echo "        handle {"
      echo "            root * ${APPS_DIR}/${name}/${sroot}"
      echo "            file_server"
      echo "        }"
      echo "    }"
    done
    # 保留的既有路由（含旧 catch-all 默认页）原样并入，排在 hero 路由之后
    if [ -s "$DEPLOY_ROOT/extra.caddy" ]; then
      echo "    import extra.caddy"
    fi
    # hero 默认页：仅当 registry 有 default 且 extra 里没有顶层 catch-all 时才发（避免覆盖既有默认页）
    local dname dsroot
    dname="$(jq -r '.projects[] | select(.default==true) | .name' "$REGISTRY")"
    if [ -n "$dname" ] && ! extra_has_default; then
      dsroot="$(jq -r '.projects[] | select(.default==true) | .static_root' "$REGISTRY")"
      echo "    handle {"
      echo "        root * ${APPS_DIR}/${dname}/${dsroot}"
      echo "        file_server"
      echo "    }"
    fi
    echo "}"
  } > "$tmp"
  mv "$tmp" "$MASTER"
  ok "已生成 master: $MASTER"
}

# ---------- autostart ----------
# 探测 caddy（有就用，没才装）→ 应用合并后的 master → 配开机自启。改系统状态，调用前应已确认。
cmd_autostart() {
  need jq
  cmd_regen >/dev/null                       # 确保 master 含最新合并内容
  local caddy; caddy="$(detect_caddy)"
  [ -n "$caddy" ] || die "未找到且无法安装 caddy"
  info "使用 caddy: $caddy"
  "$caddy" validate --config "$MASTER" >/dev/null 2>&1 || die "caddy validate 失败，已中止（不切换运行中实例）"

  # 后端 LaunchAgent
  mkdir -p "$LA_DIR"
  jq -r '.projects[] | .name as $n | .repo as $repo | .backends[]? | "\($n)\t\(.name)\t\(.start)\t\($repo)"' "$REGISTRY" \
  | while IFS="$(printf '\t')" read -r proj bname start repo; do
      [ -n "${bname:-}" ] || continue
      local label="hero-${bname}" plist="$LA_DIR/hero-${bname}.plist"
      gen_plist "$label" "$start" "$repo" > "$plist"
      launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
      launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null \
        || launchctl load "$plist" 2>/dev/null || true
      ok "后端自启: ${label}（${start}）"
    done

  # caddy 自启：brew 的 caddy 走 brew services；否则用户级 hero-caddy LaunchAgent
  local brew_caddy=""
  command -v brew >/dev/null 2>&1 && brew_caddy="$(brew --prefix)/bin/caddy"
  if [ -n "$brew_caddy" ] && [ "$caddy" = "$brew_caddy" ]; then
    local bf; bf="$(brew_caddyfile)"
    if [ -e "$bf" ] && [ ! -L "$bf" ]; then
      cp "$bf" "$bf.bak.$(date +%Y%m%d%H%M%S)"; info "已备份原 $bf"
    fi
    ln -sfn "$MASTER" "$bf"
    brew services restart caddy >/dev/null
    ok "caddy 走 brew services（开机自启），配置 -> master"
  else
    local plist="$LA_DIR/hero-caddy.plist"
    gen_caddy_plist "$caddy" "$MASTER" > "$plist"
    # 运行中实例先热加载合并配置（不停机保留既有路由），再交给 LaunchAgent 持久化
    "$caddy" reload --config "$MASTER" 2>/dev/null \
      && ok "运行中 caddy 已 reload 到合并配置（既有路由保留）" || true
    launchctl bootout "gui/$(id -u)/hero-caddy" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null \
      || launchctl load "$plist" 2>/dev/null || true
    ok "caddy 走 hero-caddy LaunchAgent（开机自启）: $plist"
  fi
}

gen_caddy_plist() {
  local caddy="$1" cfg="$2"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>hero-caddy</string>
  <key>ProgramArguments</key>
  <array>
    <string>${caddy}</string><string>run</string><string>--config</string><string>${cfg}</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/hero-caddy.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/hero-caddy.err.log</string>
</dict>
</plist>
PLIST
}

gen_plist() {
  local label="$1" start="$2" wd="$3"
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string><string>-lc</string><string>${start}</string>
  </array>
  <key>WorkingDirectory</key><string>${wd}</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>/tmp/${label}.out.log</string>
  <key>StandardErrorPath</key><string>/tmp/${label}.err.log</string>
</dict>
</plist>
PLIST
}

# ---------- verify ----------
cmd_verify() {
  need jq
  if command -v caddy >/dev/null 2>&1; then
    caddy validate --config "$MASTER" >/dev/null 2>&1 \
      && ok "caddy validate 通过" || die "caddy validate 失败: $MASTER"
  fi
  local base="http://localhost:$PORT"
  info "默认页:"
  curl -fsS -o /dev/null -w "  GET /  -> %{http_code}\n" "$base/" || echo "  GET / -> 失败" >&2
  jq -r '.projects[] | select(.default != true) | "\(.mount)"' "$REGISTRY" | while IFS= read -r m; do
    [ -n "$m" ] || continue
    curl -fsS -o /dev/null -w "  GET ${m}/ -> %{http_code}\n" "$base${m}/" || echo "  GET ${m}/ -> 失败" >&2
  done
}

# ---------- status ----------
cmd_status() {
  need jq
  [ -f "$REGISTRY" ] || { echo "未初始化（无 $REGISTRY）"; return 0; }
  echo "部署根: $DEPLOY_ROOT  端口: :$PORT"
  jq -r '.projects[] | "  - \(.name)\t\(if .default then "默认 /" else .mount end)\t<- \(.repo)\tbackends:\(.backends|length)"' "$REGISTRY"
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    init)      cmd_init "$@" ;;
    add)       cmd_add "$@" ;;
    regen)     cmd_regen "$@" ;;
    autostart) cmd_autostart "$@" ;;
    verify)    cmd_verify "$@" ;;
    status)    cmd_status "$@" ;;
    *) cat >&2 <<EOF
hero-deploy.sh — hero-site-deploy 确定性层
用法:
  init               建部署根（首次 /var/* 需 sudo）+ registry
  add <repo>         注册项目 + 软链 + 重生成 master（读 <repo>/site/site.json）
  regen              仅重生成 master Caddyfile
  autostart          软链 brew Caddyfile + 后端 LaunchAgent + brew services（改系统状态，先确认）
  verify             caddy validate + curl 路由探活
  status             打印已部署清单
环境: HERO_SITE_ROOT(默认 /var/www/hero-sites) HERO_SITE_PORT(默认 10086)
EOF
      exit 1 ;;
  esac
}
main "$@"
