# 贡献指南

## 命名规范（统一 `hero` 前缀）

仓库内所有 agent / skill 一律以 `hero` 开头，便于在 `~/.claude` 里和个人/其它来源的资源区分。

- **Agent：`hero-<语言>-<...>`**（带语言）
  | 类型 | 规则 | 例子 |
  |------|------|------|
  | 角色 agent | `hero-<lang>-<role>` | `hero-java-backend-developer`、`hero-java-tech-lead`、`hero-java-data-engineer` |
  | 项目领航 agent | `hero-<lang>-<project>` | `hero-java-ecrm`、`hero-java-crm` |
  | 大项目按业务域拆 | `hero-<lang>-<project>-<domain>` | `hero-java-pms-api-folio` |
- **Skill：`hero-<能力>`**（**不带语言**，skill 是跨语言/跨项目能力）
  - 工作流/转换类 → `hero-<源>-to-<目标>` 或 `hero-<动词>-<对象>`：`hero-prd-to-java`、`hero-codegraph-agents`
  - 知识/规范类 → `hero-<主题>`：`hero-conventions`

全部小写 kebab-case。文件/目录名与 frontmatter 的 `name` 必须一致。

## 新增一个共享 skill

1. 在 `skills/hero-<能力>/` 下放 `SKILL.md`，frontmatter 必须含 `name`（= 目录名）与 `description`
   （description 决定触发时机，写清楚"何时使用"）。
2. 需要的辅助资源放同目录下（脚本、模板、references）。
3. 提交 PR。安装方 `install.sh` 后软链到 `~/.claude/skills/hero-<能力>`。

## 新增一个共享 agent

在 `agents/` 放 `hero-<语言>-<...>.md`（含 `name`/`description` frontmatter，`name` = 文件名去掉 `.md`）。

## 新增一个 hook

脚本放 `config/hooks/`，在 `config/settings.json.example` 里用
`~/.claude/hooks/<name>.sh` 引用，并在该模板里说明触发时机。

## 新增 MCP server

在 `mcp/servers/<name>.json` 放配置片段，**密钥用占位符**（如 `${XXX_API_KEY}`），
并在 `mcp/README.md` 总表补一行。

## 新增 CLI 工具

在 `cli/README.md` 总表加一行；用法复杂的补一个 `cli/<tool>.md`。

## manifest.yaml

新增需要"安装到 `~/.claude`"的资源类别时，才需要改 `manifest.yaml`。字段：

- `source`：仓库内相对路径
- `target`：相对 `~/.claude` 的路径
- `mode`：`link`（软链，目录则子项逐个链） / `copy`（一次性复制） / `template`（仅提示手动合并）

## 红线

- **绝不提交真实密钥 / token / 内网敏感信息**。本地真实配置已被 `.gitignore` 忽略。
- 个人化内容（你的花名、私有偏好）不要写进共享模板。
- 改动 install/uninstall 后，务必用 `CLAUDE_HOME=/tmp/xxx` 演练验证再提交。
