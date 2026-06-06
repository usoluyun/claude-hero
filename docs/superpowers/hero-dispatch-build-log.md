# hero-dispatch 构建过程记录

> 日期：2026-06-06 ~ 06-07
> 类型：过程复盘（不是设计/计划，而是"这个功能是怎么一步步做出来的"）
> 关联：设计 [`specs/2026-06-06-hero-dispatch-design.md`](./specs/2026-06-06-hero-dispatch-design.md)、
> 计划 [`plans/2026-06-06-hero-dispatch.md`](./plans/2026-06-06-hero-dispatch.md)

本文记录 `hero-dispatch`（意图分诊入口）从"一句想法"到"合并进 main"的完整过程。
它本身就是这个仓库要推广的方法论的一次实战样例：**SSD（spec 驱动）+ brainstorming +
writing-plans + TDD + 子 Agent 驱动 + 评审门控**串成一条链，用户只给意图，主 Agent 带着走。

---

## 0. 缘起：一次项目评估

用户的诉求不是"加个功能"，而是：希望把 SSD/TDD/BDD/superpowers 流程嵌进 Agent 工作流，
让用户**只给清晰意向**，主 Agent 按设计的 workflow 一步步带路，子 Agent 各自带 skills/工具干活。
问题是："我现在整个项目能不能达到这个效果？"

**评估结论**（对照四个诉求）：
- ✅ 子 Agent 各有 tools/职责边界、引用 superpowers —— 做得扎实。
- ⚠️ SSD/TDD/BDD 只是"agent 描述里的文字引用"，没进编排层；重型线 Step4 实现→Step5 测试
  其实是**反 TDD 的 test-after**，与口号自相矛盾。
- ❌ **缺最关键一层：顶层"意图→workflow"分诊入口**。全靠显式触发词，用户说自由意图没人接。
- ⚠️ 覆盖面只有"PRD→Java"一条重型线，修 bug/小特性等轻量场景掉回裸 Claude。

骨架打 8/10，意图驱动这层只有 3/10。用户选择**先补"顶层意图分诊入口"**这一最大缺口。

---

## 1. brainstorming：把想法澄清成设计

没有直接写代码，先用 `superpowers:brainstorming` 一次问一个问题，敲定 4 个关键分岔：

| 决策点 | 选择 | 理由 |
|---|---|---|
| 入口多主动 | **轻量词触发**（`hero <意图>`） | 可控、不打扰非 hero 场景、与现有触发词一脉相承；不做常驻 ambient |
| 路由覆盖 | 用户要**补 6 条新 lane**（修bug/小迭代/小重构/调研/性能/安全） | 加上既有 prd/refresh 共 8 条线 |
| lane 形态 | **单 dispatch skill + lane playbook 文件** | 内聚、好维护、不满屏 skill |
| lane 纪律 | **精简门控 + 强制 TDD-first** | 修掉重型线 test-after 硬伤；只读线另走 readonly 骨架 |

**范围预警**：6 条 lane 全展开会让 spec 过载。收敛为：本次只交付**分诊器 + lane 契约（catalog）+
6 条 lane 骨架**；每条 lane 的完整门控正文留后续各自一轮 spec→plan。

产出 → `specs/2026-06-06-hero-dispatch-design.md`，自审 + 用户复审通过。

---

## 2. writing-plans：拆成 5 个 TDD 任务

用 `superpowers:writing-plans` 把设计拆成可执行计划。关键修正：发现 `manifest.yaml` 的 `skills`
是"目录子项逐个软链"，新 skill 目录会被 `install.sh` **自动软链**——**不需要改 manifest**。

| Task | 产出 |
|---|---|
| 1 | 测试脚手架（assert/run/test_structure）+ `SKILL.md` 路由层 |
| 2 | 3 条 mutate lane（bugfix/iterate/refactor） |
| 3 | research（readonly）+ perf/security（two-phase） |
| 4 | 意图→lane 判例 fixture + 校验测试 |
| 5 | README/CLAUDE.md/example 接线 + install dry-run 验证 |

每个任务都是"先写校验测试 → 看它失败 → 补文件 → 看它转绿 → commit"。

---

## 3. 子 Agent 驱动执行：实现 + 两阶段评审 + 修复回环

用 `superpowers:subagent-driven-development`，每个任务派**全新子 Agent** 实现，主会话不污染上下文；
每个任务后跑**两阶段评审**：先 spec 合规、再代码质量；评审发现问题 → 同一实现 Agent 修 → 复核。

先开 `feature/hero-dispatch` 分支隔离（用户确认，不在 main 上直接做）。

**评审过程中抓出并修掉的真问题**（这是两阶段评审的价值所在）：

- **Task 1**：`run.sh` 空 glob 未防护、`assert_fail` 缺失、`sed` 文件缺失时污染输出。
- **Task 2**：iterate(`微调`)/refactor(`整理代码`) 关键词只在 lane frontmatter、没进 SKILL.md
  路由表 → **双源漂移**。路由表是"唯一事实源"，让它补全。顺带统一门控措辞。
- **Task 3**：security 审计段缺方法论锚点（与 perf 诊断段不对称）→ 补 `systematic-debugging`；
  `required_input` 标点（"或" vs "/"）与路由表对齐。
- **Task 4**：判例 fixture 的 TAB 分隔符正确性（用 `od -c` 核验真 Tab）。Approved，冗余断言不返工。
- **Task 5**：`## hero 入口` 误置于 example 的"个人段落"之下 → 挪到团队共享段落区。

**一个意外**：仓库导航 `CLAUDE.md` 从会话开始就是**未追踪**（`?? CLAUDE.md`），接线时被首次
`git add` 进来。这与计划假设冲突，**没有静默接受**——拿给用户定夺，用户确认**保留追踪**
（它是 README 都在引用的仓库导航文档，本就该进版本控制）。

---

## 4. 整体终审 + 收尾

`superpowers:finishing-a-development-branch` 之前先做**整体终审**（opus）：对照 spec/plan 逐项核
覆盖、跨文件一致性、测试、无越界。结论 **READY TO MERGE**，无 Critical/Important。

- 测试：结构校验 44 + 判例 19 = **63 断言全绿**，bash 3.2 兼容。
- 合并：`--no-ff` 并回 `main`（纯本地，未推远端），合并后测试复跑仍全绿，删除 feature 分支。

---

## 5. 交付物（已在 main）

```
skills/hero-dispatch/
  SKILL.md                  路由层：8 条 lane catalog + 三段式分诊 + 边界判定 + 降级 + 两个门控原型
  lanes/bugfix.md           mutate · 复用 systematic-debugging + TDD
  lanes/iterate.md          mutate · TDD（目标模糊时先 brainstorming）
  lanes/refactor.md         mutate · TDD + 表征测试特例
  lanes/research.md         readonly · brainstorming，只读出报告
  lanes/perf.md             two-phase · 诊断→STOP→TDD-first 优化
  lanes/security.md         two-phase · 审计→STOP→TDD-first 修复
tests/hero-dispatch/        assert/run/test_structure/test_cases + cases.tsv 判例 fixture
README.md / CLAUDE.md / config/CLAUDE.md.example   入口登记
```

---

## 6. 守住的三条红线（本次不做）

1. **不**细化 6 条 lane 的完整门控正文（只交付骨架，正文留后续各自 spec→plan）。
2. **不**返工重型线 `hero-prd-to-java` 那个 Step4→Step5 反 TDD 顺序（独立改动，另开）。
3. **不**做常驻 ambient 分诊（只 `hero` 词触发）。

---

## 7. 留给后续的事

- 6 条 lane 各自的**完整门控正文细化**（每条一轮 spec→plan→实现，骨架同构、应该很快）。
- 重型线 `hero-prd-to-java` 的**反 TDD 顺序返工**（把 Step4 实现→Step5 测试改成 TDD-first）。
- `tests/hero-dispatch/cases.tsv` 判例可持续扩充，作为分诊回归 fixture。
- 远端推送（github / 内网 gitlab origin）按需进行。
