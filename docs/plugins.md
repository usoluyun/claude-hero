# 必装插件清单

团队统一安装的 Claude Code 插件。只列 **Java 相关 + 通用提效**插件（前端/Python/设计类不在此列）。
成员自行安装，**本仓库不写自动脚本、不动 settings 模板**。

## 安装方式

在 Claude Code 里用 `/plugin`（marketplace 浏览安装），或：

```bash
claude plugin install <name>@<marketplace>
```

下表插件均来自官方 marketplace `claude-plugins-official`，karpathy 来自 `karpathy-skills`。
若未添加对应 marketplace，先 `/plugin marketplace add ...`。

## 必装

| 插件 | 用途 |
|------|------|
| `jdtls-lsp` | Java LSP（Eclipse JDT.LS）：代码导航/补全/诊断，Java 团队核心 |
| `context7` | 拉取最新库/框架文档（Spring Boot / MyBatis / RocketMQ / JetCache 等），减少臆测，提升准确性 |
| `superpowers` | 规范开发流程框架：内置 **TDD**（test-driven-development）、brainstorming、systematic-debugging、subagent 驱动开发 |
| `andrej-karpathy-skills` | 减少 LLM 编码错误的行为规范：外科手术式改动、暴露假设、可验证目标 |

## 提效（推荐）

| 插件 | 用途 |
|------|------|
| `claude-md-management` | 审计/维护 CLAUDE.md 质量，沉淀会话经验 |
| `remember` | 跨会话持续记忆，减少重复交代、提升上下文一致性 |
| `code-review` | 多专家 agent 自动审查 PR（正确性/测试/错误处理），配合团队审查流程 |

> `context7` 装上后自带其 MCP server，无需再手动配 `mcp/servers/context7.json`（那份模板是给
> 不用插件、手动配 MCP 的场景兜底）。

## TDD / BDD 说明

官方 marketplace **没有**独立的 TDD / BDD 插件，已查证。团队采用：

- **TDD**：由必装的 `superpowers` 覆盖（内置 `test-driven-development` skill，RED-GREEN-REFACTOR）。
  Java 测试栈约定 JUnit 5 + Mockito + AssertJ（见 `docs/best-practices.md`）。
- **BDD**：用 standalone 的 `gherkin` skill（非 marketplace 插件，单独安装），写 `.feature`
  并配合 Java 侧 Cucumber-JVM。

## standalone skills（非 marketplace 插件）

部分能力以独立 skill 形式安装（`npx skills` 体系），与插件并存：

| skill | 用途 | 安装 |
|-------|------|------|
| `gherkin` | 写 Gherkin `.feature`（BDD），支持 Cucumber-JVM / pytest-bdd / SpecFlow | `npx skills add gherkin`（以本机实际命令为准） |

> 安装命令以团队实际使用的 skills 管理工具为准；如不确定，先 `npx skills --help` 或问团队。
