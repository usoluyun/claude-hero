#!/usr/bin/env bash
# 初始化公共工具函数。被其他 init-*.sh 与 CLI source。无副作用（source 时不执行动作）。
# 依赖: jq, codegraph CLI, git。
# 与 refresh-common.sh 互补：expand_path / require_jq 等通用函数走 refresh-common.sh。

require_codegraph() {  # 检查 codegraph CLI；失败返回 1 + 错误信息到 stderr
  command -v codegraph >/dev/null 2>&1 || {
    echo "ERROR: 需要 codegraph CLI，请先安装" >&2
    return 1
  }
}

read_json() {  # <file> <jq_filter> — 用 jq 读取 JSON 文件字段；文件不存在返回 1
  local file="$1" filter="$2"
  if [ ! -f "$file" ]; then
    echo "read_json: 文件不存在: $file" >&2
    return 1
  fi
  jq -r "$filter" "$file"
}

write_json() {  # <file> <jq_filter> — 用 jq filter 原子更新 JSON 文件（mktemp + mv）
  local file="$1" filter="$2" tmp
  tmp="$(mktemp)"
  if jq "$filter" "$file" > "$tmp" 2>/dev/null; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    echo "write_json: jq filter 执行失败: $filter" >&2
    return 1
  fi
}

init_work_dir() {  # <repo_path> — 创建 .init-work/ 目录并加入 git exclude；echo 目录路径
  local repo="$1" work_dir gitdir ex
  work_dir="$repo/.init-work"
  mkdir -p "$work_dir"
  # 非 git 仓库则跳过 exclude
  gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || true
  if [ -n "${gitdir:-}" ]; then
    ex="$gitdir/info/exclude"
    mkdir -p "$gitdir/info"
    grep -qxF '.init-work/' "$ex" 2>/dev/null || echo '.init-work/' >> "$ex"
  fi
  echo "$work_dir"
}

ensure_exclude_refresh() {  # <repo_path> — 将 .refresh-work/ 加入 git info/exclude（参考 refresh-evidence.sh ensure_exclude 模式）
  local repo="$1" gitdir ex
  gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || return 0
  ex="$gitdir/info/exclude"
  mkdir -p "$gitdir/info"
  grep -qxF '.refresh-work/' "$ex" 2>/dev/null || echo '.refresh-work/' >> "$ex"
}
