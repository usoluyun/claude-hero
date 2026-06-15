# claude-hero 维护手册

> 从「用 Hero」到「养 Hero」到「造 Hero」，一份完整的团队共创指南。

---

## 一、心态：这是大家的 Hero

Hero 不是某个人的代码，是团队的资产。这意味着三件事：

1. **看到问题就改**——Jeff Dean的 prompt 少了一个常用场景？Demis Hassabis的触发词漏了个关键词？直接提 PR，不需要等人授权。Hackathon mentality。
2. **看到好东西就抄**——隔壁组造了一个很酷的 Hero？看看他的 prompt 结构，借鉴思路到你的 Hero。
3. **分享你的 Hero**——你造了一个帮你写周报的 Hero？提 PR 共享出来，可能十个人都需要。

---

## 二、四个参与层级

| 层级 | 你做什么 | 门槛 | 影响 |
|------|---------|------|------|
| **用** | 用已有的 Hero 完成日常工作 | 装好仓库就行 | 你个人效率提升 |
| **改** | 改进现有 Hero 的 prompt / tools / CLI | 改一个 markdown 文件 | 全团队受益 |
| **造** | 创造你的专属 Hero | 了解 agent 格式 | 你 + 共享后全团队 |
| **养** | 维护 Hero 的知识保鲜 | 熟悉 codegraph + hero-refresh | 已接入项目 |

### 层级 1：用

看书接上文的[快速开始](../README.md#快速开始)。上手直接用 `hero <你的意图>`。

### 层级 2：改

想改进一个共享 Hero？比如Jeff Dean的 prompt 应该加上一个你常用的中间件：

1. 打开 `agents/hero-java-backend-developer.md`
2. 在 `## 你的职责` 或 `## 工作方式` 下面加上你的改进
3. 提 PR，描述你改了什么、为什么
4. 合入后 `git pull`，全团队自动生效

**改什么都可以：**

| 可改项 | 位置 | 例子 |
|--------|------|------|
| 触发词 | frontmatter `触发词：` | 加上你们项目的常用术语 |
| 职责描述 | `## 你的职责` | 加上你们团队特有的中间件 |
| 工作方式 | `## 工作方式` | 加上你们团队特有的约定 |
| CLI 工具 | `## CLI 工具` | 加上你发现好用的工具引用 |
| tools 白名单 | frontmatter `tools:` | 加上需要的 MCP 工具 |

### 层级 3：造

这是最有趣的部分——**创造一个属于你自己的 Hero**。

#### 什么时候该造 Hero？

- 你每周都在做同一类事——写报表 SQL、审配置文件、发上线通知、整理周报
- 这件事有固定套路、有检查清单、有输出格式
- 你觉得"这要是 AI 能帮我做就好了"

满足这些，就该造一个 Hero 了。

#### 怎么造？

```bash
# 在 agents/ 下新建一个文件
touch agents/hero-java-my-custom-hero.md
```

格式很简单：

```markdown
---
name: hero-java-my-custom-hero
description: 我是干什么的。当用户说 XXX 时使用。
触发词：我的花名 / 我的触发 / 关键词
model: sonnet
tools: Read, Edit, Write, Grep, Glob, Bash
---

## hero 露出

`🦸 hero ▸ <你的花名>（hero-java-my-custom-hero）接手 · 我在做什么`

## 你的职责

- 职责 1
- 职责 2
- 职责 3

## 工作方式

1. 第一步做什么
2. 第二步做什么
3. 输出什么格式

## CLI 工具

- **tool1**：用来干什么
- **tool2**：用来干什么
```

**命名规则：**

| 类型 | 格式 | 例子 |
|------|------|------|
| 角色 Hero | `hero-<语言>-<角色>` | `hero-java-backend-developer` |
| 领航 Hero | `hero-<语言>-<项目>` | `hero-java-payment-service` |
| 个人 Hero | `hero-<语言>-<你的花名>` | `hero-java-chongqin-weekly` |

#### 取花名

就像公司里每个人都有花名，你的 Hero 也应该有花名。

- 可以从计算/AI 先驱的名字里取（参考已有 9 个 Hero 的风格）
- 也可以从你喜欢的角色里取
- 花名要短（2 个字最佳）、好记、有辨识度

> **好的花名**：Demis Hassabis、Jeff Dean、Fei-Fei Li、Percy Liang、Chris Olah、Jan Leike、John Schulman、Oriol Vinyals、David Silver
>
> **不好的花名**：`my_hero_123`、`dev_agent`、`test_helper`

#### 要不要共享？

不强制。你造的 Hero 可以先放在自己分支上用，用熟了觉得对大家也有用，再提 PR 共享出来。

如果你只是自己用，也可以放在 `~/.claude/agents/` 下（不提交到仓库），这样其他人 pull 不会受影响。

### 层级 4：养

Hero 的知识需要保鲜。代码在变、框架在升级、业务在演进——Hero 如果停在原地，就不 Hero 了。

**领航 Hero 的保鲜靠 `hero-refresh`：**

```bash
hero 刷新              # 刷新所有
hero 刷新 <项目名>     # 只刷一个
hero 刷新 评审         # 人工审核刷新结果
hero 刷新 状态         # 看谁该刷新了
```

**角色 Hero 的保鲜靠大家：**

- 你觉得Jeff Dean的 prompt 过时了？提 PR 更新
- 你们项目换了新框架？加进相关 Hero 的职责描述
- 出了新的好用的 CLI 工具？写到 `cli/` 里

---

## 三、贡献流程

### 小改动（直接提 PR）

改一个 prompt、加一行 CLI、修一个 typo：

1. 改文件
2. `git add && git commit -m "feat(agent): Jeff Dean加上 XXX 中间件接入"`
3. `git push && 提 PR`
4. 至少一位同事 Review 后合入

### 大改动（先讨论再动手）

新 Hero、新 Skill、新子系统：

1. 在群里 / 提 Issue 讨论方案
2. 达成共识后开干
3. 提 PR，至少两位同事 Review
4. 合入

### PR 要求

| 项目 | 要求 |
|------|------|
| Commit message | `feat\\|fix\\|refactor\\|docs(scope): 描述` |
| Review | 小改动 ≥1 人，大改动 ≥2 人 |
| 测试 | 改 agent 文件时跑 `tests/hero-agent-layers/run.sh` |
| 红线 | 不提交真实密钥 / token / 内网敏感信息 |

---

## 四、如何让团队用起来

### 第一步：几个核心成员先造 Hero

不要一上来就让所有人参与。先 2-3 个人各自造一个自己的 Hero 用起来——解决自己最痛的问题。然后喝咖啡的时候聊：

> "我造了个 Hero 帮我写周报，原来半小时的事现在 5 分钟搞定。"

这种真实的案例比什么都管用。

### 第二步：建立 Hero 文化

- **Hero Showcase**——每周五下午，谁想分享自己的 Hero 就上来讲 5 分钟
- **Hero of the Month**——大家投票选出本月最有用的 Hero，给点小奖励
- **Hero 需求墙**——谁有什么想 Hero 干但还没人做的，写便利贴上墙

### 第三步：让 Hero 成为日常

- 新成员 onboarding：第一天装好仓库，教他用 `hero` 当命令
- Team standup：有人提到"我昨天手动干了 XXX" → "这事可以造个 Hero"
- Retro：回顾中有一条"重复劳动太多" → 对应责任人认领造 Hero

---

## 五、原则

### 质量

- 每个 Hero 的 prompt 要写得清晰、具体、可执行。模糊的 prompt 造不出好 Hero
- CLI 工具文档要有**真实可运行的命令例子**，不要"类似这样"的描述
- Skill 的触发词要精确，不要乱触发

### 自治

- 一个 Hero 只干一件事。**做得少、做得好**
- 如果发现一个 Hero 的职责描述越来越长，说明它该拆成两个了
- 个人 Hero 不需要像共享 Hero 那么完善——够你用就行

### 共享

- 你觉得好的，大概率别人也需要。共享出来
- 你遇到问题想问别人，先搜搜有没有 Hero 能帮你
- 维护手册也靠大家补充——你踩过的坑，写在手册里