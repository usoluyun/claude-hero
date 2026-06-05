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
