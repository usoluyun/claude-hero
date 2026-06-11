# CLAUDE.md — claude-hero 项目导航

> 本文是**仓库内工作时的文档索引**，帮你快速定位「该看哪份文件、该改哪里」。
> 注意：这里的 `CLAUDE.md` 是 **claude-hero 仓库自身**的项目说明；面向团队成员 `~/.claude` 的
> 团队基线模板是另一份 [`config/CLAUDE.md.example`](./config/CLAUDE.md.example)，别混淆。

## 这个仓库是什么

团队共享的 **Claude Code 资产仓库**：把可共享的 skills / subagents / hooks / MCP 配置 / CLI 清单 /
CLAUDE.md 实践沉淀在一处，成员 `git clone` 后 `bash install.sh` 软链进各自 `~/.claude`，统一团队
Claude Code 使用习惯。**安装靠软链**，`git pull` 即全员生效，无需重装。

入口文档：[`README.md`](./README.md)（快速开始/目录结构/安装机制）、[`docs/onboarding.md`](./docs/onboarding.md)（新成员 10 分钟接入）。

## 三大核心子系统

| 子系统 | 触发 | 干什么 | 权威文档 |
|---|---|---|---|
| **意图分诊（hero-dispatch）** | `hero <自由意图>` | 听一句开发意图 → 归类到 8 条 lane → 补输入 → 确认 → 交接对应 workflow。轻量线走 `lanes/*.md` playbook（mutate/readonly/two-phase 门控 + TDD-first），重型线委派现有 skill | [`skills/hero-dispatch/SKILL.md`](./skills/hero-dispatch/SKILL.md)；设计 [`docs/superpowers/specs/2026-06-06-hero-dispatch-design.md`](./docs/superpowers/specs/2026-06-06-hero-dispatch-design.md) |
| **PRD 驱动开发** | `hero 开发工作流 <飞书URL>` | 飞书 PRD → 设计 → Sprint 计划 → 多服务并行开发 → 测试 → 审查 → 合并，全程确认门控 + worktree 隔离 | [`skills/hero-prd-to-java/SKILL.md`](./skills/hero-prd-to-java/SKILL.md)（+ `workflow-reference.md`） |
| **资产保鲜（hero-refresh）** | `hero 刷新` / `刷新 <proj>` / `刷新 评审` / `刷新 状态` | 把 codegraph 索引 + 领航 agent + vendor docs 三件套一起保鲜。**两段式**：确定性层脚本自动跑，领航 agent 漂移走人工评审 gate | [`skills/hero-refresh/SKILL.md`](./skills/hero-refresh/SKILL.md)；设计 [`docs/superpowers/specs/2026-06-06-hero-refresh-design.md`](./docs/superpowers/specs/2026-06-06-hero-refresh-design.md) |

## 文档索引（docs/）

| 文件 | 讲什么 | 何时看 |
|---|---|---|
| [`onboarding.md`](./docs/onboarding.md) | 新成员从零接入流程 | 第一次用本仓库 |
| [`best-practices.md`](./docs/best-practices.md) | 团队最佳实践：Skill 触发 / CLAUDE.md / 安全 / Java 团队实践（多 JDK、MyBatis、事务、幂等、测试栈） | 写代码/约定前 |
| [`plugins.md`](./docs/plugins.md) | 必装插件清单（jdtls-lsp / context7 / superpowers / karpathy）+ TDD/BDD 说明 | 配环境 |
| [`codegraph-agent-plan.md`](./docs/codegraph-agent-plan.md) | **方案**：为 ~40 个 Java 服务批量生成「项目领航 agent」的整体设计、agent 解剖、模板 | 理解领航 agent 体系 |
| [`project-agent-cookbook.md`](./docs/project-agent-cookbook.md) | **实操手册**：怎么从一个 Java 服务生成领航 agent（六步流程、命令、踩坑） | **开荒**：建索引+首次生成 agent |
| [`hero-agent-roster.md`](./docs/hero-agent-roster.md) | 领航 agent **花名册**（确定性查找表）：proj / 中文名 / 触发关键词 / 栈类型 / 路径 | 路由/查表/登记新 agent |
| [`hero-agent-layers.md`](./docs/hero-agent-layers.md) | agent 分层总图 + 能力矩阵（双轴 + 角色三梯 + 漫威代号，skills/CLI 施工底图） | 看全景分层 / 加新 agent / 查 skill 用在哪 |
| `.refresh-state.json` | 已接入项目的刷新记账（`last_commit`/`last_refreshed`），团队共享 | hero-refresh 读写 |
| `.workflow-registry.json` | PRD 工作流注册表（在飞 / 已合并） | hero-prd-to-java 读写 |
| `vendor-docs/*.md` | context7 抓的库文档缓存（进 git，agent 本地读） | — |
| `.refresh-work/`、`.refresh-drafts/` | 临时 evidence pack / 待评审草稿（**gitignore**，勿提交） | hero-refresh 中间产物 |

## 资产目录速查

- **`agents/`** — 共享 subagent（`hero-java-*.md`），按**双轴分层**组织：角色 agent（规划/执行/
  评审门控三梯，横向干活）× 项目领航 agent（按服务只读带路）。完整分层 + 漫威代号 + 能力矩阵见
  [`docs/hero-agent-layers.md`](./docs/hero-agent-layers.md)。
- **`skills/`** — `hero-dispatch`（意图分诊入口）、`hero-conventions`（团队通用约定）、`hero-prd-to-java`（PRD 工作流）、`hero-refresh`（资产保鲜）、`hero-site-deploy`（本机项目主页部署：据 README 建宣传页 + 一个 Caddy:10086 统一对外 + 开机自启）。
- **`scripts/`** — `hero-refresh.sh` 确定性层入口 + `lib/refresh-*.sh`（common/state/evidence/vendor）。
- **`config/`** — `hooks/`（含 `hero-refresh-check.sh` 的 SessionStart 漂移提醒）、`CLAUDE.md.example`、`settings.json.example`。
- **`cli/`** — CLI 工具清单与用法（[`README.md`](./cli/README.md) 总表、`jdk-multiversion.md` / `maven.md` / `gradle.md`）。
- **`mcp/`** — MCP server 配置模板（密钥占位符）+ 说明。
- **`manifest.yaml`** — 资源映射清单，`install.sh` / `uninstall.sh` 都读它。

## 在本仓库工作的约定（改这里前必读）

- **命名**：agent `hero-<lang>-<...>`（带语言）；skill `hero-<能力>`（不带语言）；全小写 kebab-case，
  文件名 = frontmatter `name`。详见 [`CONTRIBUTING.md`](./CONTRIBUTING.md)。
- **安全红线**：**绝不提交真实密钥 / token / 内网敏感信息**，一律用 `*.example` + 占位符。
- **改 install/uninstall 后**：用 `CLAUDE_HOME=/tmp/xxx bash install.sh` 演练再提交，别碰真实 `~/.claude`。
- **bash 3.2 兼容**（macOS 自带）：`scripts/` 与 `config/hooks/` 的脚本避免 bash 4+ 特性
  （无关联数组 `declare -A`、无 `${var^^}`），注意 `set -u`/`set -e` 与空数组/子 shell 的坑。
- **新增资源**：新 skill/agent/hook/MCP/CLI 的落位规则见 `CONTRIBUTING.md`；需安装到 `~/.claude` 的
  新类别才改 `manifest.yaml`。

## 开荒 vs 保鲜（领航 agent 的两条路）

- **开荒**（新服务从无到有）：走 [`project-agent-cookbook.md`](./docs/project-agent-cookbook.md) —— 首次
  `codegraph init` + 首次生成领航 agent + 登记花名册。
- **保鲜**（已接入项目随代码漂移刷新）：走 `hero-refresh` —— 新 agent 生成并登记后，加进
  `docs/.refresh-state.json` 的 `projects` 即纳入保鲜。
