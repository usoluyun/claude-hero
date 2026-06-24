# hero Agent 分层总图

> 一页看清 9 个 `hero-java-*` agent 谁在哪一层、叫什么花名、怎么用。
> 两条正交轴：**角色 agent（横向干活）× 项目领航 agent（按服务只读带路）**。
> 分层沿用 orchestration / planning / execution / specialist 的通用思路，落到团队本土话术。
> 本表是**分层 + 先驱花名 + 能力**的唯一事实源；领航层触发明细见
> [`hero-agent-roster.md`](./hero-agent-roster.md)。

## 分层总图

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        Demis Hassabis   hero-java-tech-lead              (opus)
 ├─ 执行层        Jeff Dean        hero-java-backend-developer      (sonnet)
 │                Fei-Fei Li       hero-java-data-engineer          (opus)
 │                Percy Liang      hero-java-test-engineer          (sonnet)
 └─ 评审门控层    Chris Olah       hero-java-code-reviewer          (opus, 只读)
                  Jan Leike        hero-java-security-auditor       (opus, 只读)
项目领航 agent（按服务只读带路 = 领航研究层）
                  John Schulman    hero-java-ecrm                   (sonnet, 只读)
                  Oriol Vinyals    hero-java-hotel-product-center   (sonnet, 只读)
                  David Silver     hero-java-owner-biz              (sonnet, 只读)
```

正交性：角色 agent 跨服务通用、横向干活（规划/执行/评审三梯）；项目领航 agent 绑定单个服务、
只读带路。二者不重叠：领航 agent 圈定"在哪改、影响谁"，角色 agent 负责"具体怎么改"。

四层沿用通用分层思路（仅记来源，不进团队话术）：规划层 = Planning + Orchestration；
执行层 = Worker/Execution；评审门控层 = 只读评审；领航研究层 = 研究/检索带路。

## 先驱花名映射

花名取自**当今 AI 时代活跃的科学家 / 工程师 / 算法人——创造了这个时代、名字值得被记住**，
按各 agent 特点对号入座。**纯装饰/记忆点**：只用于露出标记与本表，不做"用英雄名调用"的路由。
被问到"这个花名是谁"时，按本表的「简介 + 英文维基」回答。

| Agent | 花名 | 简介（机构 · 代表作 · 英文维基） | 为何贴这一岗 |
|---|---|---|---|
| `hero-java-tech-lead` | Demis Hassabis | Google DeepMind 联合创始人兼 CEO，AlphaGo·AlphaFold 缔造者，2024 诺贝尔化学奖。<https://en.wikipedia.org/wiki/Demis_Hassabis> | 统领大兵团科研、定方向、编排全局——天生 orchestrator |
| `hero-java-backend-developer` | Jeff Dean | Google 首席科学家、Google DeepMind 负责人；MapReduce / Bigtable / TensorFlow 之父。<https://en.wikipedia.org/wiki/Jeff_Dean> | 亲手造基础设施的工程之神，工程师本色 |
| `hero-java-data-engineer` | Fei-Fei Li | 斯坦福教授，ImageNet 缔造者，"AI 教母"。<https://en.wikipedia.org/wiki/Fei-Fei_Li> | 数据驱动深度学习的奠基者，大规模数据合成 |
| `hero-java-test-engineer` | Percy Liang | 斯坦福教授，基础模型研究中心（CRFM）主任，HELM 评测基准主导。<https://en.wikipedia.org/wiki/Percy_Liang> | 评测/把关是其标签，出事前抓问题 |
| `hero-java-code-reviewer` | Chris Olah | Anthropic 联合创始人，神经网络（机制）可解释性先驱。<https://en.wikipedia.org/wiki/Chris_Olah> | 看进内部找出真正发生了什么 = 评审挖隐患 |
| `hero-java-security-auditor` | Jan Leike | AI 对齐研究者，曾领导 OpenAI / DeepMind 安全，2024 加入 Anthropic。<https://en.wikipedia.org/wiki/Jan_Leike> | 对齐 / 安全守门人 |
| `hero-java-ecrm` | John Schulman | OpenAI 联合创始人，PPO / RLHF 与 ChatGPT 背后 RL 负责人，曾任 Anthropic。<https://en.wikipedia.org/wiki/John_Schulman> | 驯服复杂 RL = 啃异构怪栈（ecrm 非 Spring 特殊栈） |
| `hero-java-hotel-product-center` | Oriol Vinyals | DeepMind，seq2seq 共同发明者、AlphaStar 负责人。<https://en.wikipedia.org/wiki/Oriol_Vinyals> | 序列映射 = 产品中心定价 / 渠道映射枢纽 |
| `hero-java-owner-biz` | David Silver | DeepMind，AlphaGo / AlphaZero 负责人，强化学习泰斗。<https://en.wikipedia.org/wiki/David_Silver_(computer_scientist)> | 在广袤搜索空间里探路 = 大单体多业务域"摸地图" |

## 露出标记格式

`agent 接手`时机的 hero 露出标记带先驱花名（详见 `hero-conventions` 露出规范）：

`🦸 hero ▸ <花名>（<agent>）接手 · <职责>`

例：`🦸 hero ▸ Jeff Dean（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`

前缀 token `🦸 hero ▸` 一字不改；花名作记忆点、agent 技术名供排查时不歧义定位。

## 能力矩阵

按层分组，每行一个 agent。`先驱花名 / 层 / model / 怎么用` 必填；`触发词 / 应加载 skills /
该用 CLI` 允许 `TODO`（待后续逐个 agent 填深）。**本表填好一格 → 去改对应 agent 文件 → 双向对齐**
（改 agent 文件是后续工作）。`TODO` 是约定哨兵值，代表"待补"，非缺漏。

### 规划层

| Agent | 先驱花名 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-tech-lead` | Demis Hassabis | opus | 技术负责人 / Demis Hassabis / 架构设计 / 技术方案 / 任务拆解 / Sprint 规划 / 设计评审 / 模块划分 / 接口契约 / 技术选型 | superpowers:brainstorming, superpowers:writing-plans, hero-conventions | codegraph, scc, ast-grep, jq, claude-mermaid | 给它特性/需求 → 产出架构设计+任务分派清单 → 主会话据此分派各专家 → 回它汇总验收 |

### 执行层

| Agent | 先驱花名 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-backend-developer` | Jeff Dean | sonnet | 后端开发 / Jeff Dean / 实现接口 / 写 Controller / 写 Service / 接入中间件 / Spring Boot 业务 / Maven 构建 / Gradle 构建 | hero-conventions, superpowers:test-driven-development | maven, gradle, jdk-multiversion, ast-grep, httpie, jq, codegraph | 给它明确任务 → 实现 Controller/Service/DAO 与中间件接入，TDD-first |
| `hero-java-data-engineer` | Fei-Fei Li | opus | 数据工程师 / Fei-Fei Li / MyBatis / 写 SQL / Mapper XML / 性能优化 / 索引设计 / 数据库管理 / DBA / 表结构 / 慢查询 / SQLServer / SQL 安全 | hero-conventions | SlowQL, pg_glimpse, mycli, sqlcmd, osv-scanner | 给它 SQL/数据层需求 → 产出 MyBatis mapper/XML、resultMap、慢查询调优 |
| `hero-java-test-engineer` | Percy Liang | sonnet | 测试工程师 / Percy Liang / 写测试 / 单元测试 / TDD / BDD / 接口测试 / Allure 报告 / 端到端测试 / 冒烟测试 | superpowers:test-driven-development, gherkin, allure（经 `skills:` 字段预加载） | maven, gradle, httpie（接口冒烟）, allure（报告）；E2E 用 Playwright MCP | 给它待测代码 → 单元(TDD)/BDD(.feature)/接口冒烟(httpie)/E2E(Playwright 无头)/Allure 报告，纯本地无容器 |

### 评审门控层

| Agent | 先驱花名 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-code-reviewer` | Chris Olah | opus（只读） | 代码审查 / Chris Olah / Code Review / 评审 / 代码质量 / 质量审查 / 审查清单 | —（自带评审 checklist + 严重级/`file:line` 格式，不依赖外部 skill） | PMD, SpotBugs, ast-grep, scc, codegraph, osv-scanner | 给它 diff/SHA → 产出正确性与质量问题清单（不改码） |
| `hero-java-security-auditor` | Jan Leike | opus（只读） | 安全审计 / Jan Leike / 安全审查 / 安全设计 / 安全审计师 / 安全门控 / 安全评审 / 代码安全 | —（自带审计 checklist + OWASP/合规清单骨架，不依赖外部 skill） | semgrep, gitleaks（🔴 设计安全）；maven/gradle 依赖树 + WebSearch（🟡 CVE） | **设计时**评审 design 文档定 🔴 门槛 + **代码时** semgrep/gitleaks/grep 验门槛。系统设计安全（未授权/越权/敏感数据/注入/不安全设计）= 🔴 强制门槛（⛔阻断）；组件 CVE = 🟡 提醒确认（不阻断） |

### 领航研究层（只读带路）

| Agent | 先驱花名 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-ecrm` | John Schulman | sonnet（只读） | ecrm、企业连锁促销审批、申请审批工作流、OpenAPI、BPMN、ActionSoft、AWS BPM、企业协议、连锁申请、促销活动审批 | —（codegraph 带路，无需加载 skill） | codegraph | 给它 ecrm 意图 → 定位代码/讲 BPMN 审批流走向/圈影响面（只读带路） |
| `hero-java-hotel-product-center` | Oriol Vinyals | sonnet（只读） | 房价码、RateCode、产品管理、定价、渠道映射、房型映射、CRS 房价码、市场价、价格模板 | —（codegraph 带路，无需加载 skill） | codegraph | 给它产品中心意图 → 定位代码/讲房价码或产品接口走向/圈影响面（只读带路） |
| `hero-java-owner-biz` | David Silver | sonnet（只读） | 业主 App、业主 Web 后端、Banner、连锁用户、业主通讯录、合同、供应商评价、GOP 大数据、日报月报、消息推送、摸地图 | —（codegraph 带路，无需加载 skill） | codegraph | 给它业主端意图 → 在多业务域里找入口/看跨域调用/圈影响面（只读带路） |

> 触发词列：领航 agent 取自 [`hero-agent-roster.md`](./hero-agent-roster.md)「业务关键词/别名」，须与之一致；
> 所有角色 agent 的触发词现已全部补全（此前标 `TODO` 的均已填）。
> 领航 agent 由 `hero-refresh` 工作流定期保鲜（随代码漂移重生 agent 卡），但那是**对其维护、非运行时加载**；
> 它们干活只用 codegraph，故「应加载 skills」列记 `—`。
> **框架/库文档核实**统一分层：先读 `docs/vendor-docs/` 本地缓存（hero-refresh 维护）+ codegraph →
> 本地缺再用 **context7 MCP** 兜底。为此 backend / code-reviewer / security-auditor / tech-lead / data-engineer 的 `tools`
> 已含 context7 MCP（`mcp__plugin_context7_context7__*`）；security-auditor 另含 WebSearch/WebFetch 查 CVE，
> tech-lead 另含 Write/Edit 以落盘设计文档。
> Jan Leike（security-auditor）双模：设计时读 `docs/design-*.md` 定 🔴 门槛、代码时验；🔴=系统设计安全（强制），
> 🟡=组件依赖 CVE（提醒确认）。CLI（semgrep/gitleaks/CodeQL）经 Bash、OWASP 经 context7→`vendor-docs`、
> 合规口径见 `docs/security-standards.md`——`tools:` 白名单不变。详见 spec `2026-06-07-security-auditor-design-gate.md`。
> Percy Liang（test-engineer）的 skills（tdd/gherkin/allure）经 frontmatter `skills:` 字段**预加载**（本仓首次用该字段，
> C-systemic 试点）；E2E 的 Playwright MCP 经 `tools:` 白名单（`mcp__playwright__*`）+ `mcp/servers/playwright.json` 模板启用。
> 纯本地测试、不依赖容器。详见 spec `2026-06-08-test-engineer-local-testing.md`。

## 新增 agent 登记规则

加一个 agent 时按此走，保证落位确定、不漏归层：

1. **选轴**：横向干活 → 角色 agent；按服务只读带路 → 项目领航 agent。
2. **选层**：角色 → 规划 / 执行 / 评审门控 其一；领航 → 领航研究层。
3. **命名** `hero-<lang>-<...>`，文件名 = frontmatter `name`（见 [`CONTRIBUTING.md`](../CONTRIBUTING.md)）。
4. **起先驱花名**：在「先驱花名映射」补一行——取一位贴其特点、当今活跃且**有英文维基页面**的 AI 科学家/工程师，连简介 + 维基链接一起登记。机构优先级：**Anthropic > DeepMind ≈ 学术界 > OpenAI > Meta（兜底）**。无英文维基页面者不取。
5. **补能力矩阵**：在对应层的表补一行（先驱花名/model/怎么用 必填，其余可 `TODO`）。
6. **改露出行**：在该 agent 文件 `## hero 露出` 写带花名的自报家门行。
7. 若是**领航 agent**，另在 [`hero-agent-roster.md`](./hero-agent-roster.md) 登记一行。
8. 跑 `bash tests/hero-agent-layers/run.sh` 确认未漏归层 / 漏花名。

## skills 维护入口

能力矩阵的「应加载 skills」列即 **skill → agent 反查索引**：改动 / 废弃某个 skill 时，
`grep '<skill-name>' docs/hero-agent-layers.md` 即知影响哪些 agent，逐个评估同步。
（当前 backend-developer / tech-lead / test-engineer 的 skills 字段已填，code-reviewer / security-auditor / data-engineer 的审计/安全/合规清单由 agent 自身携带、不依赖外部 skill。）
