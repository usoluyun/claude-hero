# codegraph：领航 agent 的知识底座

> **权威源**：[`docs/codegraph-agent-plan.md`](../codegraph-agent-plan.md) + [`docs/project-agent-cookbook.md`](../project-agent-cookbook.md)
> **范围**：本文解读 codegraph 如何作为领航 agent 的知识底座，不复制现有 docs 全文。

## 一句话引言

**codegraph 是领航 agent 的「知识底座」**。它提供两样东西：**结构骨架**（模块/包/符号/调用关系）和 **语义补足**（通过 pom/CLAUDE.md 将骨架翻译成「这服务是干什么的」）。二者合一，让领航 agent 能「懂该服务·带路·圈影响面」。

## codegraph 工具简介

| 项 | 内容 |
|---|---|
| 版本 | v0.9.7 |
| 安装路径 | `~/.codegraph/versions/v0.9.7` |
| 支持语言 | Java（tree-sitter-java）、Kotlin（kotlin.wasm） |

**核心命令**（7+ 个）：

| 命令 | 作用 |
|---|---|
| `init` | 初始化索引配置 |
| `index` | 构建/重建代码索引 |
| `status` | 查看符号数、语言分布 |
| `query` | 按符号名搜索（类/方法/注解） |
| `files` | 列出文件与模块结构 |
| `callers` | 查「谁调了 X」 |
| `callees` | 查「X 调了谁」 |
| `impact` | 圈定改动影响面（上游调用链） |
| `serve --mcp` | 启动 MCP server，供 agent 实时查询 |
| `install` | 注册到 Claude Code |

日常开发中最常用的三条：`query` 定位入口 → `callers/impact` 圈影响面 → `files --format grouped` 看项目全景。

## 领航 agent 的定位

领航 agent（`hero-java-<proj>`）是**单服务、只读、codegraph 驱动**的知识/导航层。核心职责：「懂该服务·带路·圈影响面」，**自己不写代码**。

它与 6 个横向角色 agent **正交**（见下文双轴图解）。一句话记住分工：**领航 agent 圈定「在哪改、影响谁」，角色 agent 负责「具体怎么改」**。

粒度：默认 1 项目 = 1 个领航 agent。超阈值大项目（>2000 `.java` 文件 或 >15 顶层业务模块）按业务域拆成 2-3 个 bounded-context agent，命名 `hero-java-<proj>-<domain>`。

## 正文七部分解剖

每个领航 agent 的正文由 7 段组成，来源是 codegraph 结构 + pom/CLAUDE.md 语义：

| 段 | 内容 | 来源 |
|---|---|---|
| ① 服务定位 | 业务域、架构位置、上下游关系 | CLAUDE.md + 顶层包命名 |
| ② 技术栈指纹 | 框架·中间件·JDK 版本 | `pom.xml` / `build.gradle` 关键依赖 |
| ③ 代码地图 | 顶层包/模块 → 职责、分层与命名规律 | `codegraph files --format grouped` |
| ④ 关键入口 | Controller / Feign / MQ 消费者 / 定时任务（真实类名） | `codegraph query` 按注解/接口名搜索 |
| ⑤ 对外契约与依赖 | 下游服务、暴露接口、MQ topic/group、二方包 | `codegraph callers` + Feign/MQ 注解扫描 |
| ⑥ 领域知识/坑 | 核心实体·状态机·易错点 | 代码 + 经验沉淀（初版留占位） |
| ⑦ 导航工作法 + 协作边界 | 先 codegraph MCP 定位再动手；实现/SQL/测试/架构交对应角色 agent | codegraph MCP + 团队约定 |

Frontmatter 的 `description` 字段遵循**四段式命令规范**：

1. 服务一句话定位
2. **触发词锚点**（`触发词：<proj> / <中文名> / <核心业务名词…> / <别名> / <关联系统>`）
3. 何时路由到它（触发场景）
4. 边界（不做什么、跨服务交谁）

触发词锚点是 orchestrator 稳定路由的关键：词面命中决定 agent 是否被派发。

## Evidence Pack 组装流程

生成一个领航 agent 之前，先组装 evidence pack（喂给 LLM 的素材包）。5 个来源：

| # | 素材 | 命令/来源 |
|---|---|---|
| 1 | 模块/包结构 + 符号数 | `codegraph files --format grouped --filter src/main/java` |
| 2 | 入口符号（Controller/Feign/Service/Mapper/MQ 消费者） | `codegraph query Controller` 等按注解搜索 |
| 3 | 技术栈指纹 | `pom.xml` / `build.gradle` 关键依赖（spring-boot / eureka / apollo / rocketmq / mybatis / jetcache / xxljob 等中间件） |
| 4 | 语义种子 | 项目根 CLAUDE.md 中该项目的一句话说明 + 架构分组；项目内 README（若有） |
| 5 | 顶层包树 | `com.atour.<svc>...` 包结构 |

优先级：**项目内 CLAUDE.md/README > 上级 CLAUDE.md > 包命名推断**。Pilot 中 owner-biz 的 ATLWork/CLAUDE.md 无条目，但项目自带 CLAUDE.md 提供了完整栈/分层/外部依赖，经验是优先吃项目内的。

## 双轴正交关系

领航 agent 与 6 个角色 agent 是两条正交的轴，不重叠：

```
角色 agent（横向干活，跨服务通用）
 ├─ 规划层        孔明     hero-java-tech-lead
 ├─ 执行层        文远     hero-java-backend-developer
 │                子长     hero-java-data-engineer
 │                希仁     hero-java-test-engineer
 └─ 评审门控层    玄成     hero-java-code-reviewer
                  鹏举     hero-java-security-auditor

项目领航 agent（按服务只读带路 = 领航研究层）
 ├─ 子文     hero-java-ecrm
 ├─ 郑和     hero-java-hotel-product-center
 └─ 霞客     hero-java-owner-biz
```

> 一句话记住分工：领航 agent 圈定「在哪改、影响谁」，角色 agent 负责「具体怎么改」

为什么不做「每个角色 × 每个服务」的组合？因为 40 服务 × 6 角色 = 240 个 agent，爆炸。正交设计把「知道在哪」和「知道怎么干」解耦：服务越多只加领航 agent，角色 agent 始终 6 个。

## 在 hero-prd-to-java 中的 4 个插入点

领航 agent 在 PRD 驱动开发的 8 步流水线中有 4 个明确的插入点：

| Step | 步骤名 | 领航 agent 的角色 |
|---|---|---|
| Step 0 | 服务识别 | 比对花名册（`docs/hero-agent-roster.md`），命中存量服务 |
| Step 1 | 现状勘察 | 用 codegraph 摸地图，产出勘察报告喂给设计阶段 |
| Step 4 | 开发导航 | 实现 agent 动手前取定位：「在哪改、影响谁」 |
| Step 6 | 影响面复核 | 用 `codegraph impact` 复核全部受影响 caller 都被覆盖 |

**协作边界**：领航只管单服务内「代码长啥样、改了影响谁」；跨服务的整体拆分 / 契约对齐 / 拓扑排序归 **tech-lead**；实现归 backend-developer，SQL 归 data-engineer，测试归 test-engineer。领航产出**喂给** tech-lead / 角色 agent，自己不下场。

## 降级策略

不是每个服务都有领航 agent。三种情况，三种策略：

| 情况 | 策略 |
|---|---|
| 命中服务**有**领航 agent | 派发它勘察/导航 |
| 命中服务**无**领航 agent | 回退到现场勘察（`codegraph` CLI 或 `Grep/Glob` 直接扫该服务），workflow **不阻塞** |
| **新增**服务 | 无存量可勘察，走绿地设计 |

缺领航 agent 的存量服务可事后用 `hero-init` 补齐，逐步覆盖 ~40 个服务。新生成的 agent 登记到 `docs/hero-agent-roster.md` 后即纳入 `hero-refresh` 保鲜体系。
