#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
REPO="$(cd "$DIR/../.." && pwd)"
SKILL="$REPO/skills/hero-dispatch/SKILL.md"
LANES="$REPO/skills/hero-dispatch/lanes"

# 1. SKILL.md 存在且 frontmatter name 正确
assert_ok "[ -f '$SKILL' ]" "SKILL.md exists"
name="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL" 2>/dev/null | head -1)"
assert_eq "hero-dispatch" "$name" "SKILL name"

# 2. catalog 引用的 lanes/*.md 都存在
for ref in $(grep -o 'lanes/[a-z]*\.md' "$SKILL" | sort -u); do
  assert_ok "[ -f '$REPO/skills/hero-dispatch/$ref' ]" "catalog ref $ref exists"
done

# 3. 6 条 lane 文件齐全
for lane in bugfix iterate refactor research perf security; do
  assert_ok "[ -f '$LANES/$lane.md' ]" "lane $lane exists"
done

# 4. 每条 lane frontmatter 必备字段 + archetype 枚举
if [ -d "$LANES" ]; then
  for f in "$LANES"/*.md; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    for key in lane archetype intent_keywords required_input; do
      assert_ok "grep -q '^$key:' '$f'" "$base has $key"
    done
    arch="$(sed -n 's/^archetype:[[:space:]]*//p' "$f" | awk '{print $1}' | head -1)"
    assert_ok "[ '$arch' = mutate ] || [ '$arch' = readonly ] || [ '$arch' = two-phase ]" "$base archetype enum: $arch"
  done
fi

assert_summary
