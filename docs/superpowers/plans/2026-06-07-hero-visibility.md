# hero 露出机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让所有 hero skill 触发、hero agent 运作时打出统一的 `🦸 hero ▸` 单行标记，使用户感知 hero 体系正在接管。

**Architecture:** 纯文案约定——在 `hero-conventions` 定义唯一标记规范（事实源），各 skill/agent 内联同构露出指令；新增 `tests/hero-visibility/` 结构测试用 `grep -qF` 卡死统一 token，防漏防漂移。子 agent 接手用「编排方主打 + 子 agent 自打」双保险。

**Tech Stack:** Markdown（skill/agent 提示词）、bash 3.2 测试脚本（复用 `tests/hero-dispatch/` 的 `assert.sh` 风格）。

**关联 spec:** `docs/superpowers/specs/2026-06-07-hero-visibility-design.md`

**固定 token（全程一字不改）:** `🦸 hero ▸`

---

### Task 1: 测试脚手架 + hero-conventions 露出规范（事实源）

**Files:**
- Create: `tests/hero-visibility/assert.sh`（从 `tests/hero-dispatch/assert.sh` 原样复制）
- Create: `tests/hero-visibility/run.sh`（从 `tests/hero-dispatch/run.sh` 原样复制）
- Create: `tests/hero-visibility/test_visibility.sh`
- Modify: `skills/hero-conventions/SKILL.md`（新增 `## hero 露出规范` 段）

- [ ] **Step 1: 复制零依赖断言助手与 runner**

```bash
mkdir -p tests/hero-visibility
cp tests/hero-dispatch/assert.sh tests/hero-visibility/assert.sh
cp tests/hero-dispatch/run.sh tests/hero-visibility/run.sh
```

`run.sh` 内容与 hero-dispatch 版一致（`cd "$(dirname "$0")"`，遍历 `test_*.sh`，glob 有 `[ -f "$t" ] || continue` 防护），无需改动。

- [ ] **Step 2: 写 test_visibility.sh，先只断言 hero-conventions（会失败）**

Create `tests/hero-visibility/test_visibility.sh`:

```bash
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
```

- [ ] **Step 3: 运行，确认失败**

Run: `bash tests/hero-visibility/run.sh`
Expected: FAIL —— `conventions has 露出规范 section` 与 `conventions has token` 两条 ✗（当前 hero-conventions 还是示例占位，没有该段）。

- [ ] **Step 4: 给 hero-conventions 追加露出规范段**

在 `skills/hero-conventions/SKILL.md` 末尾（`## 新增团队 skill` 段之前或之后均可，建议放「## 约定」之后）插入：

```markdown
## hero 露出规范

所有 hero skill / agent 运作时，必须用统一标记让用户感知「hero 体系正在接管」，区别于裸 Claude
或用户自有机制。

**固定 token**：`🦸 hero ▸`（作为前缀，后跟一句话，单独成行；一字不改，便于结构测试卡死防漂移）

**四个时机模板**：

| 时机 | 模板 |
|---|---|
| skill 激活 | `🦸 hero ▸ <skill/lane> · <加载的纪律/门控>` |
| agent 接手 | `🦸 hero ▸ <agent> 接手 · <一句职责>` |
| 门控 STOP | `🦸 hero ▸ STOP<n> <门控> · <等什么>` |
| 任务收尾 | `🦸 hero ▸ <lane/workflow> 完成 · 已交付，退出 hero 体系` |

**agent 接手的双保险分工**（子 agent 输出对用户主线是折叠的，故）：
- **编排方**（dispatch 子 agent 的 lane/workflow）在派单时打 `🦸 hero ▸ X 接手` —— 主线可见，**主路径**。
- **子 agent** 在自己输出顶部也打一行自报家门 —— **兜底**，展开看子 agent 工作时可见。
```

- [ ] **Step 5: 运行，确认通过**

Run: `bash tests/hero-visibility/run.sh`
Expected: PASS —— `ALL TESTS PASSED`。

- [ ] **Step 6: 提交**

```bash
git add tests/hero-visibility/ skills/hero-conventions/SKILL.md
git commit -m "feat(hero-visibility): 露出规范事实源 + 测试脚手架"
```

---

### Task 2: 9 个 agent 内联自报家门

**Files:**
- Modify: `tests/hero-visibility/test_visibility.sh`（追加 agent 断言）
- Modify: `agents/hero-java-backend-developer.md`、`hero-java-code-reviewer.md`、`hero-java-data-engineer.md`、`hero-java-ecrm.md`、`hero-java-hotel-product-center.md`、`hero-java-owner-biz.md`、`hero-java-security-auditor.md`、`hero-java-tech-lead.md`、`hero-java-test-engineer.md`

- [ ] **Step 1: 在 test_visibility.sh 的 `assert_summary` 之前追加 agent 断言（会失败）**

在 `assert_summary` 行**之前**插入：

```bash
# 2. 每个 hero-java-* agent 含统一 token（子 agent 自报家门兜底）
for f in "$REPO"/agents/hero-java-*.md; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  assert_ok "grep -qF '$TOKEN' '$f'" "$base has hero token"
done
```

- [ ] **Step 2: 运行，确认失败**

Run: `bash tests/hero-visibility/run.sh`
Expected: FAIL —— 9 条 `<agent>.md has hero token` ✗。

- [ ] **Step 3: 给每个 agent 顶部插入露出段**

在每个 agent 文件 **frontmatter（`---` 结束）之后、正文第一段之后**插入下面这段。`<agent-name>` 与
`<职责短语>` 按下表逐文件替换，模板其余文字完全一致：

```markdown
## hero 露出

接手任务时，先在输出顶部打一行自报家门（遵循 `hero-conventions` 露出规范，token 一字不改）：

`🦸 hero ▸ <agent-name> 接手 · <职责短语>`
```

| 文件 | `<agent-name>` | `<职责短语>` |
|---|---|---|
| hero-java-backend-developer.md | hero-java-backend-developer | Controller/Service 实现，TDD-first |
| hero-java-code-reviewer.md | hero-java-code-reviewer | 代码评审 |
| hero-java-data-engineer.md | hero-java-data-engineer | 复杂 SQL / 数据处理 |
| hero-java-ecrm.md | hero-java-ecrm | ecrm 服务领航（只读带路） |
| hero-java-hotel-product-center.md | hero-java-hotel-product-center | 酒店产品中心领航（只读带路） |
| hero-java-owner-biz.md | hero-java-owner-biz | owner-biz 领航（只读带路） |
| hero-java-security-auditor.md | hero-java-security-auditor | 安全审计 |
| hero-java-tech-lead.md | hero-java-tech-lead | 技术方案 / 任务拆解 |
| hero-java-test-engineer.md | hero-java-test-engineer | 测试编写 |

例（backend-developer.md 插入后）：

```markdown
## hero 露出

接手任务时，先在输出顶部打一行自报家门（遵循 `hero-conventions` 露出规范，token 一字不改）：

`🦸 hero ▸ hero-java-backend-developer 接手 · Controller/Service 实现，TDD-first`
```

- [ ] **Step 4: 运行，确认通过**

Run: `bash tests/hero-visibility/run.sh`
Expected: PASS —— 9 条 agent 断言全绿。

- [ ] **Step 5: 提交**

```bash
git add tests/hero-visibility/test_visibility.sh agents/hero-java-*.md
git commit -m "feat(hero-visibility): 9 个 agent 内联 hero 接手标记"
```

---

### Task 3: hero-dispatch SKILL + 6 条 lane 露出打点

**Files:**
- Modify: `tests/hero-visibility/test_visibility.sh`（追加 dispatch + lanes 断言）
- Modify: `skills/hero-dispatch/SKILL.md`
- Modify: `skills/hero-dispatch/lanes/bugfix.md`、`iterate.md`、`refactor.md`、`research.md`、`perf.md`、`security.md`

- [ ] **Step 1: 在 `assert_summary` 之前追加 dispatch + lanes 断言（会失败）**

```bash
# 3. hero-dispatch SKILL 含 token
DISPATCH="$REPO/skills/hero-dispatch/SKILL.md"
assert_ok "grep -qF '$TOKEN' '$DISPATCH'" "hero-dispatch SKILL has hero token"

# 4. 6 条 lane 含 token（门控/收尾打点）
for lane in bugfix iterate refactor research perf security; do
  f="$REPO/skills/hero-dispatch/lanes/$lane.md"
  assert_ok "grep -qF '$TOKEN' '$f'" "lane $lane has hero token"
done
```

- [ ] **Step 2: 运行，确认失败**

Run: `bash tests/hero-visibility/run.sh`
Expected: FAIL —— `hero-dispatch SKILL has hero token` + 6 条 `lane <x> has hero token` ✗。

- [ ] **Step 3: 给 hero-dispatch SKILL.md 加露出段**

在 `## 触发词` 段之后插入：

```markdown
## hero 露出

本入口及其交接的每条 lane 都属 hero 体系，运作时按 `hero-conventions`《hero 露出规范》打
`🦸 hero ▸` 单行标记，让用户感知 hero 在接管：
- **分诊命中**：`🦸 hero ▸ 分诊 → <lane>`
- **交接 lane/skill**：`🦸 hero ▸ <lane> · <加载的纪律/门控>`
- **派子 agent**（由本编排方打，主线可见）：`🦸 hero ▸ <agent> 接手 · <职责>`
```

- [ ] **Step 4: 给 6 条 lane 各加露出段**

在每个 `skills/hero-dispatch/lanes/<lane>.md` 的 frontmatter 之后插入（`<lane>` 替换为
bugfix/iterate/refactor/research/perf/security，其余文字一致）：

```markdown
## hero 露出

按 `hero-conventions` 露出规范，本 lane 运作时打 `🦸 hero ▸` 标记（token 一字不改）：
- 进入：`🦸 hero ▸ <lane> lane · <纪律/门控>`
- 每个 STOP 门：`🦸 hero ▸ STOP<n> <门控> · <等什么>`
- 收尾：`🦸 hero ▸ <lane> lane 完成 · 已交付，退出 hero 体系`
- 若派子 agent：派单处打 `🦸 hero ▸ <agent> 接手 · <职责>`
```

- [ ] **Step 5: 运行，确认通过**

Run: `bash tests/hero-visibility/run.sh`
Expected: PASS。

- [ ] **Step 6: 提交**

```bash
git add tests/hero-visibility/test_visibility.sh skills/hero-dispatch/
git commit -m "feat(hero-visibility): hero-dispatch + 6 lane 露出打点"
```

---

### Task 4: hero-refresh + hero-prd-to-java 露出指令 + 全量验证

**Files:**
- Modify: `tests/hero-visibility/test_visibility.sh`（追加 refresh + prd 断言）
- Modify: `skills/hero-refresh/SKILL.md`
- Modify: `skills/hero-prd-to-java/SKILL.md`

- [ ] **Step 1: 在 `assert_summary` 之前追加两 skill 断言（会失败）**

```bash
# 5. hero-refresh / hero-prd-to-java SKILL 含 token
for s in hero-refresh hero-prd-to-java; do
  f="$REPO/skills/$s/SKILL.md"
  assert_ok "[ -f '$f' ]" "$s SKILL.md exists"
  assert_ok "grep -qF '$TOKEN' '$f'" "$s has hero token"
done
```

- [ ] **Step 2: 运行，确认失败**

Run: `bash tests/hero-visibility/run.sh`
Expected: FAIL —— `hero-refresh has hero token` + `hero-prd-to-java has hero token` ✗。

- [ ] **Step 3: 给 hero-refresh/SKILL.md 加露出段**

在文档首个二级标题之后（介绍段之后）插入：

```markdown
## hero 露出

hero-refresh 运作时按 `hero-conventions` 露出规范打 `🦸 hero ▸` 标记：
- 启动：`🦸 hero ▸ hero-refresh · 确定性层 + 漂移评审 gate`
- 评审 STOP：`🦸 hero ▸ STOP 漂移评审 · 请人工裁定再写回`
- 收尾：`🦸 hero ▸ hero-refresh 完成 · 已交付，退出 hero 体系`
```

- [ ] **Step 4: 给 hero-prd-to-java/SKILL.md 加露出段**

在文档首个二级标题之后（介绍段之后）插入：

```markdown
## hero 露出

PRD 工作流运作时按 `hero-conventions` 露出规范打 `🦸 hero ▸` 标记：
- 启动：`🦸 hero ▸ hero-prd-to-java · PRD→设计→Sprint→并行开发→测试→审查→合并`
- 每个确认门：`🦸 hero ▸ STOP <门控> · <等什么>`
- 派子 agent（编排方打，主线可见）：`🦸 hero ▸ <agent> 接手 · <职责>`
- 收尾：`🦸 hero ▸ PRD 工作流完成 · 已交付，退出 hero 体系`
```

- [ ] **Step 5: 运行 hero-visibility 全量测试，确认全绿**

Run: `bash tests/hero-visibility/run.sh`
Expected: PASS —— `ALL TESTS PASSED`。

- [ ] **Step 6: 跑既有 hero-dispatch 测试，确认未回归**

Run: `bash tests/hero-dispatch/run.sh`
Expected: PASS（露出段不破坏既有 catalog/lane 结构断言）。

- [ ] **Step 7: install dry-run 演练，确认新增 tests 目录不影响软链**

Run: `CLAUDE_HOME=/tmp/hero-vis-install bash install.sh`
Expected: 成功完成，无报错（`tests/` 不在 manifest，纯仓库内资产，不软链）。

- [ ] **Step 8: 提交**

```bash
git add tests/hero-visibility/test_visibility.sh skills/hero-refresh/SKILL.md skills/hero-prd-to-java/SKILL.md
git commit -m "feat(hero-visibility): hero-refresh + hero-prd-to-java 露出指令"
```

---

## 自审（spec 覆盖核对）

- ✅ 标记规范（token + 四模板）→ Task 1（hero-conventions 事实源）。
- ✅ 双保险分工 → Task 1 写进规范；Task 2 子 agent 自打；Task 3/4 编排方派单打。
- ✅ 落点：hero-conventions(T1) / hero-dispatch+6 lane(T3) / hero-refresh(T4) / hero-prd-to-java(T4) / 9 agent(T2)。
- ✅ 防漂移测试：`grep -qF` 卡统一 token，覆盖 conventions/agents/3 skill/6 lane（T1–T4 增量构建）。
- ✅ 验收：全量测试绿(T4 S5) + 不回归(T4 S6) + install 演练(T4 S7)；人工走查留实现期抽查。
- ✅ 范围红线：不做 statusline/banner/hook、不改 superpowers、不细化 lane 门控正文——计划内无相关任务，符合。
- token 字面 `🦸 hero ▸` 在全计划一致，测试用 `grep -qF` 精确匹配。
