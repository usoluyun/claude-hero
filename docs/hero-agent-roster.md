# 项目领航 Agent 花名册（roster）

> 本表是**领航研究层**明细；全局分层（含角色 agent）+ 先驱花名见 [`hero-agent-layers.md`](./hero-agent-layers.md)。

> 所有 `hero-java-<proj>` 项目领航 agent 的**确定性查找表**。
>
> 用途：
> 1. `hero-prd-to-java` 工作流 **Step 0「服务识别」** 的确定性查表（拿 PRD 关键词比对本表，
>    而非只靠 orchestrator 模糊匹配 description）。
> 2. 人工触发命令 `hero 领航 <X>` 的解析表（X 命中下表任一关键词/别名 → 调对应 agent）。
> 3. codegraph 手册批量生成时，**每生成一个领航 agent 就在此登记一行**，逐步覆盖 ~40 个服务。
>
> 命名规范：`hero-java-<proj>[-<domain>]`，全小写、与项目目录同名、统一 `hero-java-` 前缀。
> description 规范见 [`codegraph-agent-plan.md`](./codegraph-agent-plan.md) 模板的「四段式 + 触发词锚点」。

## 花名册

| Agent | proj | 中文名 | 业务关键词 / 别名 | 栈类型 | 项目路径 |
|---|---|---|---|---|---|
| `hero-java-ecrm` | ecrm | 企业/连锁/促销 申请审批工作流 | ecrm、企业连锁促销审批、申请审批工作流、OpenAPI、BPMN、ActionSoft、AWS BPM、企业协议、连锁申请、促销活动审批 | ⚠️ ActionSoft AWS BPM（**非 Spring Boot**，DBSql 裸 SQL） | `~/Documents/ATLWork/ecrm` |
| `hero-java-hotel-product-center` | hotel-product-center | 酒店产品中心 | 房价码、RateCode、产品管理、定价、渠道映射、房型映射、CRS 房价码、市场价、价格模板 | 标准 Spring 栈 | `~/Documents/ATLWork/hotel-product-center` |
| `hero-java-owner-biz` | owner-biz | 雅途业主服务端 | 业主 App、业主 Web 后端、Banner、连锁用户、业主通讯录、合同、供应商评价、GOP 大数据、日报月报、消息推送、摸地图 | Spring Cloud 单体 | `~/Documents/ATLWork/owner-biz` |

> 待补：atour 项目下其余 ~37 个 Java 服务（见 `codegraph-agent-plan.md` 阶段 1 批量计划）。
> 大项目按业务域拆 `hero-java-<proj>-<domain>` 时，每个域 agent 单独占一行，关键词收窄到该域。

## 登记规则

新增一个领航 agent 时，按下列字段补一行：
- **Agent**：`hero-java-<proj>[-<domain>]`，与 `agents/` 下文件名一致。
- **proj**：项目目录名。
- **中文名**：一句话业务定位。
- **业务关键词 / 别名**：与该 agent `description` 里「触发词：…」那行**保持一致**（这是触发命中的事实来源）。
- **栈类型**：标准 Spring 栈 / Spring Cloud 单体 / 非 Spring 特殊栈（标 ⚠️ 并注明差异）。
- **项目路径**：本地 codegraph 索引所在目录。
