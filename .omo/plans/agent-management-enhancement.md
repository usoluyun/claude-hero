# Agent Management Enhancement (OMC-Inspired)

## TL;DR

> **Quick Summary**: 参考 oh-my-claudecode 的 agent 管理模式，对 claude-hero 的 9 个 agent 进行结构化重写（5 章节模板）、建立 AGENTS.md 元数据注册、引入 .omo/state/ 通用状态层。
>
> **Deliverables**:
> - 9 个 agent prompt 按 5 章节模板全量重写
> - `agents/AGENTS.md` 元数据注册表
> - `.omo/state/` 状态目录 + schema
> - `templates/navigator-agent.md.tmpl` 模板更新
> - manifest.yaml + .gitignore 更新
> - 4 个验证脚本
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 5 波，最大并发 6（Wave 2）
> **Critical Path**: Task 1 → Task 5 → Task 15 → Task 20 → F1-F4 → user okay

---

## Context

### Original Request
"参考 oh-my-claudecode，如何能正确管理多个 agents"

### Interview Summary
**Key Discussions**:
- **OMC 架构深入研究**：19 agent / 35 skill / XML 结构化 prompt / TypeScript 注册层 / 模型三级路由 / Team mode 5 阶段流水线 / per-agent benchmarks / per-agent disallowedTools
- **claude-hero 现状盘点**：9 agent（6 角色型 + 3 项目型）/ 双轴分层 / 47 skill / manifest.yaml + install.sh / 花名体系
- **用户核心决策**：
  - Agent Prompt 结构 → 自由文本 + 强化模板（5 章节）
  - 注册机制 → agents/AGENTS.md 元数据文件
  - 状态持久化 → .omo/state/ 目录
  - 迁移策略 → 全量迁移 9 个 agent
  - disallowedTools → 写入 Constraints 章节（Claude Code 不支持 frontmatter disallowedTools）

**Research Findings**:
- OMC 用 TypeScript 注册层 + 自动模型路由，太重不适合 claude-hero 的 markdown-first 理念
- Claude Code 的权限控制靠 `tools:` 白名单，5 个只读 agent 已通过不列 Write/Edit 实现
- `docs/.refresh-state.json`（3 项目刷新记账）和 `docs/.workflow-registry.json`（PRD 工作流注册）是当前分散的状态文件
- `templates/navigator-agent.md.tmpl` 有 244 行 / 60+ Mustache 占位符，是 hero-init.sh 的模板

### Metis Review
**Identified Gaps** (addressed):
- **Q1 disallowedTools 技术可行性**: Claude Code 不支持 `disallowedTools` frontmatter → Constraints 章节作文档声明，保留 `tools:` 白名单不动
- **Q2 .omo/state/ 共享策略**: 仓库级，`*.json` git 跟踪，`.cache/` gitignore
- **Q3 AGENTS.md 格式**: YAML frontmatter + structured YAML field blocks
- **Q4 navigator-agent.md.tmpl 同步**: 纳入本次范围，作为第 6 个交付件
- **Q5 skills: frontmatter**: 保留不变，AGENTS.md 记录 skills 映射

---

## Work Objectives

### Core Objective
提升 claude-hero 多 agent 的可维护性、可发现性和一致性，参考 OMC 的最佳设计实践，适配自身 markdown-first 轻量架构。

### Concrete Deliverables
- 9 个 agents/hero-*.md 按 5 章节模板重写
- agents/AGENTS.md 元数据注册表
- .omo/state/ 目录 + JSON schema
- templates/navigator-agent.md.tmpl 更新
- manifest.yaml 新增 .omo/state/ entry
- .gitignore 新增 .omo/state/.cache/
- scripts/validate-* 验证脚本（4 个）

### Definition of Done
- [x] 所有 9 个 agent 包含 5 个必需章节
- [ ] AGENTS.md 覆盖所有 9 个 agent
- [ ] .omo/state/ 包含完整 schema 文档
- [ ] manifest.yaml 正确引用 .omo/state/
- [ ] 验证脚本全部 PASS
- [ ] install.sh 在隔离环境 PASS
- [ ] agent 路由测试通过

### Must Have
- 9 个 agent 全部按 5 章节模板重写（Role / Success Criteria / Constraints / Failure Modes / Final Checklist）
- 只读 agent（玄成/鹏举/子文/郑和/霞客）的 Constraints 章节写明 tools 限制
- AGENTS.md 机器可解析
- .omo/state/ 从 docs/.refresh-state.json 和 docs/.workflow-registry.json 迁移
- navigator-agent.md.tmpl 与 5 章节模板对齐
- 每个 task 包含 agent-executed QA scenarios

### Must NOT Have (Guardrails)
- 不引入 XML 结构化 body
- 不引入 TypeScript 注册层
- 不引入 per-agent benchmark
- 不修改任何 agent 的 model 字段
- 不修改任何 agent 的文件名
- 不修改 tools: 白名单字段
- 不触碰 cli/ 目录
- 不修改 agent 的 frontmatter description 字段
- 不引入新的 frontmatter 字段（Claude Code 不支持的）
- 不重新排序 frontmatter 字段顺序

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES（bash 脚本验证）
- **Automated tests**: Tests-after（验证脚本，非 TDD）
- **Framework**: bash
- **Agent-Executed QA**: 每个任务 mandatory

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.omo/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Markdown 结构**: grep 验证章节存在
- **Schema 一致性**: jq / yq 验证 JSON/YAML 结构
- **安装验证**: `CLAUDE_HOME=/tmp/test-hero bash install.sh`
- **Agent 路由**: 触发 hero-dispatch 验证路由正确

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - Foundation & Shared Specs):
├── 1. Define 5-Chapter Template Spec [quick]
├── 2. Define AGENTS.md YAML Schema [quick]
└── 3. Define .omo/state/ Directory Schema [quick]

Wave 2 (After Wave 1 - Role Agent Migration, MAX PARALLEL):
├── 4. Rewrite 孔明 (tech-lead) to 5-Chapter [unspecified-high]
├── 5. Rewrite 文远 (backend-dev) to 5-Chapter [unspecified-high]
├── 6. Rewrite 子长 (data-engineer) to 5-Chapter [unspecified-high]
├── 7. Rewrite 希仁 (test-engineer) to 5-Chapter [unspecified-high]
├── 8. Rewrite 玄成 (code-reviewer) to 5-Chapter [unspecified-high]
└── 9. Rewrite 鹏举 (security-auditor) to 5-Chapter [unspecified-high]

Wave 3 (After Wave 1 - Navigator Agent Migration, MAX PARALLEL):
├── 10. Rewrite 子文 (ecrm) to 5-Chapter [unspecified-high]
├── 11. Rewrite 郑和 (hotel-product) to 5-Chapter [unspecified-high]
└── 12. Rewrite 霞客 (owner-biz) to 5-Chapter [unspecified-high]

Wave 4 (After Wave 2 & 3 - Infrastructure Integration):
├── 13. Update navigator-agent.md.tmpl [unspecified-high]
├── 14. Populate AGENTS.md with All 9 Agents [quick]
├── 15. Initialize .omo/state/ + Migrate State Files [quick]
└── 16. Update manifest.yaml + .gitignore [quick]

Wave 5 (After Wave 4 - Verification Tooling):
├── 17. Template Compliance Validator Script [quick]
├── 18. AGENTS.md ↔ roster.md Consistency Checker [quick]
├── 19. State Migration Integrity Checker [quick]
└── 20. Install.sh Isolated Environment Test [quick]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── F1. Plan compliance audit (oracle)
├── F2. Code quality review (unspecified-high)
├── F3. Manual QA full pass (unspecified-high)
└── F4. Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: 1 → 4 → 13 → 15 → 17 → F1-F4 → user okay
Parallel Speedup: ~65% faster than sequential
Max Concurrent: 6 (Wave 2)
```

### Dependency Matrix

| Task | Blocked By | Blocks |
|------|-----------|--------|
| 1 | - | 4-12, 13, 14, 17 |
| 2 | - | 14, 18 |
| 3 | - | 15, 19 |
| 4 | 1 | 14, 13 |
| 5 | 1 | 14 |
| 6 | 1 | 14 |
| 7 | 1 | 14 |
| 8 | 1 | 14 |
| 9 | 1 | 14 |
| 10 | 1 | 13 |
| 11 | 1 | 13 |
| 12 | 1 | 13 |
| 13 | 1, 10, 11, 12 | 20 |
| 14 | 2, 4-9 | 18 |
| 15 | 3 | 19 |
| 16 | 15 | 20 |
| 17 | 1, 4-12 | 20 |
| 18 | 2, 14 | 20 |
| 19 | 3, 15 | 20 |
| 20 | 16, 17, 18, 19 | F1-F4 |

### Agent Dispatch Summary

- **1**: **3** - T1-T3 → `quick`
- **2**: **6** - T4-T9 → `unspecified-high`
- **3**: **3** - T10-T12 → `unspecified-high`
- **4**: **4** - T13-T14 → `quick` / T13 → `unspecified-high`, T15-T16 → `quick`
- **5**: **4** - T17-T20 → `quick`
- **FINAL**: **4** - F1 → `oracle`, F2-F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

> **FORMAT**: Task labels use bare numbers: `1.`, `2.`, `3.`.
> Final Verification Wave labels use `F1.`, `F2.`, etc.

- [x] 1. 定义 5 章节模板规范（Agent Prompt Template Spec）

  **What to do**:
  - 在 `docs/` 下新建 `agent-prompt-template-spec.md`，明确定义每个 agent prompt 必须包含的 5 个章节
  - 章节：`## Role` / `## Success Criteria` / `## Constraints` / `## Failure Modes` / `## Final Checklist`
  - 为每个章节写 2-3 行示例说明应包含什么内容
  - 明确角色型 agent（可执行）与领航型 agent（只读）的 Constraints 章节差异

  **Status**: ✅ COMPLETE - `docs/agent-prompt-template-spec.md` exists with all 5 chapters defined

  **Must NOT do**:
  - 不引入 XML 标签或任何 Claude Code 不解析的结构
  - 不修改 frontmatter 字段定义

  **Recommended Agent Profile**:
  > - **Category**: `writing`
  >   Reason: 写规范文档，需要清晰准确的技术表述
  > - **Skills**: 无特殊 skill 依赖
  > - **Skills Evaluated but Omitted**:
  >   - `hero-conventions`: 不直接涉及 agent prompt 格式约定

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 1 内并行）
  - **Parallel Group**: Wave 1（with Tasks 2, 3）
  - **Blocks**: 4-12, 13, 14, 17
  - **Blocked By**: None（Wave 1 首个任务）

  **References**:
  - `agents/hero-java-backend-developer.md` - 当前自由文本格式示例，用于理解原有结构
  - `templates/navigator-agent.md.tmpl` - 领航 agent 模板，了解领航型 agent 的特殊约束
  - OMC `agents/executor.md` — 参考其 XML 结构中的 Role/Constraints/Failure_Modes/Checklist 章节组织方式（仅借鉴内容组织，不抄 XML）

  **Acceptance Criteria**:
  - [ ] `docs/agent-prompt-template-spec.md` 存在且包含 5 个章节的完整定义
  - [ ] 角色型 vs 领航型差异说明存在
  - [ ] 每个章节至少有 2 行示例

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 模板规范文件完整性验证
    Tool: Bash
    Precondition: 文件已创建
    Steps:
      1. 运行: test -f docs/agent-prompt-template-spec.md && echo "EXISTS"
      2. 运行: grep -c "^## " docs/agent-prompt-template-spec.md
    Expected Result: 文件存在，包含 5 个章节定义
    Failure Indicator: grep 返回 < 5 或文件不存在
    Evidence: .omo/evidence/task-1-template-spec-exists.txt
  ```

  **Commit**: YES
  - Message: `docs(agents): add 5-chapter prompt template spec`
  - Files: `docs/agent-prompt-template-spec.md`
  - Pre-commit: `test -f docs/agent-prompt-template-spec.md && grep -c "^## " docs/agent-prompt-template-spec.md`

---

- [x] 2. 定义 AGENTS.md YAML Schema（Agent Metadata Schema）

  **What to do**:
  - 在 `docs/` 下新建 `agents-md-schema.md`，定义 `agents/AGENTS.md` 的结构
  - 格式：每个 agent 用 YAML frontmatter 字段描述，字段包括：name、display_name（花名）、model、role_type、readonly、skills、triggers、tools_count
  - 明确 AGENTS.md 与 docs/hero-agent-roster.md 的关系
  - 定义权威性：agent name 字段必须与 frontmatter `name` 字段一致

  **Status**: ✅ COMPLETE - `docs/agents-md-schema.md` exists with full YAML schema definition

  **Must NOT do**:
  - 不引入 JSON schema 文件（保持 markdown-first）
  - 不实现 TypeScript 解析层
  - 不修改 hero-agent-roster.md（那是给人看的，本次不改）

  **Recommended Agent Profile**:
  > - **Category**: `writing`
  >   Reason: 技术 schema 文档，需要精确的字段定义
  > - **Skills**: 无特殊 skill

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 1 内并行）
  - **Parallel Group**: Wave 1（with Tasks 1, 3）
  - **Blocks**: 14, 18
  - **Blocked By**: None

  **References**:
  - `docs/hero-agent-roster.md` - 当前花名表，理解需要覆盖的字段
  - `docs/hero-agent-layers.md` - 理解双轴分层（角色型 vs 项目型）
  - `agents/hero-java-tech-lead.md`（frontmatter 示例，含 `skills:` 字段）

  **Acceptance Criteria**:
  - [ ] `docs/agents-md-schema.md` 存在
  - [ ] 定义了 name / display_name / model / role_type / readonly / skills / triggers 字段
  - [ ] 说明了与 roster.md 的权威性关系

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Schema 文档覆盖所有必需字段
    Tool: Bash
    Steps:
      1. 运行: test -f docs/agents-md-schema.md && echo "EXISTS"
      2. 运行: for field in name display_name model role_type readonly skills triggers; do grep -q "$field" docs/agents-md-schema.md && echo "OK: $field"; done
    Expected Result: 7 个字段全部 grep 到
    Failure Indicator: 任何字段缺失
    Evidence: .omo/evidence/task-2-schema-fields.txt
  ```

  **Commit**: YES
  - Message: `docs(agents): define AGENTS.md YAML schema`
  - Files: `docs/agents-md-schema.md`
  - Pre-commit: `test -f docs/agents-md-schema.md`

---

- [x] 3. 定义 .omo/state/ 目录结构 + JSON Schema（State Directory Schema）

  **What to do**:
  - 在 `docs/` 下新建 `omo-state-schema.md`，定义 `.omo/state/` 的目录结构和 JSON schema
  - 目录布局：refresh-state.json / workflow-registry.json / agent-executions.json / .cache/
  - 定义每个文件的字段、类型、示例
  - 明确迁移策略和 Git 追踪策略

  **Status**: ✅ COMPLETE - `docs/omo-state-schema.md` exists with full directory structure and JSON schemas

  **Must NOT do**:
  - 不实际迁移文件（task 15 负责）
  - 不修改现有 `docs/.refresh-state.json` 内容
  - 不在 `.omo/` 下存放非 state 内容（plans/drafts 已有独立目录）

  **Recommended Agent Profile**:
  > - **Category**: `writing`
  >   Reason: 技术 schema 文档，需要精确的 JSON 结构定义
  > - **Skills**: 无特殊 skill

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 1 内并行）
  - **Parallel Group**: Wave 1（with Tasks 1, 2）
  - **Blocks**: 15, 19
  - **Blocked By**: None

  **References**:
  - `docs/.refresh-state.json` - 现有刷新状态格式，理解字段结构
  - `docs/.workflow-registry.json` - 现有 PRD 工作流注册格式
  - `scripts/lib/refresh-state.sh` - 读写 .refresh-state.json 的脚本，理解消费者

  **Acceptance Criteria**:
  - [ ] `docs/omo-state-schema.md` 存在
  - [ ] 定义了 refresh.json / workflow-registry.json / agent-executions.json 三个文件 schema
  - [ ] 定义了 .cache/ gitignore 策略

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: State schema 文档完整性
    Tool: Bash
    Steps:
      1. 运行: test -f docs/omo-state-schema.md && echo "EXISTS"
      2. 运行: grep -q "refresh.json" docs/omo-state-schema.md && echo "REFRESH_OK"
      3. 运行: grep -q "workflow-registry.json" docs/omo-state-schema.md && echo "WORKFLOW_OK"
      4. 运行: grep -q "agent-executions.json" docs/omo-state-schema.md && echo "EXEC_OK"
      5. 运行: grep -q "gitignore" docs/omo-state-schema.md && echo "GITIGNORE_OK"
    Expected Result: 全部 5 项 OK
    Failure Indicator: 任何字段缺失
    Evidence: .omo/evidence/task-3-state-schema.txt
  ```

  **Commit**: YES
  - Message: `docs(state): define .omo/state/ directory schema`
  - Files: `docs/omo-state-schema.md`
  - Pre-commit: `test -f docs/omo-state-schema.md`

- [x] 4. 重写 孔明 (hero-java-tech-lead) 到 5 章节模板

  **What to do**:
  - 打开 `agents/hero-java-tech-lead.md`，保留 frontmatter（name/description/model/tools/skills 字段全部不变）
  - 在 prompt body 中重组为 5 个章节：Role / Success Criteria / Constraints / Failure Modes / Final Checklist
  - 保留现有所有指令语义，只做结构重组
  - 角色型 agent，可执行（tools 含 Write/Edit），Constraints 章节不需写"只读"

  **Must NOT do**:
  - 不修改 frontmatter 任何字段
  - 不新增或删除现有指令（只做格式重组）
  - 不改变 tools: 白名单

  **Recommended Agent Profile**:
  > - **Category**: `writing`
  > - **Skills**: 无特殊 skill（纯文档重组）

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2 内并行，6 个 agent 同时改）
  - **Parallel Group**: Wave 2（with Tasks 5-9）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-tech-lead.md` - 当前文件，完整内容
  - `docs/agent-prompt-template-spec.md` - 5 章节规范（task 1 产出）
  - `docs/hero-agent-roster.md` - 确认花名"孔明"和职责描述

  **Acceptance Criteria**:
  - [ ] 文件包含 5 个 `##` 章节（按顺序）
  - [ ] frontmatter 完全未动（git diff 验证）
  - [ ] 原有指令语义全部保留

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-tech-lead.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-4-kongming-chapters.txt

  Scenario: frontmatter 未被修改
    Tool: Bash
    Steps:
      1. 运行: git diff -- agents/hero-java-tech-lead.md | grep "^-.*model:" | wc -l
    Expected Result: 0（model 字段未被修改）
    Failure Indicator: > 0
    Evidence: .omo/evidence/task-4-kongming-frontmatter.txt
  ```

  **Commit**: NO（Wave 2+3 统一提交，见 task 9 后）

---

- [x] 5. 重写 文远 (hero-java-backend-developer) 到 5 章节模板

  **What to do**: 同 Task 4，操作 `agents/hero-java-backend-developer.md`

  **Must NOT do**: 同 Task 4

  **Recommended Agent Profile**:
  > - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2）
  - **Parallel Group**: Wave 2（with Tasks 4, 6-9）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-backend-developer.md`
  - `docs/agent-prompt-template-spec.md`

  **Acceptance Criteria**:
  - [ ] 5 个章节完整
  - [ ] frontmatter 未动

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-backend-developer.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-5-wenyuan-chapters.txt
  ```

  **Commit**: NO（统一提交）

---

- [x] 6. 重写 子长 (hero-java-data-engineer) 到 5 章节模板

  **What to do**: 同 Task 4，操作 `agents/hero-java-data-engineer.md`

  **Must NOT do**: 同 Task 4

  **Recommended Agent Profile**:
  > - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2）
  - **Parallel Group**: Wave 2（with Tasks 4-5, 7-9）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-data-engineer.md`
  - `docs/agent-prompt-template-spec.md`

  **Acceptance Criteria**:
  - [ ] 5 个章节完整
  - [ ] frontmatter 未动

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-data-engineer.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-6-zichang-chapters.txt
  ```

  **Commit**: NO（统一提交）

---

- [x] 7. 重写 希仁 (hero-java-test-engineer) 到 5 章节模板

  **What to do**: 同 Task 4，操作 `agents/hero-java-test-engineer.md`

  **Must NOT do**: 同 Task 4

  **Recommended Agent Profile**:
  > - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2）
  - **Parallel Group**: Wave 2（with Tasks 4-6, 8-9）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-test-engineer.md`
  - `docs/agent-prompt-template-spec.md`

  **Acceptance Criteria**:
  - [ ] 5 个章节完整
  - [ ] frontmatter 未动

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-test-engineer.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-7-xiren-chapters.txt
  ```

  **Commit**: NO（统一提交）

---

- [x] 8. 重写 玄成 (hero-java-code-reviewer) 到 5 章节模板

  **What to do**:
  - 操作 `agents/hero-java-code-reviewer.md`
  - 同 Task 4 的 5 章节结构
  - **特殊**：玄成是**只读评审 agent**，Constraints 章节必须写明：
    > "本 agent 的 `tools:` 白名单不含 Write/Edit，即只读。禁止通过 Bash 执行任何写操作（如 touch、chmod、git commit）。只能阅读代码、运行静态分析（PMD/SpotBugs/semgrep）、输出审查报告。"

  **Must NOT do**: 同 Task 4，额外：不在 Constraints 中引入新的工具限制（tools: 字段已控制）

  **Recommended Agent Profile**:
  > - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2）
  - **Parallel Group**: Wave 2（with Tasks 4-7, 9）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-code-reviewer.md` - 当前只读 agent，tools 不含 Write/Edit
  - `docs/agent-prompt-template-spec.md`

  **Acceptance Criteria**:
  - [ ] 5 个章节完整
  - [ ] Constraints 章节包含只读声明（tools: 白名单说明）
  - [ ] frontmatter 未动

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 只读约束文档化验证
    Tool: Bash
    Steps:
      1. 运行: grep -A5 "## Constraints" agents/hero-java-code-reviewer.md | grep -i "tools.*白名单\|只读\|read.only\|Write.*Edit"
    Expected Result: 找到只读/tools 限制说明
    Failure Indicator: grep 无输出
    Evidence: .omo/evidence/task-8-xuancheng-readonly.txt

  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-code-reviewer.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-8-xuancheng-chapters.txt
  ```

  **Commit**: NO（统一提交）

---

- [x] 9. 重写 鹏举 (hero-java-security-auditor) 到 5 章节模板

  **What to do**:
  - 操作 `agents/hero-java-security-auditor.md`
  - 同 Task 4 的 5 章节结构
  - **特殊**：鹏举同样是**只读评审 agent**，Constraints 章节必须写明：
    > "本 agent 的 `tools:` 白名单不含 Write/Edit，即只读。禁止通过 Bash 执行任何写操作。只能阅读代码、运行 semgrep/OSV-Scanner 扫描、输出安全审计报告。不直接修复漏洞，只报告问题。"

  **Must NOT do**: 同 Task 4

  **Recommended Agent Profile**:
  > - **Category**: `writing`

  **Parallelization**:
  - **Can Run In Parallel**: YES（Wave 2）
  - **Parallel Group**: Wave 2（with Tasks 4-8）
  - **Blocks**: 14
  - **Blocked By**: 1

  **References**:
  - `agents/hero-java-security-auditor.md` - 当前只读 agent
  - `docs/agent-prompt-template-spec.md`

  **Acceptance Criteria**:
  - [ ] 5 个章节完整
  - [ ] Constraints 章节包含只读声明
  - [ ] frontmatter 未动

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 只读约束文档化验证
    Tool: Bash
    Steps:
      1. 运行: grep -A5 "## Constraints" agents/hero-java-security-auditor.md | grep -i "tools.*白名单\|只读\|read.only\|Write.*Edit"
    Expected Result: 找到只读/tools 限制说明
    Failure Indicator: grep 无输出
    Evidence: .omo/evidence/task-9-pengju-readonly.txt

  Scenario: 章节完整性验证
    Tool: Bash
    Steps:
      1. 运行: for chapter in "Role" "Success Criteria" "Constraints" "Failure Modes" "Final Checklist"; do grep -q "^## $chapter" agents/hero-java-security-auditor.md && echo "OK: $chapter"; done
    Expected Result: 5 个章节全部 OK
    Failure Indicator: 任何章节缺失
    Evidence: .omo/evidence/task-9-pengju-chapters.txt

  Scenario: Wave 2 批量提交
    Tool: Bash
    Precondition: Tasks 4-9 全部完成
    Steps:
      1. 运行: git add agents/hero-java-tech-lead.md agents/hero-java-backend-developer.md agents/hero-java-data-engineer.md agents/hero-java-test-engineer.md agents/hero-java-code-reviewer.md agents/hero-java-security-auditor.md
      2. 运行: git diff --cached --stat | wc -l
    Expected Result: 6 个文件已暂存
    Failure Indicator: < 6
    Evidence: .omo/evidence/task-9-wave2-commit.txt
  ```

  **Commit**: YES（Wave 2+3 统一提交）
  - Message: `refactor(agents): rewrite 6 role agents to 5-chapter template`
  - Files: `agents/hero-java-tech-lead.md`, `agents/hero-java-backend-developer.md`, `agents/hero-java-data-engineer.md`, `agents/hero-java-test-engineer.md`, `agents/hero-java-code-reviewer.md`, `agents/hero-java-security-auditor.md`
  - Pre-commit: `for f in agents/hero-java-{tech-lead,backend-developer,data-engineer,test-engineer,code-reviewer,security-auditor}.md; do for c in Role "Success Criteria" Constraints "Failure Modes" "Final Checklist"; do grep -q "^## $c" "$f" || exit 1; done; done`

<!-- WAVE 3 TASKS INSERTED BELOW -->

- [x] 10. Rewrite 子文 (hero-java-ecrm) to 5-Chapter [unspecified-high]

  **What to do**:
  - Open `agents/hero-java-ecrm.md` and rewrite the prompt body using the 5-chapter template structure (Role / Success Criteria / Constraints / Failure Modes / Final Checklist)
  - Preserve all existing content, semantics, and structure — only reorganize into the new format
  - Add a Constraints chapter specific to read-only navigation: "Never modify code, write files, or make recommendations for code changes. Only provide read-only analysis of the ecrm codebase."
  - Ensure Success Criteria clearly state the expected output format (e.g., "Return a navigation summary with file paths, function names, and dependency relationships")
  - Add Failure Modes specific to navigator agents (e.g., "Do not suggest code refactoring, do not write test cases")

  **Must NOT do**:
  - Do not change frontmatter fields (model, tools, description)
  - Do not remove or add semantic content — structure only
  - Do not change the `tools:` whitelist

  **Why it matters**: This is one of three navigator agents that provides read-only guidance for a specific codebase (ecrm). The 5-chapter format makes the agent's constraints explicit and prevents scope creep into implementation tasks.

  **Acceptance criteria**:
  - File `agents/hero-java-ecrm.md` contains exactly 5 top-level sections (Role, Success Criteria, Constraints, Failure Modes, Final Checklist)
  - All original frontmatter fields remain unchanged
  - Constraints chapter explicitly prohibits Write/Edit operations
  - File passes the chapter validation script (task 17)

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate 5-chapter structure present
    Tool: Bash (grep)
    Steps:
      1. for ch in "## Role" "## Success Criteria" "## Constraints" "## Failure Modes" "## Final Checklist"; do grep -q "^$ch$" agents/hero-java-ecrm.md && echo "FOUND: $ch" || echo "MISSING: $ch"; done
      2. Verify all 5 lines say FOUND
    Expected Result: 5/5 chapters found
    Failure Indicator: Any MISSING line
    Evidence: .omo/evidence/task-10-ziewen-chapters-pass.txt

  Scenario: Validate frontmatter unchanged
    Tool: Bash (git diff)
    Steps:
      1. git diff agents/hero-java-ecrm.md | head -5 (should show only body changes below the `---` delimiter)
      2. Verify no lines above the second `---` are modified
    Expected Result: diff starts after the second `---` (body only)
    Failure Indicator: frontmatter lines appear in diff
    Evidence: .omo/evidence/task-10-ziewen-frontmatter-unchanged.txt

  Scenario: Validate Constraints contains read-only wording
    Tool: Bash (grep)
    Steps:
      1. sed -n '/^## Constraints/,/^## /p' agents/hero-java-ecrm.md | grep -i "read-only\|readonly\|do not modify\|never modify" | head -3
    Expected Result: At least 1 match confirming read-only constraint
    Failure Indicator: 0 matches
    Evidence: .omo/evidence/task-10-ziewen-readonly-constraint.txt
  ```

  **Parallelization**: Can run in parallel with tasks 11, 12 (Wave 3)

  **Agent profile**: `unspecified-high`

  **Blocked By**: Task 1 (5-chapter template spec)
  **Blocks**: Task 17 (validate-chapters.sh needs file to exist)

  **Commit**: NO — committed with Wave 2 agents as: `refactor(agents): rewrite 9 hero agents to 5-chapter template`

  **Output files**: `agents/hero-java-ecrm.md`

---

- [x] 11. Rewrite 郑和 (hero-java-hotel-product-center) to 5-Chapter [unspecified-high]

  **What to do**:
  - Open `agents/hero-java-hotel-product-center.md` and rewrite the prompt body using the 5-chapter template structure (Role / Success Criteria / Constraints / Failure Modes / Final Checklist)
  - Preserve all existing content, semantics, and structure — only reorganize into the new format
  - Add a Constraints chapter specific to read-only navigation: "Never modify code, write files, or make recommendations for code changes. Only provide read-only analysis of the hotel-product-center codebase."
  - Ensure Success Criteria clearly state the expected output format (e.g., "Return a navigation summary with file paths, function names, and dependency relationships")
  - Add Failure Modes specific to navigator agents (e.g., "Do not suggest code refactoring, do not write test cases")

  **Must NOT do**:
  - Do not change frontmatter fields (model, tools, description)
  - Do not remove or add semantic content — structure only
  - Do not change the `tools:` whitelist

  **Why it matters**: This is one of three navigator agents that provides read-only guidance for a specific codebase (hotel-product-center). The 5-chapter format makes the agent's constraints explicit and prevents scope creep into implementation tasks.

  **Acceptance criteria**:
  - File `agents/hero-java-hotel-product-center.md` contains exactly 5 top-level sections (Role, Success Criteria, Constraints, Failure Modes, Final Checklist)
  - All original frontmatter fields remain unchanged
  - Constraints chapter explicitly prohibits Write/Edit operations
  - File passes the chapter validation script (task 17)

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate 5-chapter structure present
    Tool: Bash (grep)
    Steps:
      1. for ch in "## Role" "## Success Criteria" "## Constraints" "## Failure Modes" "## Final Checklist"; do grep -q "^$ch$" agents/hero-java-hotel-product-center.md && echo "FOUND: $ch" || echo "MISSING: $ch"; done
      2. Verify all 5 lines say FOUND
    Expected Result: 5/5 chapters found
    Failure Indicator: Any MISSING line
    Evidence: .omo/evidence/task-11-zhenghe-chapters-pass.txt

  Scenario: Validate frontmatter unchanged
    Tool: Bash (git diff)
    Steps:
      1. git diff agents/hero-java-hotel-product-center.md | head -5 (should show only body changes below the `---` delimiter)
      2. Verify no lines above the second `---` are modified
    Expected Result: diff starts after the second `---` (body only)
    Failure Indicator: frontmatter lines appear in diff
    Evidence: .omo/evidence/task-11-zhenghe-frontmatter-unchanged.txt

  Scenario: Validate Constraints contains read-only wording
    Tool: Bash (grep)
    Steps:
      1. sed -n '/^## Constraints/,/^## /p' agents/hero-java-hotel-product-center.md | grep -i "read-only\|readonly\|do not modify\|never modify" | head -3
    Expected Result: At least 1 match confirming read-only constraint
    Failure Indicator: 0 matches
    Evidence: .omo/evidence/task-11-zhenghe-readonly-constraint.txt
  ```

  **Parallelization**: Can run in parallel with tasks 10, 12 (Wave 3)

  **Agent profile**: `unspecified-high`

  **Blocked By**: Task 1 (5-chapter template spec)
  **Blocks**: Task 17 (validate-chapters.sh needs file to exist)

  **Commit**: NO — committed with Wave 2 agents as: `refactor(agents): rewrite 9 hero agents to 5-chapter template`

  **Output files**: `agents/hero-java-hotel-product-center.md`

---

- [x] 12. Rewrite 霞客 (hero-java-owner-biz) to 5-Chapter [unspecified-high]

  **What to do**:
  - Open `agents/hero-java-owner-biz.md` and rewrite the prompt body using the 5-chapter template structure (Role / Success Criteria / Constraints / Failure Modes / Final Checklist)
  - Preserve all existing content, semantics, and structure — only reorganize into the new format
  - Add a Constraints chapter specific to read-only navigation: "Never modify code, write files, or make recommendations for code changes. Only provide read-only analysis of the owner-biz codebase."
  - Ensure Success Criteria clearly state the expected output format (e.g., "Return a navigation summary with file paths, function names, and dependency relationships")
  - Add Failure Modes specific to navigator agents (e.g., "Do not suggest code refactoring, do not write test cases")

  **Must NOT do**:
  - Do not change frontmatter fields (model, tools, description)
  - Do not remove or add semantic content — structure only
  - Do not change the `tools:` whitelist

  **Why it matters**: This is the third navigator agent that provides read-only guidance for a specific codebase (owner-biz). The 5-chapter format makes the agent's constraints explicit and prevents scope creep into implementation tasks.

  **Acceptance criteria**:
  - File `agents/hero-java-owner-biz.md` contains exactly 5 top-level sections (Role, Success Criteria, Constraints, Failure Modes, Final Checklist)
  - All original frontmatter fields remain unchanged
  - Constraints chapter explicitly prohibits Write/Edit operations
  - File passes the chapter validation script (task 17)

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate 5-chapter structure present
    Tool: Bash (grep)
    Steps:
      1. for ch in "## Role" "## Success Criteria" "## Constraints" "## Failure Modes" "## Final Checklist"; do grep -q "^$ch$" agents/hero-java-owner-biz.md && echo "FOUND: $ch" || echo "MISSING: $ch"; done
      2. Verify all 5 lines say FOUND
    Expected Result: 5/5 chapters found
    Failure Indicator: Any MISSING line
    Evidence: .omo/evidence/task-12-xiake-chapters-pass.txt

  Scenario: Validate frontmatter unchanged
    Tool: Bash (git diff)
    Steps:
      1. git diff agents/hero-java-owner-biz.md | head -5 (should show only body changes below the `---` delimiter)
      2. Verify no lines above the second `---` are modified
    Expected Result: diff starts after the second `---` (body only)
    Failure Indicator: frontmatter lines appear in diff
    Evidence: .omo/evidence/task-12-xiake-frontmatter-unchanged.txt

  Scenario: Validate Constraints contains read-only wording
    Tool: Bash (grep)
    Steps:
      1. sed -n '/^## Constraints/,/^## /p' agents/hero-java-owner-biz.md | grep -i "read-only\|readonly\|do not modify\|never modify" | head -3
    Expected Result: At least 1 match confirming read-only constraint
    Failure Indicator: 0 matches
    Evidence: .omo/evidence/task-12-xiake-readonly-constraint.txt
  ```

  **Parallelization**: Can run in parallel with tasks 10, 11 (Wave 3)

  **Agent profile**: `unspecified-high`

  **Blocked By**: Task 1 (5-chapter template spec)
  **Blocks**: Task 17 (validate-chapters.sh needs file to exist)

  **Commit**: NO — committed with Wave 2 agents as: `refactor(agents): rewrite 9 hero agents to 5-chapter template`

  **Output files**: `agents/hero-java-owner-biz.md`

---

## Wave 4 Tasks (13-16)

- [ ] 13. Update navigator-agent.md.tmpl to 5-Chapter Format [quick]

  **What to do**:
  - Open `templates/navigator-agent.md.tmpl` (the Mustache template used by `scripts/hero-init.sh` to generate new navigator agents)
  - Rewrite the template to use the 5-chapter structure (Role / Success Criteria / Constraints / Failure Modes / Final Checklist)
  - Preserve all existing Mustache variables ({{agent_name}}, {{codebase_path}}, {{description}}, etc.)
  - Add Constraints chapter template with read-only restrictions (similar to tasks 10-12)
  - Add Failure Modes template specific to navigator agents
  - Ensure the template generates markdown files that will pass the chapter validation script (task 17)

  **Why it matters**: This template is used by `scripts/hero-init.sh` to generate new navigator agents. Updating it ensures future navigator agents automatically follow the 5-chapter format.

  **Acceptance criteria**:
  - Template `templates/navigator-agent.md.tmpl` contains all 5 chapter headers (Role, Success Criteria, Constraints, Failure Modes, Final Checklist)
  - All original Mustache variables remain unchanged
  - Constraints chapter includes read-only restrictions template
  - Template generates files that pass the chapter validation script (task 17)

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate template has all 5 chapter headers
    Tool: Bash (grep)
    Steps:
      1. for ch in "## Role" "## Success Criteria" "## Constraints" "## Failure Modes" "## Final Checklist"; do grep -qF "$ch" templates/navigator-agent.md.tmpl && echo "FOUND: $ch" || echo "MISSING: $ch"; done
    Expected Result: 5/5 chapters found
    Failure Indicator: Any MISSING line
    Evidence: .omo/evidence/task-13-template-chapters.txt

  Scenario: Validate Mustache variables preserved
    Tool: Bash (grep)
    Steps:
      1. grep -c "{{agent_name}}\|{{AGENT_NAME}}\|{{codebase_path}}\|{{description}}" templates/navigator-agent.md.tmpl
    Expected Result: >= 3 (multiple Mustache variables present)
    Failure Indicator: 0 (variables deleted)
    Evidence: .omo/evidence/task-13-template-mustache-preserved.txt
  ```

  **Agent profile**: `quick`

  **Dependencies**: None (Wave 4, can run in parallel with 14, 15, 16)

  **Output files**: `templates/navigator-agent.md.tmpl`

---

- [ ] 14. Create agents/AGENTS.md Registry File [quick]

  **What to do**:
  - Create `agents/AGENTS.md` following the schema defined in `docs/agents-md-schema.md` (task 2)
  - Include metadata entries for all 9 agents (6 role agents + 3 navigator agents)
  - Each entry should include: agent name, file path, role category, read-only status, and brief description
  - This file serves as a machine-readable registry for tooling and automation

  **Why it matters**: The AGENTS.md file provides a centralized, machine-readable registry of all agents in the project. This enables tools and automation to discover and manage agents programmatically.

  **Acceptance criteria**:
  - File `agents/AGENTS.md` exists and follows the schema defined in task 2
  - Contains metadata entries for all 9 agents
  - Each entry includes: name, file path, role category, read-only status, description
  - File is valid YAML frontmatter format

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate AGENTS.md exists
    Tool: Bash
    Steps:
      1. ls -la agents/AGENTS.md && echo "EXISTS" || echo "MISSING"
    Expected Result: EXISTS
    Failure Indicator: MISSING
    Evidence: .omo/evidence/task-14-agents-md-exists.txt

  Scenario: Validate AGENTS.md has 9 agent entries
    Tool: Bash (grep)
    Steps:
      1. grep -E "^## .+" agents/AGENTS.md | wc -l
      2. grep -E "^## hero-java-" agents/AGENTS.md | wc -l
    Expected Result: >= 9 (at least 9 agent sections)
    Failure Indicator: < 9
    Evidence: .omo/evidence/task-14-agents-md-entries.txt

  Scenario: Validate AGENTS.md has required fields
    Tool: Bash (yq or grep)
    Steps:
      1. grep -E "name:|file_path:|role_category:|read_only:|description:" agents/AGENTS.md | head -20
    Expected Result: Sample of required fields visible
    Failure Indicator: 0 matches (no required fields found)
    Evidence: .omo/evidence/task-14-agents-md-fields.txt
  ```

  **Agent profile**: `quick`

  **Dependencies**: Task 2 (schema definition must be complete)

  **Output files**: `agents/AGENTS.md`

---

- [ ] 15. Initialize .omo/state/ Directory with Migrated JSON Files [quick]

  **What to do**:
  - Create the `.omo/state/` directory structure if it doesn't exist
  - Move `docs/.refresh-state.json` to `.omo/state/refresh-state.json` (preserving content)
  - Move `docs/.workflow-registry.json` to `.omo/state/workflow-registry.json` (preserving content)
  - Create empty JSON files for new state tracking: `.omo/state/agent-executions.json` (initialize with `[]`) and `.omo/state/session-history.json` (initialize with `[]`)
  - Create `.omo/state/.cache/` directory and add `.omo/state/.cache/.gitignore` to ignore all cache files
  - Update root `.gitignore` to add `.omo/state/.cache/` (if not already present)
  - Delete the original files from `docs/` (`.refresh-state.json` and `.workflow-registry.json`) after successful migration

  **Must NOT do**:
  - Do not modify the content of migrated JSON files during migration
  - Do not delete any files other than the original `docs/.refresh-state.json` and `docs/.workflow-registry.json`
  - Do not alter the `.gitignore` of other directories

  **Why it matters**: This consolidates all agent state files into a single `.omo/state/` directory, making it easier to manage, track, and version control agent state. The migration ensures backward compatibility while establishing the new structure.

  **Acceptance criteria**:
  - Directory `.omo/state/` exists
  - Files `.omo/state/refresh-state.json` and `.omo/state/workflow-registry.json` exist with original content preserved
  - Files `.omo/state/agent-executions.json` and `.omo/state/session-history.json` exist (initialized with `[]`)
  - Directory `.omo/state/.cache/` exists with `.gitignore` ignoring all files
  - Root `.gitignore` contains `.omo/state/.cache/`
  - Original files `docs/.refresh-state.json` and `docs/.workflow-registry.json` are deleted

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate state directory structure exists
    Tool: Bash
    Steps:
      1. test -d .omo/state && echo "state dir: OK" || echo "state dir: FAIL"
      2. test -d .omo/state/.cache && echo "cache dir: OK" || echo "cache dir: FAIL"
      3. test -f .omo/state/.cache/.gitignore && echo "cache gitignore: OK" || echo "cache gitignore: FAIL"
    Expected Result: All three lines output OK
    Failure Indicators: Any line outputs FAIL
    Evidence: .omo/evidence/task-15-state-structure.txt

  Scenario: Validate migrated JSON files exist
    Tool: Bash
    Steps:
      1. test -f .omo/state/refresh-state.json && jq empty .omo/state/refresh-state.json && echo "refresh: OK" || echo "refresh: FAIL"
      2. test -f .omo/state/workflow-registry.json && jq empty .omo/state/workflow-registry.json && echo "workflow: OK" || echo "workflow: FAIL"
      3. test -f .omo/state/agent-executions.json && jq empty .omo/state/agent-executions.json && echo "executions: OK" || echo "executions: FAIL"
      4. test -f .omo/state/session-history.json && jq empty .omo/state/session-history.json && echo "history: OK" || echo "history: FAIL"
    Expected Result: All four lines output OK
    Failure Indicators: Any line outputs FAIL
    Evidence: .omo/evidence/task-15-migrated-json.txt

  Scenario: Validate original files deleted
    Tool: Bash
    Steps:
      1. test ! -f docs/.refresh-state.json && echo "old refresh deleted: OK" || echo "old refresh still exists: FAIL"
      2. test ! -f docs/.workflow-registry.json && echo "old workflow deleted: OK" || echo "old workflow still exists: FAIL"
    Expected Result: Both lines output OK
    Failure Indicators: Either line outputs FAIL
    Evidence: .omo/evidence/task-15-old-files-deleted.txt

  Scenario: Validate root gitignore updated
    Tool: Bash
    Steps:
      1. grep -q ".omo/state/.cache" .gitignore && echo "gitignore entry: OK" || echo "gitignore entry: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-15-gitignore-updated.txt
  ```

  **Agent profile**: `quick`

  **Blocked By**: None (Wave 4, can run in parallel with 13, 14, 16)
  
  **Commit**: YES — commit message: `feat(state): add .omo/state/ and migrate JSON from docs/`

  **Output files**: `.omo/state/` directory, `.omo/state/refresh-state.json`, `.omo/state/workflow-registry.json`, `.omo/state/agent-executions.json`, `.omo/state/session-history.json`, `.omo/state/.cache/`, root `.gitignore`

---

- [ ] 16. Update manifest.yaml with .omo/state/ Link Entry [quick]

  **What to do**:
  - Open `manifest.yaml` (the installer manifest used by `install.sh`)
  - Add a new entry under the `link` section for `.omo/state/`:
    ```yaml
    - name: omo-state
      path: .omo/state/
      description: Agent state persistence directory
    ```
  - Ensure the entry follows the same format as other `link` entries in the manifest
  - Update `install.sh` to create `.omo/state/` during installation (if not already handled by the link installer logic)

  **Must NOT do**:
  - Do not modify existing manifest entries
  - Do not remove any `install: true` entries or change their values
  - Do not break YAML syntax

  **Why it matters**: This ensures that `.omo/state/` is properly installed when users run `install.sh`, so agent state persistence works immediately after installation.

  **Acceptance criteria**:
  - `manifest.yaml` contains a new `link` entry for `.omo/state/`
  - Entry follows the same format as other `link` entries
  - `install.sh` creates `.omo/state/` during installation
  - Running `install.sh` in a clean environment successfully installs `.omo/state/`

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Validate manifest entry exists and is correct
    Tool: Bash (yq or grep)
    Steps:
      1. yq '.link[] | select(.path == ".omo/state/")' manifest.yaml
      2. Expected output should contain: name: omo-state, path: .omo/state/, description: Agent state persistence directory, install: false
    Expected Result: Non-empty output from yq with correct name/path/install fields
    Failure Indicators: Empty output or missing install: false field
    Evidence: .omo/evidence/task-16-manifest-entry.txt

  Scenario: Validate YAML syntax
    Tool: Bash (yq)
    Steps:
      1. yq '.' manifest.yaml >/dev/null 2>&1 && echo "YAML valid: OK" || echo "YAML invalid: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-16-yaml-syntax.txt

  Scenario: Validate install script runs correctly
    Tool: Bash
    Steps:
      1. INSTALL_DIR=/tmp/test-hero bash install.sh 2>&1 | tail -20
      2. test -d /tmp/test-hero/.omo/state && echo "state dir installed: OK" || echo "state dir installed: FAIL"
    Expected Result: Both checks pass
    Failure Indicators: State directory not created
    Evidence: .omo/evidence/task-16-install-script.txt
  ```

  **Agent profile**: `quick`

  **Blocked By**: Task 15 (.omo/state/ directory must exist before adding to manifest)
  
  **Commit**: YES — commit message: `feat(manifest): add .omo/state/ as install: false link entry`

  **Output files**: `manifest.yaml`, potentially `install.sh`

---

## Wave 5 Tasks (17-20)

- [ ] 17. Create Chapter Validation Script (validate-chapters.sh) [quick]

  **What to do**:
  - Create `scripts/validate-chapters.sh` that validates agent files follow the 5-chapter format
  - The script should:
    1. Accept a directory path as argument (default: `agents/`)
    2. Find all `hero-*.md` files in the directory (excluding `AGENTS.md`)
    3. For each file, verify it contains exactly 5 top-level headers: `## Role`, `## Success Criteria`, `## Constraints`, `## Failure Modes`, `## Final Checklist`
    4. Output validation results with pass/fail status for each file
    5. Exit with code 1 if any file fails validation, 0 if all pass
  - Make the script executable (`chmod +x`)
  - Handle edge cases: files with no headers, files with extra headers, files with missing headers

  **Must NOT do**:
  - Do not create the script if it already exists and is passing (Wave 5 tasks may run out of order, check first)
  - Do not validate files outside the specified directory
  - Do not modify agent files during validation

  **Why it matters**: This validation script enforces the 5-chapter format across all agent files, ensuring consistency and making it easy to catch formatting errors during development and CI.

  **Acceptance Criteria**:
  - File `scripts/validate-chapters.sh` exists and is executable
  - Script correctly identifies files with missing, extra, or incorrect chapter headers
  - Script exits with code 0 for valid files, 1 for invalid files
  - Script handles edge cases gracefully
  - Running the script on `agents/` after tasks 10-12 returns exit code 0

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Script exists and is executable
    Tool: Bash
    Steps:
      1. test -x scripts/validate-chapters.sh && echo "executable: OK" || echo "executable: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-17-script-exists.txt

  Scenario: Script validates correctly on valid agent files
    Tool: Bash
    Steps:
      1. Test on a known valid agent file (hero-java-code-reviewer.md is fully 5-chapter compliant in current state)
      2. scripts/validate-chapters.sh --file agents/hero-java-code-reviewer.md
    Expected Result: Exit code 0, output indicates "PASS" for that file
    Failure Indicators: Exit code 1 or output indicates "FAIL"
    Evidence: .omo/evidence/task-17-script-validates-valid.txt

  Scenario: Script detects missing chapters correctly
    Tool: Bash
    Steps:
      1. Create a temporary test file with only 3 chapters
      2. echo "## Role\n## Success Criteria\n## Constraints" > /tmp/test-missing.md
      3. scripts/validate-chapters.sh --file /tmp/test-missing.md (should fail)
      4. Verify exit code is 1
    Expected Result: Exit code 1, output shows missing chapters
    Failure Indicators: Exit code 0 or no mention of missing chapters
    Evidence: .omo/evidence/task-17-script-detects-missing.txt

  Scenario: Script validates all agents correctly
    Tool: Bash
    Steps:
      1. scripts/validate-chapters.sh agents/
      2. Count output lines with "PASS:" status
    Expected Result: Exit code 0, exactly 9 files show PASS (6 role + 3 navigator)
    Failure Indicators: Exit code 1 or PASS count != 9
    Evidence: .omo/evidence/task-17-script-validates-all.txt
  ```

  **Agent profile**: `quick`

  **Blocked By**: None (Wave 5, can run in parallel with 18, 19, 20)
  
  **Commit**: YES — commit message: `chore(scripts): add validate-chapters.sh for 5-chapter format enforcement`

  **Output files**: `scripts/validate-chapters.sh`

---

- [ ] 18. Create AGENTS.md Validation Script (validate-agents-md.sh) [quick]

  **What to do**:
  - Create `scripts/validate-agents-md.sh` that validates the `agents/AGENTS.md` registry file
  - The script should:
    1. Parse `agents/AGENTS.md` and extract metadata entries
    2. Find all `hero-*.md` files in `agents/` directory (excluding `AGENTS.md`)
    3. Verify that every agent file has a corresponding entry in `AGENTS.md`
    4. Verify that every entry in `AGENTS.md` has a valid `file_path` that points to an existing file
    5. Output validation results with pass/fail status
    6. Exit with code 1 if validation fails, 0 if all checks pass
  - Make the script executable (`chmod +x`)
  - Handle edge cases: missing AGENTS.md, malformed entries, duplicate entries

  **Must NOT do**:
  - Do not validate content inside agent files (that's validate-chapters.sh's job)
  - Do not require AGENTS.md entries to be in any particular order
  - Do not validate fields beyond what's defined in the task 2 schema

  **Why it matters**: This validation script ensures the AGENTS.md registry stays in sync with actual agent files, preventing drift between the registry and the codebase.

  **Acceptance Criteria**:
  - File `scripts/validate-agents-md.sh` exists and is executable
  - Script correctly identifies missing or invalid registry entries
  - Script exits with code 0 for valid registry, 1 for invalid registry
  - Script handles edge cases gracefully
  - Running the script after task 14 returns exit code 0

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Script exists and is executable
    Tool: Bash
    Steps:
      1. test -x scripts/validate-agents-md.sh && echo "executable: OK" || echo "executable: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-18-script-exists.txt

  Scenario: Script validates valid registry correctly
    Tool: Bash
    Steps:
      1. scripts/validate-agents-md.sh agents/
    Expected Result: Exit code 0, output shows "PASS" for all 9 agents
    Failure Indicators: Exit code 1 or any agent shows FAIL
    Evidence: .omo/evidence/task-18-script-validates-valid.txt

  Scenario: Script detects missing agent in registry
    Tool: Bash
    Steps:
      1. Temporarily rename agents/AGENTS.md to agents/AGENTS.md.bak
      2. Create minimal agents/AGENTS.md with only 1 entry
      3. scripts/validate-agents-md.sh agents/
      4. Verify exit code is 1 and output mentions "8 agents not registered"
      5. Restore original AGENTS.md
    Expected Result: Exit code 1 and output mentions missing agents
    Failure Indicators: Exit code 0 or no mention of missing agents
    Evidence: .omo/evidence/task-18-script-detects-missing.txt

  Scenario: Script detects orphaned registry entry
    Tool: Bash
    Steps:
      1. Temporarily create test AGENTS.md with entry pointing to non-existent file
      2. scripts/validate-agents-md.sh agents/
      3. Verify exit code is 1 and output mentions "orphaned entry"
      4. Restore original AGENTS.md
    Expected Result: Exit code 1 and output mentions orphaned entry
    Failure Indicators: Exit code 0 or no mention of orphan
    Evidence: .omo/evidence/task-18-script-detects-orphaned.txt
  ```

  **Agent profile**: `quick`

  **Blocked By**: Task 14 (AGENTS.md must exist before validation)
  
  **Commit**: YES — commit message: `chore(scripts): add validate-agents-md.sh for registry-sync validation`

  **Output files**: `scripts/validate-agents-md.sh`

---

- [ ] 19. Create State Migration Validation Script (validate-state-migration.sh) [quick]

  **What to do**:
  - Create `scripts/validate-state-migration.sh` that validates the state directory migration
  - The script should:
    1. Verify `.omo/state/` directory exists
    2. Verify all required files exist: `refresh-state.json`, `workflow-registry.json`, `agent-executions.json`, `session-history.json`
    3. Verify `.omo/state/.cache/` directory exists with `.gitignore`
    4. Verify original files (`docs/.refresh-state.json` and `docs/.workflow-registry.json`) no longer exist
    5. Verify `.omo/state/` is listed in `manifest.yaml`
    6. Verify root `.gitignore` contains `.omo/state/.cache/`
    7. Output validation results with pass/fail status
    8. Exit with code 1 if any check fails, 0 if all pass
  - Make the script executable (`chmod +x`)

  **Must NOT do**:
  - Do not validate content inside state files (only existence)
  - Do not create or modify any state files during validation
  - Do not require JSON files to have specific content (empty `[]` is valid)

  **Why it matters**: This validation script ensures the state migration is complete and correct, preventing issues with state persistence and backward compatibility.

  **Acceptance Criteria**:
  - File `scripts/validate-state-migration.sh` exists and is executable
  - Script correctly validates all aspects of the state migration
  - Script exits with code 0 for valid migration, 1 for invalid migration
  - Running the script after task 15 returns exit code 0

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Script exists and is executable
    Tool: Bash
    Steps:
      1. test -x scripts/validate-state-migration.sh && echo "executable: OK" || echo "executable: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-19-script-exists.txt

  Scenario: Script validates correctly on valid state migration
    Tool: Bash
    Steps:
      1. scripts/validate-state-migration.sh
    Expected Result: Exit code 0, all validation items show "PASS"
    Failure Indicators: Exit code 1 or any item shows "FAIL"
    Evidence: .omo/evidence/task-19-script-validates-valid.txt

  Scenario: Script detects missing state file correctly
    Tool: Bash
    Steps:
      1. Temporarily rename .omo/state/agent-executions.json to .omo/state/agent-executions.json.bak
      2. scripts/validate-state-migration.sh
      3. Verify exit code is 1 and output mentions "agent-executions.json not found"
      4. Restore renamed file
    Expected Result: Exit code 1 and output mentions missing file
    Failure Indicators: Exit code 0 or no mention of missing file
    Evidence: .omo/evidence/task-19-script-detects-missing.txt

  Scenario: Script detects orphaned original files correctly
    Tool: Bash
    Steps:
      1. Temporarily create test file docs/.refresh-state.json
      2. scripts/validate-state-migration.sh
      3. Verify exit code is 1 and output mentions "original file still exists"
      4. Remove test file
    Expected Result: Exit code 1 and output mentions orphaned original
    Failure Indicators: Exit code 0 or no mention of orphan
    Evidence: .omo/evidence/task-19-script-detects-orphaned.txt
  ```

  **Agent profile**: `quick`

  **Blocked By**: Task 15 (state migration must be complete before validation)
  
  **Commit**: YES — commit message: `chore(scripts): add validate-state-migration.sh for state-directory validation`

  **Output files**: `scripts/validate-state-migration.sh`

---

- [ ] 20. Create Install Test Script (test-install.sh) [quick]

  **What to do**:
  - Create `scripts/test-install.sh` that tests the installer in a clean environment
  - The script should:
    1. Create a temporary directory (e.g., `/tmp/test-install-$RANDOM`)
    2. Set `INSTALL_DIR` environment variable to the temporary directory
    3. Run `install.sh` with the temporary directory as the target
    4. Verify all expected files and directories are installed:
       - All 9 agent markdown files
       - `agents/AGENTS.md`
       - `.omo/state/` directory with all state files
       - All other files listed in `manifest.yaml`
    5. Verify `.omo/state/.cache/` has correct permissions
    6. Output installation results with pass/fail status
    7. Clean up the temporary directory
    8. Exit with code 1 if any verification fails, 0 if all pass
  - Make the script executable (`chmod +x`)

  **Why it matters**: This test script ensures the installer works correctly and installs all expected files, preventing broken installations for users.

  **Acceptance criteria**:
  - File `scripts/test-install.sh` exists and is executable
  - Script successfully runs `install.sh` in a clean environment
  - Script verifies all expected files are installed
  - Script exits with code 0 for successful installation
  - Running the script after task 16 returns exit code 0

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Script exists and is executable
    Tool: Bash
    Steps:
      1. test -x scripts/test-install.sh && echo "executable: OK" || echo "executable: FAIL"
    Expected Result: Line outputs OK
    Failure Indicators: Line outputs FAIL
    Evidence: .omo/evidence/task-20-script-exists.txt

  Scenario: Install test succeeds on valid manifest
    Tool: Bash
    Steps:
      1. scripts/test-install.sh
      2. Capture exit code and final summary line
    Expected Result: Exit code 0, output contains "All installations verified successfully"
    Failure Indicators: Exit code 1 or summary shows failures
    Evidence: .omo/evidence/task-20-install-test-success.txt

  Scenario: Install test detects missing agent files
    Tool: Bash
    Steps:
      1. Temporarily rename one agent file (e.g., hero-java-ecrm.md.bak)
      2. scripts/test-install.sh
      3. Verify exit code is 1 and output mentions "hero-java-ecrm.md not found"
      4. Restore renamed file
    Expected Result: Exit code 1 and output mentions missing file
    Failure Indicators: Exit code 0 or no mention of missing file
    Evidence: .omo/evidence/task-20-install-test-detects-missing.txt

  Scenario: Install test verifies state directory structure
    Tool: Bash
    Steps:
      1. scripts/test-install.sh
      2. Verify output mentions ".omo/state/ directory structure: OK"
      3. Verify output mentions all 4 state files (refresh-state.json, workflow-registry.json, agent-executions.json, session-history.json)
    Expected Result: Output confirms state directory and all files installed
    Failure Indicators: Output shows state directory or files missing
    Evidence: .omo/evidence/task-20-install-test-validates-state.txt

  Scenario: Install test cleans up temporary directory
    Tool: Bash
    Steps:
      1. Run scripts/test-install.sh
      2. Check that no /tmp/test-install-* directories remain after script completes
      3. ls -d /tmp/test-hero-* 2>/dev/null | wc -l should equal 0
    Expected Result: Temporary directories are removed
    Failure Indicators: Directories still exist
    Evidence: .omo/evidence/task-20-install-test-cleanup.txt
  ```

  **Agent profile**: `quick`

  **Dependencies**: Task 16 (manifest.yaml must be updated before testing)

  **Output files**: `scripts/test-install.sh`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists. For each "Must NOT Have": search for forbidden patterns. Check evidence files exist.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Quality Review** — `unspecified-high`
  Review all 9 rewritten agents for: chapter completeness, constraint accuracy, frontmatter integrity. Review AGENTS.md for schema compliance. Review .omo/state/ schema. Run validation scripts.
  Output: `Agents [N/9 compliant] | AGENTS.md [PASS/FAIL] | State [PASS/FAIL] | Scripts [N/N pass] | VERDICT`

- [ ] F3. **Full QA Pass** — `unspecified-high`
  Start from clean state. Run all 4 validation scripts. Run install.sh in isolated env. Trigger agent dispatch routes. Save to `.omo/evidence/final-qa/`.
  Output: `Scripts [N/N pass] | Install [PASS/FAIL] | Routes [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: verify 1:1 spec compliance. Check "Must NOT do" compliance. Detect cross-task contamination.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat(agents): define 5-chapter template spec, AGENTS.md schema, state schema` - .omo/plans/agent-management-enhancement.md (plan itself)
- **Wave 2+3**: `refactor(agents): rewrite 9 agents to 5-chapter template` - agents/hero-*.md
- **Wave 4**: `feat(state): add .omo/state/ + agents/AGENTS.md + update manifest` - .omo/, agents/AGENTS.md, manifest.yaml, templates/, .gitignore
- **Wave 5**: `chore(scripts): add validation scripts` - scripts/validate-*.sh
- **FINAL**: `test(verify): validation scripts + test evidence` - .omo/evidence/

---

## Success Criteria

### Verification Commands
```bash
# All 9 agents have 5 required chapters
bash scripts/validate-chapters.sh 2>&1 | grep -c "PASS"  # Expected: 9

# AGENTS.md covers all 9 agents
bash scripts/validate-agents-md.sh 2>&1 | tail -1  # Expected: "PASS: 9/9 agents registered"

# State migration integrity
bash scripts/validate-state-migration.sh 2>&1 | tail -1  # Expected: "PASS: state files migrated correctly"

# Install works in isolation
INSTALL_DIR=/tmp/test-hero bash test-install.sh && echo PASS  # test-install.sh handles full install verification
ls /tmp/test-hero/agents/hero-*.md | wc -l  # Expected: 9
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All 4 validation scripts pass
- [ ] install.sh isolated test passes
- [ ] Evidence files captured for all tasks
