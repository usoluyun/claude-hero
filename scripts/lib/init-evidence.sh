#!/usr/bin/env bash
# 证据收集函数库。被 init-layout.sh 与 CLI source。无副作用（source 时不执行动作）。
# 依赖：refresh-common.sh 提供 expand_path；init-common.sh 提供 require_codegraph。
# 所有外部命令（codegraph/jq/find）调用失败均优雅回退，不中断调用方。

# ── 确保 expand_path 可用（init-common.sh 不提供它，从 refresh-common.sh 补） ──
if ! declare -f expand_path >/dev/null 2>&1; then
  _init_ev_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$_init_ev_libdir/refresh-common.sh" ]; then
    . "$_init_ev_libdir/refresh-common.sh"
  else
    expand_path() { local p="$1"; case "$p" in "~") echo "$HOME" ;; "~/"*) echo "$HOME/${p#\~/}" ;; *) echo "$p" ;; esac; }
  fi
fi

# ── collect_directory_structure ──────────────────────────────────────────────
# 参数: <repo_path>
# 行为: 收集项目目录结构（深度 3，排除 target/build/.gradle/.git/node_modules/__pycache__/.venv）
# 优先使用 codegraph files，失败则回退到 find + awk
# 输出: echo 目录树文本到 stdout

collect_directory_structure() {
  local repo; repo="$(expand_path "$1")"

  # 优先 codegraph
  if command -v codegraph >/dev/null 2>&1; then
    local out; out="$(codegraph files --format grouped -p "$repo" 2>/dev/null)" || true
    if [ -n "${out:-}" ]; then
      echo "$out"
      return 0
    fi
  fi

  # 回退：find + awk 生成目录树（深度 3，排除构建/版本控制/依赖目录）
  find "$repo" -maxdepth 3 -type d \
    -not \( -path '*/target' -o -path '*/target/*' \
         -o -path '*/build' -o -path '*/build/*' \
         -o -path '*/.gradle' -o -path '*/.gradle/*' \
         -o -path '*/.git' -o -path '*/.git/*' \
         -o -path '*/node_modules' -o -path '*/node_modules/*' \
         -o -path '*/__pycache__' -o -path '*/__pycache__/*' \
         -o -path '*/.venv' -o -path '*/.venv/*' \) \
    2>/dev/null | sort | \
    awk -v root="$repo" '
      {
        rel = substr($0, length(root) + 2)
        if (rel == "") next
        depth = split(rel, parts, "/")
        indent = ""
        for (i = 1; i < depth; i++) indent = indent "  "
        printf "%s%s/\n", indent, parts[depth]
      }'
}

# ── collect_config_files ─────────────────────────────────────────────────────
# 参数: <repo_path>
# 行为: 收集关键配置文件并返回 JSON 数组
# 输出: JSON 数组到 stdout（通过临时文件管道构建，避免 shell 中转破坏 JSON）

collect_config_files() {
  local repo; repo="$(expand_path "$1")"
  local tmp; tmp="$(mktemp)" || { echo '[]'; return 1; }
  echo '[]' > "$tmp"
  local f

  for f in \
    "src/main/resources/application.yml" \
    "src/main/resources/application.properties" \
    "src/main/resources/bootstrap.yml" \
    "src/main/resources/logback.xml" \
    "src/main/resources/logback-spring.xml" \
    "pom.xml" \
    "build.gradle" \
    "gradle.properties" \
    "settings.gradle" \
  ; do
    local full="$repo/$f"
    if [ -f "$full" ]; then
      jq -c --arg p "$f" --rawfile s "$full" \
        '. + [{"path":$p, "exists":true, "content_snippet": ($s | split("\n")[0:30] | join("\n"))}]' \
        "$tmp" > "$tmp.tmp" 2>/dev/null || {
        jq -c --arg p "$f" '. + [{"path":$p, "exists":true, "content_snippet": ""}]' "$tmp" > "$tmp.tmp"
      }
      mv "$tmp.tmp" "$tmp"
    else
      jq -c --arg p "$f" '. + [{"path":$p, "exists":false, "content_snippet": ""}]' "$tmp" > "$tmp.tmp"
      mv "$tmp.tmp" "$tmp"
    fi
  done
  cat "$tmp"
  rm -f "$tmp" "$tmp.tmp"
}

# ── collect_entry_points ─────────────────────────────────────────────────────
# 参数: <repo_path> <build_tool>
# 行为: 收集代码入口类（通过 codegraph query 搜索符号）
# 输出: JSON 对象到 stdout；codegraph 不可用时输出全空数组

collect_entry_points() {
  local repo; repo="$(expand_path "$1")"
  local build_tool="$2"

  if ! command -v codegraph >/dev/null 2>&1; then
    echo '{"controllers":[],"services":[],"mappers":[],"listeners":[],"jobs":[]}'
    return 0
  fi

  # 查询符号，返回行列表
  _query_sym_lines() {
    codegraph query "$1" -p "$repo" 2>/dev/null | while IFS= read -r line; do
      [ -z "$line" ] && continue
      printf '%s\n' "$line"
    done
  }

  # 查询符号，排除含指定子串的条目
  _query_sym_exclude_lines() {
    local sym="$1" exclude="$2"
    codegraph query "$sym" -p "$repo" 2>/dev/null | while IFS= read -r line; do
      [ -z "$line" ] && continue
      case "$line" in *"$exclude"*) continue ;; esac
      printf '%s\n' "$line"
    done
  }

  # 行列表 → JSON 数组
  _lines_to_json_array() {
    jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]'
  }

  local controllers_json services_json mappers_json listeners_json jobs_json

  controllers_json="$(_query_sym_lines "Controller" | _lines_to_json_array)"

  # Service：排除所有含 "Impl" 的实现类（ServiceImpl / AbstractServiceImpl 等）
  services_json="$(_query_sym_exclude_lines "Service" "Impl" | _lines_to_json_array)"

  mappers_json="$(_query_sym_lines "Mapper" | _lines_to_json_array)"

  # Listener: 合并 Listener + Consumer
  local listener_lines consumer_lines
  listener_lines="$(_query_sym_lines "Listener")"
  consumer_lines="$(_query_sym_lines "Consumer")"
  listeners_json="$(printf '%s\n%s' "$listener_lines" "$consumer_lines" | _lines_to_json_array)"

  # Job: 合并 Job + Task + Scheduler
  local job_lines task_lines sched_lines
  job_lines="$(_query_sym_lines "Job")"
  task_lines="$(_query_sym_lines "Task")"
  sched_lines="$(_query_sym_lines "Scheduler")"
  jobs_json="$(printf '%s\n%s\n%s' "$job_lines" "$task_lines" "$sched_lines" | _lines_to_json_array)"

  jq -n \
    --argjson c "$controllers_json" \
    --argjson s "$services_json" \
    --argjson m "$mappers_json" \
    --argjson l "$listeners_json" \
    --argjson j "$jobs_json" \
    '{controllers:$c, services:$s, mappers:$m, listeners:$l, jobs:$j}'
}
