# hero Agent 分层 + 能力矩阵 + 漫威命名 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 9 个 hero-java agent 建立分层总图 + 能力矩阵脚手架，给每个 agent 起漫威代号并落到 hero 露出标记，全程用 bash 结构测试卡死防漂移。

**Architecture:** 纯文档 + prose 约定改动。新建一份 `docs/hero-agent-layers.md` 作为分层/矩阵/漫威映射的唯一事实源；把漫威名落到 `hero-conventions` 露出模板与 9 个 agent 的露出行（只改露出行）；CLAUDE.md / roster 接线交叉引用。新增 `tests/hero-agent-layers/` 结构测试，沿用 `tests/hero-visibility/` 的 bash 3.2 风格（`grep -qF` 卡字面）。

**Tech Stack:** Markdown 文档、bash 3.2 结构测试（assert.sh / run.sh / test_*.sh）、git。

**约束：** bash 3.2 兼容（无关联数组、无 `${var^^}`、`set -u` 下用 `[ -f "$f" ] || continue` 防空 glob）。漫威名纯装饰不可路由；token `🦸 hero ▸` 一字不改，既有 `tests/hero-visibility/` 不得回归。

---

## File Structure

- **Create** `docs/hero-agent-layers.md` — 分层总图 + 漫威映射 + 露出格式 + 能力矩阵 + 登记规则 + skills 维护入口（唯一事实源）。
- **Create** `tests/hero-agent-layers/assert.sh` — 断言助手（从 `tests/hero-visibility/assert.sh` 原样复制）。
- **Create** `tests/hero-agent-layers/run.sh` — 跑本目录所有 `test_*.sh`（从 hero-visibility 改注释）。
- **Create** `tests/hero-agent-layers/test_layers.sh` — 结构断言，跨 Task 1→3 增量构建。
- **Modify** `skills/hero-conventions/SKILL.md:42` — `agent 接手` 模板升级为英雄名（agent）格式。
- **Modify** `agents/hero-java-*.md`（9 个）— 各自露出行替换为带漫威名版本（**只改露出行**）。
- **Modify** `CLAUDE.md` — 文档索引加一行 + 资产目录速查 `agents/` 段收敛去重。
- **Modify** `docs/hero-agent-roster.md:1-13` 区间开头 — 加 cross-link 到 layers doc。

---

## Task 1: 分层总图 doc + 测试脚手架

**Files:**
- Create: `tests/hero-agent-layers/assert.sh`
- Create: `tests/hero-agent-layers/run.sh`
- Create: `tests/hero-agent-layers/test_layers.sh`
- Create: `docs/hero-agent-layers.md`

- [ ] **Step 1: 复制断言助手与 runner**

```bash
mkdir -p tests/hero-agent-layers
cp tests/hero-visibility/assert.sh tests/hero-agent-layers/assert.sh
```

新建 `tests/hero-agent-layers/run.sh`（内容如下，注意注释已改为 hero-agent-layers）：

```bash
#!/usr/bin/env bash
# 跑 tests/hero-agent-layers 下所有 test_*.sh，任一失败则整体失败。
set -u
cd "$(dirname "$0")"
fail=0
for t in test_*.sh; do
  [ -f "$t" ] || continue
  echo "== $t =="
  bash "$t" || fail=1
done
[[ "$fail" -eq 0 ]] && echo "ALL TESTS PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
```

- [ ] **Step 2: 写失败测试（分层总图 doc 结构 + 漫威名 + 分层骨架）**

新建 `tests/hero-agent-layers/test_layers.sh`：

```bash
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
```

- [ ] **Step 3: 跑测试确认失败**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: FAIL —— `hero-agent-layers.md exists` 等断言报 ✗（doc 尚未创建）。

- [ ] **Step 4: 创建 `docs/hero-agent-layers.md`**

写入以下完整内容：

````markdown
# hero Agent 分层总图

> 一页看清 9 个 `hero-java-*` agent 谁在哪一层、叫什么代号、怎么用。
> 两条正交轴：**角色 agent（横向干活）× 项目领航 agent（按服务只读带路）**。
> 参考 oh-my-openagent 的 orchestration / planning / execution / specialist 分层，落到团队本土话术。
> 本表是**分层 + 漫威代号 + 能力**的唯一事实源；领航层触发明细见
> [`hero-agent-roster.md`](./hero-agent-roster.md)。

## 分层总图

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        神盾局长 Nick Fury     hero-java-tech-lead              (opus)
 ├─ 执行层        钢铁侠 Iron Man        hero-java-backend-developer      (sonnet)
 │                幻视 Vision            hero-java-data-engineer          (sonnet)
 │                蜘蛛侠 Spider-Man      hero-java-test-engineer          (sonnet)
 └─ 评审门控层    奇异博士 Doctor Strange hero-java-code-reviewer         (opus, 只读)
                  海姆达尔 Heimdall      hero-java-security-auditor       (opus, 只读)
项目领航 agent（按服务只读带路 = 领航研究层）
                  火箭浣熊 Rocket        hero-java-ecrm                   (sonnet, 只读)
                  星爵 Star-Lord         hero-java-hotel-product-center   (sonnet, 只读)
                  猎鹰 Falcon            hero-java-owner-biz              (sonnet, 只读)
```

正交性：角色 agent 跨服务通用、横向干活（规划/执行/评审三梯）；项目领航 agent 绑定单个服务、
只读带路。二者不重叠：领航 agent 圈定"在哪改、影响谁"，角色 agent 负责"具体怎么改"。

与 oh-my-openagent 分层的对应（仅记来源，不进团队话术）：

| 本团队层 | 对应 omo 层 |
|---|---|
| 规划层 | Planning（Prometheus/Atlas）+ Orchestration（Sisyphus） |
| 执行层 | Worker/Execution（Hephaestus/Sisyphus-Junior） |
| 评审门控层 | Specialist 中的只读评审（Momus/Oracle 审查面） |
| 领航研究层 | Specialist/Research（Oracle/Librarian/Explore） |

## 漫威代号映射

按各 agent 特点取名，**纯装饰/记忆点**：只用于露出标记与本表，不做"用英雄名调用"的路由。

| Agent | 漫威代号 | 取名理由（贴特点） |
|---|---|---|
| `hero-java-tech-lead` | 神盾局长 Nick Fury | 组建团队、拆任务派活、最后验收——天生编排者 |
| `hero-java-backend-developer` | 钢铁侠 Iron Man | 亲手造装备/写实现，工程师本色 |
| `hero-java-data-engineer` | 幻视 Vision | 由数据而生、擅综合；跨 MySQL/SQLServer 方言=多源数据合成 |
| `hero-java-test-engineer` | 蜘蛛侠 Spider-Man | 蜘蛛感应提前预警=测试在出事前抓 bug |
| `hero-java-code-reviewer` | 奇异博士 Doctor Strange | 推演千万结局找隐患=正确性/质量评审 |
| `hero-java-security-auditor` | 海姆达尔 Heimdall | 阿斯加德守门人、洞察一切入侵=安全审计守门 |
| `hero-java-ecrm` | 火箭浣熊 Rocket | 把不按常理的怪装备玩明白；ecrm 非 Spring 特殊栈(ActionSoft BPM) |
| `hero-java-hotel-product-center` | 星爵 Star-Lord | 带队探索定位；产品中心是定价/映射枢纽 |
| `hero-java-owner-biz` | 猎鹰 Falcon | 空中侦察大范围地形=大单体多业务域"摸地图" |

## 露出标记格式

`agent 接手`时机的 hero 露出标记带英雄名（详见 `hero-conventions` 露出规范）：

`🦸 hero ▸ <英雄名>（<agent>）接手 · <职责>`

例：`🦸 hero ▸ 钢铁侠（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`

前缀 token `🦸 hero ▸` 一字不改；英雄名作记忆点、agent 技术名供排查时不歧义定位。

## 能力矩阵

按层分组，每行一个 agent。`漫威代号 / 层 / model / 怎么用` 必填；`触发词 / 应加载 skills /
该用 CLI` 允许 `TODO`（待后续逐个 agent 填深）。**本表填好一格 → 去改对应 agent 文件 → 双向对齐**
（改 agent 文件是后续工作）。`TODO` 是约定哨兵值，代表"待补"，非缺漏。

### 规划层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-tech-lead` | 神盾局长 | opus | TODO | superpowers:brainstorming, superpowers:writing-plans, hero-conventions | codegraph | 给它特性/需求 → 产出架构设计+任务分派清单 → 主会话据此分派各专家 → 回它汇总验收 |

### 执行层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-backend-developer` | 钢铁侠 | sonnet | TODO | hero-conventions, superpowers:test-driven-development | maven, gradle, jdk-multiversion | 给它明确任务 → 实现 Controller/Service/DAO 与中间件接入，TDD-first |
| `hero-java-data-engineer` | 幻视 | sonnet | TODO | hero-conventions | mycli（MySQL）, SQLServer CLI TODO | 给它 SQL/数据层需求 → 产出 MyBatis mapper/XML、resultMap、慢查询调优 |
| `hero-java-test-engineer` | 蜘蛛侠 | sonnet | TODO | superpowers:test-driven-development, gherkin, allure | maven, gradle | 给它待测代码 → 产出 JUnit5 单测 / Gherkin BDD .feature / 集成测试 |

### 评审门控层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-code-reviewer` | 奇异博士 | opus（只读） | TODO | superpowers:requesting-code-review, hero-conventions | TODO | 给它 diff/SHA → 产出正确性与质量问题清单（不改码） |
| `hero-java-security-auditor` | 海姆达尔 | opus（只读） | TODO | security-review | TODO | 给它代码/配置 → 产出安全风险（CVE/注入/越权）与修复建议（只读） |

### 领航研究层（只读带路）

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-ecrm` | 火箭浣熊 | sonnet（只读） | ecrm、企业连锁促销审批、申请审批工作流、OpenAPI、BPMN、ActionSoft、AWS BPM、企业协议、连锁申请、促销活动审批 | hero-refresh | codegraph | 给它 ecrm 意图 → 定位代码/讲 BPMN 审批流走向/圈影响面（只读带路） |
| `hero-java-hotel-product-center` | 星爵 | sonnet（只读） | 房价码、RateCode、产品管理、定价、渠道映射、房型映射、CRS 房价码、市场价、价格模板 | hero-refresh | codegraph | 给它产品中心意图 → 定位代码/讲房价码或产品接口走向/圈影响面（只读带路） |
| `hero-java-owner-biz` | 猎鹰 | sonnet（只读） | 业主 App、业主 Web 后端、Banner、连锁用户、业主通讯录、合同、供应商评价、GOP 大数据、日报月报、消息推送、摸地图 | hero-refresh | codegraph | 给它业主端意图 → 在多业务域里找入口/看跨域调用/圈影响面（只读带路） |

> 触发词列：领航 agent 取自 [`hero-agent-roster.md`](./hero-agent-roster.md)「业务关键词/别名」，须与之一致；
> 角色 agent 暂无显式触发锚点，标 `TODO`，待后续补。

## 新增 agent 登记规则

加一个 agent 时按此走，保证落位确定、不漏归层：

1. **选轴**：横向干活 → 角色 agent；按服务只读带路 → 项目领航 agent。
2. **选层**：角色 → 规划 / 执行 / 评审门控 其一；领航 → 领航研究层。
3. **命名** `hero-<lang>-<...>`，文件名 = frontmatter `name`（见 [`CONTRIBUTING.md`](../CONTRIBUTING.md)）。
4. **起漫威代号**：在「漫威代号映射」补一行（按特点取名）。
5. **补能力矩阵**：在对应层的表补一行（漫威代号/model/怎么用 必填，其余可 `TODO`）。
6. **改露出行**：在该 agent 文件 `## hero 露出` 写带英雄名的自报家门行。
7. 若是**领航 agent**，另在 [`hero-agent-roster.md`](./hero-agent-roster.md) 登记一行。
8. 跑 `bash tests/hero-agent-layers/run.sh` 确认未漏归层 / 漏代号。

## skills 维护入口

能力矩阵的「应加载 skills」列即 **skill → agent 反查索引**：改动 / 废弃某个 skill 时，
`grep '<skill-name>' docs/hero-agent-layers.md` 即知影响哪些 agent，逐个评估同步。
（当前多数角色 agent 的 skills 仍是首填基线 + `TODO`，会随后续逐个 agent 填深而完善。）
````

- [ ] **Step 5: 跑测试确认通过**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: PASS —— `→ N passed, 0 failed` 且末行 `ALL TESTS PASSED`。

- [ ] **Step 6: Commit**

```bash
git add tests/hero-agent-layers/ docs/hero-agent-layers.md
git commit -m "feat(hero-agent-layers): 分层总图 + 能力矩阵 + 漫威映射 doc + 测试脚手架"
```

---

## Task 2: 漫威名落到 hero-conventions 模板 + 9 个 agent 露出行

**Files:**
- Modify: `tests/hero-agent-layers/test_layers.sh`（追加断言 7、8）
- Modify: `skills/hero-conventions/SKILL.md:42`
- Modify: `agents/hero-java-backend-developer.md`、`hero-java-data-engineer.md`、`hero-java-test-engineer.md`、`hero-java-code-reviewer.md`、`hero-java-security-auditor.md`、`hero-java-tech-lead.md`、`hero-java-ecrm.md`、`hero-java-hotel-product-center.md`、`hero-java-owner-biz.md`（各改露出行一行）

- [ ] **Step 1: 追加失败断言（露出行带漫威名 + token；conventions 模板含英雄名格式）**

在 `tests/hero-agent-layers/test_layers.sh` 的 `assert_summary` 行**之前**插入：

```bash
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
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: FAIL —— `... has marvel name ...` 与 `conventions ... 英雄名 ...` 断言报 ✗。

- [ ] **Step 3: 升级 hero-conventions 露出模板**

在 `skills/hero-conventions/SKILL.md` 把 `agent 接手` 那行表格（第 42 行）：

```
| agent 接手 | `🦸 hero ▸ <agent> 接手 · <一句职责>` |
```

改为：

```
| agent 接手 | `🦸 hero ▸ <英雄名>（<agent>）接手 · <一句职责>`（英雄名见 `docs/hero-agent-layers.md` 漫威代号映射） |
```

- [ ] **Step 4: 替换 9 个 agent 的露出行**

逐个文件把现有露出行整行替换为带漫威名版本（**只改这一行**，正文不动）：

| 文件 | 新露出行 |
|---|---|
| `agents/hero-java-backend-developer.md` | `` `🦸 hero ▸ 钢铁侠（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first` `` |
| `agents/hero-java-data-engineer.md` | `` `🦸 hero ▸ 幻视（hero-java-data-engineer）接手 · 复杂 SQL / 数据处理` `` |
| `agents/hero-java-test-engineer.md` | `` `🦸 hero ▸ 蜘蛛侠（hero-java-test-engineer）接手 · 测试编写` `` |
| `agents/hero-java-code-reviewer.md` | `` `🦸 hero ▸ 奇异博士（hero-java-code-reviewer）接手 · 代码评审` `` |
| `agents/hero-java-security-auditor.md` | `` `🦸 hero ▸ 海姆达尔（hero-java-security-auditor）接手 · 安全审计` `` |
| `agents/hero-java-tech-lead.md` | `` `🦸 hero ▸ 神盾局长（hero-java-tech-lead）接手 · 技术方案 / 任务拆解` `` |
| `agents/hero-java-ecrm.md` | `` `🦸 hero ▸ 火箭浣熊（hero-java-ecrm）接手 · ecrm 服务领航（只读带路）` `` |
| `agents/hero-java-hotel-product-center.md` | `` `🦸 hero ▸ 星爵（hero-java-hotel-product-center）接手 · 酒店产品中心领航（只读带路）` `` |
| `agents/hero-java-owner-biz.md` | `` `🦸 hero ▸ 猎鹰（hero-java-owner-biz）接手 · owner-biz 领航（只读带路）` `` |

对每个文件，把旧行 `` `🦸 hero ▸ <agent> 接手 · <职责>` `` 用 Edit 精确替换为上表对应新行（旧行原文见各文件，职责短语保持不变，仅在 agent 名前加 `<英雄中文名>（` 、agent 名后加 `）`）。

- [ ] **Step 5: 跑测试确认通过 + hero-visibility 不回归**

Run: `bash tests/hero-agent-layers/run.sh && bash tests/hero-visibility/run.sh`
Expected: 两个都 `ALL TESTS PASSED`（hero-visibility 因 token 前缀未变，继续全绿）。

- [ ] **Step 6: Commit**

```bash
git add tests/hero-agent-layers/test_layers.sh skills/hero-conventions/SKILL.md agents/hero-java-*.md
git commit -m "feat(hero-agent-layers): 漫威名落到 hero-conventions 模板 + 9 agent 露出行"
```

---

## Task 3: 导航接线（CLAUDE.md / roster）+ 全量验证

**Files:**
- Modify: `tests/hero-agent-layers/test_layers.sh`（追加断言 4、5）
- Modify: `CLAUDE.md`
- Modify: `docs/hero-agent-roster.md`

- [ ] **Step 1: 追加失败断言（CLAUDE.md 与 roster 交叉链接）**

在 `tests/hero-agent-layers/test_layers.sh` 的 `assert_summary` 行**之前**插入：

```bash
# 4. CLAUDE.md 含指向 hero-agent-layers.md 的链接
CLAUDEMD="$REPO/CLAUDE.md"
assert_ok "grep -qF 'hero-agent-layers.md' '$CLAUDEMD'" "CLAUDE.md links layers doc"

# 5. roster 含指向 hero-agent-layers.md 的 cross-link
ROSTER="$REPO/docs/hero-agent-roster.md"
assert_ok "grep -qF 'hero-agent-layers.md' '$ROSTER'" "roster cross-links layers doc"
```

- [ ] **Step 2: 跑测试确认失败**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: FAIL —— `CLAUDE.md links layers doc`、`roster cross-links layers doc` 报 ✗。

- [ ] **Step 3: CLAUDE.md 文档索引加一行**

在 `CLAUDE.md` 「## 文档索引（docs/）」表格里，`hero-agent-roster.md` 行**之后**插入一行：

```
| [`hero-agent-layers.md`](./docs/hero-agent-layers.md) | agent 分层总图 + 能力矩阵（双轴 + 角色三梯 + 漫威代号，skills/CLI 施工底图） | 看全景分层 / 加新 agent / 查 skill 用在哪 |
```

- [ ] **Step 4: CLAUDE.md 资产目录速查 `agents/` 段收敛去重**

把 `CLAUDE.md` 「## 资产目录速查」里 `agents/` 那段（描述「角色 agent / 项目领航 agent」两类的整段）替换为收敛一句 + 链向分层总图：

```
- **`agents/`** — 共享 subagent（`hero-java-*.md`），按**双轴分层**组织：角色 agent（规划/执行/
  评审门控三梯，横向干活）× 项目领航 agent（按服务只读带路）。完整分层 + 漫威代号 + 能力矩阵见
  [`docs/hero-agent-layers.md`](./docs/hero-agent-layers.md)。
```

- [ ] **Step 5: roster 开头加 cross-link**

在 `docs/hero-agent-roster.md` 标题 `# 项目领航 Agent 花名册（roster）` 之后、首个 `>` 引用块之前，插入一行：

```
> 本表是**领航研究层**明细；全局分层（含角色 agent）+ 漫威代号见 [`hero-agent-layers.md`](./hero-agent-layers.md)。
```

- [ ] **Step 6: 跑全量测试（本套 + 不回归）**

Run: `bash tests/hero-agent-layers/run.sh && bash tests/hero-visibility/run.sh && bash tests/hero-dispatch/run.sh && bash tests/hero-refresh/run.sh`
Expected: 四套全部 `ALL TESTS PASSED`。

- [ ] **Step 7: install dry-run 演练（不碰真实 ~/.claude）**

Run: `CLAUDE_HOME=/tmp/hero-layers-dryrun bash install.sh && echo "INSTALL OK"`
Expected: 结尾 `INSTALL OK`，无报错（新增 tests/docs 不影响软链）。

- [ ] **Step 8: Commit**

```bash
git add tests/hero-agent-layers/test_layers.sh CLAUDE.md docs/hero-agent-roster.md
git commit -m "feat(hero-agent-layers): CLAUDE.md/roster 接线交叉引用 + 全量验证"
```

---

## 自审记录（spec 覆盖核对）

- 分层骨架（双轴 + 角色三梯 + 领航研究层）→ Task 1 doc 分层总图 + 测试断言 3。✅
- 能力矩阵（含漫威代号列 + 现状首填 + TODO 哨兵）→ Task 1 doc 能力矩阵 + 首填基线全部写入。✅
- 漫威代号映射（9 个按特点）→ Task 1 doc 漫威代号映射 + 测试断言 6。✅
- 露出带名（hero-conventions 模板 + 9 agent 露出行，token 不变）→ Task 2 + 测试断言 7、8 + hero-visibility 不回归。✅
- 新增 agent 登记规则 + skills 维护入口 → Task 1 doc 两节 + 测试断言 1。✅
- CLAUDE.md / roster 接线去重 → Task 3 + 测试断言 4、5。✅
- 验收：四套测试不回归 + install dry-run → Task 3 Step 6、7。✅
- 非目标守住：不改 agent 正文（只改露出行）、不动 dispatch/路由、漫威名不可路由、不填深 skills/CLI（留 TODO）。✅
