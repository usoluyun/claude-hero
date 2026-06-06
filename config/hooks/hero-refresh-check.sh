#!/usr/bin/env bash
# L1 SessionStart hook：秒级 git SHA 漂移检测，发现已接入项目有新 commit 就注入提醒。
# 纯只读：不重索引、不抓文档、不写文件。任何错误都静默退出，绝不阻塞会话启动。
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE="$ROOT/docs/.refresh-state.json"
command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$STATE" ]] || exit 0

stale=()
while IFS= read -r proj; do
  [[ -z "$proj" ]] && continue
  repo="$(jq -r --arg p "$proj" '.projects[$p].repo_path' "$STATE" 2>/dev/null)"
  [[ -z "$repo" || "$repo" == "null" ]] && continue
  case "$repo" in "~") repo="$HOME";; "~/"*) repo="$HOME/${repo#\~/}";; esac
  prev="$(jq -r --arg p "$proj" '.projects[$p].last_commit' "$STATE")"
  cur="$(git -C "$repo" rev-parse HEAD 2>/dev/null)" || continue
  [[ -z "$cur" ]] && continue
  if [[ "$cur" != "$prev" ]]; then stale+=("$proj"); fi
done < <(jq -r '.projects | keys[]' "$STATE" 2>/dev/null)

[[ "${#stale[@]}" -eq 0 ]] && exit 0

msg="⚠️ hero-refresh：以下已接入项目自上次刷新后有新 commit，建议在本会话跑 \`hero 刷新\`：${stale[*]}"
# 通过 SessionStart hook 的 additionalContext 把提醒注入会话上下文
jq -cn --arg c "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
