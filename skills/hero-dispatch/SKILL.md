---
name: hero-dispatch
description: hero 意图分诊入口。触发词：hero <自由意图>。听用户一句开发意图，归类到 8 条 lane（prd 大需求 / refresh 保鲜 / bugfix / iterate / refactor / research / perf / security），补齐必要输入后交接给对应 workflow。重型线委派现有 skill，轻量线加载 lanes/ playbook。不接管纯闲聊/纯问答。
---

# hero 意图分诊（hero-dispatch）

**核心价值**：用户不必记工作流，说 `hero <意图>` 即可。分诊器判断该走哪条线、补齐输入、STOP 确认后交接给对应 workflow，自己退场。**只做路由，不做业务**。

## 触发词

`hero <自由意图>`，例：`hero 修一下登录报错` / `hero 这个接口太慢` / `hero 评估下加 X 影响多大`。
老触发词 `hero 开发工作流 <URL>` / `hero 刷新` 仍直达对应 skill，不必绕本入口。

## hero 露出

本入口及其交接的每条 lane 都属 hero 体系，运作时按 `hero-conventions`《hero 露出规范》打
`🦸 hero ▸` 单行标记，让用户感知 hero 在接管：
- **分诊命中**：`🦸 hero ▸ 分诊 → <lane>`
- **交接 lane/skill**：`🦸 hero ▸ <lane> · <加载的纪律/门控>`
- **派子 agent**（由本编排方打，主线可见）：`🦸 hero ▸ <agent> 接手 · <职责>`

## lane catalog（路由表，唯一事实源）

| Lane | 触发关键词（意图信号） | 必需输入 | 交接目标 |
|---|---|---|---|
| prd-大需求 | PRD、飞书链接、新功能、大需求、开发工作流 | 飞书 URL | 委派 `hero-prd-to-java` |
| refresh-保鲜 | 刷新、保鲜、索引漂移、领航过期 | proj（可选） | 委派 `hero-refresh` |
| bugfix | 修bug、报错、异常、复现、修一下、不对/不生效 | 现象/复现路径 | `lanes/bugfix.md` |
| iterate | 小迭代、加个字段、改个逻辑、小改动、加个开关、微调 | 改动目标 | `lanes/iterate.md` |
| refactor | 重构、抽方法、改命名、拆类、消除重复、整理代码 | 重构对象 | `lanes/refactor.md` |
| research | 调研、评估、能不能、影响面、怎么改、要不要 | 问题/范围 | `lanes/research.md` |
| perf | 慢、性能、瓶颈、优化耗时、压测、超时 | 慢的位置/指标 | `lanes/perf.md` |
| security | 安全、越权、注入、漏洞、CVE、敏感信息 | 审计范围 | `lanes/security.md` |
| team-组队 | 组队、team、spawn、分屏、并行、多位 Hero 同时干、Demis Hassabis+Jeff Dean+Percy Liang 一起 | 组队意图（可选） | `lanes/team.md` |

## 分诊三段式

1. **关键词命中**：意图文本扫上表关键词，单一命中 → 候选该 lane。
2. **语义兜底**：无命中或多义时，按意图**语义**归类（非纯字面）。
3. **不确定就 STOP 追问**：候选 ≥2 且分不清 → 列最可能的 2-3 条让用户选，不替用户拍板。

## 边界判定（轻量 vs 重型分流）

- 命中「PRD / 飞书 URL / 大需求 / 多服务」→ **prd 重型线**；
- 否则一律先归**轻量线**——「修个 bug」不会被误升级成 8 步流水线；
- 用户可在确认 STOP 时手动改判（「这其实是大需求，走 PRD 线」）。

## 必需输入缺失 → 追问

任何 lane 缺关键输入都先 STOP 补齐，不带空输入交接：prd 缺飞书 URL → 追问 URL；
bugfix 缺复现信息 → 追问现象/路径；以此类推。

## 降级（避免过度拦截）

8 条都不沾边（纯闲聊 / 纯问答）→ **不接管**，告知「这不像开发任务，我直接答」，回落普通 Claude。

## 交接

- **重型线**：用 `Skill` 工具调 `hero-prd-to-java` 或 `hero-refresh`，把已补齐的输入传过去。
- **轻量线**：读对应 `lanes/<name>.md`，按其 frontmatter 与「门控骨架」执行。

---

## 门控骨架（两个原型，lane 文件引用本节）

### Archetype A：mutate（改代码线）

```
1. 勘察定位（存量服务: 领航 agent 摸地图 + codegraph 圈影响面）
   ⏸ STOP ①  「问题/改动定位 + 方案」确认 ── 继续 / 改方向 / 止步
2. RED   ← hero-java-test-engineer 先写失败测试（test-driven-development 强制）
3. GREEN ← hero-java-backend-developer / data-engineer 实现到测试通过
4. REFACTOR ← 测试保护下清理
   ⏸ STOP ②  「改动 + 测试结果 + 影响面复核」报告 ── 收 / 返工
```

测试先行，由 `superpowers:test-driven-development` 强制，不是 test-after。

### Archetype B：readonly（只读出报告线）

```
1. 调查（领航 agent 摸地图 + codegraph，只读，不碰代码）
2. 分析（影响面 / 可行性 / 风险 / 工作量）
   ⏸ STOP  「结论 + 选项 + 建议」报告 ── 采纳哪个 / 追问
```

无 RED-GREEN，不产代码。产物常作为后续 prd 线 / mutate 线的输入。

### two-phase：性能 & 安全（先只读诊断，再可选改）

= B 段诊断 → STOP「清单」→ 按需转 A 段（TDD-first，基准/复现测试当 RED）。两段都复用 A/B。
