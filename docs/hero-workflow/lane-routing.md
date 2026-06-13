# hero-dispatch：意图分诊与 lane 路由

> **权威源**：[`skills/hero-dispatch/SKILL.md`](../../skills/hero-dispatch/SKILL.md)
> **范围**：本文解读 hero-dispatch 的 lane catalog 路由表和分诊三段式，不复制 SKILL.md 全文。

## 一句话

hero-dispatch 是 hero 体系的**顶层意图分诊入口**。用户说一句 `hero <意图>`，分诊器（dispatch）自动判断该走哪条 lane、补齐输入、确认后交接给对应 workflow，自己退场。**只做路由，不做业务。**

## 两个 dispatch，别混淆

hero 体系有两个以 `dispatch` 命名的机制，但**完全不同**：

| 机制 | 触发方式 | 职责 |
|------|---------|------|
| **hero-dispatch** | `hero <意图>`（自然语言） | 意图分诊 → 9 条 lane |
| **hero-issue-dispatch** | `issue <命令>`（结构化命令） | GitLab Issue 路由 → agent 认领 |

本文只讲 hero-dispatch。issue-dispatch 在另一篇文档（[issue-dispatch.md](./issue-dispatch.md)）中单独说明。

## 触发机制

1. 用户输入 `hero <自由意图>`，例：`hero 修一下登录报错`、`hero 这个接口太慢`
2. Claude Code 引擎将意图文本与 skill 的 `description` 做**语义匹配**
3. 匹配命中后加载 `hero-dispatch/SKILL.md`，分诊器接管
4. 分诊器读取 lane catalog（路由表），归类意图、补齐输入、确认后交接

老触发词 `hero 开发工作流 <URL>` / `hero 刷新` 直达对应 skill，不绕本入口。

## 9 条 lane catalog（路由表）

分诊器根据用户意图的关键词匹配 lane。下表是唯一事实源：

| Lane | 触发关键词（意图信号） | 必需输入 | 交接目标 |
|---|---|---|---|
| **prd-大需求** | PRD、飞书链接、新功能、大需求、开发工作流 | 飞书 URL | 委派 `hero-prd-to-java` |
| **refresh-保鲜** | 刷新、保鲜、索引漂移、领航过期 | proj（可选） | 委派 `hero-refresh` |
| **bugfix** | 修bug、报错、异常、复现、修一下、不对/不生效 | 现象/复现路径 | `lanes/bugfix.md` |
| **iterate** | 小迭代、加个字段、改个逻辑、小改动、加个开关、微调 | 改动目标 | `lanes/iterate.md` |
| **refactor** | 重构、抽方法、改命名、拆类、消除重复、整理代码 | 重构对象 | `lanes/refactor.md` |
| **research** | 调研、评估、能不能、影响面、怎么改、要不要 | 问题/范围 | `lanes/research.md` |
| **perf** | 慢、性能、瓶颈、优化耗时、压测、超时 | 慢的位置/指标 | `lanes/perf.md` |
| **security** | 安全、越权、注入、漏洞、CVE、敏感信息 | 审计范围 | `lanes/security.md` |
| **team-组队** | 组队、team、spawn、分屏、并行、多位 Hero | 组队意图（可选） | `lanes/team.md` |

## 分诊三段式

分诊器判断用户意图走哪个 lane，分三步：

1. **关键词命中**：扫描意图文本中的关键词，单一命中 → 候选该 lane
2. **语义兜底**：无命中或多义时，按意图的**语义**归类（不是纯字面匹配）。例如「这个登录好像有点问题」不含「修bug」字眼，但语义上归 bugfix
3. **不确定就 STOP 追问**：候选 lane ≥2 且分不清 → 列出最可能的 2-3 条让用户选，**不替用户拍板**

### 边界判定（轻量 vs 重型分流）

- 命中「PRD / 飞书 URL / 大需求 / 多服务」→ **prd 重型线**
- 其他情况一律先归**轻量线**。「修个 bug」不会被误升级成 8 步流水线
- 用户可在确认 STOP 时手动改判（「这其实是大需求，走 PRD 线」）

### 必需输入缺失 → 追问

任何 lane 缺关键输入都先 STOP 补齐，不带空输入交接。例如：prd 缺飞书 URL → 追问 URL；bugfix 缺复现信息 → 追问现象/路径。

### 降级（避免过度拦截）

8 条都不沾边（纯闲聊 / 纯问答）→ **不接管**，告知「这不像开发任务，我直接答」，回落普通对话模式。

## 分类交接：重型线 vs 轻量线

分诊确认后，交接方式分两种：

| 类型 | 包含 lane | 交接方式 |
|------|----------|---------|
| **重型线** | prd、refresh | 用 `Skill` 工具**委派完整 skill**（`hero-prd-to-java` 或 `hero-refresh`），传已补齐的输入 |
| **轻量线** | bugfix、iterate、refactor、research、perf、security、team | **加载 `lanes/<name>.md` playbook**，按其 frontmatter 与门控骨架执行 |

重型线因为流程长、步骤多（prd 有 8 步流水线，refresh 有两段式保鲜），所以走独立 skill。轻量线相对简短，共享同一套门控骨架，各自 lane 文件只定义差异部分。

## 门控骨架：三种 archetype

所有轻量 lane 都继承以下三种 archetype（原型）之一。lane 文件只声明自己属于哪种 archetype，不重复定义门控流程。

### Archetype A：mutate（改代码线）

用于 bugfix、iterate、refactor。流程：

```
勘察定位 → ⏸ STOP ①（确认方案）→ RED（先写失败测试）→ GREEN（实现到通过）→ REFACTOR（测试保护下清理）→ ⏸ STOP ②（报告收/返工）
```

核心原则：**测试先行**，由 `superpowers:test-driven-development` 强制，不是 test-after。

### Archetype B：readonly（只读线）

用于 research。流程：

```
调查（只读，不碰代码）→ 分析（影响面/可行性/风险/工作量）→ ⏸ STOP（输出结论+选项+建议）
```

无 RED-GREEN，不产代码。产物常作为后续 prd 线或 mutate 线的输入。

### two-phase：性能 & 安全（先诊断，再可选改）

用于 perf、security。流程：

```
B 段诊断 → ⏸ STOP「清单」→ 按需转 A 段（TDD-first，基准/复现测试当 RED）
```

两段都复用 A/B 骨架。先只读摸清问题，再决定要不要动手改。

## 示例

### 示例 1：`hero 修一下登录报错`

1. 关键词命中「修一下」→ bugfix lane
2. 分诊器追问：「请描述复现路径：什么操作、报什么错、哪个环境」
3. 用户补齐后，分诊器确认：`🦸 hero ▸ 分诊 → bugfix`
4. 加载 `lanes/bugfix.md`（mutate archetype），勘察 → STOP ① → RED → GREEN → REFACTOR → STOP ②

### 示例 2：`hero 这个接口太慢了，帮忙看看`

1. 关键词命中「慢」→ perf lane
2. 分诊器追问：「哪个接口？大概多慢？有没有压测数据」
3. 确认后走 two-phase：先 B 段诊断定位瓶颈 → STOP 输出清单 → 用户决定是否转 A 段优化
