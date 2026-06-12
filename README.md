<div align="center">

<img src="https://img.shields.io/badge/status-active-brightgreen" alt="Status">
<img src="https://img.shields.io/badge/coverage-团队共创-blueviolet" alt="Team">
<img src="https://img.shields.io/badge/license-MIT-blue" alt="License">

# 🦸 claude-hero · 英雄殿

**把繁重的工作交给 Hero，把时间留给创造力和温度。**

</div>

---

## 这是谁的仓库

**每一个人的。**

这不是架构师画完图丢给团队执行的项目。这是一个**团队共同建造的英雄殿堂**——每个人都可以创造属于自己的 Hero，也可以改进别人的 Hero，把你每天的繁琐工作交给 Hero，把你最熟悉的工作流沉淀成 Skill，然后看着整个团队一起变强。

### Hero 是什么？

Hero 是一个 AI agent——有名字、有花名、有明确的职责边界。它不只是个 prompt 文件，它配有工具、技能（skill）、CLI 工具集，像团队里一个靠谱的队友。

比如已有 9 个共享 Hero：

| 花名 | 本名 | 负责什么 |
|------|------|---------|
| **孔明** | hero-java-tech-lead | 技术负责人、拆任务、画架构 |
| **文远** | hero-java-backend-developer | 写 Controller/Service，接入中间件 |
| **子长** | hero-java-data-engineer | MyBatis SQL + DBA |
| **希仁** | hero-java-test-engineer | TDD/BDD/冒烟/端到端测试 |
| **玄成** | hero-java-code-reviewer | 代码审查（只读） |
| **鹏举** | hero-java-security-auditor | 安全设计审计（只读） |
| **子文** | hero-java-ecrm | 企业连锁审批领航 |
| **郑和** | hero-java-hotel-product-center | 酒店产品中心领航 |
| **霞客** | hero-java-owner-biz | 业主服务端领航 |

> **花名取自中国历史英雄的字号。** 花名是团队的共同语言，也是文化的印记。你也可以给你创造的 Hero 取花名，就像公司里的伙伴都有自己的花名一样。

---

## 快速开始

```bash
# 10 分钟接入
git clone <repo-url> claude-hero && cd claude-hero && bash install.sh

# 然后直接用意图叫 Hero
hero 修一下登录报错          # → 自动分诊到 bugfix 线
hero 这个接口太慢            # → perf 线——先诊断后优化
hero 开发工作流 https://...   # → PRD 驱动全流程开发
hero 刷新                    # → 让所有 Hero 的知识保鲜
```

接入后你可以：

- **用现有的 Hero**——文远帮你写代码，鹏举帮你查安全，希仁帮你写测试
- **用 Agent Teams 组队**——孔明出设计 + 文远写代码 + 希仁补测试，三位并行推进，自动分屏协作（tmux 已自动安装）
- **改进现有的 Hero**——文远的 prompt 可以更好？提 PR，大家一起变强
- **创造你自己的 Hero**——你最懂你日常做什么。造一个，命个花名，解放自己
- **沉淀团队的 Skill**——团队特有的工作流、规范，写成 Skill 共享出来

---

## 核心子系统

### 🎯 意图分诊（hero-dispatch）

说一句意图 → 自动归类到 8 条 lane（bugfix/perf/refactor/research/security/prd/refresh/iterate）→ 补齐输入 → 确认 → 交接给对应 Hero 或 workflow。不记命令，自然语言直达。

### 📋 PRD 驱动开发（hero-prd-to-java）

给一个飞书 PRD 链接 → 自动读取 → 孔明出设计文档 + Sprint 计划 → 多 Hero 并行开发 → 玄成和鹏举把关 → 合并。全程确认门控 + worktree 隔离。

### 🔄 资产保鲜（hero-refresh）

项目代码在变，Hero 的知识不能过时。定期扫描代码变化 → 刷新领航 Hero 的认知 → 有人工 gate 确认才生效。

### 🌱 主动开荒（hero-init）

一个新 Java 服务从无到有接入：`bash scripts/hero-init.sh <项目路径> <花名>` → 自动建 codegraph 索引 + 生成领航 Hero + 登记花名册 + 开好 Git 分支，剩下提 MR 即可。

### 🏯 英雄殿看板（hero-tavern）

仙剑客栈风格的像素监控看板，实时展示 hero（Claude Code）和 omo（OpenCode）的 agent 状态：活跃 / 空闲 / 休眠 / 异常，消息流 + 阻塞检测。详见 [`hero-tavern/README.md`](hero-tavern/README.md)。

### 🤝 Agent Teams（团队协作）

多位 Hero 组队协作——孔明明出设计、文远写代码、希仁补测试，三位同时在各自 pane 里并行推进，互相通信，合力完成复杂任务。`install.sh` 已自动检测并安装 `tmux`（分屏模式依赖），无需手动配置。

```bash
# 进入 tmux 会话
tmux new -s work
claude

# 对 Claude 说：
# "Spawn a team of 3 agents: 孔明（opus）做设计，文远（sonnet）写代码，希仁（haiku）写测试"
```

---

### 🎫 GitLab Issue 集成

让 AI 英雄直接通过 GitLab Issues 认领任务、汇报进度：

| 操作 | 命令 | 作用 |
|------|------|------|
| 拉取待办 | `issue pull` | 列出所有 `hero::status:pending` Issue |
| 认领任务 | `issue claim #123` | 改标签为 in_progress，开始工作 |
| 完成汇报 | `issue done #123 "完成说明"` | 评论 + 关 Issue + 关联 MR |
| 拆解需求 | `issue decompose #1` | tech-lead 把主 Issue 拆为子任务 |
| 查看分配 | `issue list tech-lead` | 看某 agent 的待办 Issue |

#### 工作流闭环

```
1. 人在 GitLab 建主 Issue（标签: hero::type:epic）
   ↓
2. tech-lead (孔明) 自动拆解子 Issue（分配给各角色 agent）
   ↓
3. 各 agent 认领、执行、建 MR
   ↓
4. agent 评论 + 关闭子 Issue
   ↓
5. 人验证后手动关闭主 Issue
```

#### 安全限制

- 主 Issue（`hero::type:epic`）**只能人手动关闭**，agent 不得触碰
- 所有 Issue 标签必须用 `hero::` 前缀
- tech-lead 拆解子 Issue 后需 STOP 确认
- 代码审查 / 安全审计角色只读 Issue 状态，不改标签

#### 相关资源

- Issue 模板：`.gitlab/issue_templates/`
- Dispatch skill：`skills/hero-issue-dispatch/`
- glab skill：`skills/hero-glab/`
- Poller 脚本：`scripts/hero-issue-poller.sh`

---

## 仓库结构

| 目录 | 装什么 | 怎么用 |
|------|--------|--------|
| `agents/` | 所有 Hero（`hero-*.md`） | 改 prompt / 新建你的 Hero |
| `skills/` | 能力包：hero 工作流 + 13 个 CLI 工具 skill + 整套 lark 飞书 skill | 写自己的工作流 Skill |
| `cli/` | 18 个 CLI 工具文档 | 查工具用法 |
| `config/` | hooks / 模板 | 改 hook / 合并配置 |
| `mcp/` | MCP server 配置模板 | 配自己的 MCP |
| `scripts/` | `hero-refresh.sh`（保鲜）/ `hero-init.sh`（开荒）等入口 | 跑保鲜 / 开荒 |
| `templates/` | 领航 Agent 模板（`navigator-agent.md.tmpl`） | hero-init 生成 Hero 用 |
| `hero-tavern/` | 英雄殿监控看板（Python + Web） | 看 agent 实时状态 |
| `site/` | 宣传页（Caddy 静态站） | 对外展示 |
| `docs/` | 文档手册 | 看 onboarding / 维护手册 |
| `tests/` | dispatch / refresh / 分层 / 可见性测试 | 改核心子系统前后跑 |

---

## 维护指南

> **完整的维护手册见 [`docs/maintenance.md`](docs/maintenance.md)。**

| 你想做什么 | 怎么做 |
|-----------|--------|
| 改进一个共享 Hero | 改 `agents/hero-*.md` → 提 PR |
| 创造你的专属 Hero | 在 `agents/` 新建 `hero-<语言>-<名字>.md`，取个花名 |
| 给新 Java 服务开荒一个领航 Hero | `bash scripts/hero-init.sh <项目路径> <花名>`（自动建索引 + 生成 Hero + 开分支） |
| 沉淀一个团队 Skill | 在 `skills/hero-<能力>/` 写 `SKILL.md` |
| 加上你发现好用的 CLI 工具 | 在 `cli/` 写文档，更新总表 |
| 有想法 / 想讨论 | 提 Issue / 在群里聊 |

---

## 哲学

**Hero 不是为了取代人，是为了让人做人该做的事。**

写重复代码、修同样的 Bug、查千篇一律的安全问题——这些应该由 Hero 做。人的精力应该放在：

- **创造力**——设计更好的架构、探索新的方案、学习新的技术
- **有温度的互动**——跟业务方聊需求、帮同事过代码、带新人成长
- **真正的价值**——解决业务问题、推动技术演进、做有影响力的事

而这一切的起点，就是**给自己造一个 Hero**。

> 像公司里的伙伴都有自己的花名一样，给你的 Hero 取个名字。那些最烦、最重复、最消耗你的事，交给他。你把时间省下来，做只有你能做的事。

---

## 贡献

这是**所有人的仓库**。想参与，看 [`CONTRIBUTING.md`](CONTRIBUTING.md)。