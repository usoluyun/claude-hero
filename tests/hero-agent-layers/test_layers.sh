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

# 4. CLAUDE.md 含指向 hero-agent-layers.md 的链接
CLAUDEMD="$REPO/CLAUDE.md"
assert_ok "grep -qF 'hero-agent-layers.md' '$CLAUDEMD'" "CLAUDE.md links layers doc"

# 5. roster 含指向 hero-agent-layers.md 的 cross-link
ROSTER="$REPO/docs/hero-agent-roster.md"
assert_ok "grep -qF 'hero-agent-layers.md' '$ROSTER'" "roster cross-links layers doc"

# 9. 能力对齐加固（防回退）：phantom skill 已清 / 领航层 skills 已纠错 / codegraph 进 cli 清单
#    9a. 矩阵不再引用不存在的 security-review skill
assert_fail "grep -qF 'security-review' '$LAYERS'" "no phantom security-review skill in matrix"
#    9b. 领航三行不再把 hero-refresh 当 skills（旧式 '| hero-refresh | codegraph |' 配对应消失）
assert_fail "grep -qF 'hero-refresh | codegraph' '$LAYERS'" "navigators no longer list hero-refresh as skill"
#    9c. 领航层正向校验：codegraph 带路 字样在矩阵存在
assert_ok "grep -qF 'codegraph 带路，无需加载 skill' '$LAYERS'" "navigators use codegraph 带路"
#    9d. codegraph 已进 cli 清单且有专页
assert_ok "grep -qF 'codegraph' '$REPO/cli/README.md'" "cli README lists codegraph"
assert_ok "[ -f '$REPO/cli/codegraph.md' ]" "cli/codegraph.md exists"

# 10. 能力充足性加固（防回退）：正文点名要用的工具，必须真在 tools 白名单里
AG="$REPO/agents"
#    10a. backend/reviewer/security/tech-lead 正文都「查 context7」→ tools 必含 context7 MCP
for a in hero-java-backend-developer hero-java-code-reviewer hero-java-security-auditor hero-java-tech-lead; do
  assert_ok "grep -qE '^tools:.*context7' '$AG/$a.md'" "$a tools include context7 MCP"
done
#    10b. security 要查 CVE → tools 必含 WebSearch
assert_ok "grep -qE '^tools:.*WebSearch' '$AG/hero-java-security-auditor.md'" "security-auditor tools include WebSearch"
#    10c. tech-lead 要落盘 docs/*.md → tools 必含 Write
assert_ok "grep -qE '^tools:.*Write' '$AG/hero-java-tech-lead.md'" "tech-lead tools include Write"

# 11. code-reviewer 自带评审格式（复盘类A）：不再引用加载不了的 requesting-code-review skill
#     （白名单无 Skill 工具 → 加载不了；对齐 security-auditor 的自洽范式）
assert_fail "grep -qF 'requesting-code-review' '$LAYERS'" "matrix no longer lists requesting-code-review skill"
assert_fail "grep -qF 'requesting-code-review' '$AG/hero-java-code-reviewer.md'" "code-reviewer body no longer references requesting-code-review"
assert_ok "grep -qF '自带评审 checklist' '$LAYERS'" "code-reviewer matrix marks self-contained review format"

# 12. security-auditor 系统设计安全门控强化（spec 2026-06-07）
SA="$AG/hero-java-security-auditor.md"
assert_ok "grep -qF '🔴 强制门槛' '$SA'" "security 卡含 🔴 强制门槛"
assert_ok "grep -qF '🟡 提醒确认' '$SA'" "security 卡含 🟡 提醒确认"
assert_ok "grep -qF '⛔ 阻断' '$SA'" "security 卡含 ⛔ 阻断标记"
assert_ok "grep -qF '设计时' '$SA'" "security 卡含设计时工作法"
assert_ok "grep -qF '代码时' '$SA'" "security 卡含代码时工作法"
assert_ok "grep -qF 'semgrep' '$SA'" "security 卡引用 semgrep"
assert_ok "grep -qF 'gitleaks' '$SA'" "security 卡引用 gitleaks"
assert_ok "grep -qF 'security-standards.md' '$SA'" "security 卡引用合规规范"
assert_ok "grep -qE '^tools:.*WebSearch.*context7' '$SA'" "security tools 仍含 WebSearch+context7"
assert_fail "grep -qE '^tools:.*(Skill|Edit|Write)' '$SA'" "security tools 未引入 Skill/Edit/Write"

# 13. 矩阵 security 行反映双模 + 强制门槛 + SAST 工具
assert_ok "grep -qF 'semgrep' '$LAYERS'" "矩阵含 semgrep"
assert_ok "grep -qF 'gitleaks' '$LAYERS'" "矩阵含 gitleaks"
assert_ok "grep -qF '设计时' '$LAYERS'" "矩阵含双模（设计时）"
assert_ok "grep -qF '强制门槛' '$LAYERS'" "矩阵含强制门槛"

# 14. 合规规范文档（海姆达尔判定敏感/加密/鉴权的权威口径）
STD="$REPO/docs/security-standards.md"
assert_ok "[ -f '$STD' ]" "security-standards.md 存在"
assert_ok "grep -qF 'PCI-DSS' '$STD'" "含 PCI-DSS"
assert_ok "grep -qF '等保' '$STD'" "含 等保"
assert_ok "grep -qF 'PIPL' '$STD'" "含 PIPL"

# 15. 安全 CLI 文档 + README 收录
for c in semgrep gitleaks codeql; do
  assert_ok "[ -f '$REPO/cli/$c.md' ]" "cli/$c.md 存在"
  assert_ok "grep -qF '$c' '$REPO/cli/README.md'" "cli README 含 $c"
done

# 15. test-engineer 本地测试重塑（spec 2026-06-08）
TE="$AG/hero-java-test-engineer.md"
assert_ok "grep -qE '^skills:.*test-driven-development' '$TE'" "test 卡 skills: 预加载 tdd"
assert_ok "grep -qE '^skills:.*gherkin' '$TE'" "skills: 含 gherkin"
assert_ok "grep -qE '^skills:.*allure' '$TE'" "skills: 含 allure"
assert_ok "grep -qE '^tools:.*mcp__playwright__' '$TE'" "tools 含 Playwright MCP"
assert_ok "grep -qE '^tools:.*Edit.*Write' '$TE'" "tools 仍含 Edit/Write"
assert_ok "grep -qF 'httpie' '$TE'" "卡含 httpie 接口冒烟"
assert_ok "grep -qF 'Playwright MCP' '$TE'" "卡含 Playwright E2E"
assert_ok "grep -qF 'localhost' '$TE'" "卡含本地起服务打 localhost"
assert_fail "grep -qF 'Testcontainers' '$TE'" "卡不再依赖 Testcontainers"

assert_summary
