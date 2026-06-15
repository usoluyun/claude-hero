# CLI 工具清单（Java 团队）

团队在 Java 开发与 Claude Code 工作流中常用的命令行工具。新增工具加一行总表，用法复杂的
补一个 `<tool>.md`。

| 工具 | 用途 | 安装 | 团队约定 / 详情 |
|------|------|------|----------------|
| **JDK 切换** | 1.8/11/17 手动 `JAVA_HOME` 管理 | 见详情 | **重点**，见 `jdk-multiversion.md` |
| **mvn** | Maven 构建 | `brew install maven` 或私服 wrapper | 走私服，见 `maven.md` |
| **gradle** | Gradle 构建 | 用项目 `./gradlew` | wrapper 优先，见 `gradle.md` |
| **codegraph** | 代码图谱：符号查找 / 结构 / 调用方 / 影响面 | 见详情 | 领航 agent 与 tech-lead 定位必用，见 `codegraph.md` |
| **httpie** | 接口冒烟探测（`http` 命令打 localhost） | `brew install httpie` | test-engineer 接口冒烟，见 `httpie.md` |
| **allure** | 测试报告生成/查看 | `brew install allure` | test-engineer 报告，见 `allure.md` |
| **osv-scanner** | SCA：依赖 CVE 自动化扫描（🟡 组件） | 见 `sca.md` | Google OSV 在线查，单二进制，见 `sca.md` |
| **scc** | 代码统计 + 复杂度热点 + COCOMO 估人天 | 见 `scc.md` | 摸项目全貌/找热点文件，见 `scc.md` |
| **ast-grep** | 结构化代码搜索/改写（`sg`），AST 级比 grep 精准 | `pip3 install ast-grep-cli` | 开发时找模式/批量重构，见 `ast-grep.md` |
| **PMD** | 静态代码分析：死代码/空 catch/复杂度 | 见 `pmd.md` | Chris Olah审代码前批量扫问题，见 `pmd.md` |
| **SpotBugs** | 字节码级 Bug 检测：NPE/线程安全/资源泄漏 | 见 `spotbugs.md` | Chris Olah深层语义分析，和 PMD 互补，见 `spotbugs.md` |
| **SlowQL** | SQL 静态分析器：安全/性能/合规，支持 MyBatis mapper | 见 `slowql.md` | Fei-Fei Li写 Mapper 后查注入/全表扫描，见 `slowql.md` |
| **pg_glimpse** | PostgreSQL 实时 TUI 监控（锁/查询/缓存） | 见 `pg-glimpse.md` | Fei-Fei Li DBA 排障，看锁/死元组/复制延迟，见 `pg-glimpse.md` |
| **jq** | JSON 命令行处理器，API 响应提取/格式化 | `brew install jq` | 接口自测日常必备，见 `jq.md` |
| semgrep | SAST：注入/越权/危险模式扫描（🔴 设计安全） | `brew install semgrep` | Jan Leike代码时验门槛主力，见 `semgrep.md` |
| **gitleaks** | 密钥/凭据硬编码扫描（🔴 敏感数据） | `brew install gitleaks` | 命中即 🔴 强制门槛，见 `gitleaks.md` |
| **codeql** | 深度污点分析（🔴 可选重档） | 见详情 | 越权/注入污点佐证，见 `codeql.md` |
| mycli | 查询 **MySQL**（补全/高亮） | `brew install mycli` | 查 MySQL 一律用它，人工执行 |
| sqlcmd / mssql-cli | 查询 **SQLServer** | `brew install sqlcmd`（go-sqlcmd）或 `pip install mssql-cli` | 查 SQLServer 用它，人工执行 |
| redis-cli | JetCache 后端 Redis 排障 | `brew install redis` | 仅排障，缓存读写走 JetCache |
| mqadmin | RocketMQ 运维（topic/消费进度/死信） | 随 RocketMQ 发行包 | 配合控制台，详见 best-practices.md |
| podman | 容器构建/运行，连私有仓库 | `brew install podman` | 私服 `zot.chester.monster` |
| **glab** | GitLab CLI：MR、流水线、Issue、Release 管理 | `brew install glab` 或自动安装 | 团队协作必备，`install.sh` 自动装，详见 `glab.md` |
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
