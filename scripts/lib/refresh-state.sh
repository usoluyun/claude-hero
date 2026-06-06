#!/usr/bin/env bash
# .refresh-state.json 读写。依赖 refresh-common.sh（调用方负责先 source 它）。
# 允许用 HERO_STATE_FILE 覆盖状态文件路径（测试用）。

state_file() {
  if [[ -n "${HERO_STATE_FILE:-}" ]]; then echo "$HERO_STATE_FILE";
  else echo "$(repo_root)/docs/.refresh-state.json"; fi
}

state_projects() {  # 每行一个项目 key
  jq -r '.projects | keys[]' "$(state_file)" 2>/dev/null
}

state_has() {  # exit 0 若项目存在
  local proj="$1"
  jq -e --arg p "$proj" '.projects | has($p)' "$(state_file)" >/dev/null 2>&1
}

state_get() {  # echo 字段值
  local proj="$1" field="$2"
  jq -r --arg p "$proj" --arg f "$field" '.projects[$p][$f] // ""' "$(state_file)"
}

state_set() {  # 原地更新字段（仅限已存在项目）
  local proj="$1" field="$2" value="$3" f tmp
  state_has "$proj" || { echo "state_set: 未知项目 $proj" >&2; return 1; }
  f="$(state_file)"; tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN   # 无论成败都清理临时文件
  jq --arg p "$proj" --arg k "$field" --arg v "$value" \
     '.projects[$p][$k] = $v' "$f" > "$tmp" && mv "$tmp" "$f"
}
