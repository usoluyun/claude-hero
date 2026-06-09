# hero Agent 分层 + 能力矩阵 + 漫威命名设计

> 日期：2026-06-07
> 类型：设计 spec
> 关联：花名册 [`../../hero-agent-roster.md`](../../hero-agent-roster.md)、
> codegraph 方案 [`../../codegraph-agent-plan.md`](../../codegraph-agent-plan.md)、
> 露出机制 [`2026-06-07-hero-visibility-design.md`](./2026-06-07-hero-visibility-design.md)

## 目标

给现有 9 个 `hero-java-*` agent 建立**一页看清的分层 + 能力矩阵**，参考 oh-my-openagent
（omo）的 orchestration / planning / execution / specialist 分层，落到团队本土话术；
并给每个 agent 起一个**贴其特点的漫威英雄代号**，在 hero 露出标记里带上，强化记忆点与
"hero 体系在接管"的人格感。

分层不是为了好看，是给后续这些事搭**施工底图**：
1. 逐步给每个 agent **配齐 skills 与对应 CLI 工具**；
2. 调提示词让 agent 能被**正确触发**；
3. 团队**一眼看懂每个 agent 怎么用**（漫威代号让"谁是谁"更好记）；
4. 让**新增 agent**有确定性落位流程；
5. 让 **skills 维护**有 skill→agent 反查入口。

本次交付**脚手架 + 现状首填 + 漫威命名落地**：建矩阵、把现状已知的填上、空缺标 `TODO`、
给 9 个 agent 定代号并改其露出行 + hero-conventions 露出模板。不在本次做"逐个 agent 填深
skills/CLI 与调提示词"（那是后续以本矩阵为底图的独立工作）。

## 非目标（YAGNI / 本次不做）

- 除**露出行**外，不改 `agents/hero-java-*.md` 的其它内容（职责正文、frontmatter 不动）。
- 漫威名**纯装饰/记忆点**：只出现在露出标记与矩阵里；**不**做"用英雄名调用"的路由
  （不动 hero-dispatch、不在花名册加别名映射）。
- 不改 `hero-dispatch` 的分诊 / 路由机制，不做 omo 式的"抽象类目→模型"路由。
- 不新增 agent，不删 agent。
- 不做"逐个 agent 填深 skills/CLI"与"调提示词"——本次只首填现状、空缺留 `TODO`。
- 顶层分类沿用团队既有「角色 agent × 项目领航 agent」双轴，**不**照搬 omo 英文层名。

## 分层骨架（双轴为主，角色类内分三梯）

顶层保留团队既有的两条正交轴；仅在**角色 agent 类内部**细分三梯。领航类本身即只读
研究层，保持整块。

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        孔明    hero-java-tech-lead              (opus)
 ├─ 执行层        文远       hero-java-backend-developer      (sonnet)
 │                子长           hero-java-data-engineer          (sonnet)
 │                希仁     hero-java-test-engineer          (sonnet)
 └─ 评审门控层    玄成 hero-java-code-reviewer        (opus, 只读)
                  鹏举     hero-java-security-auditor       (opus, 只读)
项目领航 agent（按服务只读带路 = 研究层）
                  子文       hero-java-ecrm                   (sonnet, 只读)
                  郑和        hero-java-hotel-product-center   (sonnet, 只读)
                  霞客           hero-java-owner-biz              (sonnet, 只读)
```

## 漫威代号映射（按特点取名，纯装饰/记忆点）

| Agent | 漫威代号 | 取名理由（贴特点） |
|---|---|---|
| `hero-java-tech-lead` | **孔明** | 组建团队、拆任务派活、最后验收——天生编排者 |
| `hero-java-backend-developer` | **文远** | 亲手造装备/写实现，工程师本色 |
| `hero-java-data-engineer` | **子长** | 由数据而生、擅综合；跨 MySQL/SQLServer 方言=多源数据合成 |
| `hero-java-test-engineer` | **希仁** | 蜘蛛感应提前预警=测试在出事前抓 bug |
| `hero-java-code-reviewer` | **玄成** | 推演千万结局找隐患=正确性/质量评审 |
| `hero-java-security-auditor` | **鹏举** | 阿斯加德守门人、洞察一切入侵=安全审计守门 |
| `hero-java-ecrm` | **子文** | 把不按常理的怪装备玩明白；ecrm 非 Spring 特殊栈(ActionSoft BPM) |
| `hero-java-hotel-product-center` | **郑和** | 带队探索定位；产品中心是定价/映射枢纽 |
| `hero-java-owner-biz` | **霞客** | 空中侦察大范围地形=大单体多业务域"摸地图" |

## 露出标记格式（漫威名落到 hero-visibility）

`agent 接手`这一时机的标记，由现有：

`🦸 hero ▸ <agent> 接手 · <职责>`

升级为**英雄名（agent）并列**：

`🦸 hero ▸ <英雄名>（<agent>）接手 · <职责>`

例：`🦸 hero ▸ 文远（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`

- 前缀 token `🦸 hero ▸` **一字不改**——hero-visibility 既有结构测试（`grep -qF '🦸 hero ▸'`）继续全绿。
- 英雄名记忆点 + agent 技术名不歧义，排查时一眼知道是哪个 agent。
- 仅 `agent 接手` 时机带英雄名；skill 激活 / STOP / 收尾三时机不带（它们不是 agent 维度）。

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

| Agent | 漫威代号 | 层 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用（一句话） |

**现状首填规则**（每格要么填现状已知、要么填字面 `TODO`）：

- **漫威代号 / 层 / model**：必填，来自上面映射表与各 agent frontmatter，**不允许 TODO**。
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

### 2. 改 `skills/hero-conventions/SKILL.md` + 9 个 agent 露出行（漫威名落地）

- **hero-conventions 露出规范**：`agent 接手`模板由 `🦸 hero ▸ <agent> 接手 · <职责>`
  升级为 `🦸 hero ▸ <英雄名>（<agent>）接手 · <职责>`；并补一句"英雄名见分层总图
  `docs/hero-agent-layers.md` 漫威代号映射"。token `🦸 hero ▸` 不变。
- **9 个 `agents/hero-java-*.md` 的 `## hero 露出` 行**：把自报家门那行改成带英雄名格式，
  例如 backend-developer 改为
  `🦸 hero ▸ 文远（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`。
  **只改这一行**，其余正文不动。

### 3. 改 `CLAUDE.md`（仓库导航）

- 「文档索引（docs/）」表新增一行：
  `hero-agent-layers.md | agent 分层总图 + 能力矩阵（双轴 + 角色三梯，skills/CLI 施工底图） | 看全景分层 / 加新 agent / 查 skill 用在哪`
- 「资产目录速查」`agents/` 段：现有的 2 类散文描述**收敛为一句 + 链到分层总图**，
  消除散文与新 doc 的重复（去重，不再两处各描述一遍分类）。

### 4. 改 `docs/hero-agent-roster.md`（轻）

- 开头加一行 cross-link：
  「本表是**领航研究层**明细；全局分层 + 角色 agent 见 [`hero-agent-layers.md`](./hero-agent-layers.md)」。
  （roster 与 layers doc 同在 `docs/`，相对链接 `./hero-agent-layers.md`。）

### 5. 防漂移测试 `tests/hero-agent-layers/`（bash 3.2，沿用 `tests/hero-visibility/` 风格）

文件：`assert.sh`、`run.sh`（复用既有风格）、`test_layers.sh`。断言：

1. `docs/hero-agent-layers.md` 存在，且含分层总图四块标题（总图 / 能力矩阵 / 登记规则 / skills 维护）。
2. `agents/` 下每个 `hero-java-*.md`（取文件名 stem）都在 `hero-agent-layers.md` 中出现一次以上
   —— catch「加了 agent 忘归层」。
3. 四个层名（规划层 / 执行层 / 评审门控层 / 领航研究层）在 doc 中均出现。
4. `CLAUDE.md` 含指向 `hero-agent-layers.md` 的链接。
5. `hero-agent-roster.md` 含指向 `hero-agent-layers.md` 的 cross-link。
6. 9 个漫威代号（文远 / 子长 / 希仁 / 玄成 / 鹏举 / 子文 / 郑和 / 霞客 /
   孔明）在 `hero-agent-layers.md` 中均出现。
7. 9 个 `agents/hero-java-*.md` 各自的露出行含本 agent 的漫威代号（grep 该 agent 对应中文名），
   且仍含 token `🦸 hero ▸` —— 漫威名与 hero 露出都不漏。
8. `skills/hero-conventions/SKILL.md` 的露出模板含「英雄名（agent）」格式标识（如 `（` 占位
   或字样 `英雄名`）。

**不**断言「应加载 skills / 该用 CLI / 触发词」非空——这些允许 `TODO`，是首填后逐步补的格。
既有 `tests/hero-visibility/` 须继续全绿（token 前缀未变）。

## 验收标准

- `docs/hero-agent-layers.md` 落盘，含总图 + 漫威代号映射 + 露出格式 + 9 行能力矩阵
  （漫威代号/层/model/怎么用 无空，其余 ≥首填基线）+ 登记规则 + skills 维护入口。
- 9 个 agent 露出行 + hero-conventions 露出模板均已改成带英雄名格式，token `🦸 hero ▸` 未变。
- `CLAUDE.md`、`hero-agent-roster.md` 交叉链接到位且无分类描述重复。
- `bash tests/hero-agent-layers/run.sh` 全绿；既有 `tests/hero-visibility/`、`tests/hero-dispatch/`、
  `tests/hero-refresh/` 不回归。
- `CLAUDE_HOME=/tmp/xxx bash install.sh` 演练通过（新增 tests/docs 不影响软链）。
- 人工走查：从分层总图任取一个 agent，能看到它的英雄代号/层/用法；模拟其接手，露出行带英雄名。

## 范围收敛

本次只交付**分层骨架 + 能力矩阵脚手架 + 现状首填 + 漫威命名落地（露出带名）+ 测试 + 导航接线**。
逐个 agent 的 skills/CLI 填深与提示词调优，是以本矩阵为底图的后续独立工作，每个 agent（或每层）
可单独成轮；漫威名的"可路由调用"若将来需要，另开 hero-dispatch 别名映射一轮。
