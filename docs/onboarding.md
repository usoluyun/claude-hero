# 新成员 Onboarding

从零到可用，大约 10 分钟。

## 欢迎来到英雄殿

你加入的不只是一个代码仓库，是一个**团队共同建造的 Hero 殿堂**。这里已经有 9 个 Hero 等你差遣——孔明帮你做技术方案、文远帮你写代码、子长帮你写 SQL、希仁帮你写测试……你越用他们，他们越懂你。

用得顺手了，你也可以给他们提改进建议，甚至造一个你自己的 Hero。

---

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

- 在 Claude Code 里查看 skill 列表，应能看到团队共享的 skill（`hero-conventions`、
  `hero-prd-to-java` 等）。
- 改一下仓库里某个 `SKILL.md`，无需重装即生效（软链）。

## 5. 下一步

- 扫一遍 [`../README.md`](../README.md) 了解全貌
- 看看 [`hero-agent-layers.md`](../docs/hero-agent-layers.md) 认识所有 Hero
- 想想你日常最烦的事，造一个你的 Hero（[维护手册](maintenance.md)有教程）
- 想贡献？看 [`../CONTRIBUTING.md`](../CONTRIBUTING.md)
