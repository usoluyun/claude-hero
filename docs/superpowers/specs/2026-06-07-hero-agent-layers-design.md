# hero Agent 分层 + 能力矩阵脚手架设计

> 日期：2026-06-07
> 类型：设计 spec
> 关联：花名册 [`../../hero-agent-roster.md`](../../hero-agent-roster.md)、
> codegraph 方案 [`../../codegraph-agent-plan.md`](../../codegraph-agent-plan.md)、
> 露出机制 [`2026-06-07-hero-visibility-design.md`](./2026-06-07-hero-visibility-design.md)

## 目标

给现有 9 个 `hero-java-*` agent 建立**一页看清的分层 + 能力矩阵**，参考 oh-my-openagent
（omo）的 orchestration / planning / execution / specialist 分层，落到团队本土话术。

分层不是为了好看，是给后续这些事搭**施工底图**：
1. 逐步给每个 agent **配齐 skills 与对应 CLI 工具**；
2. 调提示词让 agent 能被**正确触发**；
3. 团队**一眼看懂每个 agent 怎么用**；
4. 让**新增 agent**有确定性落位流程；
5. 让 **skills 维护**有 skill→agent 反查入口。

本次只交付**脚手架 + 现状首填**：建矩阵、把现状已知的填上、空缺标 `TODO`。不改 9 个
agent 文件、不动 dispatch / 路由机制、不做模型路由抽象、不新增 agent，也不在本次做
"填深 / 调提示词"（那是后续逐个 agent 的独立工作，以本矩阵为底图）。

## 非目标（YAGNI / 本次不做）

- 不修改任何 `agents/hero-java-*.md` 文件（提示词、frontmatter 都不动）。
- 不改 `hero-dispatch` 的分诊 / 路由机制，不做 omo 式的"抽象类目→模型"路由。
- 不新增 agent，不删 agent。
- 不做"逐个 agent 填深 skills/CLI"与"调提示词"——本次只首填现状、空缺留 `TODO`。
- 顶层分类沿用团队既有「角色 agent × 项目领航 agent」双轴，**不**照搬 omo 英文层名。

## 分层骨架（双轴为主，角色类内分三梯）

顶层保留团队既有的两条正交轴；仅在**角色 agent 类内部**细分三梯。领航类本身即只读
研究层，保持整块。

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        hero-java-tech-lead              (opus)
 ├─ 执行层        hero-java-backend-developer      (sonnet)
 │                hero-java-data-engineer          (sonnet)
 │                hero-java-test-engineer          (sonnet)
 └─ 评审门控层    hero-java-code-reviewer          (opus, 只读)
                  hero-java-security-auditor       (opus, 只读)
项目领航 agent（按服务只读带路 = 研究层）
                  hero-java-ecrm                   (sonnet, 只读)
                  hero-java-hotel-product-center   (sonnet, 只读)
                  hero-java-owner-biz              (sonnet, 只读)
```

与 omo 分层的对应（仅供理解来源，不进话术）：

| 本团队层 | 对应 omo 层 |
|---|---|
| 规划层 | Planning（Prometheus/Atlas）+ Orchestration（Sisyphus）合并 |
| 执行层 | Worker/Execution（Hephaestus/Sisyphus-Junior） |
| 评审门控层 | Specialist 中的只读评审（Momus/Oracle 的审查面） |
| 领航研究层 | Specialist/Research（Oracle/Librarian/Explore） |

## 交付物

### 1. 新建 `docs/hero-agent-layers.md`（唯一分层事实源）

包含四块：

**A. 分层总图** — 上节那棵树（纯文本，便于结构测试断言）+ 与 omo 的对照小表。

**B. 能力矩阵** — 按层分组，每个 agent 一行，固定列：

| Agent | 层 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用（一句话） |

**现状首填规则**（每格要么填现状已知、要么填字面 `TODO`）：

- **层 / model**：必填，来自上面骨架与各 agent frontmatter，**不允许 TODO**。
- **触发词**：领航 agent 从花名册「业务关键词/别名」取（须与花名册一致）；角色 agent
  现状 description 无显式触发锚点的，填 `TODO`。
- **应加载 skills**：从各 agent 正文/description 已提到的提炼，缺则 `TODO`。首填基线：
  - tech-lead：`superpowers:brainstorming`、`superpowers:writing-plans`、`hero-conventions`
  - backend-developer：`hero-conventions`、`superpowers:test-driven-development`
  - data-engineer：`hero-conventions`
  - test-engineer：`superpowers:test-driven-development`、`gherkin`、`allure`
  - code-reviewer：`superpowers:requesting-code-review`、`hero-conventions`
  - security-auditor：`security-review`
  - ecrm / hotel-product-center / owner-biz：`hero-refresh`（codegraph 保鲜）
- **该用 CLI**：从 `cli/` 现有清单取，缺则 `TODO`。首填基线：
  - tech-lead / 三个领航：`codegraph`
  - backend-developer / test-engineer：`maven`、`gradle`、`jdk-multiversion`
  - data-engineer：`mycli`（MySQL）；SQLServer 暂无 CLI 清单 → 追加 `TODO`
  - code-reviewer / security-auditor：`TODO`
- **怎么用**：从 description 提炼一句「何时找它 / 给它什么 / 它产出什么」，必填。

矩阵顶部注明：**本表是事实源**；后续每填好一格 → 去改对应 agent 文件 → 双向对齐
（改 agent 文件是后续工作，不在本次）。`TODO` 是**约定哨兵值**，代表"待逐步补"，
非 spec 缺漏。

**C. 新增 agent 登记规则** — 让"加 agent"有确定性流程（对标花名册登记规则）：
1. 选轴：横向干活 → 角色 agent；按服务只读带路 → 项目领航 agent。
2. 选层：角色 → 规划/执行/评审门控其一；领航 → 领航研究层。
3. 命名 `hero-<lang>-<...>`，文件名 = frontmatter `name`（见 `CONTRIBUTING.md`）。
4. 在能力矩阵对应层补一行（层/model/怎么用 必填，其余可 `TODO`）。
5. 若是领航 agent，另在 `hero-agent-roster.md` 登记一行。
6. 跑 `bash tests/hero-agent-layers/run.sh` 确认未漏归层。

**D. skills 维护入口** — 一句话说明：「应加载 skills」列即 **skill→agent 反查索引**；
改动/废弃某 skill 时，`grep` 此列即知影响哪些 agent。

### 2. 改 `CLAUDE.md`（仓库导航）

- 「文档索引（docs/）」表新增一行：
  `hero-agent-layers.md | agent 分层总图 + 能力矩阵（双轴 + 角色三梯，skills/CLI 施工底图） | 看全景分层 / 加新 agent / 查 skill 用在哪`
- 「资产目录速查」`agents/` 段：现有的 2 类散文描述**收敛为一句 + 链到分层总图**，
  消除散文与新 doc 的重复（去重，不再两处各描述一遍分类）。

### 3. 改 `docs/hero-agent-roster.md`（轻）

- 开头加一行 cross-link：
  「本表是**领航研究层**明细；全局分层 + 角色 agent 见 [`hero-agent-layers.md`](./hero-agent-layers.md)」。
  （roster 与 layers doc 同在 `docs/`，相对链接 `./hero-agent-layers.md`。）

### 4. 防漂移测试 `tests/hero-agent-layers/`（bash 3.2，沿用 `tests/hero-visibility/` 风格）

文件：`assert.sh`、`run.sh`（复用既有风格）、`test_layers.sh`。断言：

1. `docs/hero-agent-layers.md` 存在，且含分层总图四块标题（总图 / 能力矩阵 / 登记规则 / skills 维护）。
2. `agents/` 下每个 `hero-java-*.md`（取文件名 stem）都在 `hero-agent-layers.md` 中出现一次以上
   —— catch「加了 agent 忘归层」。
3. 四个层名（规划层 / 执行层 / 评审门控层 / 领航研究层）在 doc 中均出现。
4. `CLAUDE.md` 含指向 `hero-agent-layers.md` 的链接。
5. `hero-agent-roster.md` 含指向 `hero-agent-layers.md` 的 cross-link。

**不**断言「应加载 skills / 该用 CLI / 触发词」非空——这些允许 `TODO`，是首填后逐步补的格。

## 验收标准

- `docs/hero-agent-layers.md` 落盘，含总图 + 9 行能力矩阵（层/model/怎么用 无空，其余 ≥首填基线）+ 登记规则 + skills 维护入口。
- `CLAUDE.md`、`hero-agent-roster.md` 交叉链接到位且无分类描述重复。
- `bash tests/hero-agent-layers/run.sh` 全绿；既有 `tests/hero-visibility/`、`tests/hero-dispatch/` 不回归。
- `CLAUDE_HOME=/tmp/xxx bash install.sh` 演练通过（新增 tests/docs 不影响软链）。
- 人工走查：从分层总图任取一个 agent，能顺着矩阵看到它的层/用法，TODO 格一目了然知道"待补什么"。

## 范围收敛

本次只交付**分层骨架 + 能力矩阵脚手架 + 现状首填 + 测试 + 导航接线**。逐个 agent 的
skills/CLI 填深与提示词调优，是以本矩阵为底图的后续独立工作，每个 agent（或每层）可单独成轮。
