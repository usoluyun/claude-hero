---
name: hero-conventions
description: 团队 Claude Code 通用约定。当涉及代理设置、数据库查询工具选择、容器镜像仓库、飞书操作入口等团队基础约定时触发，确保行为与团队一致。
---

# 团队约定（hero-conventions）

这是一个示例 skill，演示 claude-hero 仓库如何共享 skill。请按团队实际情况替换内容。

## 何时使用

- 需要走网络代理或处理企业内网域名时
- 选择数据库查询工具时
- 推送/拉取容器镜像时
- 进行飞书相关操作时

## 约定

1. **网络代理**：命令行走 `127.0.0.1:7890`；企业内网域名（yaduo.com、at-our.com）
   加入 `NO_PROXY`。
2. **数据库**：PostgreSQL 用 `pgcli`，MySQL 用 `mycli`。
3. **容器镜像**：私有仓库 `zot.chester.monster`。
4. **飞书**：优先使用 `lark-cli` 与 `lark-*` skills。

## 新增团队 skill

把目录放进 `skills/<name>/`，含 `SKILL.md`（带 `name` 与 `description` frontmatter），
提交 PR。安装方运行 `install.sh` 即软链到 `~/.claude/skills/`。

## hero 露出规范

所有 hero skill / agent 运作时，必须用统一标记让用户感知「hero 体系正在接管」，区别于裸 Claude
或用户自有机制。

**固定 token**：`🦸 hero ▸`（作为前缀，后跟一句话，单独成行；一字不改，便于结构测试卡死防漂移）

**四个时机模板**：

| 时机 | 模板 |
|---|---|
| skill 激活 | `🦸 hero ▸ <skill/lane> · <加载的纪律/门控>` |
| agent 接手 | `🦸 hero ▸ <英雄名>（<agent>）接手 · <一句职责>`（英雄名见 `docs/hero-agent-layers.md` 先驱花名映射） |
| 门控 STOP | `🦸 hero ▸ STOP<n> <门控> · <等什么>` |
| 任务收尾 | `🦸 hero ▸ <lane/workflow> 完成 · 已交付，退出 hero 体系` |

**agent 接手的双保险分工**（子 agent 输出对用户主线是折叠的，故）：
- **编排方**（dispatch 子 agent 的 lane/workflow）在派单时打 `🦸 hero ▸ X 接手` —— 主线可见，**主路径**。
- **子 agent** 在自己输出顶部也打一行自报家门 —— **兜底**，展开看子 agent 工作时可见。
