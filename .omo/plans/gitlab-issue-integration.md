# GitLab Issue 集成实施计划

> 把 GitLab Issues 变成 claude-hero 的任务总线——agent 从 Issue 拉任务，完成后评论汇报关 Issue，tech-lead 拆解子 Issue 分发。

## TL;DR

> **Quick Summary**: 让 claude-hero 体系能从 GitLab Issue 拉任务并在 Issue 中汇报执行结果。人建主 Issue（PRD 级）→ tech-lead 拆子 Issue（具体任务）→ 各 role agent 自动拉取执行 → 评论汇报 → 关闭。领航 agent 扩展只读查询能力。
>
> **Deliverables**:
> - 2 个 Issue 模板（AgentTask / FeatureRequest）
> - 扩展 `hero-glab` skill 加入 Issue 工作流命令
> - `dispatch` 新增 `issue` lane
> - `scripts/hero-issue-poller.sh` 轮询入口
> - 6 个 role agent prompt 优化（+1 个 tech-lead 增强型）
> - 领航 agent 模板 + `hero-init.sh` 加 GitLab 配置
> - README + 主页 Issue 工作流演示
>
> **Estimated Effort**: Large（5-7 小时）
> **Parallel Execution**: YES - 4 波次，最大并发 6 任务
> **Critical Path**: Task 2 (skill 扩展) → Task 4 (lane) → Task 6 (tech-lead) → Task 12 (hero-init) → F1-F4

---

## Context

### Original Request

用户想在 claude-hero 体系里深度集成 GitLab：

1. 通过 GitLab Issues 记录和分派 AI agent 任务
2. 每个 agent 自动从 GitLab Issue 获取任务与上下文
3. 新增领航 hero 时也要考虑 GitLab 提示词问题
4. Issue 来源模式：**两者都要**（人建主 issue + agent 拆子 issue）

### Interview Summary

**Key Discussions**:
- 用户确认 Issue 双源模式：人建主 issue + tech-lead 拆子 issue
- `glab` 已经装好（fac08ef 已 merge），不需要安装工作
- 现有 hero 体系（dispatch + prd-to-java + refresh）保持不变，Issue 是**新通道**

**Research Findings**（3 个 librarian + explore 调研）:
- **GitLab Duo Agent Platform Flows**（18.3+）是官方验证模式，证明 Issue→Agent→MR 闭环可行
- `glab` CLI 完整支持 Issue CRUD + label 驱动状态机 + `--output json` 机器可读 + `related_issues` API
- 现有 9 个 agent 中：6 个角色 agent 影响中等（需 prompt 优化），3 个领航 agent 几乎不受影响
- 当前 hero 体系通过飞书 PRD 走重型线，没有外部 issue tracker 集成
- Issue 层级建模：主 Issue（PRD/Feature 级）↔ 子 Issue（具体任务）通过 `related_issues` 关联

**当前 Hero 任务来源机制**（3 通道）:

```
1. 自然语言 → hero-dispatch → 8 条 lane → role agent
2. 飞书 PRD URL → hero-prd-to-java → 8 步工作流 → 多 agent 并行
3. 用户直接 agent 调用 → 匹配 description 触发
```

→ **新增第 4 通道**：GitLab Issue → hero-dispatch issue lane → role agent

### Metis Review

**Identified Gaps** (addressed):

1. **多 project 场景**: dispatch 怎么知道操作哪个 GitLab project？
   → 通过 dispatch 输入时指定 `--repo` 或 label 中的 `service:<name>`（确定性查表）

2. **并发问题**: 多 agent 同时 polling 会不会冲突？
   → 用 label 状态机：拉取前先把 `status:pending` 改成 `status:in_progress`，其他 agent 看到后 skip

3. **Issue 模板字段 → lane 期望格式的对齐**:
   → 模板字段（Task Type / Requirements / Files / Acceptance Criteria）与 `lanes/issue.md` 的解析格式严格一致

4. **主 Issue 不能被单个 agent 关闭**:
   → Guardrail：所有 role agent 的 prompt 中明确禁止关闭主 Issue，只能关自己的子 Issue

5. **领航 agent 查询范围**:
   → 领航 agent 保持只读；glab 查询仅限本服务的 issue/MR，不跨服务污染

---

## Work Objectives

### Core Objective

让 claude-hero 体系能从 GitLab Issue 拉任务并在 Issue 中汇报执行结果，支持"人建主 Issue + tech-lead 拆子 Issue"的分层协作模式，并让领航 agent 能查询本项目服务的 GitLab 元数据。

### Concrete Deliverables

- `.gitlab/issue_templates/AgentTask.md` — 子 Issue 模板（给单个 agent 用）
- `.gitlab/issue_templates/FeatureRequest.md` — 主 Issue 模板（PRD/Feature 级）
- `skills/hero-glab/SKILL.md` 扩展版 — 加 Issue 工作流命令
- `skills/hero-dispatch/lanes/issue.md` — 新路由 lane 处理 Issue 输入
- `skills/hero-dispatch/SKILL.md` 更新 — 8 条 lane → 9 条
- `scripts/hero-issue-poller.sh` — 轮询入口脚本
- 6 个角色 agent prompt 优化
- `templates/navigator-agent.md.tmpl` 加 GitLab 只读查询
- `scripts/hero-init.sh` 加 GitLab project 配置阶段
- `README.md` 加 Issue 集成章节
- `site/public/index.html` 加 Issue 工作流演示章节
- `site/public/css/main.css` 加 Issue 演示样式

### Definition of Done

- [ ] 人可手动 `glab issue create --template AgentTask` 建 issue
- [ ] tech-lead 能从主 issue 自动拆子 issue（建 `related_issues` 关联）
- [ ] role agent 能从 `glab issue view <iid>` 获取任务上下文
- [ ] agent 完成后 `glab issue note` (评论) + `glab issue close` (关闭自己的子 issue)
- [ ] MR 创建带 `--related-issue <iid>`
- [ ] 领航 agent 能用 glab 查询本项目服务的相关 issue/MR
- [ ] `scripts/hero-issue-poller.sh` 可轮询 `agent:<name>` 标签的 pending issues 并调用 dispatch
- [ ] README 和主页体现 Issue 集成

### Must Have

- Issue label 状态机：`agent:<name>` + `status:pending|in_progress|done`
- 模板字段与 lane 格式对齐：Task Type / Requirements / Files to Modify / Acceptance Criteria
- tech-lead 拆子 issue 时要建 `related_issues` 关联
- agent 汇报必须：评论内容（做了什么 + diff 摘要 + 验证状态）+ 关联 MR（如建了）+ 关 issue
- MR 创建必须带 `--related-issue <iid>`
- 状态推进通过 **label 修改**（不依赖 assignee）

### Must NOT Have (Guardrails)

- ❌ 不替换飞书 PRD 线——Issue 是**额外通道**
- ❌ 不修改领航 agent 的核心只读导航职责（只扩展查询能力）
- ❌ role agent 不允许关闭**主 Issue**（只能关自己的子 Issue）
- ❌ 不在 issue 描述中嵌入敏感信息（token / password）— glab 不存储凭据
- ❌ 不自动创建 GitLab project 或改项目设置（用户先手动配置 Issue Board + Labels + 模板）
- ❌ 不修改现有 `lanes/bugfix|iterate|refactor|perf|security|research|prd|refresh` 的既有逻辑
- ❌ 不让 agent 自动 approve 自己的 MR（保持玄成/鹏举的评审门控）

---

## Verification Strategy

> ZERO HUMAN INTERVENTION — 全部 agent-executed QA，无手工介入。

### Test Decision
- **Infrastructure exists**: YES（`tests/` 目录已有 dispatch / refresh / 分层测试）
- **Automated tests**: NO（本次是 prompt 优化 + skill 扩展，不适合传统单元测试）
- **Agent-Executed QA**: MANDATORY — 每个 task 都有具体 QA 场景

### QA Policy

每个 task 必须有 agent-executable 的 QA 场景：
- **模板任务**: 用 Bash 验证模板文件存在、Markdown 语法合法、字段完整
- **Skill 任务**: 用测试 prompt 触发 skill，验证 glab 命令被正确调用
- **Prompt 优化任务**: 用真实 GitLab issue iids 测试 agent 能否从 issue 读上下文并执行
- **领航 agent**: 用真实 GitLab project 测试查询能力
- **脚本任务**: Bash 执行 + 输出断言

Evidence 保存到 `.omo/evidence/task-{N}-{scenario-slug}.{ext}`。

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1（基础设施，并行独立）:
├── Task 1: .gitlab/issue_templates/AgentTask.md + FeatureRequest.md — quick
├── Task 2: 扩展 skills/hero-glab/SKILL.md (加 Issue 工作流) — unspecified-high
└── Task 3: 更新 templates/navigator-agent.md.tmpl (加 GitLab 查询) — quick

Wave 2（路由层 + 入口，依赖 Wave 1）:
├── Task 4: skills/hero-dispatch/lanes/issue.md — deep
└── Task 5: scripts/hero-issue-poller.sh 轮询脚本 — quick

Wave 3（角色 agent prompt，依赖 Wave 1+2）:
├── Task 6: hero-java-tech-lead.md 加 issue 拆解能力 — unspecified-high
├── Task 7: hero-java-backend-developer.md 加 issue context — unspecified-high
├── Task 8: hero-java-data-engineer.md 加 issue context — unspecified-high
├── Task 9: hero-java-test-engineer.md 加 issue context — unspecified-high
├── Task 10: hero-java-code-reviewer.md 加 MR-issue 关联 — unspecified-high
└── Task 11: hero-java-security-auditor.md 加 MR-issue 关联 — unspecified-high

Wave 4（hero-init + 文档主页，依赖 Wave 2+3）:
├── Task 12: scripts/hero-init.sh GitLab project 配置阶段 — unspecified-high
├── Task 13: README.md 加 Issue 集成章节 — writing
└── Task 14: site/public/index.html 加 Issue 工作流演示 — visual-engineering

Final Verification:
├── F1: Plan Compliance Audit (oracle)
├── F2: Skill Trigger Test (unspecified-high)
├── F3: End-to-End Issue Workflow (unspecified-high)
└── F4: Prompt Regression Check (deep)

Critical Path: Task 2 → Task 4 → Task 6 → Task 12 → F1-F4
Parallel Speedup: ~60% (vs 串行)
Max Concurrent: 6 (Wave 3)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 (模板) | — | 4, 6-11 |
| 2 (skill 扩展) | — | 4, 5, 6-11 |
| 3 (领航模板) | — | 12 |
| 4 (lanes/issue.md) | 1, 2 | 6-11, 13, 14 |
| 5 (poller script) | 2 | 13, 14 |
| 6 (tech-lead) | 1, 4 | 7, 12, 13, 14 |
| 7 (backend-dev) | 1, 4 | 12, 13, 14 |
| 8 (data-engineer) | 1, 4 | 12, 13, 14 |
| 9 (test-engineer) | 1, 4 | 12, 13, 14 |
| 10 (code-reviewer) | 1, 4 | 12, 13, 14 |
| 11 (security-auditor) | 1, 4 | 12, 13, 14 |
| 12 (hero-init) | 3, 6-11 | 13, 14 |
| 13 (README) | 4, 5, 6-11, 12 | F1-F4 |
| 14 (index.html) | 4, 5, 6-11, 12, 13 | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: **3** - Task 1 → `quick`, Task 2 → `unspecified-high`, Task 3 → `quick`
- **Wave 2**: **2** - Task 4 → `deep`, Task 5 → `quick`
- **Wave 3**: **6** - Task 6-11 → each `unspecified-high`
- **Wave 4**: **3** - Task 12 → `unspecified-high`, Task 13 → `writing`, Task 14 → `visual-engineering`
- **FINAL**: **4** - F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

> Implementation + Test = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> FORMAT: bare-number task labels (1., 2., 3.) for /start-work counter.

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. 用户确认后才完成。
> **NEVER mark F1-F4 as checked before getting user's okay.**

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. 对每个 "Must Have" 验证实现存在（读文件、跑命令、调 glab）。
  对每个 "Must NOT Have" 在代码库中搜禁止模式——找到即 reject。
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Skill Trigger Test** — `unspecified-high`
  构造测试 prompt：`"拉取待处理的 GitLab issue"`、`"issue #42 上下文"`、`"关闭 issue 并评论"`。
  每个 prompt 触发 hero-glab skill，验证 glab 命令被构造且参数正确。
  Output: `Scenarios [N/N pass] | VERDICT`

- [ ] F3. **End-to-End Issue Workflow** — `unspecified-high`
  在 GitLab 测试 project 创建真实 issue → 派 role agent → 验证 agent 读取 issue、执行任务、评论、关闭 issue（子 issue 仅）。
  Output: `Main Issue [OPEN] | Sub Issues [N/N closed] | Comments [N present] | VERDICT`

- [ ] F4. **Prompt Regression Check** — `deep`
  对比每个被修改的 role agent prompt 与 `HEAD~` 版本：
  - 新增的 glab 指引没有破坏原有角色边界
  - "不关闭主 issue" guardrail 显式写入
  - hero 露出标记 `🦸 hero ▸` 没丢
  Output: `Agents [N/N safe] | Guardrails [N present] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat(gitlab-issue): templates + glab issue skill + navigator template`
- **Wave 2**: `feat(dispatch): issue lane + poller script`
- **Wave 3**: `feat(agents): issue context integration for 6 role agents`
- **Wave 4**: `feat(hero-init + docs): gitlab project config + issue workflow documentation`
- **FINAL**: 4 个 review 通过后再 `feat: finalize gitlab issue integration`

---

## Success Criteria

### Verification Commands
```bash
# 模板存在
ls .gitlab/issue_templates/AgentTask.md .gitlab/issue_templates/FeatureRequest.md

# Skill 触发测试（用 test prompt）
glab issue list --label "agent:backend-dev,status:pending" --output json | jq '.'

# Lane 文件存在
test -f skills/hero-dispatch/lanes/issue.md

# Poller 脚本语法
bash -n scripts/hero-issue-poller.sh

# Role agent prompt 检查
grep -l "glab issue view" agents/hero-java-*.md

# 领航 agent 模板检查
grep "glab" templates/navigator-agent.md.tmpl

# hero-init 新阶段
grep -A5 "check_glab\|gitlab" scripts/hero-init.sh

# README 新章节
grep -c "GitLab Issue" README.md
```

### Final Checklist
- [ ] 2 个 issue 模板存在且字段完整
- [ ] `hero-glab` skill 扩展包含 Issue 工作流
- [ ] `lanes/issue.md` 路由逻辑与模板字段对齐
- [ ] 6 个 role agent prompt 都有 glab issue 操作指引
- [ ] tech-lead prompt 能拆解子 issue 并建 `related_issues`
- [ ] 领航 agent 能查本服务 gitlab issue/MR
- [ ] `hero-init.sh` 新加 GitLab project 配置阶段
- [ ] README 和 index.html 体现 Issue 集成
- [ ] 所有 Must NOT Have 都未破坏
- [ ] Final Wave F1-F4 全部 APPROVE
