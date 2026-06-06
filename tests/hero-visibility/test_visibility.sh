#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
REPO="$(cd "$DIR/../.." && pwd)"
TOKEN='🦸 hero ▸'

# 1. hero-conventions 含露出规范段 + 统一 token（事实源）
CONV="$REPO/skills/hero-conventions/SKILL.md"
assert_ok "[ -f '$CONV' ]" "hero-conventions exists"
assert_ok "grep -q '## hero 露出规范' '$CONV'" "conventions has 露出规范 section"
assert_ok "grep -qF '$TOKEN' '$CONV'" "conventions has token"

# 2. 每个 hero-java-* agent 含统一 token（子 agent 自报家门兜底）
for f in "$REPO"/agents/hero-java-*.md; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  assert_ok "grep -qF '$TOKEN' '$f'" "$base has hero token"
done

# 3. hero-dispatch SKILL 含 token
DISPATCH="$REPO/skills/hero-dispatch/SKILL.md"
assert_ok "grep -qF '$TOKEN' '$DISPATCH'" "hero-dispatch SKILL has hero token"

# 4. 6 条 lane 含 token（门控/收尾打点）
for lane in bugfix iterate refactor research perf security; do
  f="$REPO/skills/hero-dispatch/lanes/$lane.md"
  assert_ok "grep -qF '$TOKEN' '$f'" "lane $lane has hero token"
done

# 5. hero-refresh / hero-prd-to-java SKILL 含 token
for s in hero-refresh hero-prd-to-java; do
  f="$REPO/skills/$s/SKILL.md"
  assert_ok "[ -f '$f' ]" "$s SKILL.md exists"
  assert_ok "grep -qF '$TOKEN' '$f'" "$s has hero token"
done

assert_summary
