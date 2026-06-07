# CLI 工具清单（Java 团队）

团队在 Java 开发与 Claude Code 工作流中常用的命令行工具。新增工具加一行总表，用法复杂的
补一个 `<tool>.md`。

| 工具 | 用途 | 安装 | 团队约定 / 详情 |
|------|------|------|----------------|
| **JDK 切换** | 1.8/11/17 手动 `JAVA_HOME` 管理 | 见详情 | **重点**，见 `jdk-multiversion.md` |
| **mvn** | Maven 构建 | `brew install maven` 或私服 wrapper | 走私服，见 `maven.md` |
| **gradle** | Gradle 构建 | 用项目 `./gradlew` | wrapper 优先，见 `gradle.md` |
| **codegraph** | 代码图谱：符号查找 / 结构 / 调用方 / 影响面 | 见详情 | 领航 agent 与 tech-lead 定位必用，见 `codegraph.md` |
| mycli | 查询 **MySQL**（补全/高亮） | `brew install mycli` | 查 MySQL 一律用它，人工执行 |
| sqlcmd / mssql-cli | 查询 **SQLServer** | `brew install sqlcmd`（go-sqlcmd）或 `pip install mssql-cli` | 查 SQLServer 用它，人工执行 |
| redis-cli | JetCache 后端 Redis 排障 | `brew install redis` | 仅排障，缓存读写走 JetCache |
| mqadmin | RocketMQ 运维（topic/消费进度/死信） | 随 RocketMQ 发行包 | 配合控制台，详见 best-practices.md |
| podman | 容器构建/运行，连私有仓库 | `brew install podman` | 私服 `zot.chester.monster` |
| jq | JSON 处理（hero-refresh 状态读写依赖） | `brew install jq` | 脚本依赖，见 scripts/lib/ |

## 数据库访问约定

- MySQL → `mycli`，SQLServer → `sqlcmd`/`mssql-cli`。
- **查库一律用 CLI、人工执行**，不给 Claude 配数据库 MCP 直连（安全）。

## 中间件辅助

- RocketMQ：`mqadmin` 看 topic / 消费堆积 / 死信队列（`%DLQ%`）；优先用控制台。
- Redis（JetCache 后端）：`redis-cli` 仅用于排障查 key，业务读写走 JetCache。
- SkyWalking：UI 看链路（地址放团队内部文档/Apollo），详见 best-practices.md。

## 代理约定

命令行走 `127.0.0.1:7890`；遇到企业内网域名（yaduo.com、at-our.com）加入 `NO_PROXY`。
私服多在内网，通常无需外网代理（见 `maven.md`）。
