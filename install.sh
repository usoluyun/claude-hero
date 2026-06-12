#!/usr/bin/env bash
#
# claude-hero 安装脚本
# 读取 manifest.yaml，把仓库内的共享资源软链/复制到 ~/.claude。
#
# 用法:
#   bash install.sh            # 安装到 $HOME/.claude
#   CLAUDE_HOME=/tmp/x install.sh   # 演练：指定目标根目录
#
# 设计原则:
#   - link 目录 => 子项逐个软链，绝不整目录覆盖
#   - 目标已存在且非本仓库软链 => 先备份 *.bak.<时间戳> 再建链
#   - template => 不写入，只在结尾提示手动合并
#   - 幂等：已是正确软链则跳过

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
MANIFEST="$REPO_DIR/manifest.yaml"
TS="$(date +%Y%m%d-%H%M%S)"

# 颜色（非 TTY 时关闭）
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_INFO=$'\033[36m'; C_RST=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_INFO=""; C_RST=""
fi

linked=()      # 新建/更新的软链
skipped=()     # 已正确，跳过
backed_up=()   # 备份过的旧文件
templates=()   # 待手动合并

log()  { printf '%s\n' "$*"; }
info() { printf '%s%s%s\n' "$C_INFO" "$*" "$C_RST"; }
ok()   { printf '%s%s%s\n' "$C_OK"   "$*" "$C_RST"; }
warn() { printf '%s%s%s\n' "$C_WARN" "$*" "$C_RST"; }

check_tmux() {
  if command -v tmux &> /dev/null; then
    local ver; ver="$(tmux -V 2>&1)"
    ok "✓ tmux 已安装：$ver"
    return
  fi

  warn "tmux 未安装（Agent Teams 分屏模式依赖 tmux）"

  if [ "$(uname -s)" = "Darwin" ]; then
    if command -v brew &> /dev/null; then
      log "  正在用 Homebrew 安装 tmux ..."
      if brew install tmux; then
        ok "✓ tmux 安装成功"
      else
        warn "✗ brew install tmux 失败，请手动安装"
      fi
    else
      log "  未找到 Homebrew，请先安装 https://brew.sh 再执行："
      log "    brew install tmux"
    fi
  elif command -v apt-get &> /dev/null; then
    log "  检测到 apt，尝试 sudo apt-get install tmux ..."
    if sudo apt-get install -y tmux; then
      ok "✓ tmux 安装成功"
    else
      warn "✗ 安装失败，请手动：apt-get install tmux"
    fi
  elif command -v yum &> /dev/null; then
    log "  检测到 yum，尝试 sudo yum install tmux ..."
    if sudo yum install -y tmux; then
      ok "✓ tmux 安装成功"
    else
      warn "✗ 安装失败，请手动：yum install tmux"
    fi
  else
    log "  无法自动安装，请手动安装 tmux："
    log "    https://github.com/tmux/tmux/wiki/Installing"
  fi
}

check_glab() {
  if command -v glab &> /dev/null; then
    local ver; ver="$(glab --version 2>&1)"
    ok "✓ glab 已安装：$ver"
    return
  fi

  warn "glab 未安装（GitLab CLI：终端管理 MR / CI / issue）"

  if [ "$(uname -s)" = "Darwin" ]; then
    if command -v brew &> /dev/null; then
      log "  正在用 Homebrew 安装 glab ..."
      if brew install glab; then
        ok "✓ glab 安装成功"
      else
        warn "✗ brew install glab 失败，请手动安装"
      fi
    else
      log "  未找到 Homebrew，请先安装 https://brew.sh 再执行："
      log "    brew install glab"
    fi
  elif command -v apt-get &> /dev/null; then
    log "  检测到 apt，尝试通过 GitLab 官方 deb 源安装 glab ..."
    local install_ok=true
    curl -fsSL "https://gitlab.com/gitlab-org/cli/-/raw/main/scripts/setup-apt.sh" | sudo bash || install_ok=false
    sudo apt-get update -qq && sudo apt-get install -y glab || install_ok=false
    if $install_ok; then
      ok "✓ glab 安装成功"
    else
      log "  官方源安装失败，请手动："
      log "    https://docs.gitlab.com/cli/install/"
    fi
  elif command -v yum &> /dev/null; then
    log "  检测到 yum，尝试用 rpm 源安装 glab ..."
    if curl -fsSL "https://gitlab.com/gitlab-org/cli/-/raw/main/scripts/setup-yum.sh" | sudo bash && sudo yum install -y glab; then
      ok "✓ glab 安装成功"
    else
      log "  安装失败，请手动下载："
      log "    https://gitlab.com/gitlab-org/cli/-/releases"
    fi
  else
    log "  无法自动安装，请手动安装 glab："
    log "    https://docs.gitlab.com/cli/install/"
  fi
}

# 解析 manifest.yaml 的 entries，输出 "source<TAB>target<TAB>mode"
parse_manifest() {
  awk '
    /^entries:/ { in_e=1; next }
    in_e && /^[[:space:]]*-[[:space:]]*source:/ {
      if (src != "") print src "\t" tgt "\t" mode
      src=$0; sub(/^[^:]*:[[:space:]]*/, "", src); tgt=""; mode=""; next
    }
    in_e && /^[[:space:]]*target:/ { tgt=$0; sub(/^[^:]*:[[:space:]]*/, "", tgt); next }
    in_e && /^[[:space:]]*mode:/   { mode=$0; sub(/^[^:]*:[[:space:]]*/, "", mode)
                                     sub(/[[:space:]]*#.*/, "", mode); next }
    END { if (src != "") print src "\t" tgt "\t" mode }
  ' "$MANIFEST"
}

# 软链单个 src_path -> dst_path，处理备份与幂等
link_one() {
  local src_path="$1" dst_path="$2"
  mkdir -p "$(dirname "$dst_path")"
  if [ -L "$dst_path" ]; then
    local cur; cur="$(readlink "$dst_path")"
    if [ "$cur" = "$src_path" ]; then
      skipped+=("$dst_path")
      return
    fi
    rm "$dst_path"   # 旧软链直接替换
  elif [ -e "$dst_path" ]; then
    mv "$dst_path" "$dst_path.bak.$TS"
    backed_up+=("$dst_path -> $dst_path.bak.$TS")
  fi
  ln -s "$src_path" "$dst_path"
  linked+=("$dst_path -> $src_path")
}

install_entry() {
  local source="$1" target="$2" mode="$3"
  local src_abs="$REPO_DIR/$source"
  local dst_abs="$CLAUDE_DIR/$target"

  case "$mode" in
    link)
      if [ -d "$src_abs" ]; then
        # 目录：子项逐个软链到 target/ 下
        mkdir -p "$dst_abs"
        local child
        for child in "$src_abs"/*; do
          [ -e "$child" ] || continue   # 空目录跳过
          link_one "$child" "$dst_abs/$(basename "$child")"
        done
      elif [ -e "$src_abs" ]; then
        link_one "$src_abs" "$dst_abs"
      else
        log "${C_WARN}跳过(源不存在): $source${C_RST}"
      fi
      ;;
    copy)
      mkdir -p "$(dirname "$dst_abs")"
      cp -R "$src_abs" "$dst_abs"
      linked+=("(copy) $dst_abs")
      ;;
    template)
      templates+=("$target  <=  $source")
      ;;
    *)
      log "${C_WARN}未知 mode '$mode' (source=$source)，已跳过${C_RST}"
      ;;
  esac
}

main() {
  [ -f "$MANIFEST" ] || { log "找不到 manifest.yaml: $MANIFEST"; exit 1; }
  info "claude-hero 安装"
  log  "  仓库:   $REPO_DIR"
  log  "  目标:   $CLAUDE_DIR"
  mkdir -p "$CLAUDE_DIR"

  # Agent Teams 依赖 tmux（分屏模式），先检查并尝试安装
  check_tmux
  echo
  check_glab
  echo

  while IFS=$'\t' read -r source target mode; do
    [ -n "$source" ] || continue
    install_entry "$source" "$target" "$mode"
  done < <(parse_manifest)

  echo
  info "==== 安装摘要 ===="
  if [ ${#linked[@]} -gt 0 ]; then
    log "${C_OK}已链接 (${#linked[@]}):${C_RST}"
    printf '  + %s\n' "${linked[@]}"
  fi
  if [ ${#skipped[@]} -gt 0 ]; then
    log "已是最新，跳过 (${#skipped[@]}):"
    printf '  = %s\n' "${skipped[@]}"
  fi
  if [ ${#backed_up[@]} -gt 0 ]; then
    log "${C_WARN}已备份原文件 (${#backed_up[@]}):${C_RST}"
    printf '  ~ %s\n' "${backed_up[@]}"
  fi
  if [ ${#templates[@]} -gt 0 ]; then
    echo
    log "${C_WARN}以下为模板，需手动合并（含密钥/高度个人化，未自动安装）:${C_RST}"
    printf '  ! %s\n' "${templates[@]}"
    log "    参考对应 example，按需合并进你的 $CLAUDE_DIR 下文件。"
  fi
  echo
  info "完成。"
}

main "$@"
