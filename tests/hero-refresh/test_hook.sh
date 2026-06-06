#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"

repo="$(mktemp -d)"; git -C "$repo" init -q
git -C "$repo" -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init
sha="$(git -C "$repo" rev-parse HEAD)"

root="$(mktemp -d)"; mkdir -p "$root/docs" "$root/config/hooks"
cp "$DIR/../../config/hooks/hero-refresh-check.sh" "$root/config/hooks/"

# 状态里 last_commit 为空 → 视为漂移
cat > "$root/docs/.refresh-state.json" <<JSON
{ "projects": { "demo": { "repo_path": "$repo", "agent": "x", "last_commit": "", "last_refreshed": "" } } }
JSON
out="$(CLAUDE_PROJECT_DIR="$root" bash "$root/config/hooks/hero-refresh-check.sh")"
echo "$out" | grep -q 'additionalContext' && assert_ok "true" "有漂移时输出 additionalContext" || assert_ok "false" "有漂移时输出 additionalContext"
echo "$out" | grep -q 'demo'             && assert_ok "true" "提醒里点名 demo"             || assert_ok "false" "提醒里点名 demo"

# last_commit = 当前 sha → 无漂移，应无输出
cat > "$root/docs/.refresh-state.json" <<JSON
{ "projects": { "demo": { "repo_path": "$repo", "agent": "x", "last_commit": "$sha", "last_refreshed": "2026-06-06" } } }
JSON
out2="$(CLAUDE_PROJECT_DIR="$root" bash "$root/config/hooks/hero-refresh-check.sh")"
assert_eq "" "$out2" "无漂移时零输出（不阻塞、不打扰）"

rm -rf "$repo" "$root"
assert_summary
