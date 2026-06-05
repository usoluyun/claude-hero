# 新成员 Onboarding

从零到可用，大约 10 分钟。

## 1. 前置

- 已安装 Claude Code
- macOS（脚本基于 bash，已在 zsh/bash 下验证）
- 已安装常用 CLI（见 [`../cli/README.md`](../cli/README.md)）

## 2. 接入仓库

```bash
git clone <repo-url> ~/Documents/ops/claude-hero
cd ~/Documents/ops/claude-hero
bash install.sh
```

此时 `~/.claude/skills/`、`~/.claude/agents/`、`~/.claude/hooks/` 已软链到本仓库。

## 3. 合并个人化模板

安装脚本会列出待合并项：

- `CLAUDE.md`：参考 [`../config/CLAUDE.md.example`](../config/CLAUDE.md.example)，把团队基线段落
  合并进你的 `~/.claude/CLAUDE.md`，再补你自己的私有段落。
- `settings.json`：参考 `../config/settings.json.example`。
- `.mcp.json`：按 [`../mcp/README.md`](../mcp/README.md) 选需要的 server 合并，换上自己的密钥。

## 4. 验证

- 在 Claude Code 里查看 skill 列表，应能看到团队共享的 skill（如 `team-conventions`）。
- 改一下仓库里某个 `SKILL.md`，无需重装即生效（软链）。

## 5. 日常

- `git pull` 获取团队更新，skills/agents 自动生效。
- 想贡献？看 [`../CONTRIBUTING.md`](../CONTRIBUTING.md)。
