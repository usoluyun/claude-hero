#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"

# 准备临时仓库（充当被刷项目）
proj_repo="$(mktemp -d)"; git -C "$proj_repo" init -q
git -C "$proj_repo" -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init
sha="$(git -C "$proj_repo" rev-parse HEAD)"

export HERO_STATE_FILE="$(mktemp)"
cat > "$HERO_STATE_FILE" <<JSON
{ "projects": { "demo": { "repo_path": "$proj_repo", "agent": "hero-java-demo", "last_commit": "", "last_refreshed": "" } } }
JSON

# 用 stub 覆盖触外部的函数，避免真跑 codegraph/curl
out="$(bash -c '
  source '"$DIR"'/../../scripts/lib/refresh-common.sh
  source '"$DIR"'/../../scripts/lib/refresh-state.sh
  source '"$DIR"'/../../scripts/lib/refresh-evidence.sh
  source '"$DIR"'/../../scripts/lib/refresh-vendor.sh
  reindex(){ echo STUB_REINDEX; }; export_evidence(){ :; }; refresh_vendor_docs(){ :; }
  # 复刻 CLI 主循环（简化：只验跳过/触发）
  for proj in $(state_projects); do
    repo="$(state_get "$proj" repo_path)"; cur="$(repo_head "$repo")" || cur=""; prev="$(state_get "$proj" last_commit)"
    if [[ "$cur" == "$prev" && -n "$prev" ]]; then echo "SKIP $proj"; continue; fi
    reindex "$repo"; state_set "$proj" last_commit "$cur"
  done
')"
assert_ok "grep -q STUB_REINDEX <<<\"$out\"" "首次（last_commit空）触发重索引"
assert_eq "$sha" "$(HERO_STATE_FILE=$HERO_STATE_FILE bash -c 'source '"$DIR"'/../../scripts/lib/refresh-common.sh; source '"$DIR"'/../../scripts/lib/refresh-state.sh; state_get demo last_commit')" "回写了 HEAD"

# 未知项目必须 exit 1（回归：exit 1 曾被 process-sub 子shell吞掉）
st_empty="$(mktemp)"; echo '{ "projects": {} }' > "$st_empty"
HERO_STATE_FILE="$st_empty" bash "$DIR/../../scripts/hero-refresh.sh" __nope__ >/dev/null 2>&1; rc=$?
assert_eq "1" "$rc" "未知项目退出码为 1"
rm -f "$st_empty"

rm -rf "$proj_repo"; rm -f "$HERO_STATE_FILE"
assert_summary
