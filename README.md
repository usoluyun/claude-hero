<div align="center">

<img src="https://img.shields.io/badge/status-active-brightgreen" alt="Status">
<img src="https://img.shields.io/badge/coverage-团队共创-blueviolet" alt="Team">
<img src="https://img.shields.io/badge/license-MIT-blue" alt="License">

# 🦸 claude-hero

> 在路上的开发者，需要一个替你背行囊的伙伴。

**开发的路上不必独行——让 Hero 替你背起繁琐，把创造力和温度，留给只有你能做的事。**

</div>

---

## 这是谁的仓库

**每一个人的。**

这不是架构师画完图丢给团队执行的项目。这是一支**团队一起带出来的队伍**——每个人都可以创造属于自己的 Hero，也可以改进别人的 Hero，把你每天的繁琐工作交给 Hero，把你最熟悉的工作流沉淀成 Skill，然后看着整个团队一起变强。

### Hero 是什么？

Hero 是一个 AI agent——有名字、有花名、有明确的职责边界。它不只是个 prompt 文件，它配有工具、技能（skill）、CLI 工具集，像团队里一个靠谱的队友。

团队里的 Hero 分两种，正好对应「具体怎么干」和「在哪儿干」——它们各司其职、彼此搭手。

#### ① 标准 Hero（角色型）——横向干活，跨服务通用

不绑定具体项目，按职责分**规划 / 执行 / 评审**三梯，哪个项目都能上场。它们负责「**具体怎么改**」：

| 花名 | 本名 | 梯队 | 负责什么 |
|------|------|------|---------|
| **Demis Hassabis** | hero-java-tech-lead | 规划 | 技术负责人、拆任务、画架构 |
| **Jeff Dean** | hero-java-backend-developer | 执行 | 写 Controller/Service，接入中间件 |
| **Fei-Fei Li** | hero-java-data-engineer | 执行 | MyBatis SQL + DBA |
| **Percy Liang** | hero-java-test-engineer | 执行 | TDD/BDD/冒烟/端到端测试 |
| **Chris Olah** | hero-java-code-reviewer | 评审 | 代码审查（只读） |
| **Jan Leike** | hero-java-security-auditor | 评审 | 安全设计审计（只读） |

#### ② 领航 Hero（项目型）——按服务只读带路

每个领航 Hero **绑定一个具体的 Java 服务**，靠 codegraph 索引吃透这个项目的代码结构，**只读、不动手**。它的活是「**带路**」：圈定「这次该在哪儿改、会牵连到谁」，再把「具体怎么改」交给标准 Hero。一个新服务可以用 `hero-init` 开荒出属于它的领航 Hero，代码漂移了用 `hero-refresh` 保鲜它的认知。

| 花名 | 本名 | 带路的服务 |
|------|------|-----------|
| **John Schulman** | hero-java-ecrm | 企业/连锁/促销 申请审批工作流（特殊栈） |
| **Oriol Vinyals** | hero-java-hotel-product-center | 酒店产品中心（房价码 / 定价 / 渠道映射） |
| **David Silver** | hero-java-owner-biz | 雅途业主服务端（大单体多业务域） |

> 一句话记住分工：**领航 Hero 圈定「在哪改、影响谁」，标准 Hero 负责「具体怎么改」。** 服务越多，领航 Hero 越多——目标是让每个 Java 服务都有一位熟门熟路的带路人。

> **花名取自创造了计算与 AI 时代的先驱——他们的名字值得被记住。** 它不是排行榜上的名次，而是身边一个同行伙伴的名字——叫得出名字，才有温度。花名是团队的共同语言，也是一份致敬。你也可以给你创造的 Hero 取花名，就像公司里的伙伴都有自己的花名一样。

---

## 快速开始

```bash
# 10 分钟接入
git clone <repo-url> claude-hero && cd claude-hero && bash install.sh

# 给一个新 Java 服务开荒（花名可选，留空自动分配）
bash scripts/hero-init.sh ~/Documents/ATLWork/ecrm  # 花名可选，自动分配
bash scripts/hero-init.sh ~/Documents/ATLWork/ecrm John Schulman  # 也可显式指定

# 然后直接用意图叫 Hero
hero 修一下登录报错          # → 自动分诊到 bugfix 线
hero 这个接口太慢            # → perf 线——先诊断后优化
hero 开发工作流 https://...   # → PRD 驱动全流程开发
hero 刷新                    # → 让所有 Hero 的知识保鲜
```

### 卸载

```bash
cd claude-hero && bash uninstall.sh
```

只删除**指向本仓库**的软链，绝不动 `*.bak.*` 备份、个人 `CLAUDE.md` / `settings.json` / `.mcp.json`。
卸载后可随时 `bash install.sh` 重新接入。

接入后你可以：

- **用现有的 Hero**——Jeff Dean帮你写代码，Jan Leike帮你查安全，Percy Liang帮你写测试
- **用 Agent Teams 组队**——Demis Hassabis出设计 + Jeff Dean写代码 + Percy Liang补测试，三位并行推进，自动分屏协作（tmux 已自动安装）
- **改进现有的 Hero**——Jeff Dean的 prompt 可以更好？提 PR，大家一起变强
- **创造你自己的 Hero**——你最懂你日常做什么。造一个，命个花名，解放自己
- **沉淀团队的 Skill**——团队特有的工作流、规范，写成 Skill 共享出来

---

## 核心子系统

> 想看运行机制全景（五层架构 / Wave 工作流 / Skill 调度 / 工作流执行可视化），见项目主页机制页 [`site/public/mechanism.html`](site/public/mechanism.html)。

### 🎯 意图分诊（hero-dispatch）

说一句意图 → 自动归类到 8 条 lane（bugfix/perf/refactor/research/security/prd/refresh/iterate）→ 补齐输入 → 确认 → 交接给对应 Hero 或 workflow。不记命令，自然语言直达。

### 📋 PRD 驱动开发（hero-prd-to-java）

给一个飞书 PRD 链接 → 自动读取 → Demis Hassabis出设计文档 + Sprint 计划 → 多 Hero 并行开发 → Chris Olah和Jan Leike把关 → 合并。全程确认门控 + worktree 隔离。

### 🧭 代码图与索引（codegraph）

领航 Hero 的**知识底座**。为每个服务构建代码结构图（模块关系、依赖流向、核心接口）并建立可增量更新的索引——开荒（hero-init）时首次构建，保鲜（hero-refresh）时跟随代码漂移更新。领航 Hero 正是靠它才能只读带路、圈定「在哪改、影响谁」。

### 🔄 资产保鲜（hero-refresh）

项目代码在变，Hero 的知识不能过时。定期扫描代码变化 → 刷新领航 Hero 的认知 → 有人工 gate 确认才生效。

### 🌱 主动开荒（hero-init）

一个新 Java 服务从无到有接入：`bash scripts/hero-init.sh <项目路径> [花名]` → 自动建 codegraph 索引 + 生成领航 Hero + 登记花名册 + 开好 Git 分支，剩下提 MR 即可。

> **花名是可选参数**：留空时系统会从先驱名字池里随机挑一个未被占用的花名自动分配；显式传入时必须唯一（不与现有 Hero 重复，脚本会校验）。
### 🤝 Agent Teams（团队协作）

多位 Hero 组队协作——Demis Hassabis出设计、Jeff Dean写代码、Percy Liang补测试，三位同时在各自 pane 里并行推进，互相通信，合力完成复杂任务。`install.sh` 已自动检测并安装 `tmux`（分屏模式依赖），无需手动配置。

```bash
# 进入 tmux 会话
tmux new -s work
claude

# 对 Claude 说：
# "Spawn a team of 3 agents: Demis Hassabis（opus）做设计，Jeff Dean（sonnet）写代码，Percy Liang（haiku）写测试"
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
2. tech-lead (Demis Hassabis) 自动拆解子 Issue（分配给各角色 agent）
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
| `site/` | 宣传页（Caddy 静态站） | 对外展示 |
| `docs/` | 文档手册 | 看 onboarding / 维护手册 |
| `tests/` | dispatch / refresh / 分层 / 可见性测试 | 改核心子系统前后跑 |

---

## 文档索引（docs/）

| 文档 | 内容 | 何时看 |
|------|------|--------|
| [`hero-workflow/`](./docs/hero-workflow/) | hero 工作流机制指南（7 篇解读：触发词 / lane 路由 / playbook / 露出规范 / PRD 流水线 / refresh 保鲜 / codegraph） | 想深入理解 hero 机制 |

---

## 维护指南

> **完整的维护手册见 [`docs/maintenance.md`](docs/maintenance.md)。**

| 你想做什么 | 怎么做 |
|-----------|--------|
| 改进一个共享 Hero | 改 `agents/hero-*.md` → 提 PR |
| 创造你的专属 Hero | 在 `agents/` 新建 `hero-<语言>-<名字>.md`，取个花名 |
| 给新 Java 服务开荒一个领航 Hero | `bash scripts/hero-init.sh <项目路径> [花名]`（自动建索引 + 生成 Hero + 开分支；花名可选，留空自动分配）|
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

我们想要的，是一种自然、静谧、温暖、朴实的协作——工具退到背景里安静地替你分担，人留在前台做有温度的事。而这一切的起点，就是**给自己造一个 Hero**。

> 像公司里的伙伴都有自己的花名一样，给你的 Hero 取个名字。那些最烦、最重复、最消耗你的事，交给他背着；你把时间省下来，把温度留给只有你能做的事。

---

## 贡献

这是**所有人的仓库**。想参与，看 [`CONTRIBUTING.md`](CONTRIBUTING.md)。