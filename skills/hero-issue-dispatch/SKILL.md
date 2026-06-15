---
name: hero-issue-dispatch
description: GitLab Issue 命令路由。当用户输入 Issue 相关操作时，根据命令类型和 Issue 标签自动路由到对应角色 agent。触发关键词包括：issue pull/claim/done/decompose/list/view/status/review/audit、glab、gitlab issue、hero::status、hero::agent、hero::type。支持中文自然语言如「拉取待办 Issue」「认领 #456」「完成 #789」「拆解主 Issue」「审查代码」「代码审计」等。
---

# hero-issue-dispatch — GitLab Issue 命令路由

> **核心价值**：用户输入一行 Issue 命令 → 自动识别命令类型、解析 Issue 标签、路由到正确角色 agent，用户不必知道哪个 agent 负责什么。

## 触发词

- `issue pull` — 拉取待处理 Issue
- `issue claim <iid>` — 认领 Issue
- `issue done <iid> [message]` — 完成并关闭 Issue
- `issue decompose <iid>` — 分解 Issue 为子任务
- `issue list <agent>` — 列出分配给某 agent 的 Issue
- `issue view <iid>` — 查看 Issue 详情
- `issue status` — 查看所有 agent 的任务分布概况
- `issue review <iid>` — 请求代码审查（只读，路由 code-reviewer）
- `issue audit <iid>` — 请求安全审计（只读，路由 security-auditor）

## hero 露出

本 skill 及其路由到的 agent 都属 hero 体系，运作时按 `hero-conventions`《hero 露出规范》打出标记：

- **命令识别**：`🦸 hero ▸ issue-dispatch · 识别命令 → <command>`
- **路由到 agent**：`🦸 hero ▸ <agent-花名>（<agent-file>）接手 · <职责>`

---

## 支持的命令

| 命令 | 用途 | 路由目标 | 门控 |
|------|------|---------|------|
| `issue pull` | 拉取待处理 Issue，触发轮询 | 轮询脚本 → 各 agent | 无（自动执行） |
| `issue claim <iid>` | 认领 Issue（`pending` → `in_progress`） | 根据 `hero::agent` 标签路由 | 确认后执行 |
| `issue done <iid> [msg]` | 完成汇报 + 关闭 Issue | 根据 `hero::agent` 标签路由 | ⚠️ 关闭前检查非 epic |
| `issue decompose <iid>` | 拆解主 Issue 为子任务 | **tech-lead（Demis Hassabis）** | ⏸ STOP 确认拆解方案 |
| `issue list <agent>` | 列出 agent 的待办 | 无（直接查询） | 无 |
| `issue view <iid>` | 查看 Issue 详情 | 无（直接查看） | 无 |
| `issue status` | 全局任务分布概况 | 无（直接统计） | 无 |
| `issue review <iid>` | 请求代码审查（Chris Olah，只读） | **code-reviewer（Chris Olah）** | 无（只读不关闭 Issue） |
| `issue audit <iid>` | 请求安全审计（Jan Leike，只读） | **security-auditor（Jan Leike）** | 无（只读不关闭 Issue） |

---

## 路由逻辑

### 核心规则

```
命令进入
  │
  ├─ decompose → 强制路由 tech-lead（Demis Hassabis），不管标签
  │
  ├─ claim / done → 读取 Issue 标签 hero::agent:<name>
  │     ├─ 有标签 → 路由到对应 agent
  │     └─ 无标签 → 路由 tech-lead（Demis Hassabis）分配
  │
  ├─ pull → 触发 scripts/hero-issue-poller.sh
  │     └─ 脚本逐个拉取 → 每个 Issue 按标签路由到 agent
  │
  │
  ├─ review → 强制路由 code-reviewer（Chris Olah），只读查看 + 评论，不执行 claim/done/close
  │
  ├─ audit → 强制路由 security-auditor（Jan Leike），只读查看 + 评论，不执行 claim/done/close
  │
  └─ list / view / status → 不路由 agent，直接执行查询
```

### 详细路由表

| Issue 标签 `hero::agent:` | 路由到 agent | 花名 | agent 文件 |
|---|---|---|---|
| `kongming` | tech-lead | Demis Hassabis | `agents/hero-java-tech-lead.md` |
| `wenyuan` | backend-dev | Jeff Dean | `agents/hero-java-backend-developer.md` |
| `zichang` | data-engineer | Fei-Fei Li | `agents/hero-java-data-engineer.md` |
| `xiren` | test-engineer | Percy Liang | `agents/hero-java-test-engineer.md` |
| `xuancheng` | code-reviewer | Chris Olah | `agents/hero-java-code-reviewer.md` |
| `pengju` | security-auditor | Jan Leike | `agents/hero-java-security-auditor.md` |
| （无标签） | tech-lead | Demis Hassabis | `agents/hero-java-tech-lead.md` |

> **标签名使用花名拼音**（如 `wenyuan`），与 `hero-glab` skill 中的 Label 命名空间一致。

---

## Agent 映射（6 个角色）

| 角色 | 花名 | Agent 文件 | 职责 | 触发关键词 |
|------|------|-----------|------|-----------|
| **tech-lead** | Demis Hassabis | `hero-java-tech-lead` | 架构设计、任务拆解、分配协调 | `decompose`, `assignment`, `分解`, `分配`, `拆解` |
| **backend-dev** | Jeff Dean | `hero-java-backend-developer` | 业务逻辑实现、中间件接入 | `code`, `implementation`, `代码`, `实现`, `接口`, `Controller`, `Service` |
| **data-engineer** | Fei-Fei Li | `hero-java-data-engineer` | 数据层、MyBatis、SQL 调优 | `data`, `SQL`, `数据`, `数据库`, `MyBatis`, `Mapper`, `索引` |
| **test-engineer** | Percy Liang | `hero-java-test-engineer` | TDD/BDD 测试、接口冒烟、E2E | `test`, `testing`, `测试`, `验证`, `单元测试`, `冒烟`, `Allure` |
| **code-reviewer** | Chris Olah | `hero-java-code-reviewer` | 代码审查（只读） | `review`, `code review`, `代码审查`, `评审`, `质量` |
| **security-auditor** | Jan Leike | `hero-java-security-auditor` | 安全审计（只读） | `security`, `audit`, `安全`, `审计`, `漏洞`, `越权` |

### 各 agent 认领后的标准流程

所有 agent 认领任务后统一走 `hero-glab` skill 定义的 Issue 生命周期：

1. **认领**：`pending` → `in_progress`（`glab issue update <iid> --label "hero::status:in_progress" --unlabel "hero::status:pending"`）
2. **执行**：按 agent 自身职责完成工作
3. **汇报**：在 Issue 下留结构化评论（做了什么 / diff 摘要 / 验证状态）
4. **完成**：`in_progress` → `done`（`glab issue update <iid> --label "hero::status:done" --unlabel "hero::status:in_progress"`）
5. **关闭**：确认非 `hero::type:epic` 后 `glab issue close <iid>`

> 🚨 **安全红线**：任何 agent **禁止关闭**带 `hero::type:epic` 标签的 Issue。关闭前必须 `glab issue view <iid> --output json | jq '.labels'` 确认。

---

## 工作流示例

### 示例 1：拆解 + 认领 + 完成（完整闭环）

```
用户: issue decompose #123

🦸 hero ▸ issue-dispatch · 识别命令 → decompose
🦸 hero ▸ Demis Hassabis（hero-java-tech-lead）接手 · 任务拆解

→ Demis Hassabis读取 Issue #123（glab issue view 123）
→ Demis Hassabis分析需求，规划子任务：
   - 子任务 A：数据库表设计 → Fei-Fei Li（data-engineer）
   - 子任务 B：接口实现 → Jeff Dean（backend-dev）
   - 子任务 C：单元测试 + 冒烟 → Percy Liang（test-engineer）

⏸ STOP ① 「确认拆解方案」

| 子任务 | 负责人 | 优先级 | 标签 |
|--------|--------|--------|------|
| 数据库表设计 | Fei-Fei Li | high | hero::agent:zichang |
| 接口实现 | Jeff Dean | high | hero::agent:wenyuan |
| 测试 | Percy Liang | medium | hero::agent:xiren |

→ 用户确认后，Demis Hassabis批量创建子 Issue：
  glab issue create -t "[子任务] 数据库表设计" ... --label "hero::agent:zichang,..."
  glab issue create -t "[子任务] 接口实现" ... --label "hero::agent:wenyuan,..."
  glab issue create -t "[子任务] 测试" ... --label "hero::agent:xiren,..."

→ Demis Hassabis在主 Issue #123 下评论拆解结果
────────────────────────────────────────

用户: issue claim #124

🦸 hero ▸ issue-dispatch · 识别命令 → claim
🦸 hero ▸ 读取 Issue #124 标签 → hero::agent:wenyuan
🦸 hero ▸ Jeff Dean（hero-java-backend-developer）接手 · 认领任务

→ Jeff Dean认领：glab issue update 124 --label "hero::status:in_progress" --unlabel "hero::status:pending"
→ Jeff Dean开始工作...
────────────────────────────────────────

用户: issue done #124 "完成用户认证模块，修改 3 个文件，单元测试通过"

🦸 hero ▸ issue-dispatch · 识别命令 → done
🦸 hero ▸ 读取 Issue #124 标签 → hero::agent:wenyuan
🦸 hero ▸ Jeff Dean（hero-java-backend-developer）接手 · 完成汇报

→ Jeff Dean评论完成报告：
  glab issue note 124 -m "## ✅ 任务完成汇报
  ### 做了什么
  - 完成用户认证模块
  ### Diff 摘要
  - 修改了 3 个文件
  ### 验证状态
  - [x] 单元测试通过"

→ Jeff Dean更新状态：glab issue update 124 --label "hero::status:done" --unlabel "hero::status:in_progress"

→ ⚠️ 关闭前检查标签 → 确认是 hero::type:task，非 epic
→ Jeff Dean关闭：glab issue close 124

→ Jeff Dean检查父 Issue #123 的子任务完成情况：
  glab issue list --output json | jq '[.[] | select(.description | contains("Relates to #123"))]'
  → 发现还有 #125（Percy Liang/测试）未完成
  → 提示用户：「#124 已完成。父 Issue #123 还有子任务 #125（Percy Liang/测试）待完成。」
```

### 示例 2：拉取待办

```
用户: issue pull

🦸 hero ▸ issue-dispatch · 识别命令 → pull

→ 触发 scripts/hero-issue-poller.sh
→ 轮询脚本扫描所有 agent 的 pending 任务
→ 按优先级排序，逐个认领并路由：

  🦸 hero ▸ Fei-Fei Li（hero-java-data-engineer）接手 · Issue #201（hero::priority:high）
  🦸 hero ▸ Jeff Dean（hero-java-backend-developer）接手 · Issue #202（hero::priority:medium）
  🦸 hero ▸ Percy Liang（hero-java-test-engineer）接手 · Issue #203（hero::priority:low）

→ 各 agent 并行开始执行各自任务
```

### 示例 3：查看任务分布

```
用户: issue status

🦸 hero ▸ issue-dispatch · 识别命令 → status

→ 统计各 agent 任务分布：

| Agent | pending | in_progress | done | 合计 |
|-------|---------|-------------|------|------|
| Jeff Dean（backend-dev） | 3 | 1 | 5 | 9 |
| Fei-Fei Li（data-engineer） | 1 | 0 | 2 | 3 |
| Percy Liang（test-engineer） | 2 | 1 | 3 | 6 |
| Chris Olah（code-reviewer） | 0 | 0 | 4 | 4 |
| Jan Leike（security-auditor） | 0 | 0 | 1 | 1 |

→ 查询命令：
  glab issue list --label "hero::status:pending" --output json \
    | jq '[.[] | .labels[] | select(startswith("hero::agent:"))] | group_by(.) | map({agent: .[0], count: length})'
```

---

## 集成点

### 依赖的 Skill 和脚本

| 集成点 | 路径 | 用途 |
|--------|------|------|
| **hero-glab** | `skills/hero-glab/SKILL.md` | 所有 `glab` CLI 命令参考（Issue CRUD、Label 命名空间、状态机） |
| **hero-conventions** | `skills/hero-conventions/SKILL.md` | hero 露出规范、团队约定 |
| **hero-issue-poller** | `scripts/hero-issue-poller.sh` | `issue pull` 触发的轮询脚本 |
| **Issue 模板** | `.gitlab/issue_templates/AgentTask.md` | 子 Issue 的标准模板 |
| **Issue 模板** | `.gitlab/issue_templates/FeatureRequest.md` | 主 Issue（epic）的标准模板 |

### Label 命名空间（引用自 hero-glab）

| 标签 | 用途 |
|------|------|
| `hero::agent:<name>` | 任务指派（`kongming` / `wenyuan` / `zichang` / `xiren` / `xuancheng` / `pengju`） |
| `hero::status:pending` | 待认领 |
| `hero::status:in_progress` | 进行中 |
| `hero::status:done` | 已完成 |
| `hero::type:epic` | 主 Issue（禁止关闭） |
| `hero::type:task` | 子 Issue（可关闭） |
| `hero::priority:high` / `medium` / `low` | 优先级 |

### 状态机

```
pending → in_progress → done → (close)
```

---

## 命令执行流程（详细）

### `issue decompose <iid>`

```
1. 强制路由到 tech-lead（Demis Hassabis），不检查标签
2. tech-lead 执行 glab issue view <iid> 读取主 Issue
3. tech-lead 分析需求，规划子任务拆分
4. ⏸ STOP 确认拆解方案（子任务、负责人、优先级）
5. 用户确认后，tech-lead 逐个创建子 Issue：
   glab issue create -t "[子任务] ..." -d "... Relates to #<iid>" --label "hero::agent:<name>,hero::status:pending,hero::type:task,hero::priority:<level>"
6. tech-lead 在主 Issue 评论拆解结果
```

### `issue claim <iid>`

```
1. 读取 Issue 标签：glab issue view <iid> --output json | jq '.labels'
2. 提取 hero::agent:<name> 标签值
3. 有标签 → 路由到对应 agent
   无标签 → 路由到 tech-lead（Demis Hassabis）分配
4. agent 执行认领：
   glab issue update <iid> --label "hero::status:in_progress" --unlabel "hero::status:pending"
5. agent 输出确认：「已认领 #<iid>，开始工作」
```

### `issue done <iid> [message]`

```
1. 读取 Issue 标签，路由到对应 agent
2. agent 在 Issue 下评论完成报告（若用户提供了 message 则使用）：
   glab issue note <iid> -m "## ✅ 任务完成汇报 ..."
3. agent 更新状态：
   glab issue update <iid> --label "hero::status:done" --unlabel "hero::status:in_progress"
4. ⚠️ 关闭前检查：glab issue view <iid> --output json | jq '.labels'
   - 确认有 hero::type:task，且无 hero::type:epic
   - 不满足 → 拒绝关闭，提示原因
5. 满足条件 → glab issue close <iid>
6. agent 检查父 Issue 的子任务完成情况（如有 Relates to 引用）
7. 若所有子任务完成 → 提示用户关闭父 Issue
```

### `issue pull`

```
1. 触发 scripts/hero-issue-poller.sh
2. 轮询脚本扫描所有 hero::status:pending 的 Issue
3. 按 hero::priority 排序（high → medium → low）
4. 逐个认领并路由到对应 agent
5. 各 agent 收到任务后自动进入 claim → execute → done 流程
```

### `issue list <agent>`

```
1. 将 agent 名解析为标签名（如 backend-dev → wenyuan）
2. 执行查询：
   glab issue list --label "hero::agent:<name>,hero::status:pending" --output json
3. 格式化输出表格（iid / title / priority / status）
```

### `issue view <iid>`

```
1. 直接执行 glab issue view <iid>
2. 展示 Issue 标题、描述、标签、评论列表
```

### `issue review <iid>`

```
1. 强制路由到 code-reviewer（Chris Olah）
2. Chris Olah执行 glab issue view <iid> 读取 Issue 上下文
3. 若 Issue 有关联 MR（通过 description 或 labels 找到）：
   glab mr view <mr-iid> → 分析 code changes
4. Chris Olah提供代码审查反馈（在 Issue 下评论）：
   glab issue note <iid> -m "## 🔍 代码审查摘要 ..."
5. ⚠️ Chris Olah不修改 Issue 状态，不执行 claim/done/close
```

### `issue audit <iid>`

```
1. 强制路由到 security-auditor（Jan Leike）
2. Jan Leike执行 glab issue view <iid> 读取 Issue 上下文
3. Jan Leike评估安全风险（在 Issue 下评论）：
   glab issue note <iid> -m "## 🛡️ 安全审计摘要 ..."
4. ⚠️ Jan Leike不修改 Issue 状态，不执行 claim/done/close
```

### `issue status`

```
1. 对每个 agent 标签统计 pending / in_progress / done 数量
2. 输出全局任务分布表格
3. 高亮 overdue 任务（pending 超过 3 天的）
```

---

## 边界与降级

- **非 Issue 命令**：本 skill 只处理 `issue *` 命令，其他 hero 命令走 `hero-dispatch` 分诊入口。
- **无标签 Issue 的 claim/done**：降级路由到 tech-lead（Demis Hassabis），由Demis Hassabis判断应分配给谁。
- **review / audit 命令**：强制路由到只读角色（code-reviewer / security-auditor），仅执行查询和评论，绝不执行状态修改或关闭操作。
- **中文自然语言触发**：「拉取待办」「认领 #456」「审查代码」等中文表达会通过 `hero-dispatch` 中转，识别后交接本 skill。
- **关闭 epic 的请求**：任何 agent 都拒绝执行，提示用户「主 Issue 带 `hero::type:epic` 标签，不可由 agent 关闭。请手动确认后关闭。」
- **重复认领**：如果 Issue 已是 `in_progress` 状态，拒绝认领并提示「该任务已被认领，当前状态：in_progress」。
- **轮询脚本缺失**：`issue pull` 依赖 `scripts/hero-issue-poller.sh`，如脚本不存在则提示路径并建议手动执行 `glab issue list`。

---

## 与 hero-dispatch 的关系

`hero-dispatch` 是顶层意图分诊入口，处理 `hero <自由意图>` 的自然语言输入。当用户意图涉及 Issue 操作时，`hero-dispatch` 会将控制权交给本 skill：

```
hero <意图>
  │
  └─ hero-dispatch 分诊
       │
       ├─ prd / refresh / bugfix / ... → 各自 lane
       │
       └─ 涉及 Issue 操作 → 交接 hero-issue-dispatch
            │
            ├─ issue decompose / claim / done / ...
            └─ 路由到对应 role agent
```

用户也可以直接使用 `issue <command>` 触发本 skill，跳过 `hero-dispatch`。
