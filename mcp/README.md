# MCP 服务配置

本目录收纳团队共享的 MCP server 配置**模板**。每个 server 一个文件放在
`servers/`，密钥用占位符（如 `${YOUR_API_KEY}`），**禁止提交真实密钥**。

## 使用方式

1. 看下表选择需要的 server，参考 `servers/<name>.json` 片段。
2. 把片段合并进你的 `~/.claude.json`（用户级）或项目根的 `.mcp.json`（项目级）。
3. 把占位符换成你自己的真实密钥/路径（本地文件，已被 .gitignore 忽略）。

> install.sh 以 `template` 模式处理 MCP，不会自动写入——避免覆盖你已有的配置或泄露密钥。

## 已收录的 server

| 名称 | 作用 | 作用域建议 | 所需 env / 前置 |
|------|------|-----------|----------------|
| context7 | 拉取最新库/框架文档 | 用户级 | **优先用插件方式**（见下） |
| <name> | <作用> | 用户级/项目级 | <env> |

> **context7 优先用插件方式**：团队必装的 `context7` 插件（见 `docs/plugins.md`）已自带其 MCP
> server，装了插件就有，无需再手动配下面的模板。`servers/context7.json` 仅作为「不装插件、
> 手动配 MCP」场景的兜底。

## server 配置片段格式

每个 `servers/<name>.json` 形如：

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@context7/mcp"],
      "env": { "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}" }
    }
  }
}
```
