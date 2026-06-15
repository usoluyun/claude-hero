---
title: claude-hero
tagline: 团队共享的 Claude Code 资产仓库，一次 clone 全员生效
status: shipped
tags: [ai, llm, cli]
serviceUrl: http://127.0.0.1:10086/
---

把团队可共享的 Claude Code 资产——skills / subagents / hooks / MCP 配置 / CLI 清单 / CLAUDE.md 实践——沉淀在一处。成员 `git clone` 后跑一次 `install.sh`，逐项**软链**进各自 `~/.claude`，统一团队的 Claude Code 使用习惯。靠软链而非拷贝，`git pull` 即全员生效，无需重装。

三大核心子系统：**意图分诊**（`hero <自由意图>` 一句话归类到 8 条 lane 再交接）、**PRD 驱动开发**（飞书 PRD → 设计 → 多服务并行开发 → 测试 → 审查 → 合并，全程确认门控 + worktree 隔离）、**资产保鲜**（codegraph 索引 + 领航 agent + vendor docs 三件套两段式刷新）。

Hero 是有名字、有职责的 AI agent，花名取自 AI 时代的先驱（Demis Hassabis / Jeff Dean / Fei-Fei Li…）。分两类：角色型横向干活、跨服务通用；领航型按服务只读带路。理念是「了解英雄、学习英雄、成为英雄」——了解现有 agent 能力、学怎么写并配置 agent、最后创建并提交属于自己的 agent。

宣传站由 Caddy 静态托管，本机 `:10086` 统一对外、开机自启。当前在团队内活跃使用与迭代中。
