#!/usr/bin/env bash
#
# claude-hero 卸载脚本
# 只删除"指向本仓库"的软链，绝不动 *.bak 备份与个人文件。
#
# 用法:
#   bash uninstall.sh
#   CLAUDE_HOME=/tmp/x uninstall.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
MANIFEST="$REPO_DIR/manifest.yaml"

if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_INFO=$'\033[36m'; C_RST=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_INFO=""; C_RST=""
fi

removed=()
kept=()

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

# 删除一个软链，前提：它指向本仓库内部
remove_if_ours() {
  local path="$1"
  if [ -L "$path" ]; then
    local tgt; tgt="$(readlink "$path")"
    case "$tgt" in
      "$REPO_DIR"/*) rm "$path"; removed+=("$path") ;;
      *)             kept+=("$path (指向 $tgt，非本仓库，保留)") ;;
    esac
  fi
}

main() {
  [ -f "$MANIFEST" ] || { echo "找不到 manifest.yaml: $MANIFEST"; exit 1; }
  printf '%sclaude-hero 卸载%s\n' "$C_INFO" "$C_RST"
  printf '  目标: %s\n' "$CLAUDE_DIR"

  while IFS=$'\t' read -r source target mode; do
    [ -n "$source" ] || continue
    [ "$mode" = "link" ] || continue   # 只处理 link 模式
    local src_abs="$REPO_DIR/$source"
    local dst_abs="$CLAUDE_DIR/$target"
    if [ -d "$src_abs" ]; then
      local child base
      for child in "$src_abs"/*; do
        [ -e "$child" ] || continue
        base="$(basename "$child")"
        remove_if_ours "$dst_abs/$base"
      done
    else
      remove_if_ours "$dst_abs"
    fi
  done < <(parse_manifest)

  echo
  if [ ${#removed[@]} -gt 0 ]; then
    printf '%s已移除软链 (%d):%s\n' "$C_OK" "${#removed[@]}" "$C_RST"
    printf '  - %s\n' "${removed[@]}"
  else
    echo "没有找到指向本仓库的软链。"
  fi
  if [ ${#kept[@]} -gt 0 ]; then
    printf '%s保留 (%d):%s\n' "$C_WARN" "${#kept[@]}" "$C_RST"
    printf '  = %s\n' "${kept[@]}"
  fi
  echo
  printf '%s注意：%s.bak.* 备份与个人 CLAUDE.md / settings.json 未被触碰。\n' "$C_WARN" "$C_RST"
}

main "$@"
