# ATLWork Java 项目批量 codegraph → 项目级 subagent 描述

> 实操步骤/命令/经验见配套手册 [`project-agent-cookbook.md`](./project-agent-cookbook.md)。

## Context（为什么做这件事）

为 `~/Documents/ATLWork` 下的 ~40 个 Java 微服务批量生成 codegraph 代码图谱，再以此为素材生成每个项目对应的「项目级 subagent」描述，让团队能把任务路由到对应服务的代码专家 agent。先验证思路可行性（pilot），确认质量后再批量。

### 现状盘点
- **工具**：`codegraph` v0.9.7 已装（`~/.codegraph/versions/v0.9.7`），支持 Java/Kotlin（tree-sitter-java/kotlin.wasm）。命令含 `init/index/status/query/files/context/callers/callees/impact/serve --mcp/install`。
- **规模**：ATLWork 共 **39,619 个 .java / 3.2GB**，~40 个独立 git 仓库（Maven 23 + Gradle 13 + 其他）。crm 单项目 990 个 java 文件。
- **语义种子已存在**：`ATLWork/CLAUDE.md` 已有每个项目的一句话说明 + 架构分组。
- **目标格式参考**：`claude-hero/agents/hero-java-backend-developer.md` —— frontmatter（name/description/model/tools）+ 中文正文。

### 可行性结论
**可行**。codegraph 提供"结构骨架"（模块/包/符号/入口类/调用关系），但"服务用途、何时该用"这类语义要靠 pom 依赖 + 包命名 + Controller/Feign 名 + 已有 CLAUDE.md 说明补足。最终方案 = **codegraph 结构 + pom/CLAUDE.md 语义** 一起喂 LLM 生成描述。

## 决策
1. **产物**：subagent `.md`，落 `claude-hero/agents/`，纳入团队 git，可被 Task 调用。
2. **范围**：先 pilot 验证，再批量全量。
3. **索引**：`.codegraph/` 保留并长期挂 MCP，供生成的 agent 实时查代码。
4. **agent 定位 = 领航/知识层**（只读 + codegraph MCP），**正交于** claude-hero 已有的 6 个横向角色 agent（hero-java-backend-developer / hero-java-code-reviewer / hero-java-test-engineer / hero-java-data-engineer / hero-java-tech-lead / hero-java-security-auditor）。项目 agent 负责"懂该服务·带路·圈定影响面"，干活交角色 agent。**不按角色拆**（否则 40×6 爆炸）。
5. **粒度**：默认 **1 项目 = 1 个领航 agent**；**超阈值的大项目按业务域拆 2-3 个** bounded-context agent（命名 `hero-java-<proj>-<domain>`）。阈值初定：`>2000 .java 文件` 或 `>15 顶层业务模块`。拆分依据是 `com.atour.<svc>.module.*` / 顶层包的业务边界，不按技术分层、不按角色。

## 项目级 agent 的解剖（合格标准）
**Frontmatter**：`name: hero-java-<proj>[-<domain>]`；`model: sonnet`；`tools: Read, Grep, Glob, Bash`（+ codegraph MCP 只读导航类）；`description` 必须含三要素——①服务一句话定位 ②**何时路由到它**（触发场景）③边界（不做什么、跨服务交谁），这是 Claude 决定调用与否的唯一依据。

**正文七部分**：①服务定位（业务域/架构位置/上下游）②技术栈指纹（框架·中间件·JDK，来自 pom·gradle）③代码地图（顶层包/模块→职责、分层与命名规律）④关键入口（Controller·对外 API、Feign Client、MQ 消费者、定时任务，真实类名）⑤对外契约与依赖（下游服务、暴露接口、MQ topic/group、二方包）⑥领域知识/坑（核心实体·状态机·易错点——codegraph 给不了，靠代码+经验沉淀，初版留占位）⑦导航工作法 + 协作边界（先 codegraph MCP 定位再动手；实现/SQL/测试/架构分别交对应角色 agent）。

---

## 执行方案

### 阶段 0 · Pilot（先用最小项目端到端跑通）

**第一步只做一个小项目 = `ecrm`（35 文件，Maven，电商 CRM）**，最快验证 index→evidence→生成 agent 全链路是否成立、codegraph 对该栈解析质量如何、是否有 git/噪声问题。跑通并认可后，再扩到：
- **chain-biz**（57 文件，Gradle）→ 验证 Gradle 解析
- **一个超阈值大项目**（取文件数最多者，如 pms-api / crs）→ 验证「按业务域拆多个 agent」路径与阈值判定

1. **索引并量化成本**
   - `codegraph init -i <项目路径>`（init+首次索引）。
   - 记录：耗时、`.codegraph/` 体积、`codegraph status` 的符号数。
   - **验证 Java 解析有效**：`codegraph query Controller`、`codegraph files --filter src/main/java` 应返回真实类/包，符号数 > 0。
   - **检查噪声**：确认 codegraph 是否索引了 `target/`、`build/`、`.idea/` 等非源码；必要时清理后重建。

2. **防 git 污染**（关键运维点）
   - 各 service 是独立 git 仓库，`.codegraph/` 会出现在 `git status`。
   - 处理：往每个项目 `.git/info/exclude` 追加 `.codegraph/`（本地忽略，不改动受版本控制的 `.gitignore`）。

3. **组装 evidence pack（每项目一份，喂给 LLM 的素材）**，来源：
   - `codegraph files --format grouped --filter src/main/java`（模块/包结构 + 符号数）
   - `codegraph query` 抓 Controller / Feign / Service / Mapper / MQ 消费者 入口符号
   - `pom.xml` / `build.gradle` 关键依赖（spring-boot / eureka / apollo / rocketmq / mybatis / jetcache / xxljob 等中间件指纹）
   - `ATLWork/CLAUDE.md` 中该项目的一句话说明 + 所属架构分组
   - 顶层包树（`com.atour.<svc>...`）、README（若有）

4. **按模板生成 subagent `.md`**（模板见下）。

5. **质量评审（人工 gate）**：
   - description 的"何时使用 / 边界"是否准确
   - 正文引用的包名/类名/中间件是否真实存在（抽查 `grep` 验证不编造）
   - 是否值得继续批量。**通过后才进入阶段 1。**

### 阶段 1 · 批量（确认后，全量 ~40 个）

6. **驱动脚本**（放 `claude-hero/cli/` 或临时脚本）做确定性部分：遍历 ATLWork 下所有 Java 项目目录 → `codegraph init -i` → 写 `.git/info/exclude` → 导出 evidence pack 到临时目录。
   - 串行或小并发（控磁盘/CPU）；支持断点续跑（已 init 的跳过）。
   - 跳过非 Java 项目（`code_to_word` Python、`atour-query` 空目录等）。

7. **批量生成描述**：对每个 evidence pack 用 LLM 套模板生成 `.md`。可用 `superpowers:dispatching-parallel-agents` 分批并行。

8. **挂 MCP**：`codegraph install`（注册到 Claude Code，stdio）或文档化 `codegraph serve --mcp -p <项目>`，使生成的 agent 能对所属项目实时 `callers/callees/impact/query`。

### subagent 模板（领航/知识层；单 agent 与按域拆同模板，域 agent 把范围收窄到该业务域）

```markdown
---
name: hero-java-<proj>[-<domain>]
description: 亚朵 <中文名>(<proj>[/<域>]) 服务代码领航。当需要理解/定位 <proj> 代码、
  圈定改动影响面、排查 Controller/Service/Mapper/MQ 走向时路由到它。它带路与定位、
  不直接写业务代码：实现交 hero-java-backend-developer、SQL 交 hero-java-data-engineer、
  测试交 hero-java-test-engineer、架构交 hero-java-tech-lead。仅限本服务[本业务域]。
model: sonnet
tools: Read, Grep, Glob, Bash   # + codegraph MCP（query/callers/callees/impact）
---

你是 **<proj>（<中文用途>）[<业务域>]** 的代码领航员（知识/导航层，不替代角色 agent 干活）。

## ① 服务定位
<业务域 / 架构分组(来自 CLAUDE.md) / 上下游>

## ② 技术栈指纹
<pom·gradle 提取：Spring Boot x.y, Eureka, Apollo, RocketMQ, MyBatis, JetCache, JDK 版本, Maven/Gradle>

## ③ 代码地图
<顶层包 com.atour.<svc>.module.* → 职责；分层与命名规律>

## ④ 关键入口（真实类名）
<主要 Controller·对外 API / Feign Client / MQ 消费者 / 定时任务>

## ⑤ 对外契约与依赖
<Feign 调的下游服务 / 暴露接口 / MQ topic·group / 二方包>

## ⑥ 领域知识 / 坑（持续沉淀）
<核心实体·状态机·易错点——codegraph 给不了，初版留占位，按代码与经验补>

## ⑦ 导航工作法 + 协作边界
- 先用 codegraph MCP（query/callers/callees/impact）定位、圈影响面，不凭记忆。
- 我只领航定位；动手交角色 agent（实现/SQL/测试/架构如上）。遵循 hero-conventions、best-practices。
- 只负责 <proj>[本业务域]，不跨服务/跨域直接改动。
```

### 设计取舍 / 待 pilot 验证的风险
- **agent 总数膨胀**：默认 ~40 个，大项目按域拆后可能 50-60 个。缓解：`hero-java-` 前缀统一命名；若过重，可改放 `ATLWork/.claude/agents/`（项目作用域加载）。
- **按域拆的阈值与边界**需 pilot 在大项目上实测校准。
- **领域知识（第⑥部分）无法自动化**：codegraph 只给结构，初版留占位，靠后续人工/经验沉淀。
- **索引成本未知**：3.2GB/4 万文件，全量索引耗时与磁盘待 pilot 实测外推。
- **codegraph 是否索引 target/build 噪声** 待 pilot 确认。

## 验证（如何确认成功）
1. **索引有效**：pilot 项目 `codegraph status` 符号数 > 0；`codegraph query Controller` 返回真实类。
2. **不污染 git**：pilot 项目 `git status` 干净（`.git/info/exclude` 生效）。
3. **描述准确**：生成的 agent `.md` frontmatter 合法；正文引用的包/类用 `grep` 抽查真实存在、无编造；description 经认可。
4. **MCP 可用**：新开 Claude 会话调用该 agent，能通过 codegraph MCP 对所属项目实时查询。
5. **批量完成**：~40 个 Java 项目均有索引 + 对应 agent；脚本可重跑幂等。
