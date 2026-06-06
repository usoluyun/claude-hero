---
name: hero-refresh
description: hero 资产统一刷新工作流。触发词：hero 刷新 / hero 刷新 <proj> / hero 刷新 评审 / hero 刷新 状态。把 codegraph 索引 / 领航 agent / context7 vendor docs 三件套一起保鲜：确定性层（重索引+抓文档）跑脚本自动完成，领航 agent 漂移走人工评审 gate。只刷已接入项目（docs/.refresh-state.json）。
---

# hero 统一刷新工作流（hero-refresh）

**核心价值**：一条命令把三件套保鲜。确定性脏活交脚本，领航 agent 变更交人工判断——机器干活、你只做判断。

设计依据：`docs/superpowers/specs/2026-06-06-hero-refresh-design.md`。

## 触发词

| 命令 | 作用 |
|---|---|
| `hero 刷新` | 刷全部已接入项目 |
| `hero 刷新 <proj>` | 只刷一个项目 |
| `hero 刷新 评审` | 逐个过领航 agent 漂移草稿 |
| `hero 刷新 状态` | 列已接入项目 / 谁有新 commit / 几份草稿待评审 |

「已接入」= `docs/.refresh-state.json` 里登记的项目（有 codegraph 索引 + 领航 agent）。

## `hero 刷新` / `hero 刷新 <proj>`：跑确定性层 + 产出漂移草稿

### Step A：跑确定性层（脚本）

执行（`<proj>` 可选）：
```
bash scripts/hero-refresh.sh [<proj>]
```
脚本对每个目标项目：HEAD 未变则跳过；否则重索引 + 导出 evidence（到 `docs/.refresh-work/<proj>/`）+ 抓 vendor docs，并回写 `docs/.refresh-state.json`。

读脚本输出，记下「已刷新」的项目列表（即有变更的项目）。无变更则到此为止，告知用户「全部新鲜，无需评审」。

### Step B：确定性产物提交（低风险，无需评审）

把确定性产物作为**一次** commit 提交（与 agent 改动分离）：
```
git add docs/.refresh-state.json docs/vendor-docs/
git commit -m "chore(hero-refresh): 刷新确定性产物（状态 + vendor docs）"
```

### Step C：领航 agent 漂移检测（逐个有变更的项目）

对每个有变更的项目，读两样东西做比对：
1. 新 evidence pack：`docs/.refresh-work/<proj>/structure.txt`、`entrypoints.txt`、`deps-*`。
2. 现有领航 agent：`agents/<该项目的 agent>.md`（agent 名见状态文件）。

**判定结构性漂移**——只要出现下列任一，即需出草稿：
- evidence 的 entrypoints 里出现 agent ④关键入口**未记录**的真实 Controller / Feign Client / MQ 消费者 / 定时任务类；
- agent ④记录的入口类在 evidence/代码里**已不存在**（删除/改名）；
- structure 顶层包与 agent ③代码地图明显不一致（新增/删除顶层业务包）；
- deps 指纹与 agent ②技术栈明显不一致（换了中间件/框架）。

无结构漂移 → 不出草稿（领域知识第⑥段等语义内容不因结构未变而动），告知该项目「仅索引刷新，agent 无需更新」。

### Step D：生成待评审草稿（绝不动线上 agent）

对有结构漂移的项目，写一份草稿到 `docs/.refresh-drafts/<proj>.md`，含两部分：

1. **漂移摘要**（人读）：新增了哪些入口、删了哪些、包结构/技术栈变化，逐条列。
2. **拟更新的 agent 全文**：以现有 `agents/<agent>.md` 为基底，按 evidence 更新 ③代码地图 / ④关键入口 / ⑤对外契约 / ②技术栈（**只改结构性内容**；①定位、⑥领域知识、⑦工作法保持原样，除非 evidence 直接推翻）。引用的每个类名必须来自 evidence 或代码，不编造。

产出后告知用户：「<proj> 检测到漂移，草稿已写入 docs/.refresh-drafts/<proj>.md，跑 `hero 刷新 评审` 来过。」**不在此覆盖线上 agent。**

## `hero 刷新 评审`：人工 gate（rigid）

对 `docs/.refresh-drafts/` 下每个草稿，逐个执行：

1. **展示**漂移摘要 + 草稿 agent 与线上 `agents/<agent>.md` 的 diff。
2. **反编造验证**（硬门槛，零容忍）：草稿正文引用的每个类/接口/方法，在对应项目代码里 grep 验证真实存在：
   ```
   for c in <草稿引用的类名...>; do
     find <repo_path> -name "$c.java" >/dev/null 2>&1 && echo "OK $c" || echo "MISSING $c"
   done
   ```
   任一 MISSING → 修正草稿再验，不得提交。
3. **⏸ STOP — 等用户确认**：
   - 用户「**确认/通过**」→ 用草稿覆盖线上 `agents/<agent>.md`；若草稿 description「触发词：」那行关键词变了，同步更新 `docs/hero-agent-roster.md` 对应行；删除该草稿；
     ```
     git add agents/<agent>.md docs/hero-agent-roster.md
     git commit -m "refresh(<proj>): 领航 agent 随代码漂移更新"
     ```
   - 用户「**驳回**」→ 删除草稿，不动线上 agent。
   - 用户「**改**」→ 按反馈调整草稿，回到第 1 步。

每个项目的 agent 变更**单独 commit**，始终有人工 gate——这是 rigid 规则，不可跳过自动提交。

## `hero 刷新 状态`

读 `docs/.refresh-state.json` 与各项目 HEAD，呈现：
```
已接入项目：
  ecrm                 上次刷新 2026-06-06  ✓ 无新 commit
  hotel-product-center 上次刷新 2026-06-01  ⚠ 有 3 个新 commit，建议刷新
  owner-biz            从未刷新            ⚠ 待建立基线
待评审草稿：docs/.refresh-drafts/ 下 [N] 份
```

## 关键约定

- **两段式**：确定性层（脚本，自动）vs 评审层（agent 漂移，人工 gate）。脚本绝不碰线上 agent；skill 评审确认后才覆盖。
- **只保鲜、不开荒**：刷新只处理 `docs/.refresh-state.json` 里已接入的项目。新服务首次建索引 + 首次生成 agent 走 `docs/project-agent-cookbook.md`，与本流程解耦。
- **反编造硬门槛**：评审提交前，草稿引用的类必须 grep 零 MISSING（沿用 cookbook 约定）。
- **提交分离**：确定性产物（state + vendor docs）一次 commit；每个 agent 变更各自单独 commit。
- **领域知识不自动刷**：agent 第⑥段（坑/状态机）靠人工经验沉淀，刷新只动结构性内容。

## 与其他资产的关系

- 消费 `scripts/hero-refresh.sh` 及 `scripts/lib/*`（确定性层）。
- 读写 `docs/.refresh-state.json`、`docs/.refresh-work/`、`docs/.refresh-drafts/`、`docs/vendor-docs/`、`agents/hero-java-*`、`docs/hero-agent-roster.md`。
- L1 `config/hooks/hero-refresh-check.sh` 只做提醒，真正刷新/评审都在本 skill。
- 与 `hero-prd-to-java` 正交：那个管「PRD→开发」，这个管「资产保鲜」。
