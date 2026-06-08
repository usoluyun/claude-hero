# hero Agent 分层总图

> 一页看清 9 个 `hero-java-*` agent 谁在哪一层、叫什么代号、怎么用。
> 两条正交轴：**角色 agent（横向干活）× 项目领航 agent（按服务只读带路）**。
> 参考 oh-my-openagent 的 orchestration / planning / execution / specialist 分层，落到团队本土话术。
> 本表是**分层 + 漫威代号 + 能力**的唯一事实源；领航层触发明细见
> [`hero-agent-roster.md`](./hero-agent-roster.md)。

## 分层总图

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        神盾局长 Nick Fury     hero-java-tech-lead              (opus)
 ├─ 执行层        钢铁侠 Iron Man        hero-java-backend-developer      (sonnet)
 │                幻视 Vision            hero-java-data-engineer          (sonnet)
 │                蜘蛛侠 Spider-Man      hero-java-test-engineer          (sonnet)
 └─ 评审门控层    奇异博士 Doctor Strange hero-java-code-reviewer         (opus, 只读)
                  海姆达尔 Heimdall      hero-java-security-auditor       (opus, 只读)
项目领航 agent（按服务只读带路 = 领航研究层）
                  火箭浣熊 Rocket        hero-java-ecrm                   (sonnet, 只读)
                  星爵 Star-Lord         hero-java-hotel-product-center   (sonnet, 只读)
                  猎鹰 Falcon            hero-java-owner-biz              (sonnet, 只读)
```

正交性：角色 agent 跨服务通用、横向干活（规划/执行/评审三梯）；项目领航 agent 绑定单个服务、
只读带路。二者不重叠：领航 agent 圈定"在哪改、影响谁"，角色 agent 负责"具体怎么改"。

与 oh-my-openagent 分层的对应（仅记来源，不进团队话术）：

| 本团队层 | 对应 omo 层 |
|---|---|
| 规划层 | Planning（Prometheus/Atlas）+ Orchestration（Sisyphus） |
| 执行层 | Worker/Execution（Hephaestus/Sisyphus-Junior） |
| 评审门控层 | Specialist 中的只读评审（Momus/Oracle 审查面） |
| 领航研究层 | Specialist/Research（Oracle/Librarian/Explore） |

## 漫威代号映射

按各 agent 特点取名，**纯装饰/记忆点**：只用于露出标记与本表，不做"用英雄名调用"的路由。

| Agent | 漫威代号 | 取名理由（贴特点） |
|---|---|---|
| `hero-java-tech-lead` | 神盾局长 Nick Fury | 组建团队、拆任务派活、最后验收——天生编排者 |
| `hero-java-backend-developer` | 钢铁侠 Iron Man | 亲手造装备/写实现，工程师本色 |
| `hero-java-data-engineer` | 幻视 Vision | 由数据而生、擅综合；跨 MySQL/SQLServer 方言=多源数据合成 |
| `hero-java-test-engineer` | 蜘蛛侠 Spider-Man | 蜘蛛感应提前预警=测试在出事前抓 bug |
| `hero-java-code-reviewer` | 奇异博士 Doctor Strange | 推演千万结局找隐患=正确性/质量评审 |
| `hero-java-security-auditor` | 海姆达尔 Heimdall | 阿斯加德守门人、洞察一切入侵=安全审计守门 |
| `hero-java-ecrm` | 火箭浣熊 Rocket | 把不按常理的怪装备玩明白；ecrm 非 Spring 特殊栈(ActionSoft BPM) |
| `hero-java-hotel-product-center` | 星爵 Star-Lord | 带队探索定位；产品中心是定价/映射枢纽 |
| `hero-java-owner-biz` | 猎鹰 Falcon | 空中侦察大范围地形=大单体多业务域"摸地图" |

## 露出标记格式

`agent 接手`时机的 hero 露出标记带英雄名（详见 `hero-conventions` 露出规范）：

`🦸 hero ▸ <英雄名>（<agent>）接手 · <职责>`

例：`🦸 hero ▸ 钢铁侠（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`

前缀 token `🦸 hero ▸` 一字不改；英雄名作记忆点、agent 技术名供排查时不歧义定位。

## 能力矩阵

按层分组，每行一个 agent。`漫威代号 / 层 / model / 怎么用` 必填；`触发词 / 应加载 skills /
该用 CLI` 允许 `TODO`（待后续逐个 agent 填深）。**本表填好一格 → 去改对应 agent 文件 → 双向对齐**
（改 agent 文件是后续工作）。`TODO` 是约定哨兵值，代表"待补"，非缺漏。

### 规划层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-tech-lead` | 神盾局长 | opus | TODO | superpowers:brainstorming, superpowers:writing-plans, hero-conventions | codegraph | 给它特性/需求 → 产出架构设计+任务分派清单 → 主会话据此分派各专家 → 回它汇总验收 |

### 执行层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-backend-developer` | 钢铁侠 | sonnet | TODO | hero-conventions, superpowers:test-driven-development | maven, gradle, jdk-multiversion | 给它明确任务 → 实现 Controller/Service/DAO 与中间件接入，TDD-first |
| `hero-java-data-engineer` | 幻视 | sonnet | TODO | hero-conventions | mycli（MySQL）, sqlcmd（SQLServer） | 给它 SQL/数据层需求 → 产出 MyBatis mapper/XML、resultMap、慢查询调优 |
| `hero-java-test-engineer` | 蜘蛛侠 | sonnet | TODO | superpowers:test-driven-development, gherkin, allure（经 `skills:` 字段预加载） | maven, gradle, httpie（接口冒烟）, allure（报告）；E2E 用 Playwright MCP | 给它待测代码 → 单元(TDD)/BDD(.feature)/接口冒烟(httpie)/E2E(Playwright 无头)/Allure 报告，纯本地无容器 |

### 评审门控层

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-code-reviewer` | 奇异博士 | opus（只读） | TODO | —（自带评审 checklist + 严重级/`file:line` 格式，不依赖外部 skill） | —（只读评审，Read/Grep/git diff 为主） | 给它 diff/SHA → 产出正确性与质量问题清单（不改码） |
| `hero-java-security-auditor` | 海姆达尔 | opus（只读） | TODO | —（自带审计 checklist + OWASP/合规清单骨架，不依赖外部 skill） | semgrep, gitleaks（🔴 设计安全）；maven/gradle 依赖树 + WebSearch（🟡 CVE） | **设计时**评审 design 文档定 🔴 门槛 + **代码时** semgrep/gitleaks/grep 验门槛。系统设计安全（未授权/越权/敏感数据/注入/不安全设计）= 🔴 强制门槛（⛔阻断）；组件 CVE = 🟡 提醒确认（不阻断） |

### 领航研究层（只读带路）

| Agent | 漫威代号 | model | 触发词 | 应加载 skills | 该用 CLI | 怎么用 |
|---|---|---|---|---|---|---|
| `hero-java-ecrm` | 火箭浣熊 | sonnet（只读） | ecrm、企业连锁促销审批、申请审批工作流、OpenAPI、BPMN、ActionSoft、AWS BPM、企业协议、连锁申请、促销活动审批 | —（codegraph 带路，无需加载 skill） | codegraph | 给它 ecrm 意图 → 定位代码/讲 BPMN 审批流走向/圈影响面（只读带路） |
| `hero-java-hotel-product-center` | 星爵 | sonnet（只读） | 房价码、RateCode、产品管理、定价、渠道映射、房型映射、CRS 房价码、市场价、价格模板 | —（codegraph 带路，无需加载 skill） | codegraph | 给它产品中心意图 → 定位代码/讲房价码或产品接口走向/圈影响面（只读带路） |
| `hero-java-owner-biz` | 猎鹰 | sonnet（只读） | 业主 App、业主 Web 后端、Banner、连锁用户、业主通讯录、合同、供应商评价、GOP 大数据、日报月报、消息推送、摸地图 | —（codegraph 带路，无需加载 skill） | codegraph | 给它业主端意图 → 在多业务域里找入口/看跨域调用/圈影响面（只读带路） |

> 触发词列：领航 agent 取自 [`hero-agent-roster.md`](./hero-agent-roster.md)「业务关键词/别名」，须与之一致；
> 角色 agent 暂无显式触发锚点，标 `TODO`，待后续补。
> 领航 agent 由 `hero-refresh` 工作流定期保鲜（随代码漂移重生 agent 卡），但那是**对其维护、非运行时加载**；
> 它们干活只用 codegraph，故「应加载 skills」列记 `—`。
> **框架/库文档核实**统一分层：先读 `docs/vendor-docs/` 本地缓存（hero-refresh 维护）+ codegraph →
> 本地缺再用 **context7 MCP** 兜底。为此 backend / code-reviewer / security-auditor / tech-lead 的 `tools`
> 已含 context7 MCP（`mcp__plugin_context7_context7__*`）；security-auditor 另含 WebSearch/WebFetch 查 CVE，
> tech-lead 另含 Write/Edit 以落盘设计文档。
> 海姆达尔（security-auditor）双模：设计时读 `docs/design-*.md` 定 🔴 门槛、代码时验；🔴=系统设计安全（强制），
> 🟡=组件依赖 CVE（提醒确认）。CLI（semgrep/gitleaks/CodeQL）经 Bash、OWASP 经 context7→`vendor-docs`、
> 合规口径见 `docs/security-standards.md`——`tools:` 白名单不变。详见 spec `2026-06-07-security-auditor-design-gate.md`。
> 蜘蛛侠（test-engineer）的 skills（tdd/gherkin/allure）经 frontmatter `skills:` 字段**预加载**（本仓首次用该字段，
> C-systemic 试点）；E2E 的 Playwright MCP 经 `tools:` 白名单（`mcp__playwright__*`）+ `mcp/servers/playwright.json` 模板启用。
> 纯本地测试、不依赖容器。详见 spec `2026-06-08-test-engineer-local-testing.md`。

## 新增 agent 登记规则

加一个 agent 时按此走，保证落位确定、不漏归层：

1. **选轴**：横向干活 → 角色 agent；按服务只读带路 → 项目领航 agent。
2. **选层**：角色 → 规划 / 执行 / 评审门控 其一；领航 → 领航研究层。
3. **命名** `hero-<lang>-<...>`，文件名 = frontmatter `name`（见 [`CONTRIBUTING.md`](../CONTRIBUTING.md)）。
4. **起漫威代号**：在「漫威代号映射」补一行（按特点取名）。
5. **补能力矩阵**：在对应层的表补一行（漫威代号/model/怎么用 必填，其余可 `TODO`）。
6. **改露出行**：在该 agent 文件 `## hero 露出` 写带英雄名的自报家门行。
7. 若是**领航 agent**，另在 [`hero-agent-roster.md`](./hero-agent-roster.md) 登记一行。
8. 跑 `bash tests/hero-agent-layers/run.sh` 确认未漏归层 / 漏代号。

## skills 维护入口

能力矩阵的「应加载 skills」列即 **skill → agent 反查索引**：改动 / 废弃某个 skill 时，
`grep '<skill-name>' docs/hero-agent-layers.md` 即知影响哪些 agent，逐个评估同步。
（当前多数角色 agent 的 skills 仍是首填基线 + `TODO`，会随后续逐个 agent 填深而完善。）
