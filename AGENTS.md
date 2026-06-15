# AGENTS.md

共享 Claude Code 资产仓库（skills / subagents / hooks / MCP / CLI 文档），成员 `bash install.sh` 软链进 `~/.claude`。本文件补充 `CLAUDE.md`（已有完整导航），只记录容易踩坑的细节。

## 验证 / 测试命令

纯 bash 资产，无 package.json / Makefile / lint 管线。脚本跑前必跑对应测试，改核心子系统前后把相关 suite 都过一遍。

单 suite：`bash tests/<suite>/run.sh`（4 个 suite：`hero-dispatch` / `hero-refresh` / `hero-agent-layers` / `hero-visibility`）
安装回归：`bash scripts/test-install.sh`
agent 五段式章节校验：`bash scripts/validate-chapters.sh`（要求 agents/ 下 hero 必须含 `## Role` / `## Success Criteria` / `## Constraints` / `## Failure Modes` / `## Final Checklist`）
agent-registry 与真实 .md 对齐校验：`bash scripts/validate-agents-md-coverage.sh`
state file 迁移校验：`bash scripts/validate-state-migration.sh`

测试 runner 约定：每个子目录都有 `test_*.sh` + `assert.sh`（自定义 assert 函数库）+ `run.sh`（遍历 `test_*.sh`），任一失败整体非 0 退出。新 suite 必须沿此结构。

## 脚本约束（重要）

- **bash 3.2 兼容（macOS 自带）**：`scripts/` 与 `config/hooks/` 一律禁用 bash 4+ 特性
  - ❌ 关联数组 `declare -A`、`${var^^}` / `${var,,}`、`${var@Q}`、`read -d`、`mapfile` / `readarray`
  - ✅ 普通字符串数组、`tr` 大小写转换、显式字符串比较
- `set -euo pipefail` 标配。常见坑：`set -u` 下空数组 `"${arr[@]}"` 会报错，要先判空或用 `"${arr[@]+${arr[@]}}"`
- 子 shell `(...)` 里对父数组的修改不生效
- 改 `install.sh` / `uninstall.sh` 后用 `CLAUDE_HOME=/tmp/xxx bash install.sh` 演练，**不要直接跑在真实 `~/.claude`**

## 安装机制

`manifest.yaml` 是安装清单的事实源（`install.sh` / `uninstall.sh` / `test-install.sh` 都读）。三类 mode：
- `link`：子项逐个软链，目录不会整目录链（避免覆盖成员自有 skill/agent）
- `copy`：一次性复制
- `template`：不自动安装，仅打印需手动合并（`CLAUDE.md` / `settings.json` / `.mcp.json` 的 example）

新增资源类别（需装到 `~/.claude`）才改 `manifest.yaml`。新增 skill/agent/hook 只要放进已有目录就自动被 link mode 覆盖。

## 命名规则（强约束）

- **Agent 必须带语言前缀**：`hero-<lang>-<role|project>[-<domain>]`，如 `hero-java-backend-developer` / `hero-java-ecrm` / `hero-java-pms-api-folio`
- **Skill 不带语言前缀**：`hero-<能力>`（跨语言能力）。工作流 `hero-<源>-to-<目标>` 或 `hero-<动词>-<对象>`（`hero-prd-to-java` / `hero-codegraph-agents`）；知识 `hero-<主题>`（`hero-conventions`）
- 全小写 kebab-case，目录名 / 文件名必须等于 frontmatter 的 `name` 字段

## 关键入口

- `install.sh` / `uninstall.sh`：安装 / 卸载（`manifest.yaml` 驱动）
- `scripts/hero-init.sh <项目路径> [花名]`：为 Java 服务开荒领航 agent（花名可选，自动分配；自动建 codegraph 索引 + 生成 agent + 开 Git 分支）
- `scripts/hero-refresh.sh`：保鲜入口（`hero 刷新` / `刷新 <proj>` / `刷新 评审` / `刷新 状态`）
- `scripts/hero-issue-poller.sh`：GitLab Issue 集成
- `.claude/settings.json`：SessionStart hook 触发 `config/hooks/hero-refresh-check.sh`（漂移提醒）

## 易混淆文件

- 仓库自身导航 `CLAUDE.md` ≠ 团队基线模板 `config/CLAUDE.md.example`（前者描述本仓库，后者是成员合并进自己 `~/.claude/CLAUDE.md` 的起点）
- `agents/AGENTS.md` 是 agent 花名册 registry（frontmatter YAML + roster 表）
- `docs/.refresh-state.json`、`docs/.refresh-work/`、`docs/.refresh-drafts/` 是 `hero-refresh` 的中间产物（后两个已 gitignore，勿提交）
- `site/public/css/*.css` 的引用必须带 `?v=YYYYMMDD<letter>` 缓存打散（如 `tokens.css?v=20260614b`）。改任何 CSS 后**必须递增**所有引用它的 HTML 里的版本号，否则中间层/浏览器缓存会让用户滞后 4 小时看到旧样式。Caddyfile 未配 cache-control，全靠 query string 破缓存。
- `site/` 是对外宣传页（Caddy 静态站，`site.json` 配 `static_root`），与核心资产无关

## 安全红线

绝不提交真实密钥 / token / 内网敏感信息。密钥一律用 `${XXX_API_KEY}` 占位符 + `*.example` 后缀（参考 `mcp/servers/*.json`、`config/settings.json.example`）。

## 完整上下文

- `CLAUDE.md`：仓库内工作时的权威导航（三大子系统 + 目录速查 + 维护约定）
- `CONTRIBUTING.md`：命名规范详情 + 新增 skill / agent / hook / MCP / CLI 的落位规则
- `docs/maintenance.md`：从用到改到造到养的 4 层级共创手册
- `docs/hero-agent-layers.md`：agent 分层总图 + 能力矩阵 + 漫威代号
