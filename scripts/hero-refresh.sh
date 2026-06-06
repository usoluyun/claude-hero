#!/usr/bin/env bash
# hero-refresh 确定性层 CLI。
# 用法：
#   scripts/hero-refresh.sh [proj] [--force]   刷全部已接入项目，或只刷 proj；--force 忽略增量跳过
# 行为：对每个目标项目，HEAD 未变则跳过（除非 --force）；否则重索引 + 导出 evidence + 抓 vendor docs，回写状态。
# 退出后由 skill 接手做漂移检测/评审；本脚本不碰线上 agent。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/refresh-common.sh"
source "$HERE/lib/refresh-state.sh"
source "$HERE/lib/refresh-evidence.sh"
source "$HERE/lib/refresh-vendor.sh"
require_jq

FORCE=0; ONLY=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) ONLY="$arg" ;;
  esac
done

# 解析目标项目列表（在主 shell 校验，确保未知项目能真正 exit 1）
if [[ -n "$ONLY" ]]; then
  state_has "$ONLY" || { echo "ERROR: 项目 [${ONLY}] 不在已接入列表（见 docs/.refresh-state.json）" >&2; exit 1; }
  TARGET_LIST="$ONLY"
else
  TARGET_LIST="$(state_projects)"
fi

changed=()
while IFS= read -r proj; do
  [[ -z "$proj" ]] && continue
  repo="$(state_get "$proj" repo_path)"
  cur="$(repo_head "$repo")" || cur=""
  [[ -z "$cur" ]] && { echo "⚠ ${proj}：读不到 HEAD（仓库不存在？${repo}），跳过"; continue; }
  prev="$(state_get "$proj" last_commit)"
  if [[ "$FORCE" -eq 0 && "$cur" == "$prev" && -n "$prev" ]]; then
    echo "· ${proj}：无新 commit，跳过"
    continue
  fi
  echo "↻ ${proj}：重索引 + 导出 evidence + vendor docs …"
  reindex "$repo"
  export_evidence "$proj" "$repo"
  refresh_vendor_docs "$proj"
  state_set "$proj" last_commit "$cur"
  state_set "$proj" last_refreshed "$(date +%F)"
  changed+=("$proj")
done <<< "$TARGET_LIST"

echo
if [[ "${#changed[@]}" -eq 0 ]]; then
  echo "✓ 没有项目需要刷新（全部无变更）。"
else
  echo "✓ 已刷新确定性层：${changed[*]}"
  echo "  evidence 在 docs/.refresh-work/<proj>/，vendor docs 已更新。"
  echo "  下一步：在 Claude 里跑 hero 刷新 评审，逐个过这些项目的领航 agent 漂移。"
fi
