# 设计：`hero-refresh` 统一刷新机制

> 状态：已评审通过，待转 implementation plan。
> 日期：2026-06-06。

## 背景与目标

claude-hero 仓库里有三类「随 atour 代码变更而过期」的资产，目前都靠手册人工维护、各自漂移：

1. **codegraph 索引**：建在各 atour 服务仓库的 `.codegraph/`，代码变了就过期。
2. **项目领航 agent**（`agents/hero-java-<proj>.md`）：LLM 拿 evidence 生成的代码地图/入口/契约，代码变了就失真。
3. **vendor docs**（context7 抓的库文档）：库升级就过期；目前尚未落地缓存。

三者的「保鲜期」都跟代码变更挂钩，分开刷容易各自漂移。**目标**：一套统一的、手动触发的刷新机制，把三者一起保鲜，且尊重它们**自动化程度不同**这一本质差异。

### 核心约束：两段式（确定性层 vs 评审层）

- **确定性层**（codegraph 重索引、vendor docs 重抓）：纯确定性，可全自动无人值守。
- **评审层**（领航 agent 刷新）：LLM 生成 + 反编造验证 + **人工 review**，**不能无人值守直接 commit**。

机器干确定性脏活，人只对 agent 变更做判断。

## 决策（已与用户敲定）

1. **领航 agent 刷新 = 两段式**：确定性层自动跑完；agent 只做**漂移检测 → 生成待评审草稿**，人工 `hero 刷新 评审` 确认后才提交。
2. **触发 = 手动 + L1 提醒 hook**：一条 `hero 刷新` 命令手动触发刷新；另配一个 `SessionStart` hook 做**秒级漂移检测**，发现已接入项目有新 commit 就注入提醒，把「定期」从靠自觉变成自动盯着。hook 只提醒、不跑重活、不阻塞启动。L2（后台自动跑确定性层）标为可选增强，不在本期。
3. **范围 = 只刷已接入项目**：已建索引 + 已有领航 agent 的服务（当前 3 个）。新服务的「从零建索引 + 首次生成 agent」仍走 codegraph 手册，**刷新只保鲜、不开荒**。支持刷全部已接入 + `hero 刷新 <proj>` 单刷一个。
4. **vendor docs = 指纹驱动**：解析领航 agent 第②段「技术栈指纹」动态汇总要抓的库，而非维护固定清单。
5. **形态 = 脚本 + skill 双层**：确定性脏活落 `scripts/hero-refresh.sh`；编排 + 漂移判断 + 评审门控落 `hero-refresh` skill（与 `hero-prd-to-java` 同套路）。

## 架构

### ① 命令面（skill `hero-refresh`）

与 `hero 开发工作流` 平行的触发词：

| 命令 | 作用 |
|---|---|
| `hero 刷新` | 刷全部已接入项目：确定性层 + vendor docs + 产出领航 agent 漂移草稿 |
| `hero 刷新 <proj>` | 只刷一个项目 |
| `hero 刷新 评审` | 逐个过待评审草稿，确认→提交，驳回→丢弃 |
| `hero 刷新 状态` | 列已接入项目 / 谁有新 commit / 几份草稿待评审 |

「已接入」= 同时有 codegraph 索引 + 领航 agent 的项目，身份登记在 `docs/hero-agent-roster.md`（花名册）+ 记账在 `docs/.refresh-state.json`。

### ② 确定性层（`scripts/hero-refresh.sh`，无 LLM）

对每个目标项目：

1. `git -C <repo> rev-parse HEAD` 对比状态文件 `last_commit`——**未变则跳过**（除非 `--force`），刷新天然增量。
2. `codegraph index <repo>` 重建索引；确保 `.git/info/exclude` 含 `.codegraph/`（防污染）。
3. 导出新 evidence pack 到 `docs/.refresh-work/<proj>/`：
   - `codegraph files --format grouped --filter src/main/java`（模块/包结构）
   - `codegraph query` 抓 Controller / Feign / Service / Mapper / MQ 消费者 入口符号
   - `pom.xml` / `build.gradle` 关键依赖
4. 回写状态文件 `last_commit` / `last_refreshed`。

输出：哪些项目有变更、evidence pack 就绪。重活纯脚本跑，不占 Claude 回合。

> 命令前提：`codegraph` v0.9.7+ 已装。`codegraph index` 用于刷新既有索引（首次 init 走手册）。

### ③ Vendor docs（指纹驱动，确定性）

刷某项目时：
1. 解析其领航 agent **②技术栈指纹**段 → 提取库/框架/中间件名。
2. 多项目指纹**合并去重**，同一库只抓一次。
3. 逐库 `context7 /api/v2/libs/search?libraryName=<lib>` 解析 `libraryId` → `/api/v2/context?libraryId=<id>&query=<lib usage/config>&type=json` 抓 → 写 `docs/vendor-docs/<lib>.md`（进 git）。
4. 鉴权用 `$CONTEXT7_API_KEY`（无 key 也能跑，限速低）。

agent 直接读 `docs/vendor-docs/` 本地文件，免每次联网。

### ④ 评审层（skill，语义判断，人工 gate）

对②中**有变更**的项目，skill 拿新 evidence pack 比对该领航 agent 现有正文（③代码地图 / ④关键入口 / ⑤对外契约）：

- **有结构性漂移**（新增/删除 Controller、顶层包、Feign Client、MQ topic/group）→ 生成**待评审草稿**：新版 agent `.md` + 人读的「变了啥」摘要，写到 `docs/.refresh-drafts/<proj>.md`。**绝不动线上 agent**。
- **无结构漂移** → 不打扰（领域知识第⑥段等语义内容不因结构未变而改）。

### ⑤ 评审门控 + 状态/产物

`hero 刷新 评审` 逐个草稿：
1. 展示漂移摘要 + 与线上 agent 的 diff。
2. 跑**反编造 grep 验证**：草稿正文引用的每个类/接口/方法必须在代码里真实存在（零 MISSING，沿用手册硬门槛）。
3. 用户确认 → 覆盖线上 `agents/hero-java-<proj>.md` + commit +（若「触发词」关键词变了则同步 `docs/hero-agent-roster.md`）；驳回 → 丢弃草稿。

**存储约定**：

| 路径 | 进 git？ | 说明 |
|---|---|---|
| `docs/.refresh-state.json` | 是 | 每项目 `last_commit` / `last_refreshed`，团队共享刷新进度 |
| `docs/vendor-docs/*.md` | 是 | 缓存的库文档 |
| `docs/.refresh-work/` | 否（gitignore） | 临时 evidence pack |
| `docs/.refresh-drafts/` | 否（gitignore） | 临时待评审草稿队列 |

**提交策略**：`hero 刷新` 跑完确定性层后，把 `.refresh-state.json` + `docs/vendor-docs/` 的改动**作为一次确定性 commit 提交**（低风险、无需评审）；领航 agent 的改动**不在此提交**，走 `hero 刷新 评审` 单独逐个确认后再各自 commit。两类变更分离，agent 变更始终有人工 gate。

`.refresh-state.json` 结构示意：

```json
{
  "projects": {
    "ecrm": { "repo_path": "~/Documents/ATLWork/ecrm", "agent": "hero-java-ecrm", "last_commit": "abc123", "last_refreshed": "2026-06-06" },
    "hotel-product-center": { "...": "..." },
    "owner-biz": { "...": "..." }
  }
}
```

### ⑥ L1 提醒 hook（`SessionStart`，秒级，不阻塞）

`config/hooks/hero-refresh-check.sh`，由 install.sh 软链、配在 **claude-hero 项目级** settings（项目作用域，只在本 repo 工作时检测，职责清晰）。`SessionStart` 触发：

1. 读 `.refresh-state.json`，对每个已接入项目 `git -C <repo> rev-parse HEAD` 对比 `last_commit`（纯 git 操作，秒级）。
2. 有新 commit 的项目，汇总成一行提醒，通过 hook JSON `hookSpecificOutput.additionalContext` 注入会话，让 Claude 知道并提醒用户跑 `hero 刷新`。
3. **不跑索引、不抓文档、不写文件**——纯只读检测，零阻塞。

> hook 由 harness 执行、Claude 不在回合里，所以只能做这种无需判断的确定性检测；真正的刷新与评审仍由用户在会话内手动触发。

## 组件边界（各单元一个职责）

| 单元 | 职责 | 依赖 | 接口 |
|---|---|---|---|
| `scripts/hero-refresh.sh` | 确定性层：git 记账 + codegraph 重索引 + 导出 evidence | codegraph CLI、git | 读/写 `.refresh-state.json`，写 `.refresh-work/` |
| skill：vendor-docs 抓取 | 解析指纹 → context7 抓 → 写本地 | context7 API、agent 正文 | 写 `docs/vendor-docs/` |
| skill：漂移检测 | evidence vs agent 正文 → 草稿 | `.refresh-work/`、agent .md | 写 `.refresh-drafts/` |
| skill：评审门控 | 展示 diff + grep 验证 + 提交 | `.refresh-drafts/`、代码 | 改 `agents/`、`roster.md`，commit |
| `config/hooks/hero-refresh-check.sh` | L1：SessionStart 秒级漂移检测 + 注入提醒 | git、`.refresh-state.json` | 输出 `additionalContext`，不写文件 |

各单元通过文件系统（state / work / drafts 目录）解耦，可独立测试。

## 验证（成功标准）

1. **幂等**：对无新 commit 的项目跑 `hero 刷新`，全部跳过、不产草稿、不改文件。
2. **增量索引**：人为在某项目加一个 Controller → 重索引后 evidence pack 含新符号。
3. **漂移检测**：上述变更触发该项目生成 `.refresh-drafts/<proj>.md`，摘要正确点出新增入口。
4. **反编造**：草稿引用的类全部 grep 命中、零 MISSING。
5. **评审提交**：确认后线上 agent 被覆盖、commit 产生、关键词变更同步到花名册。
6. **vendor docs**：3 个 agent 的指纹合并去重后，`docs/vendor-docs/` 下生成对应库 md。
7. **范围隔离**：未接入的服务（无索引或无 agent）不被刷新触碰。
8. **L1 提醒**：某接入项目有新 commit 时，新开会话能从注入的 context 看到「建议 hero 刷新」提醒；无变更时无提醒、不阻塞启动。

## 非目标（YAGNI）

- 不做 cron/launchd 定时（改用事件驱动的 L1 `SessionStart` 提醒 hook）。
- L1 hook 只检测+提醒，不在 hook 里跑索引/抓文档（那是 L2，可选增强）。
- 不做开荒（首次建索引 + 首次生成 agent 仍走 codegraph 手册）。
- 不做 codegraph MCP 挂载（评审/导航仍用 codegraph CLI）。
- 不维护固定 vendor 库清单（走指纹驱动）。
- 领域知识（agent 第⑥段）不自动刷新——靠人工经验沉淀，刷新不覆盖。

## 未来增强（不在本期）

- **L2 后台自动确定性层**：`SessionStart` hook 后台异步（detach，不卡启动）跑重索引 + 抓 vendor docs，带节流（距上次 >N 天或 git 变了才跑）+ lock 防重入 + 日志落 `docs/.refresh-work/refresh.log`，跑完攒草稿提醒评审。评审层照旧人工。
- 刷新覆盖开荒（扫描 atour 全量、自动为新服务建索引 + 生成 agent）。
- context7 vendor docs 按 topic 精抓而非整库。
