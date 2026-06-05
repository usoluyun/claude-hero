# 贡献指南

## 新增一个共享 skill

1. 在 `skills/<skill-name>/` 下放 `SKILL.md`，frontmatter 必须含 `name` 与 `description`
   （description 决定触发时机，写清楚"何时使用"）。
2. 需要的辅助资源放同目录下（脚本、模板、references）。
3. 提交 PR。安装方 `install.sh` 后软链到 `~/.claude/skills/<skill-name>`。

## 新增一个共享 agent

在 `agents/` 放 `<name>.md`（含 `name`/`description` frontmatter）。

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
