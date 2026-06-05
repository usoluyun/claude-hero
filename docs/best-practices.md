# Claude Code 最佳实践（团队）

持续沉淀团队踩过的坑与好用的做法。欢迎随时补充。

## Skill 触发

- `description` 写清楚"何时使用 + 触发关键词"，触发准确率取决于它。
- 同类能力别重复造 skill，先搜现有的。

## CLAUDE.md

- 团队基线段落统一从 [`../config/CLAUDE.md.example`](../config/CLAUDE.md.example) 同步；个人段落
  自己维护，不要写回共享模板。
- 指令写"做什么"，约束写"怎么做"，避免长篇大论稀释关键约束。

## 安全

- 任何含密钥的文件只放 `*.example` 模板 + 占位符。真实文件靠 `.gitignore` 兜底。
- 不在共享内容里写内网地址的敏感细节。

## 安装/同步

- 优先软链而非复制：`git pull` 即全员更新。
- 改 install/uninstall 脚本后，用 `CLAUDE_HOME=/tmp/xxx` 演练再提交。

## Java 团队实践

- **多 JDK 兼容**：1.8/11/17 共存，写代码注意目标 JDK 的 API 可用性；构建用 Maven toolchains /
  Gradle toolchain 锁定版本（见 `cli/jdk-multiversion.md`），别只靠 shell `JAVA_HOME`。
- **配置分层**：公共配置进 Apollo `common.*` namespace，私有进 `application`；敏感配置进 Apollo
  并设权限，代码里只留 key。
- **中间件接入清单**：Apollo / Eureka / SkyWalking / RocketMQ / JetCache 一律先看对应 `skills/*`，
  统一命名与可靠性约定。
- **MyBatis 安全**：参数用 `#{}`，**禁止 `${}` 拼接用户输入**；动态表名/列名走白名单。
- **事务边界**：`@Transactional` 自调用失效、传播行为、避免大事务与事务内远程调用/发 MQ。
- **缓存/消息幂等**：JetCache 设 TTL + 防穿透击穿；RocketMQ 消费端用业务唯一键做幂等。
- **可观测**：日志带 SkyWalking TraceId，异常不吞、不打印敏感信息。
- **测试**：TDD 由 `superpowers` 驱动（RED-GREEN-REFACTOR），Java 测试栈 **JUnit 5 + Mockito +
  AssertJ**；BDD 用 `gherkin` skill 写 `.feature` + Cucumber-JVM。
- **agent 团队与工作流**：
  - 日常编码：调用对应 agent（backend-developer / data-engineer / test-engineer）
  - **PRD 驱动开发**：触发 `hero 开发工作流` skill，自动编排 8 步流程（PRD 摄入 → 设计 → 规划 →
    分派 → 并行开发 → 测试 → 审查 → 合并），全程有确认门控（STOP & CONFIRM）、多需求隔离
   （worktree）、跨需求验证合并。见 `skills/java-prd-workflow/SKILL.md`。

## 飞书

- 文档/表格/日历/IM 走 `lark-cli` + `lark-*` skills；新建飞书文档默认进 Obsidian `Raw`。
