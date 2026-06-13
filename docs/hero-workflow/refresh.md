# hero-refresh：两段式保鲜

> **权威源**：[`skills/hero-refresh/SKILL.md`](../../skills/hero-refresh/SKILL.md)
> **范围**：本文解读 refresh 两段式保鲜机制（确定性脚本 + 漂移评审 gate），不复制 SKILL.md 全文。

## 一句话引言

项目代码每天在变，领航 agent 的知识不能过时。`hero 刷新` 一条命令把三件套保鲜：**codegraph 索引**（代码结构图）、**领航 agent**（项目导航知识）、**vendor docs**（外部库文档缓存）。确定性脏活交脚本，领航 agent 变更交人工判断——机器干活、你只做判断。

## 4 个触发词

| 命令 | 作用 |
|---|---|
| `hero 刷新` | 刷全部已接入项目 |
| `hero 刷新 <proj>` | 只刷一个项目 |
| `hero 刷新 评审` | 逐个过领航 agent 漂移草稿 |
| `hero 刷新 状态` | 列已接入项目 / 谁有新 commit / 几份草稿待评审 |

「已接入」= `docs/.refresh-state.json` 里登记的项目（有 codegraph 索引 + 领航 agent）。

## 两段式架构

整个保鲜流程分为两层，各司其职：

- **确定性层**（脚本自动跑）：重索引 + 导出 evidence + 抓 vendor docs。这一层由 `scripts/hero-refresh.sh` 完成，结果写入 `docs/.refresh-work/<proj>/`，回写 `docs/.refresh-state.json`。**脚本绝不碰线上 agent 文件**，它只产中间 evidence。
- **评审层**（agent 漂移走人工 gate）：skill 读 evidence pack，比对现有领航 agent，判断是否因代码漂移需要更新。若有漂移，生成草稿写入 `docs/.refresh-drafts/<proj>.md`，与线上 `agents/<agent>.md` 完全隔离。只有人工评审确认后，skill 才覆盖线上 agent。

两段设计的核心：机器干完确定性的脏活就停手，领航 agent 的改动永远留给人做最终裁定。

## Step A-D 详解

### Step A：跑确定性层（脚本）

执行 `bash scripts/hero-refresh.sh [<proj>]`。脚本对每个目标项目：HEAD 未变则跳过；否则重索引 + 导出 evidence（structure.txt / entrypoints.txt / deps 指纹）+ 抓 vendor docs，并回写状态文件。读脚本输出，记下有变更的项目列表。无变更则到此为止，告知用户「全部新鲜，无需评审」。

### Step B：确定性产物提交（低风险，无需评审）

把确定性产物作为**一次** commit 提交，与 agent 改动分离：

```
git add docs/.refresh-state.json docs/vendor-docs/
git commit -m "chore(hero-refresh): 刷新确定性产物（状态 + vendor docs）"
```

### Step C：领航 agent 漂移检测（逐个有变更的项目）

对每个有变更的项目，读两样东西做比对：

1. 新 evidence pack：`docs/.refresh-work/<proj>/structure.txt`、`entrypoints.txt`、`deps-*`
2. 现有领航 agent：`agents/<该项目的 agent>.md`

**判定结构性漂移的 4 条规则**——只要出现下列任一，即需出草稿：

- evidence 的 entrypoints 出现 agent 关键入口**未记录**的真实 Controller / Feign Client / MQ 消费者 / 定时任务类
- agent 记录的入口类在 evidence 或代码里**已不存在**（删除或改名）
- structure 顶层包与 agent 代码地图**明显不一致**（新增或删除顶层业务包）
- deps 指纹与 agent 技术栈**明显不一致**（换了中间件或框架）

无结构漂移 → 不出草稿（领域知识等语义内容不因结构未变而动），告知该项目「仅索引刷新，agent 无需更新」。

### Step D：生成待评审草稿（绝不动线上 agent）

对有结构漂移的项目，写一份草稿到 `docs/.refresh-drafts/<proj>.md`，含两部分：

1. **漂移摘要**（人读）：新增了哪些入口、删了哪些、包结构或技术栈变化，逐条列出
2. **拟更新的 agent 全文**：以现有 `agents/<agent>.md` 为基底，按 evidence 更新代码地图 / 关键入口 / 对外契约 / 技术栈。**只改结构性内容**；定位、领域知识、工作法保持原样，除非 evidence 直接推翻。引用的每个类名必须来自 evidence 或代码，不编造

产出后告知用户：「`<proj>` 检测到漂移，草稿已写入 `docs/.refresh-drafts/<proj>.md`，跑 `hero 刷新 评审` 来过。」**不在此覆盖线上 agent。**

## 评审 gate（rigid）

`hero 刷新 评审` 对 `docs/.refresh-drafts/` 下每个草稿，逐个执行三步：

1. **展示**漂移摘要 + 草稿 agent 与线上 `agents/<agent>.md` 的 diff
2. **反编造验证**（硬门槛，零容忍）：草稿正文引用的每个类或接口名，在对应项目代码里 grep 验证真实存在。任一 MISSING → 修正草稿再验，不得提交。原理很简单：逐类名 grep 查找，找不到就标记 MISSING，全部通过才算过关
3. **⏸ STOP 等用户确认**：
   - 用户「**确认/通过**」→ 用草稿覆盖线上 `agents/<agent>.md`；若草稿 description「触发词：」那行关键词变了，同步更新 `docs/hero-agent-roster.md` 对应行；删除该草稿；单独 commit
   - 用户「**驳回**」→ 删除草稿，不动线上 agent
   - 用户「**改**」→ 按反馈调整草稿，回到第 1 步

## 提交分离策略

- **确定性产物**（state + vendor docs）：一次 commit
  ```
  chore(hero-refresh): 刷新确定性产物（状态 + vendor docs）
  ```
- **每个领航 agent 变更**：各自单独 commit
  ```
  refresh(<proj>): 领航 agent 随代码漂移更新
  ```

始终保持人工 gate——这是 rigid 规则，不可跳过自动提交。

## "只保鲜不开荒"原则

刷新只处理 `docs/.refresh-state.json` 里已接入的项目。新服务首次建 codegraph 索引 + 首次生成领航 agent 走 `docs/project-agent-cookbook.md`，与本流程完全解耦。保鲜的前提是已经有东西可以保鲜——开荒和保鲜是两条独立的入口，各管各的。

## 状态查询

`hero 刷新 状态` 读 `docs/.refresh-state.json` 与各项目 HEAD，呈现：

```
已接入项目：
  ecrm                 上次刷新 2026-06-06  ✓ 无新 commit
  hotel-product-center 上次刷新 2026-06-01  ⚠ 有 3 个新 commit，建议刷新
  owner-biz            从未刷新            ⚠ 待建立基线
待评审草稿：docs/.refresh-drafts/ 下 [N] 份
```

## 与其他资产的关系

- L1 hook `config/hooks/hero-refresh-check.sh` 只做 SessionStart 提醒，真正刷新和评审都在本 skill
- 与 `hero-prd-to-java` 正交：那个管「PRD → 开发」，这个管「资产保鲜」
- 领域知识不自动刷：agent 第⑥段（坑和状态机）靠人工经验沉淀，刷新只动结构性内容
