#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
REPO="$(cd "$DIR/../.." && pwd)"
LAYERS="$REPO/docs/hero-agent-layers.md"

# 1. 分层总图 doc 存在，含四块标题
assert_ok "[ -f '$LAYERS' ]" "hero-agent-layers.md exists"
assert_ok "grep -q '## 分层总图' '$LAYERS'" "has 分层总图 section"
assert_ok "grep -q '## 能力矩阵' '$LAYERS'" "has 能力矩阵 section"
assert_ok "grep -q '## 新增 agent 登记规则' '$LAYERS'" "has 登记规则 section"
assert_ok "grep -q '## skills 维护入口' '$LAYERS'" "has skills 维护 section"

# 2. agents/ 下每个 hero-java-*.md 的 stem 都在 doc 里出现
for f in "$REPO"/agents/hero-java-*.md; do
  [ -f "$f" ] || continue
  stem="$(basename "$f" .md)"
  assert_ok "grep -qF '$stem' '$LAYERS'" "$stem appears in layers doc"
done

# 3. 四个层名都在 doc 里
for layer in 规划层 执行层 评审门控层 领航研究层; do
  assert_ok "grep -qF '$layer' '$LAYERS'" "layer name $layer in doc"
done

# 6. 9 个漫威中文代号都在 doc 里
for hero in 神盾局长 钢铁侠 幻视 蜘蛛侠 奇异博士 海姆达尔 火箭浣熊 星爵 猎鹰; do
  assert_ok "grep -qF '$hero' '$LAYERS'" "marvel name $hero in doc"
done

assert_summary
