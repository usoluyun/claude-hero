# Hero 工作流机制文档整理

## TL;DR

> **Quick Summary**: 把本次会话已讨论的 4 个 hero 机制话题（issue 触发词 / lane 路由 / playbook / 露出规范）+ 3 个未讨论话题（prd-to-java 流水线 / hero-refresh 保鲜 / codegraph 机制）整理成 `docs/hero-workflow/` 子目录下的 8 篇 markdown 文档（1 README + 7 主题），作为团队成员阅读的人读机制指南。
>
> **Deliverables**:
> - `docs/hero-workflow/README.md` — 入口索引 + 推荐阅读顺序
> - `docs/hero-workflow/issue-dispatch.md` — GitLab Issue 触发词机制
> - `docs/hero-workflow/lane-routing.md` — hero-dispatch（意图分诊）+ lane catalog
> - `docs/hero-workflow/playbook.md` — 7 个轻量 lane playbook 的 archetype / STOP / RED 对比
> - `docs/hero-workflow/hero-markers.md` — `🦸 hero ▸` 标记规范 + 双保险 + 英雄名映射
> - `docs/hero-workflow/prd-workflow.md` — hero-prd-to-java 8 步流水线
> - `docs/hero-workflow/refresh.md` — hero-refresh 两段式保鲜
> - `docs/hero-workflow/codegraph.md` — codegraph 作为领航 agent 知识底座
> - 主 `README.md` 追加指向新子目录的链接
>
> **Estimated Effort**: Medium（8 篇 markdown 撰写，每篇 ≤200 行）
> **Parallel Execution**: YES - 2 waves（7 主题文档并行 → README + 主 README 更新）
> **Critical Path**: 7 篇并行 → README 索引 → 主 README 更新 → 验收

---

## Context

### Original Request
用户说："深入 hero 露出规范"，此前已讲解完 4 块机制。最后说"先把这几块都整理成文档放到 docs 里"，经追问确认：
- 范围：已讨论的 4 块 + 未讨论的 3 块（hero-prd-to-java、hero-refresh、codegraph），共 7 主题
- 组织：`docs/hero-workflow/` 子目录

### Interview Summary
**Key Discussions**:
- 已逐一向用户深入讲解过 4 个机制并得到"可以"确认
- 7 主题全部基于**已读**的 SKILL.md 文件（7 个 skill + 9 个 lane + 2 份 docs/ 文档）
- 用户倾向：中文说明、markdown 表格/代码块，便于团队成员一次读完

**Research Findings**:
- 现有 `docs/` 是平铺式；新增子目录是第一次尝试
- 主 README 的"核心子系统"章节（6 个条目）是用户已知入口；新文档需与之互不重叠
- 已有 `site/public/mechanism.html` 机制可视化页，新文档聚焦"文字说明"

### Metis Review
**Identified Gaps**（addressed）:
- **重复源风险**：每篇文档开头加 `> **权威源**：[SKILL.md 路径]` 和 `> **范围**：本文只覆盖...` 声明，明确"解读而非替代"
- **issue vs dispatch 混淆**：issue-dispatch.md 标题改为 `hero-issue-dispatch（GitLab Issue 触发）`，lane-routing.md 标题改为 `hero-dispatch（意图分诊）`
- **playbook 覆盖范围**：playbook.md 明确列出 7 条轻量 lane（mutate/readonly/two-phase/setup），不含 prd/refresh 两条重型线
- **文档膨胀**：每篇硬上限 200 行；术语采用"中文说明 + 英文原名"格式

---

## Work Objectives

### Core Objective
为团队成员产出一套**人读得懂**的 hero 工作流机制指南，覆盖 7 个关键主题，与现有 SKILL.md 互补（解释"为什么这样设计"+"怎么读懂"），不重复 SKILL.md 的完整技术细节。

### Concrete Deliverables
- 8 篇 markdown 文档（`docs/hero-workflow/` 子目录）
- 主 README.md 追加新子目录索引

### Definition of Done
- [ ] `docs/hero-workflow/` 子目录存在且包含 8 个 .md 文件
- [ ] 每篇文档开头都有 `> **权威源**` 和 `> **范围**` 两个声明块
- [ ] 每篇文档 ≤200 行
- [ ] 主 README.md 包含对 `docs/hero-workflow/` 的引用
- [ ] `docs/hero-workflow/README.md` 中 7 个相对链接全部指向真实文件

### Must Have
- 中文说明为主，术语保留英文原名（lane / archetype / STOP / codegraph 等）
- README 包含推荐阅读顺序（按读者画像：新人 / 日常用户 / 贡献者）
- 每篇文档包含 1-2 个示例（从对话中复用的真实对话示例）
- 引用真实存在的 SKILL.md / docs/ 文件路径，不编造
- 用 markdown 表格、代码块、ASCII 流程图组织内容（不引入 mermaid 图，降低维护成本）

### Must NOT Have (Guardrails)
- **不创建第 9 篇文档**（不新增 hero-init、agent-teams 独立话题，仅在相关文档中链接现有 doc）
- **不复制 SKILL.md 完整内容**（只做解读和补充说明）
- **不引入新的机制或重新设计现有机制**（文档是现状的快照）
- **不创建 mermaid 流程图**（维护成本高；ASCII/表格替代）
- **不在文档中硬编码"最后更新日期"**（交给 git history）
- **不改动现有 SKILL.md / docs/*.md**（只新增，只改 README 索引）

### Spec Framework Integration
N/A（本仓库无 OpenSpec / Spec Kit / BMAD）

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO（纯 markdown 文档，无测试基建需要）
- **Automated tests**: None（N/A）
- **Agent-Executed QA**: ALWAYS

### QA Policy
每篇文档由 agent 自测三项：
1. 结构检查（grep `> **权威源**` / `> **范围**`）
2. 行数检查（`wc -l`）
3. 链接有效性（grep + ls 验证相对路径）

Evidence 保存至 `.omo/evidence/task-{N}-*.{ext}`。

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (7 篇主题文档并行撰写，互不依赖):
├── Task 1: issue-dispatch.md（GitLab Issue 触发词） [writing]
├── Task 2: lane-routing.md（意图分诊 + lane catalog） [writing]
├── Task 3: playbook.md（7 个轻量 lane playbook） [writing]
├── Task 4: hero-markers.md（露出规范） [writing]
├── Task 5: prd-workflow.md（8 步流水线） [writing]
├── Task 6: refresh.md（两段式保鲜） [writing]
└── Task 7: codegraph.md（知识底座） [writing]

Wave 2 (After Wave 1 - 索引 + 主 README):
├── Task 8: docs/hero-workflow/README.md（入口索引 + 推荐阅读顺序） [writing]
└── Task 9: 主 README.md 追加 docs/hero-workflow 链接 [quick]

Wave FINAL (并行 4 个 reviewers):
├── F1: Plan Compliance Audit (oracle)
├── F2: 文档质量审查 (unspecified-high) — 行数/声明/链接
├── F3: 内容准确性审查 (deep) — 与 SKILL.md 对照
└── F4: Scope Fidelity (deep) — 不超出 8 篇范围

Critical Path: Wave 1 (max 7 并行) → Wave 2 (max 2 并行) → F1-F4 → user okay
Parallel Speedup: ~60% faster than sequential (7 篇并行)
Max Concurrent: 7 (Wave 1)
```

### Dependency Matrix

- **Task 1-7**: 独立，无前后依赖，可完全并行
- **Task 8**: 依赖 Task 1-7（需要知道每篇标题/摘要）
- **Task 9**: 依赖 Task 8（需要新子目录路径）
- **F1-F4**: 依赖 Task 1-9

### Agent Dispatch Summary

- **Wave 1**: **7 个** `writing` 类别 agent 并行（主题文档撰写）
- **Wave 2**: **2 个**（Task 8 `writing`、Task 9 `quick`）
- **FINAL**: **4 个**（F1 oracle / F2 unspecified-high / F3 deep / F4 deep）

---

## TODOs

> 所有任务使用 bare-number 标签（`1.` `2.` 等），Final Wave 使用 `F1.` `F2.` 等。

- [x] 1. 撰写 `docs/hero-workflow/issue-dispatch.md`（GitLab Issue 触发词机制）

  **What to do**:
  - 开头两块声明：
    ```
    > **权威源**：[`skills/hero-issue-dispatch/SKILL.md`](../../skills/hero-issue-dispatch/SKILL.md)
    > **范围**：本文解读 GitLab Issue 触发词 → 加载 SKILL.md → 路由 agent 的机制，不复制 SKILL.md 全文。
    ```
  - 三层触发机制：Claude Code skill description 语义匹配 → 加载完整 SKILL.md → 按路由表和流程指令执行
  - 触发关键词分类（英文命令 / 中文表达 / 标签名）
  - 路由示例：`issue claim #456` → 读 `hero::agent` 标签 → 路由到对应 agent
  - 引用真实的 SKILL.md 路径（`skills/hero-issue-dispatch/SKILL.md:1-9` frontmatter description）

  **Must NOT do**:
  - 不复制 `hero-issue-dispatch/SKILL.md` 的 8 个命令流程细节，只引用
  - 不创建 mermaid 流程图

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: 无需额外 skill（markdown 撰写）

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Task 2-7 并行）
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-issue-dispatch/SKILL.md:1-9` — frontmatter description 中所有触发关键词
  - `skills/hero-issue-dispatch/SKILL.md:71-83` — 详细路由表（`hero::agent` → 花名映射）
  - 本次对话中已讲解过的"三层触发机制"（Claude 引擎匹配 / 加载 SKILL.md / 路由执行）

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: 结构声明完整
    Tool: Bash (grep)
    Steps:
      1. grep -c "> **权威源**" docs/hero-workflow/issue-dispatch.md
      2. grep -c "> **范围**" docs/hero-workflow/issue-dispatch.md
    Expected: 两个输出都是 1
    Evidence: .omo/evidence/task-1-header-check.out

  Scenario: 行数上限 200 行
    Tool: Bash (wc)
    Steps:
      1. wc -l docs/hero-workflow/issue-dispatch.md
    Expected: ≤ 200 行
    Evidence: .omo/evidence/task-1-line-count.out

  Scenario: 关键词覆盖
    Tool: Bash (grep)
    Steps:
      1. grep -c "issue claim\|issue done\|issue decompose" docs/hero-workflow/issue-dispatch.md
    Expected: ≥ 3（至少覆盖 3 个核心命令）
    Evidence: .omo/evidence/task-1-keyword-check.out
  ```

  **Commit**: NO（groups with 最终 commit）

- [x] 2. 撰写 `docs/hero-workflow/lane-routing.md`（hero-dispatch 意图分诊）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`skills/hero-dispatch/SKILL.md`](../../skills/hero-dispatch/SKILL.md)
    > **范围**：本文解读 hero-dispatch 的 lane catalog 路由表和分诊三段式，不复制 SKILL.md 全文。
    ```
  - 触发机制：`hero <意图>` → description 语义匹配 → 加载 SKILL.md
  - 9 条 lane catalog（prd/refresh/bugfix/iterate/refactor/research/perf/security/team）
  - 分诊三段式：关键词命中 → 语义兜底 → 不确定就 STOP 追问
  - 分类交接：重型线（委派 skill）vs 轻量线（加载 lanes/*.md playbook）
  - 门控骨架两种 archetype 简介（mutate / readonly / two-phase）
  - 示例 1-2 个（从对话复用：`hero 修一下登录报错` → bugfix）

  **Must NOT do**:
  - 不深入 playbook 细节（归 Task 3）
  - 不深入露出标记（归 Task 4）

  **Recommended Agent Profile**:
  - **Category**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-dispatch/SKILL.md:25-35` — lane catalog 路由表
  - `skills/hero-dispatch/SKILL.md:37-56` — 分诊三段式 + 边界判定
  - `skills/hero-dispatch/SKILL.md:65-92` — 门控骨架（Archetype A/B/two-phase）

  **Acceptance Criteria**:

  ```
  Scenario: 结构声明完整
    Tool: Bash (grep)
    Expected: "权威源" 和 "范围" 各 1 处
    Evidence: .omo/evidence/task-2-header-check.out

  Scenario: 行数上限 200 行
    Tool: Bash (wc)
    Expected: ≤ 200 行
    Evidence: .omo/evidence/task-2-line-count.out

  Scenario: 9 条 lane 全覆盖
    Tool: Bash (grep)
    Steps:
      1. grep -cE "prd|refresh|bugfix|iterate|refactor|research|perf|security|team" docs/hero-workflow/lane-routing.md
    Expected: ≥ 9（9 条 lane 关键词各出现 1+）
    Evidence: .omo/evidence/task-2-lane-check.out
  ```

  **Commit**: NO

- [x] 3. 撰写 `docs/hero-workflow/playbook.md`（7 个轻量 lane playbook）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`skills/hero-dispatch/lanes/`](../../skills/hero-dispatch/lanes/)
    > **范围**：本文对比解读 7 个轻量 lane playbook（bugfix/iterate/refactor/research/perf/security/team），不覆盖 prd/refresh 两条重型线。
    ```
  - 说明 9 条 lane 与 7 篇 playbook 的对应关系（prd/refresh 走重型 skill，无 playbook）
  - 按 archetype 分组解读：
    - Mutate（3 个）：bugfix / iterate / refactor
    - Readonly（1 个）：research
    - Two-phase（2 个）：perf / security
    - Setup（1 个特殊情况）：team
  - 对比表：每个 lane 的 RED 测试内容 / STOP 数量 / 特殊产物
  - 每类 archetype 配 1 个简短示例

  **Must NOT do**:
  - 不深入 team lane 的环境检查细节（已写在 SKILL.md 和 CLAUDE.md.example）
  - 不重做 SKILL.md 的完整 frontmatter

  **Recommended Agent Profile**:
  - **Category**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-dispatch/lanes/*.md`（7 个文件各 36-60 行）
  - 对比表的素材来自本次对话中已讨论过的内容
  - `skills/hero-dispatch/SKILL.md:65-92` — archetype 父类定义

  **Acceptance Criteria**:

  ```
  Scenario: 结构声明完整
    Tool: Bash (grep)
    Expected: "权威源" 和 "范围" 各 1 处
    Evidence: .omo/evidence/task-3-header-check.out

  Scenario: 行数上限
    Tool: Bash (wc)
    Expected: ≤ 200 行
    Evidence: .omo/evidence/task-3-line-count.out

  Scenario: 7 个 lane 全覆盖
    Tool: Bash (grep)
    Steps:
      1. for lane in bugfix iterate refactor research perf security team; do
           grep -c "^# .*${lane}" docs/hero-workflow/playbook.md
         done
    Expected: 每个 lane ≥ 1
    Evidence: .omo/evidence/task-3-lane-check.out
  ```

  **Commit**: NO

- [x] 4. 撰写 `docs/hero-workflow/hero-markers.md`（露出规范）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`skills/hero-conventions/SKILL.md`](../../skills/hero-conventions/SKILL.md)
    > **范围**：本文解读 `🦸 hero ▸` 标记规范的 4 时机 + 双保险机制 + 英雄名映射，不复制 SKILL.md 全文。
    ```
  - 固定 token 一字不改（便于测试卡死）
  - 4 个时机模板（skill 激活 / agent 接手 / STOP 门 / 任务收尾）
  - 双保险机制（编排方主线打 + 子 agent 自己顶部打）
  - 英雄名映射表（9 个 agent 的花名 + 取名理由）
  - 完整生命周期示例（bugfix lane 走一遍）

  **Must NOT do**:
  - 不复制 SKILL.md 的 4 个时机模板表格原文（用解读的方式写）

  **Recommended Agent Profile**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-conventions/SKILL.md:30-48` — hero 露出规范
  - `docs/hero-agent-layers.md:37-52` — 历史英雄代号映射
  - `docs/hero-agent-layers.md:53-61` — 露出标记格式示例

  **Acceptance Criteria**:

  ```
  Scenario: 结构声明 + 行数
    Tool: Bash
    Expected: 权威源和范围各 1 处，行数 ≤ 200
    Evidence: .omo/evidence/task-4-structure.out

  Scenario: 双保险机制出现
    Tool: Bash (grep)
    Expected: "双保险" ≥ 1
    Evidence: .omo/evidence/task-4-dual-insurance.out
  ```

  **Commit**: NO

- [x] 5. 撰写 `docs/hero-workflow/prd-workflow.md`（hero-prd-to-java 8 步流水线）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`skills/hero-prd-to-java/SKILL.md`](../../skills/hero-prd-to-java/SKILL.md)
    > **范围**：本文解读 PRD 驱动开发的 8 步流水线机制，不复制 SKILL.md 全文。
    ```
  - 8 步全景（Step 0-8）的一句话要点 + 对应产物
  - 状态机（intake → designing → planning → dispatched → developing → testing → reviewing → ready-to-merge → merged）
  - Worktree 隔离机制
  - 子服务先行（契约先行）
  - STOP 门控（每步末尾都有，rigid）
  - 触发词速查（3 个：`hero 开发工作流` / `hero 工作流状态` / `hero 合并验证`）
  - 领航 agent 在 4 个 Step 中的插入点

  **Must NOT do**:
  - 不复制 SKILL.md 的每步详细执行内容，只做一句话概要

  **Recommended Agent Profile**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-prd-to-java/SKILL.md:45-445` — 8 步全景
  - `skills/hero-prd-to-java/SKILL.md:509-529` — 状态机
  - `skills/hero-prd-to-java/SKILL.md:454-505` — 7 个关键约定

  **Acceptance Criteria**:

  ```
  Scenario: 8 步全部提及
    Tool: Bash (grep)
    Steps:
      1. grep -cE "Step [0-8]" docs/hero-workflow/prd-workflow.md
    Expected: ≥ 9（0-8 各一次）
    Evidence: .omo/evidence/task-5-steps.out

  Scenario: Worktree 机制
    Tool: Bash (grep)
    Expected: "worktree" ≥ 1
    Evidence: .omo/evidence/task-5-worktree.out
  ```

  **Commit**: NO

- [x] 6. 撰写 `docs/hero-workflow/refresh.md`（hero-refresh 两段式保鲜）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`skills/hero-refresh/SKILL.md`](../../skills/hero-refresh/SKILL.md)
    > **范围**：本文解读 refresh 两段式保鲜机制（确定性脚本 + 漂移评审 gate），不复制 SKILL.md 全文。
    ```
  - 4 个触发词（`hero 刷新` / `hero 刷新 <proj>` / `hero 刷新 评审` / `hero 刷新 状态`）
  - 两段式架构（确定性层脚本 vs 评审层 agent 漂移）
  - Step A-D（确定性产物 / 提交 / 漂移检测 / 生成草稿）
  - 评审 gate（rigid，反编造硬门槛）
  - 提交分离策略（确定性产物一次 commit / 每个 agent 变更单独 commit）
  - "只保鲜不开荒"原则

  **Must NOT do**:
  - 不深入 shell 脚本实现（scripts/hero-refresh.sh）
  - 不深入 hero-init（开荒）流程

  **Recommended Agent Profile**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `skills/hero-refresh/SKILL.md:19-28` — 4 个触发词
  - `skills/hero-refresh/SKILL.md:30-72` — Step A-D
  - `skills/hero-refresh/SKILL.md:73-94` — 评审 gate
  - `skills/hero-refresh/SKILL.md:107-113` — 5 个关键约定

  **Acceptance Criteria**:

  ```
  Scenario: 两段式机制出现
    Tool: Bash (grep)
    Expected: "两段式" ≥ 2
    Evidence: .omo/evidence/task-6-two-phase.out

  Scenario: 反编造硬门槛
    Tool: Bash (grep)
    Expected: "MISSING" 或 "反编造" ≥ 1
    Evidence: .omo/evidence/task-6-anti-fabrication.out
  ```

  **Commit**: NO

- [x] 7. 撰写 `docs/hero-workflow/codegraph.md`（codegraph 知识底座）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：[`docs/codegraph-agent-plan.md`](./codegraph-agent-plan.md) + [`docs/project-agent-cookbook.md`](./project-agent-cookbook.md)
    > **范围**：本文解读 codegraph 如何作为领航 agent 的知识底座，不复制现有 docs 全文。
    ```
  - codegraph 工具简介（v0.9.7，支持 Java/Kotlin，命令 init/index/query/files/callers/callees/impact）
  - 领航 agent 的定位（单服务 + 只读 + codegraph 驱动）
  - 正文七部分解剖（Frontmatter 四段式 command / 正文 7 部分）
  - Evidence Pack 组装流程（codegraph + pom + CLAUDE.md）
  - 与 6 个横向角色 agent 的正交关系
  - 在 hero-prd-to-java 中的 4 个插入点

  **Must NOT do**:
  - 不写"怎么批量生成 agent"的 cookbook 流程（归 project-agent-cookbook.md）
  - 不写"怎么建索引"的具体命令细节

  **Recommended Agent Profile**: `writing`

  **Parallelization**:
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 8
  - **Blocked By**: None

  **References**:
  - `docs/codegraph-agent-plan.md:1-126`（全文）
  - `docs/project-agent-cookbook.md`（如有需要）
  - `skills/hero-prd-to-java/SKILL.md:491-505` — 领航 agent 在 workflow 中的 4 个插入点

  **Acceptance Criteria**:

  ```
  Scenario: codegraph 命令提及
    Tool: Bash (grep)
    Expected: 至少 5 个命令名出现（init/index/query/files/callers 等）
    Evidence: .omo/evidence/task-7-codegraph-commands.out

  Scenario: 领航定位出现
    Tool: Bash (grep)
    Expected: "只读" 和 "codegraph" 各 ≥ 2
    Evidence: .omo/evidence/task-7-navigator-positioning.out
  ```

  **Commit**: NO

---

## Wave 2 Tasks (After Wave 1)

- [x] 8. 撰写 `docs/hero-workflow/README.md`（入口索引 + 推荐阅读顺序）

  **What to do**:
  - 头部两块声明：
    ```
    > **权威源**：本目录 7 篇文档的总入口
    > **范围**：本文提供 7 个主题的概览与推荐阅读顺序，不含任何机制细节。
    ```
  - 子目录总览（一句话说明 7 个主题）
  - **推荐阅读顺序**（按读者画像）：
    - 新成员（没用过 hero）：README → hero-markers → lane-routing → issue-dispatch
    - 日常使用者（想知道为什么这样设计）：lane-routing → playbook → prd-workflow → refresh → codegraph
    - 贡献者（要改 skill/agent）：issue-dispatch → playbook → hero-markers
  - 7 个相对链接 `[主题名](./xxx.md)`
  - 与主 README.md 的关系说明（1 行）
  - 与 `site/public/mechanism.html` 的关系（1 行）

  **Must NOT do**:
  - 不在 README 里重复讲机制
  - 不放 mermaid 图

  **Recommended Agent Profile**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: NO（等待 Task 1-7 完成才能写标题/摘要）
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 9
  - **Blocked By**: Task 1-7

  **References**:
  - 7 篇已完成文档的实际标题

  **Acceptance Criteria**:

  ```
  Scenario: 7 个相对链接全部有效
    Tool: Bash
    Steps:
      1. for f in $(grep -oP '\[.*?\]\(\./\K[^)]+' docs/hero-workflow/README.md); do
           test -f "docs/hero-workflow/$f" && echo "OK $f" || echo "MISSING $f"
         done
    Expected: 全部 "OK"
    Evidence: .omo/evidence/task-8-links.out

  Scenario: 推荐阅读顺序
    Tool: Bash (grep)
    Expected: "新成员" / "日常" / "贡献" 或等价表述各 ≥ 1
    Evidence: .omo/evidence/task-8-reading-order.out

  Scenario: 行数上限
    Tool: Bash (wc)
    Expected: ≤ 100 行（README 应该短）
    Evidence: .omo/evidence/task-8-line-count.out
  ```

  **Commit**: NO

- [x] 9. 主 `README.md` 追加指向 `docs/hero-workflow/` 的索引

  **What to do**:
  - 找到主 README.md 中的"核心子系统"章节（或"文档索引"章节）
  - 在合适位置追加 1 行链接：
    ```
    - [Hero 工作流机制指南](docs/hero-workflow/README.md) — 7 篇机制解读：issue 触发 / lane 路由 / playbook / 露出规范 / PRD 流水线 / refresh 保鲜 / codegraph 知识底座
    ```
  - 不改动其他内容

  **Must NOT do**:
  - 不重写"核心子系统"章节
  - 不移动现有内容
  - 不添加 mermaid 图

  **Recommended Agent Profile**: `quick`

  **Parallelization**:
  - **Can Run In Parallel**: NO（等待 Task 8 完成）
  - **Parallel Group**: Wave 2（与 Task 8 串行）
  - **Blocks**: FINAL
  - **Blocked By**: Task 8

  **References**:
  - 主 `README.md` 当前"核心子系统"章节位置（约 line 110-118）
  - `docs/hero-workflow/README.md` 标题（Task 8 的产物）

  **Acceptance Criteria**:

  ```
  Scenario: 链接存在且指向真实文件
    Tool: Bash
    Steps:
      1. grep -c "hero-workflow" README.md
      2. test -d docs/hero-workflow && echo "DIR OK" || echo "DIR MISSING"
    Expected: 1+ 处引用；目录存在
    Evidence: .omo/evidence/task-9-main-readme.out
  ```

  **Commit**: YES（groups with 最终 commit）
  - Message: `docs(workflow): 新增 hero 工作流机制指南（docs/hero-workflow/）`
  - Files: `docs/hero-workflow/*.md`（8 个）+ `README.md`（追加链接）
  - Pre-commit: 无需

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
  读完整 plan + 8 个新文档。对照"Must Have"逐项 grep 验证存在；对照"Must NOT Have"搜索违禁模式（mermaid 图 / 第 9 篇文档 / 硬编码日期）。输出：`Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT`

- [ ] F2. **文档质量审查** — `unspecified-high`
  对 7 个主题文档逐一：`wc -l` 检查 ≤200 行；`grep "权威源"` 和 `grep "范围"` 检查声明；`grep -oP '\[.*?\]\([\./]+\K[^)]+'` 提取相对链接并 `test -f` 验证存在。主 README 的 hero-workflow 引用必须存在。
  输出：`Lines [N/7 ≤200] | Headers [N/7] | Links [N/N valid] | VERDICT`

- [ ] F3. **内容准确性审查** — `deep`
  对照各 SKILL.md 原文，验证每篇文档的关键词、示例、引用路径真实存在（不编造）。检查"中文 + 英文原名"的术语一致性。检查 issue-dispatch vs hero-dispatch 在标题和开头是否清晰区分。
  输出：`Facts [N/N 无编造] | Terminology [PASS/FAIL] | Distinction [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  验证没有新增第 9 篇文档、没有新机制设计、没有改动 SKILL.md；README 只追加了 1 行链接，未重写其他内容。
  输出：`Files [8 个 .md, 符合 8 篇封顶] | Scope [CLEAN / N issues] | VERDICT`

---

## Commit Strategy

所有 8 个新文档 + 主 README 追加链接合并为**一次** commit：

```
docs(workflow): 新增 hero 工作流机制指南（docs/hero-workflow/）

新增 8 篇 markdown 文档，整理本次会话已讨论的 4 个机制 + 3 个未讨论机制
的解读性说明，作为团队成员阅读的人读机制指南：

- docs/hero-workflow/README.md：入口索引 + 推荐阅读顺序
- issue-dispatch.md / lane-routing.md / playbook.md：路由体系
- hero-markers.md / prd-workflow.md / refresh.md / codegraph.md：配套机制

每篇文档开头声明权威源和范围，行数 ≤200，与现有 SKILL.md 互补解读。
主 README.md 追加指向子目录的索引。

Files: docs/hero-workflow/*.md(8 个) + README.md
```

---

## Success Criteria

### Verification Commands
```bash
# 1. 文件数检查
ls docs/hero-workflow/ | wc -l  # Expected: 8

# 2. 行数检查（每篇 ≤200）
wc -l docs/hero-workflow/*.md   # Expected: 每篇 ≤200

# 3. 结构声明检查（每篇 1 个权威源 + 1 个范围声明）
grep -c "> **权威源**" docs/hero-workflow/*.md  # Expected: 每个文件 = 1
grep -c "> **范围**" docs/hero-workflow/*.md    # Expected: 每个文件 = 1

# 4. README 内链有效
for f in $(grep -oP '\[.*?\]\(\./\K[^)]+' docs/hero-workflow/README.md); do
  test -f "docs/hero-workflow/$f.md" && echo "OK $f" || echo "MISSING $f"
done  # Expected: 全部 OK

# 5. 主 README 包含新子目录引用
grep "hero-workflow" README.md  # Expected: 至少 1 处
```

### Final Checklist
- [ ] 8 个 docs/hero-workflow/*.md 全部存在
- [ ] 每篇 ≤200 行
- [ ] 每篇包含 `> **权威源**` 和 `> **范围**` 声明
- [ ] README.md 有推荐阅读顺序
- [ ] 主 README.md 引用新子目录
- [ ] 未新增第 9 篇文档
- [ ] 未改动任何现有 SKILL.md / docs/*.md
