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
