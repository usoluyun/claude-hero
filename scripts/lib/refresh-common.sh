#!/usr/bin/env bash
# 公共工具函数。被其他 lib 与 CLI source。无副作用（source 时不执行动作）。

expand_path() {  # 展开开头的 ~
  local p="$1"
  case "$p" in
    "~") echo "$HOME" ;;
    "~/"*) echo "$HOME/${p#\~/}" ;;
    *) echo "$p" ;;
  esac
}

require_jq() {
  command -v jq >/dev/null 2>&1 || { echo "ERROR: 需要 jq，请先 brew install jq" >&2; return 1; }
}

repo_root() {  # claude-hero 仓库根 = 本文件所在 scripts/lib 的上两级
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  (cd "$lib_dir/../.." && pwd)  # 子 shell，避免污染调用方 cwd
}

repo_head() {  # 给定本地仓库路径，echo 当前 HEAD sha
  local repo; repo="$(expand_path "$1")"
  git -C "$repo" rev-parse HEAD 2>/dev/null
}
