# claude-hero

团队共享的 Claude Code 资产仓库：把可以共享的 **skills、subagents、MCP 配置、CLI 工具
清单、CLAUDE.md/hooks/settings 实践** 沉淀在一处，团队成员 `git clone` 后一键接入各自的
`~/.claude`，统一团队的 Claude Code 使用习惯。

## 快速开始

### 安装

```bash
git clone <repo-url> claude-hero
cd claude-hero
bash install.sh        # 软链 skills/agents/hooks 到 ~/.claude
```

安装结束后，脚本会提示哪些**模板文件**（`CLAUDE.md` / `settings.json` / `.mcp.json`）需要你
手动合并——因为它们含密钥或高度个人化，不会被自动覆盖。

### 一句话入口（hero 意图分诊）

不想记具体工作流？直接说意图，分诊器帮你选线：

```bash
hero 修一下登录报错          # → bugfix 线
hero 这个接口太慢            # → perf 线（先诊断后优化）
hero 评估下加 X 影响多大      # → research 调研线（只读）
hero 开发工作流 https://...   # → PRD 重型线（仍可直达）
```

分诊器把意图归类到 8 条 lane（prd / refresh / bugfix / iterate / refactor / research /
perf / security），补齐输入、确认后交接给对应 workflow。详见 `skills/hero-dispatch/SKILL.md`。

### 启动 PRD 驱动开发流程

```bash
# 触发 Java PRD 开发工作流（读取飞书 PRD，自动生成设计 + 计划，分派 agent，并行开发，
# 全程确认门控，最后跨需求验证合并）
hero 开发工作流 https://feishu.cn/docx/xxxxxxxxxxxxx

# 或用 Slash 命令
/hero-prd-to-java https://feishu.cn/docx/xxxxxxxxxxxxx

# 查看所有在飞的 PRD 及进度
hero 工作流状态

# 触发已准备就绪的 PRD 跨需求验证合并
hero 合并验证
```

详见 `skills/hero-prd-to-java/SKILL.md`。

### 保鲜团队资产（hero 刷新）

```bash
hero 刷新            # 刷全部已接入项目（codegraph 索引 + 领航 agent + vendor docs）
hero 刷新 <proj>     # 只刷一个
hero 刷新 评审       # 逐个过领航 agent 漂移草稿（人工 gate）
hero 刷新 状态       # 看谁该刷了
```

确定性层（重索引/抓文档）自动跑，领航 agent 变更需人工评审。详见 `skills/hero-refresh/SKILL.md`。
开 Claude 时若某接入项目有新 commit，SessionStart hook 会提醒你刷新。

### 保持更新

```bash
git pull        # skills/agents 是软链，pull 后自动生效，无需重装
```

### 卸载

```bash
bash uninstall.sh      # 只移除指向本仓库的软链，不动你的个人文件与备份
```

## 目录结构

| 目录 | 内容 | 安装方式 |
|------|------|----------|
| `skills/` | 共享自定义 skill（hero-conventions 团队通用约定、hero-prd-to-java PRD 驱动工作流） | 子项逐个软链到 `~/.claude/skills/` |
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
