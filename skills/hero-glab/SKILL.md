---
name: hero-glab
description: GitLab CLI 操作。当需要管理 Merge Request、CI/CD Pipeline、Issue 工作流、Release、标签管理或 GitLab Issue 任务拉取/认领/完成汇报时使用。支持 hero::agent 标签路由、Issue 分层拆解、agent 任务生命周期管理。
---

# hero-glab — GitLab CLI 自动化

> 在终端完成全部 GitLab 日常操作：创建 MR、审 CI、管 Issue 工作流、查 Release，**告别浏览器来回切换**。

## 认证

```bash
# 交互式登录（gitlab.com）
glab auth login

# 私有 GitLab 实例（如 gitlab.corp.yaduo.com）
glab auth login --hostname http://gitlab.corp.yaduo.com/
# → 选择 HTTP
# → 输入 Personal Access Token
# → 完成

# 查看认证状态
glab auth status
```

> 内部域名（yaduo.com、at-our.com）通常无需配置代理。

---

## Label 命名空间（hero:: 前缀）

所有 hero 体系内的标签统一使用 `hero::` 前缀，避免与团队其他标签冲突。

| 标签模式 | 含义 | 示例 |
|---|---|---|
| `hero::agent:<agent-name>` | 任务指派给哪个 agent | `hero::agent:wenyuan`、`hero::agent:xiren` |
| `hero::status:pending` | 待认领 | — |
| `hero::status:in_progress` | 进行中 | — |
| `hero::status:done` | 已完成 | — |
| `hero::type:epic` | 主 Issue（史诗），**禁止 agent 关闭** | — |
| `hero::type:task` | 子 Issue（可执行任务） | — |
| `hero::priority:high` | 高优先级 | — |
| `hero::priority:medium` | 中优先级 | — |
| `hero::priority:low` | 低优先级 | — |

### 状态机

```
pending → in_progress → done → (close)
```

- **认领**：`pending` → `in_progress`
- **完成**：`in_progress` → `done`（通过评论汇报 + 标签更新）
- **关闭**：仅 `hero::type:task` 的子 Issue 允许关闭；带 `hero::type:epic` 的主 Issue **绝对不能关闭**

> ⚠️ **安全红线**：任何 agent 都**不允许关闭**带有 `hero::type:epic` 标签的 Issue。关闭前必须用 `glab issue view <iid>` 检查标签。

---

## Merge Request

```bash
# 创建 MR（从当前分支，自动填充标题和描述）
glab mr create --fill

# 创建 Draft MR（WIP）
glab mr create --draft --fill

# 指定目标分支、审核人、标签
glab mr create --fill --target-branch main --reviewer xuan-cheng --label "backend,feature"

# 列出 MR
glab mr list

# 查看指派给自己的 MR
glab mr list --assignee=@me

# 查看待审核的 MR
glab mr list --reviewer=@me

# 查看 MR 详情
glab mr view 42

# 批准 MR
glab mr approve 42

# 合并（squash + 删源分支）
glab mr merge 42 --squash --delete-source-branch

# 评论
glab mr note -m "需要补充单元测试" 42

# 关联 Issue 创建 MR（完成后自动挂钩）
glab mr create --fill --related-issue 123
```

---

## CI/CD Pipeline

```bash
# 当前分支流水线状态
glab ci status

# 列出最近流水线
glab ci list

# 查看 Job 日志
glab ci view 12345

# 重试失败 Job
glab ci retry 12345

# 手动触发流水线
glab ci run
```

---

## Issue 基础操作

```bash
# 列出 Issue
glab issue list

# 查看指派给自己的
glab issue list --assignee=@me

# 创建 Issue
glab issue create --title "修复登录页超时" --label "bug"

# 查看 Issue 详情（JSON 格式，便于解析）
glab issue view 99 --output json

# 关闭 Issue（⚠️ 关闭前必须检查标签，确认不是 hero::type:epic）
glab issue close 99
```

---

## Issue 工作流完整生命周期（Agent 任务管理）

hero agent 通过 Issue 拉取/认领/执行/汇报，形成闭环。以下是完整生命周期：

### 1. 拉取任务

agent 通过标签筛选，找到指派给自己且状态为 `pending` 的任务：

```bash
# 拉取指派给某个 agent 的待办任务
glab issue list \
  --label "hero::agent:<name>,hero::status:pending" \
  --output json

# 示例：Jeff Dean拉取自己的待办
glab issue list \
  --label "hero::agent:wenyuan,hero::status:pending" \
  --output json

# 提取关键字段
glab issue list \
  --label "hero::agent:wenyuan,hero::status:pending" \
  --output json \
  | jq '.[] | {iid, title, web_url}'
```

### 2. 认领任务

agent 确认要执行某个任务后，立即将状态从 `pending` 切换为 `in_progress`：

```bash
# 认领：去掉 pending，加上 in_progress
glab issue update <iid> \
  --label "hero::status:in_progress" \
  --unlabel "hero::status:pending"
```

> ⚠️ **认领后立刻开干**。不要认领多个任务堆积，一次认领一个，完成后再领下一个。

### 3. 查看详情

认领后仔细阅读 Issue 描述，理解任务要求：

```bash
# 查看 Issue 详情（Markdown 格式，人类可读）
glab issue view <iid>

# 查看 Issue 详情（JSON 格式，程序可解析）
glab issue view <iid> --output json

# 查看 Issue 的评论/讨论（了解上下文）
glab issue note list <iid>
```

### 4. 完成任务评论（汇报）

执行完毕后，**必须在 Issue 上留下结构化评论**，包含做了什么、diff 摘要、验证状态：

```bash
# 任务完成汇报（结构化格式）
glab issue note <iid> -m "## ✅ 任务完成汇报

### 做了什么
- <简述具体改动内容>

### Diff 摘要
- 修改了 <N> 个文件
- 新增 <X> 行，删除 <Y> 行

### 验证状态
- [ ] 单元测试通过
- [ ] 编译通过
- [ ] 代码审查通过

### MR 链接
- !<mr-iid>"
```

> **评论格式约定**：固定使用 `## ✅ 任务完成汇报` 开头，便于后续自动化解析。

### 5. 更新状态为已完成

汇报完成后，将标签状态更新为 `done`：

```bash
glab issue update <iid> \
  --label "hero::status:done" \
  --unlabel "hero::status:in_progress"
```

### 6. 关闭子 Issue（仅限 task 类型）

确认任务彻底完成后，关闭子 Issue：

```bash
# ⚠️ 关闭前必须检查：确认该 Issue 带 hero::type:task 标签，不带 hero::type:epic
glab issue view <iid> --output json | jq '.labels'
# 确认有 "hero::type:task" 且没有 "hero::type:epic"

# 安全关闭
glab issue close <iid>
```

> 🚨 **绝对禁止关闭带有 `hero::type:epic` 标签的 Issue。** 关闭前必须 `view` 检查标签。违反此规则会破坏整个任务追踪体系。

### 7. 关联 MR

完成任务时，将 MR 与 Issue 关联，实现自动挂钩：

```bash
# 方式一：创建 MR 时关联
glab mr create --fill --related-issue <iid>

# 方式二：MR 描述中引用（如果已创建 MR）
# 在 MR 描述中写入：Closes #<iid> 或 Relates to #<iid>
```

---

## 子 Issue 拆解（Tech-Lead 用法）

tech-lead（如Demis Hassabis）负责将主 Issue（epic）拆解为可执行的子 Issue（task），分配给各 agent。

### 创建子 Issue

```bash
# 创建子 Issue 并指派给特定 agent
glab issue create \
  -t "实现用户登录接口" \
  -d "## 任务描述

实现 \`POST /api/v1/auth/login\` 接口。

## 验收标准
- 支持手机号+验证码登录
- 返回 JWT token
- 错误码规范

## 关联
Relates to #<parent-iid>" \
  --label "hero::agent:wenyuan,hero::status:pending,hero::type:task,hero::priority:high"
```

### 关联到主 Issue

创建子 Issue 时，在 body 中写入关联声明：

```markdown
Relates to #<parent-iid>
```

也可以通过 GitLab Web 界面手动建立 Issue 关联关系。

### 拆解流程

```bash
# 1. 查看主 Issue 详情，理解全貌
glab issue view <parent-iid>

# 2. 逐个创建子 Issue（每个对应一个 agent 的职责范围）
glab issue create \
  -t "[子任务] 数据库表设计与 MyBatis Mapper" \
  -d "... Relates to #<parent-iid>" \
  --label "hero::agent:zichang,hero::status:pending,hero::type:task,hero::priority:high"

glab issue create \
  -t "[子任务] Service 层 + Controller 接口" \
  -d "... Relates to #<parent-iid>" \
  --label "hero::agent:wenyuan,hero::status:pending,hero::type:task,hero::priority:medium"

glab issue create \
  -t "[子任务] 接口冒烟测试" \
  -d "... Relates to #<parent-iid>" \
  --label "hero::agent:xiren,hero::status:pending,hero::type:task,hero::priority:low"

# 3. 在主 Issue 下评论，记录拆解结果
glab issue note <parent-iid> -m "## 📋 子任务拆解完成

| 子任务 | 负责人 | 优先级 |
|--------|--------|--------|
| #<child-1-iid> 数据库表设计 | Fei-Fei Li | high |
| #<child-2-iid> Service + Controller | Jeff Dean | medium |
| #<child-3-iid> 冒烟测试 | Percy Liang | low |"
```

> 🚨 **重要**：tech-lead 在创建子 Issue **之前必须停下并向用户确认拆解方案**。不要自作主张直接批量创建。让用户确认子任务的划分、负责人分配、优先级设定后再执行。

### 子 Issue 命名约定

- 标题前缀 `[子任务]` 标识这是子 Issue
- 描述中必须包含 `Relates to #<parent-iid>`
- 必须带标签：`hero::type:task` + `hero::agent:<name>` + `hero::status:pending`
- 建议带：`hero::priority:<level>`

---

## 轮询工作流（Polling Workflow）

与 `scripts/hero-issue-poller.sh` 配合，实现 agent 定时拉取并执行任务。

### 轮询脚本集成

轮询脚本的核心逻辑：

```bash
# 1. 拉取待办任务列表
PENDING=$(glab issue list \
  --label "hero::agent:${AGENT_NAME},hero::status:pending" \
  --output json)

# 2. 按优先级排序（high > medium > low）
echo "$PENDING" | jq 'sort_by(
  if .labels | any(. == "hero::priority:high") then 0
  elif .labels | any(. == "hero::priority:medium") then 1
  else 2 end
)'

# 3. 取出最高优先级的任务
TASK_IID=$(echo "$PENDING" | jq -r '.[0].iid')

# 4. 认领
if [ -n "$TASK_IID" ]; then
  glab issue update "$TASK_IID" \
    --label "hero::status:in_progress" \
    --unlabel "hero::status:pending"
fi
```

### Agent 侧轮询流程

```
┌──────────────────────────────────────────────────┐
│                   Agent 启动                      │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐
│  拉取 pending 任务（hero::   │
│  agent:<me> + pending）      │──── 无任务 → 等待/空闲
└──────────────┬───────────────┘
               │ 有任务
               ▼
┌──────────────────────────────┐
│  认领（→ in_progress）       │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  查看详情，理解任务          │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  执行任务（写代码/测试/审查）│
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  汇报评论 + 更新 → done      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  关闭子 Issue                │
│  （确认不是 epic 类型）       │
└──────────────┬───────────────┘
               │
               ▼
        ┌──────────────┐
        │  拉取下一个   │─── 回到循环
        └──────────────┘
```

### 手动触发轮询

```bash
# 执行一次拉取（单次模式）
bash scripts/hero-issue-poller.sh --agent wenyuan --once

# 持续轮询（daemon 模式）
bash scripts/hero-issue-poller.sh --agent wenyuan --interval 30
```

---

## Project / API

```bash
# 查看仓库信息
glab repo view

# 直接调用 GitLab API
glab api projects/:id/pipelines

# API + jq 提取
glab api projects/:id/pipelines | jq '.[] | {id, status, ref}'
```

---

## 常用参数

| 参数 | 用途 |
|------|------|
| `-r, --repo <namespace/project>` | 指定仓库 |
| `-f, --output-format json` | JSON 格式输出 |
| `-w, --web` | 在浏览器打开 |
| `--per-page <n>` | 每页条数 |
| `--page <n>` | 页码 |

---

## Hero 协作场景

### Chris Olah（代码审查员）

```bash
# 列出待审 MR
glab mr list --reviewer=@me

# 查看详情 → 评论 → 批准
glab mr view 42
glab mr note -m "逻辑 OK，合并吧" 42
glab mr approve 42
```

### Jeff Dean（后端开发）

```bash
# 开发完提 MR → 等 CI → 合并
glab mr create --fill --reviewer xuan-cheng --label "backend"
glab ci status
glab mr merge 42 --squash --delete-source-branch
```

#### Jeff Dean的 Issue 任务流

```bash
# 1. 拉取自己的待办
glab issue list \
  --label "hero::agent:wenyuan,hero::status:pending" \
  --output json

# 2. 认领任务
glab issue update 45 \
  --label "hero::status:in_progress" \
  --unlabel "hero::status:pending"

# 3. 执行开发 → 提 MR → 关联 Issue
glab mr create --fill --related-issue 45

# 4. 完成后汇报
glab issue note 45 -m "## ✅ 任务完成汇报
- 实现了用户登录接口
- 修改了 3 个文件
- 单元测试通过
- MR: !78"

# 5. 更新状态
glab issue update 45 \
  --label "hero::status:done" \
  --unlabel "hero::status:in_progress"

# 6. 关闭子 Issue（先检查标签）
glab issue close 45
```

### Percy Liang（测试工程师）

```bash
# 检查 CI → 看失败日志 → 重试
glab ci status
glab ci view 12345
glab ci retry 12345
```

### Demis Hassabis（技术负责人）

```bash
# 全景查看
glab mr list --per-page 50
glab ci list --per-page 20
glab api projects/:id | jq '{name, star_count, forks_count}'

# 查看主 Issue 全貌
glab issue view <epic-iid>

# 拆解子 Issue（先确认再创建）
# → 见「子 Issue 拆解」章节
```

---

## 整合其他 CLI

```bash
# glab + jq：提取 MR 信息
glab mr list --output-format json | jq '.[] | {iid, title, state, web_url}'

# glab + grep：搜索 MR 标题
glab mr list --output-format json | jq -r '.[].title' | grep -i "bugfix"

# glab + jq：找失败的 CI
glab ci list --output-format json | jq '.[] | select(.status == "failed") | {id, ref}'

# glab + jq：提取 agent 待办任务并按优先级排序
glab issue list \
  --label "hero::agent:wenyuan,hero::status:pending" \
  --output json \
  | jq '[.[] | {iid, title, labels}] | sort_by(
      if .labels | any(. == "hero::priority:high") then 0
      elif .labels | any(. == "hero::priority:medium") then 1
      else 2 end
    )'

# glab + jq：统计各 agent 的任务分布
glab issue list --label "hero::status:pending" --output json \
  | jq '[.[] | .labels[] | select(startswith("hero::agent:"))] | group_by(.) | map({agent: .[0], count: length})'

# glab + jq：追踪子 Issue 完成进度
glab issue list --output json \
  | jq '[.[] | .labels[] | select(. == "hero::type:task")] | length' 
```

---

## 团队约定

- **MR 必须有 reviewer**：不允许无审核人直接合并
- **标题格式**：遵循 `<type>: <desc>` 如 `fix: 修复登录超时`、`feat: 新增导出功能`
- **合并方式**：默认 `--squash --delete-source-branch`，保持主分支历史干净
- **CI 失败**：先 `glab ci view <job-id>` 看日志定位，不要直接重试
- **Issue 标签**：hero 体系内一律使用 `hero::` 前缀标签，不得混用其他命名
- **认领即干**：agent 认领任务后必须立刻执行，不得堆积 in_progress 状态的任务
- **epic 不关闭**：带 `hero::type:epic` 的主 Issue 在任何情况下都不得由 agent 关闭
- **汇报必填**：任务完成必须在 Issue 上留下结构化评论（做了什么 / diff 摘要 / 验证状态）
- **拆解需确认**：tech-lead 拆解子 Issue 前必须向用户确认方案

> 详细用法见 [../../cli/glab.md](../../cli/glab.md)
