# hero-dispatch 意图分诊入口 — 设计稿

> 日期：2026-06-06
> 状态：已通过 brainstorming 评审，待转实现计划
> 关联：[`skills/hero-prd-to-java/SKILL.md`](../../../skills/hero-prd-to-java/SKILL.md)、
> [`skills/hero-refresh/SKILL.md`](../../../skills/hero-refresh/SKILL.md)、
> [`docs/hero-agent-roster.md`](../../hero-agent-roster.md)

## 背景与目标

`claude-hero` 现有两条成型 workflow：`hero-prd-to-java`（重型 8 步 PRD 流水线）和
`hero-refresh`（资产保鲜）。但二者**全靠显式触发词**（`hero 开发工作流 <URL>` / `hero 刷新`），
缺一个"听用户一句自由意图、判断该走哪条线"的**顶层分诊层**。

本设计新增 `hero-dispatch` skill 作为"闸机口调度员"：用户说 `hero <自由意图>`，它把意图
归类到 8 条 lane 之一，补齐必要输入，确认后**交接**给对应 lane，自己退场。

**核心诉求**（来自用户）：用户不必严格记工作流，只需给主 Agent 清晰意向，主 Agent 据此
带着往下走；子 Agent 各自拥有对应 skills/工具做该做的事。本设计补的是这条链的**入口缺口**。

### 不做什么（YAGNI / 范围红线）

- **不做** ambient/常驻分诊（不写进 CLAUDE.md 让每条消息都被拦截）。已选**轻量词触发**：
  只有 `hero` 开头才进分诊。
- **不改**重型线 `hero-prd-to-java` 那个 Step4 实现→Step5 测试的反 TDD 顺序——那是它自己的
  独立返工，不混进本次。
- **不写满** 6 条轻量 lane 的完整门控正文，本次只交付骨架（见末尾「范围边界」）。

## 总体架构

```
用户: hero <自由意图 / 或 hero 开发工作流 URL ...>
        │
        ▼
┌─────────────────────────────────────────┐
│  hero-dispatch  (新, 纯路由层, 不做活)      │
│  1. 读 lane catalog (8 条)                 │
│  2. 意图→lane (关键词命中 + 语义兜底)        │
│  3. 补齐输入 (缺 URL/缺目标 → STOP 追问)     │
│  4. ⏸STOP 确认「我判定走 X 线, 对吗」         │
│  5. 交接 → 退场                            │
└─────────────────────────────────────────┘
        │ 交接
        ├──→ 重型线: 委派现有 skill (hero-prd-to-java / hero-refresh)  ← 零改动
        └──→ 轻量线: 加载 lanes/<name>.md, 按 archetype 骨架执行
```

**三类构件**

1. `skills/hero-dispatch/SKILL.md` —— 路由三段式逻辑 + lane catalog 表（唯一事实源）。
2. `skills/hero-dispatch/lanes/*.md` × 6 —— 轻量 lane 的薄 playbook（bug / iterate /
   refactor / research / perf / security）。
3. 重型线 `hero-prd-to-java` / `hero-refresh` —— **零改动**，dispatch 只多一个入口，
   老触发词仍直达，不强制绕 dispatch。

**关键原则**：dispatch **只做路由，不做业务**。判定 lane 后即交出控制权，路由层不夹带业务
逻辑——保证它可独立理解、可独立测试。

## 分诊逻辑（意图 → lane）

### lane catalog（路由表，住在 SKILL.md）

| Lane | 触发关键词（意图信号） | 必需输入 | archetype | 交接目标 |
|---|---|---|---|---|
| prd-大需求 | PRD、飞书链接、新功能、大需求、开发工作流 | 飞书 URL | —（重型） | 委派 `hero-prd-to-java` |
| refresh-保鲜 | 刷新、保鲜、索引漂移、领航过期 | proj（可选） | —（重型） | 委派 `hero-refresh` |
| bugfix | 修bug、报错、异常、复现、修一下、不对/不生效 | 现象/复现路径 | mutate | `lanes/bugfix.md` |
| iterate | 小迭代、加个字段、改个逻辑、小改动、加个开关 | 改动目标 | mutate | `lanes/iterate.md` |
| refactor | 重构、抽方法、改命名、拆类、消除重复 | 重构对象 | mutate | `lanes/refactor.md` |
| research | 调研、评估、能不能、影响面、怎么改、要不要 | 问题/范围 | readonly | `lanes/research.md` |
| perf | 慢、性能、瓶颈、优化耗时、压测、超时 | 慢的位置/指标 | 两段(readonly→mutate) | `lanes/perf.md` |
| security | 安全、越权、注入、漏洞、CVE、敏感信息 | 审计范围 | 两段(readonly→mutate) | `lanes/security.md` |

### 分诊三段式

1. **关键词命中**：意图文本扫 catalog 关键词，单一命中 → 候选该 lane。
2. **语义兜底**：无命中或多义时，按意图**语义**归类（非纯字面）。
3. **不确定就 STOP 追问**：候选 ≥2 且分不清 → 列最可能的 2-3 条让用户选，不替用户拍板。

### 边界判定（轻量 vs 重型分流，确定性规则）

- 命中 "PRD / 飞书 URL / 大需求 / 多服务" → **prd 重型线**；
- 否则一律先归**轻量线**——"修个 bug" 不会被误升级成 8 步流水线；
- 用户可在确认 STOP 时手动改判（"这其实是大需求，走 PRD 线"）。

### 必需输入缺失 → 追问

- prd 线缺飞书 URL → 追问 URL；
- bugfix 缺复现信息 → 追问现象/路径；
- 任何 lane 缺关键输入都先 STOP 补齐，不带空输入交接。

### 降级（避免过度拦截）

8 条都不沾边（纯闲聊 / 纯问答）→ dispatch **不接管**，告知"这不像开发任务，我直接答"，
回落普通 Claude。

## lane playbook 统一骨架模板

6 条轻量 lane 高度同构，共用一份骨架字段模板，每条只填空。建一条即建全部，维护一致。

```markdown
---
lane: bugfix
archetype: mutate          # mutate(改代码) | readonly(只读出报告) | two-phase(先诊断再可选改, 性能/安全用)
intent_keywords: [修bug, 报错, 异常, 复现, 不生效]
required_input: 现象或复现路径
---

## 触发画像        # 什么样的意图该落这条线（供 dispatch 复核）
## 复用的 superpowers skill   # 强制挂载，例: systematic-debugging + test-driven-development
## 参与的角色 agent           # 例: hero-java-backend-developer + hero-java-test-engineer
## 领航 agent 介入点          # 改存量服务时调 hero-java-<proj> 摸地图/圈影响面（复用花名册）
## 门控骨架                   # 引用下文「门控骨架」的对应 archetype
## 交接产物                   # 这条线结束交付什么（修复+测试 / 报告）
```

**关键点**

- **复用而非新造**：playbook 不发明新流程，是"把已有 superpowers skill + 角色 agent +
  领航 agent 按这条线需要编排起来"的薄装配清单。bug 线挂 `systematic-debugging`，所有
  mutate 线挂 `test-driven-development`，安全线复用 `hero-java-security-auditor`。
- **领航 agent 无缝接入**：轻量线改存量服务时，和重型线一样先问对应 `hero-java-<proj>`
  领航 agent 要定位和影响面，复用 `docs/hero-agent-roster.md` 花名册，不另起炉灶。

## 门控骨架（两个 archetype）

所有轻量 lane 归两种原型，门控只 2 个 STOP，但纪律是硬的。

### Archetype A：mutate（改代码线 — bug / iterate / refactor / 性能优化 / 安全优化）

```
1. 勘察定位
   - 存量服务: 调领航 agent 摸地图 + codegraph 圈影响面
   - bug 线额外强制挂 systematic-debugging（先复现, 禁止未复现就改）
        │
   ⏸ STOP ①  「问题/改动定位 + 方案」确认 ── 继续 / 改方向 / 止步
        │
2. RED   ← hero-java-test-engineer 先写失败测试（test-driven-development 强制）
3. GREEN ← hero-java-backend-developer / data-engineer 实现到测试通过
4. REFACTOR ← 测试保护下清理
        │
   ⏸ STOP ②  「改动 + 测试结果 + 影响面复核」报告 ── 收 / 返工
```

这是**修掉重型线反 TDD 硬伤的设计**：轻量线从设计起即 RED→GREEN→REFACTOR，测试先行，
由 `superpowers:test-driven-development` 强制，不是口号。

> **重构线特例**：REFACTOR 前提是已有测试覆盖；若目标无测试，STOP① 后先补**表征测试
> （characterization test）**锁住现有行为，再重构。

### Archetype B：readonly（只读线 — 需求/变更调研）

```
1. 调查  ← 领航 agent 摸地图 + codegraph，只读，不碰代码
2. 分析  ← 影响面 / 可行性 / 风险 / 工作量
        │
   ⏸ STOP  「调研结论 + 选项 + 建议」报告 ── 采纳哪个 / 追问
```

无 RED-GREEN（不产代码）。产物是结论文档，常作为后续走 prd 线或 mutate 线的输入——
**调研线天然是其他线的前置**。

### 两段式：性能 & 安全（先只读诊断，再可选改）

性能、安全各自 = B 段诊断 → STOP → 按需转 A 段修复：

```
性能: [B]诊断瓶颈(profiling/慢查询/codegraph) ─⏸STOP「瓶颈+优化项」─→ [A]TDD-first 优化(基准测试当 RED)
安全: [B]审计(hero-java-security-auditor 只读) ─⏸STOP「风险清单」─→ [A]TDD-first 修复(漏洞复现测试当 RED)
```

诊断阶段只读、产清单；用户挑要不要修、修哪些，再进 mutate 骨架。两段都复用 A/B，不另造流程。

## 与现有体系的接口

| 现有构件 | 怎么动 |
|---|---|
| `hero-prd-to-java` / `hero-refresh` | **零改动**。dispatch 委派；老触发词仍直达。 |
| 角色 agent（6）+ 领航 agent | **零改动**，lane playbook 直接复用。 |
| `docs/hero-agent-roster.md` 花名册 | 复用（轻量线摸地图同样查它）。 |
| `manifest.yaml` | **加一项**：`hero-dispatch` 软链到 `~/.claude/skills/`。 |
| `README.md` / 仓库 `CLAUDE.md` | **加几行**：`hero <自由意图>` 入口 + lane 总表，放现有触发词章节旁。 |
| `config/CLAUDE.md.example`（团队基线） | **加一行**轻提示：开发类意图可用 `hero` 入口（仅文档，不强制 ambient）。 |
| registry / 状态文件 | 轻量线**不写** registry（registry 是 PRD 生命周期专用，不污染）。 |

## dispatch 自身的验证

dispatch 是路由逻辑，验证方式 = 一组「意图→期望 lane」判例表（spec 内列出 + 后续做成
`tests/hero-dispatch/` fixture），可回归：

| 输入意图 | 期望 lane |
|---|---|
| "修一下登录报错" | bugfix |
| "这个接口太慢了，超时" | perf |
| "把 PRD https://feishu.cn/docx/xxx 做了" | prd 重型线 |
| "给订单加个备注字段" | iterate |
| "这段重复代码抽一下" | refactor |
| "评估下加这个功能影响多大" | research |
| "查下有没有越权风险" | security |
| "刷新一下 ecrm 索引" | refresh |
| "今天天气怎么样" | 不接管（降级回普通 Claude） |

## 范围边界

### 本次交付

1. `skills/hero-dispatch/SKILL.md`——路由三段式 + lane catalog 8 条表 + 边界判定 + 降级；
2. `skills/hero-dispatch/lanes/*.md` × 6——**统一骨架模板 + 每条 frontmatter
   （archetype/关键词/必需输入）+ 触发画像**；门控正文引用本文两个 archetype，不逐条展开；
3. `manifest.yaml` + `README.md` + 仓库 `CLAUDE.md` 的入口登记；
4. 一组意图→lane 判例表（上节，验证用）。

### 本次不做（留后续各自 spec→plan）

- 6 条 lane 各自的**完整门控正文细化**（骨架外的特例、每步具体 agent prompt）；
- 重型线 `hero-prd-to-java` 那个 Step4→Step5 反 TDD 顺序的**返工**（独立改动）；
- ambient/常驻分诊（已选轻量词触发，不做）。
