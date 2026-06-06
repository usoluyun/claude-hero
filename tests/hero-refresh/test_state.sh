#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/../../scripts/lib/refresh-common.sh"
source "$DIR/../../scripts/lib/refresh-state.sh"

export HERO_STATE_FILE="$(mktemp)"
cat > "$HERO_STATE_FILE" <<'JSON'
{ "projects": {
  "ecrm": { "repo_path": "~/Documents/ATLWork/ecrm", "agent": "hero-java-ecrm", "last_commit": "", "last_refreshed": "" }
} }
JSON

assert_eq "ecrm" "$(state_projects)" "列出项目"
assert_ok "state_has ecrm" "ecrm 存在"
assert_fail "state_has nope" "nope 不存在"
assert_eq "hero-java-ecrm" "$(state_get ecrm agent)" "读 agent 字段"
assert_eq "" "$(state_get ecrm last_commit)" "空字段读成空串"

state_set ecrm last_commit "abc123"
assert_eq "abc123" "$(state_get ecrm last_commit)" "写后能读到新值"

rm -f "$HERO_STATE_FILE"
assert_summary
