# 项目领航 Agent 生成手册（codegraph 实操）

> 配套方案见 [`codegraph-agent-plan.md`](./codegraph-agent-plan.md)。本文是**怎么做**——从一个 Java 服务生成一个 `hero-<lang>-<project>` 领航 agent 的可复用步骤、命令、经验与坑。
> 已据此产出：`hero-java-ecrm`、`hero-java-hotel-product-center`。

## 0. 这个 agent 是什么 / 不是什么
- **是**：某个服务的"代码领航员/知识层"——懂业务定位、技术栈、代码地图、入口、对外契约，能用 codegraph 圈定改动影响面。只读。
- **不是**：干活的角色 agent。实现交 `hero-java-backend-developer`、SQL 交 `hero-java-data-engineer`、测试交 `hero-java-test-engineer`、架构交 `hero-java-tech-lead`。
- 所以项目 agent 与角色 agent **正交**，不按角色拆，避免 N×6 爆炸。

## 1. 六步流程

### Step 1 · 索引 + 防 git 污染
```bash
cd <项目路径>
# 防止 .codegraph/ 出现在该服务自己的 git 仓库（本地忽略，不动受控 .gitignore）
grep -qxF '.codegraph/' .git/info/exclude 2>/dev/null || printf '.codegraph/\n' >> .git/info/exclude
codegraph init -i .          # init + 首次索引
codegraph status .           # 看符号数/语言分布，确认解析有效（>0）
git status --short           # 必须干净
```
**实测成本**：ecrm 35 文件→0.25s/1.7MB；hotel-product-center 854 文件→10s/41MB。外推全量 ~4 万文件 ≈ 8–12 分钟 / ~2GB。

### Step 2 · 探测源码布局（不要假设 `src/main/java` 在根）
```bash
# 真实源码根（Maven 单模块 vs Gradle 多模块差别大）
find . -name "*.java" -path "*/main/*" | sed -E 's#(.*/src/main/java/).*#\1#' | sort | uniq -c
# base package
find . -path "*/src/main/java/*" -name "*.java" | sed -E 's#.*/src/main/java/##; s#/[^/]+\.java$##' | sort -u | head -3
```
- ecrm：单模块 `src/main/java`，包根 `com.awspaas.user.apps.wll.ecrm`。
- hotel-product-center：**多模块** `*-api / *-core / *-boot`，包根 `com.yaduo.product`。

### Step 3 · 识别真实技术栈（决定模板，不能默认 Spring）
```bash
# Maven
grep -E "<artifactId>|<groupId>" pom.xml
# Gradle（含 version catalog / 各子模块 build.gradle）
grep -rhoE "(spring-boot[-a-z]*|spring-cloud[-a-z]*|mybatis[-a-z]*|sentinel|redis[-a-z]*|ons|rocketmq|elasticsearch|xxl-job|apollo|druid|eureka|openfeign)" */build.gradle build.gradle | sort -u
grep -riE "sourceCompatibility|JavaVersion|springBootVersion" build.gradle */build.gradle
```
**关键经验——框架自适应**：两个 pilot 完全不同栈，模板必须如实反映：
| | ecrm | hotel-product-center |
|---|---|---|
| 平台 | **ActionSoft AWS BPM PaaS**（非 Spring） | **Spring Boot 2.7.12 / Java 17** |
| 接口 | `@Controller(OPENAPI)`+`@Mapping` | `@RestController` + `*ApiImpl`(facade) |
| 数据 | 裸 `DBSql` 拼 SQL | MyBatis + Druid + Redis + ES |
| 远程 | 拼 URL 外呼 BPM/网关 | Eureka + OpenFeign |
| 团队约定适用性 | **多数不适用**（要在 agent 里警示） | 完全适用 |

### Step 4 · 组装 evidence pack（喂给生成的素材）
| 素材 | 命令/来源 |
|---|---|
| 模块/包结构 | `codegraph files --filter <src根> -p .` |
| 入口符号 | `codegraph query Controller -p .`；`grep -rln "@RestController\|@Controller" --include="*.java" .` |
| Feign 下游 | `grep -rln "@FeignClient" --include="*.java" .` |
| MQ 消费者 | `grep -rln "@RocketMQMessageListener\|MessageListener" --include="*.java" .` |
| 定时任务 | `grep -rln "@XxlJob\|@Scheduled" --include="*.java" .` |
| 对外契约 | 多模块看 `*-api` 模块的 `*Api`/`*Facade` 接口 |
| 语义种子 | `ATLWork/CLAUDE.md` 该项目一句话 + 架构分组 |

> ⚠️ zsh 坑：`--include=*.java` 不加引号会触发文件名通配报错，要写成 `--include="*.java"`。

### Step 5 · 套模板生成 agent
模板与七部分结构见 `codegraph-agent-plan.md`。要点：
- frontmatter `name = hero-<lang>-<project>`（命名规范见 `CONTRIBUTING.md`）。
- `description` 三要素：①一句话定位 ②何时路由到它 ③边界（交给哪个角色 agent）。栈非主流时在 description 里**警示**（如 ecrm 那句"非 Spring Boot，团队约定多数不适用"）。
- 正文七部分：①定位 ②技术栈指纹 ③代码地图 ④关键入口(真实类名) ⑤对外契约与依赖 ⑥领域知识/坑(留占位) ⑦导航工作法+协作边界。

### Step 6 · 反编造验证（必做，硬门槛）
正文引用的每个类/接口/方法都要在代码里真实存在：
```bash
for c in RateCodeApiImpl HotelProductApi ChainRemoteApi SyncRateCodeCacheJob; do
  find . -name "$c.java" >/dev/null 2>&1 && echo "OK $c" || echo "MISSING $c"
done
```
两个 pilot 都做到了零 MISSING。任何 MISSING 必须改掉再交付。

## 2. 关键经验（踩过的 / 反直觉的）
1. **CLAUDE.md 标签可能与代码不符**：ecrm 被标"电商 CRM"，实际是 BPM 审批工作流。**以代码为准**，并在 agent 里点明纠偏——这正是自动生成比旧文档更有价值的地方。
2. **不能默认 Spring 栈**：先识别框架再选模板，否则生成一堆不存在的 Eureka/Apollo 描述。
3. **多模块要分清职责**：`-api`=对外契约、`-core`=实现、`-boot`=启动，⑤对外契约直接取 `-api`。
4. **`route`/`@Controller` 数量是栈信号**：codegraph `route` 节点>0 基本就是 Web 服务。
5. **领域知识(第⑥部分)无法自动化**：codegraph 只给结构，坑/状态机靠人逐步沉淀，初版留占位。
6. **codegraph CLI 当下即用**（`query/files/callers/callees/impact -p`），MCP 可后置。

## 3. 验证清单（每个 agent 交付前）
- [ ] `codegraph status` 符号数 > 0、语言含 java
- [ ] 该服务 `git status` 干净（exclude 生效）
- [ ] frontmatter `name` = 文件名、含三要素 description
- [ ] 正文引用类/接口/方法全部 grep 命中（零编造）
- [ ] 技术栈如实（非 Spring 栈有警示）、协作边界指向 `hero-java-*` 角色 agent
