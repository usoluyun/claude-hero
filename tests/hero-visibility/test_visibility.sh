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

assert_summary
