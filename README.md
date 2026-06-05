# claude-hero

团队共享的 Claude Code 资产仓库：把可以共享的 **skills、subagents、MCP 配置、CLI 工具
清单、CLAUDE.md/hooks/settings 实践** 沉淀在一处，团队成员 `git clone` 后一键接入各自的
`~/.claude`，统一团队的 Claude Code 使用习惯。

## 快速开始

```bash
git clone <repo-url> claude-hero
cd claude-hero
bash install.sh        # 软链 skills/agents/hooks 到 ~/.claude
```

安装结束后，脚本会提示哪些**模板文件**（`CLAUDE.md` / `settings.json` / `.mcp.json`）需要你
手动合并——因为它们含密钥或高度个人化，不会被自动覆盖。

保持更新：

```bash
git pull        # skills/agents 是软链，pull 后自动生效，无需重装
```

卸载（只移除指向本仓库的软链，不动你的个人文件与备份）：

```bash
bash uninstall.sh
```

## 目录结构

| 目录 | 内容 | 安装方式 |
|------|------|----------|
| `skills/` | 共享自定义 skill（每个一个目录，含 `SKILL.md`） | 子项逐个软链到 `~/.claude/skills/` |
| `agents/` | 共享 subagent 定义（`*.md`） | 子项逐个软链到 `~/.claude/agents/` |
| `config/hooks/` | 可共享的 hook 脚本 | 软链到 `~/.claude/hooks/` |
| `config/*.example` | `CLAUDE.md` / `settings.json` 模板 | 模板，提示手动合并 |
| `mcp/` | MCP server 配置模板（密钥占位符）+ 说明 | 模板，提示手动合并 |
| `cli/` | CLI 工具清单与用法笔记（JDK 多版本 / Maven / Gradle / DB） | 纯文档 |
| `docs/` | 最佳实践、onboarding、[必装插件清单](./docs/plugins.md) | 纯文档 |
| `manifest.yaml` | 资源映射清单（install/uninstall 都读它） | — |

## 安装机制

`install.sh` 读取 [`manifest.yaml`](./manifest.yaml)，对每条目按 `mode` 处理：

- **link**：软链。目录类型按"子项逐个软链"，不整目录覆盖，避免动到你自有的其它
  skill/agent。目标已存在且非本仓库软链时，先备份为 `*.bak.<时间戳>` 再建链。幂等。
- **template**：不自动写入，仅在结尾汇总提示需手动合并的文件（含密钥/高度个人化）。

演练（不碰真实 `~/.claude`）：

```bash
CLAUDE_HOME=/tmp/claude-hero-test bash install.sh
```

## 贡献

见 [CONTRIBUTING.md](./CONTRIBUTING.md)。**切勿提交真实密钥**——MCP/settings 一律用占位符。
