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

# 7. 9 个 agent 露出行：含本 agent 漫威名 + token（漫威名与 hero 露出都不漏）
TOKEN='🦸 hero ▸'
check_agent_hero() { # $1=agent file stem, $2=中文漫威名
  local f="$REPO/agents/$1.md"
  assert_ok "grep -qF '$TOKEN' '$f'" "$1 still has hero token"
  assert_ok "grep -qF '$2' '$f'" "$1 露出行 has marvel name $2"
}
check_agent_hero hero-java-tech-lead 神盾局长
check_agent_hero hero-java-backend-developer 钢铁侠
check_agent_hero hero-java-data-engineer 幻视
check_agent_hero hero-java-test-engineer 蜘蛛侠
check_agent_hero hero-java-code-reviewer 奇异博士
check_agent_hero hero-java-security-auditor 海姆达尔
check_agent_hero hero-java-ecrm 火箭浣熊
check_agent_hero hero-java-hotel-product-center 星爵
check_agent_hero hero-java-owner-biz 猎鹰

# 8. hero-conventions 露出模板含「英雄名（agent）」格式（含全角括号 （ 与 英雄名 字样）
CONV="$REPO/skills/hero-conventions/SKILL.md"
assert_ok "grep -q '英雄名' '$CONV'" "conventions template mentions 英雄名"
assert_ok "grep -qF '<英雄名>（<agent>）接手' '$CONV'" "conventions has 英雄名（agent）接手 format"

assert_summary
