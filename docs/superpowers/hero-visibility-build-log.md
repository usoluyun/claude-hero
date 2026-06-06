# hero-visibility 构建过程记录

> 日期：2026-06-07
> 类型：过程复盘（这个功能是怎么一步步做出来的）
> 关联：设计 [`specs/2026-06-07-hero-visibility-design.md`](./specs/2026-06-07-hero-visibility-design.md)、
> 计划 [`plans/2026-06-07-hero-visibility.md`](./plans/2026-06-07-hero-visibility.md)

本文记录 `hero-visibility`（hero 露出机制）从"一句诉求"到"合并进 main"的完整过程。
延续 [`hero-dispatch-build-log.md`](./hero-dispatch-build-log.md) 同一条链：
**brainstorming → writing-plans → 子 Agent 驱动 + 两阶段评审 → 整体终审 → 合并**。

---

## 0. 缘起：一句诉求

用户诉求：「整体突出 hero 这个概念——所有 skill 触发、agent 运作时都要有显式露出，让用户感知
现在是 hero 这套体系在运作，和他本地自己的机制不同。」

问题本质：hero-dispatch 交接后即"隐身"，子 agent 干活时用户看到的与裸 Claude 无异，hero
体系全程**零露出**。要补的就是这层"我是 hero 在接管"的显式信号。

---

## 1. brainstorming：三个关键决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 露出形态 | **单行事件标记** `🦸 hero ▸ …` | 低噪音、信息够、不挤占屏幕；否决了块状 banner（太吵）/statusline（只能显极简、跟不上 lane 切换） |
| 露出时机 | **四个全打**：skill 激活 / agent 接手 / 门控 STOP / 任务收尾 | 用户要"全程有感知" |
| 落地机制 | **纯文案约定 + 结构测试卡死** | 否决 hook 兜底（只能打粗信息、维护 bash 成本）；token 漂移交给测试防 |

**两个写进设计的关键约束**（brainstorm 中识别）：
1. 标记是**模型输出的文本**，没有 harness 钩子能替它打出"现在是 bugfix lane"这种上下文——
   靠模型合规，测试只能保证"指令存在"、不保证"每次真打"。
2. **子 agent 不自动加载 skill**，且其输出对用户主线是折叠的 → "agent 接手"标记必须
   **内联进 agent 文件**，且主路径是**编排方在派单时打**（主线可见），子 agent 自打仅兜底。

产出 → spec，自审 + 用户复审通过。

---

## 2. writing-plans：拆成 4 个 TDD 任务

每个任务都是"先写卡 token 的断言 → 看它失败 → 加露出文案 → 看它转绿 → commit"，
测试文件 `test_visibility.sh` 跨任务**增量构建**（每个任务追加自己的断言块）。

| Task | 产出 |
|---|---|
| 1 | 测试脚手架（复用 hero-dispatch 的 assert/run 风格）+ `hero-conventions` 露出规范（事实源） |
| 2 | 9 个 agent 内联自报家门 |
| 3 | hero-dispatch SKILL + 6 条 lane 露出打点 |
| 4 | hero-refresh + hero-prd-to-java 露出指令 + 全量验证（含不回归 + install 演练） |

---

## 3. 子 Agent 驱动执行：实现 + 两阶段评审 + 修复回环

每个任务派**全新子 Agent** 实现，任务后跑**两阶段评审**（先 spec 合规、再代码质量），
评审发现问题 → 原实现 Agent 修 → 复核。全程在 `feature/hero-visibility` 分支隔离。

**评审过程中抓出并修掉的真问题**：

- **Task 1**：`run.sh` 注释残留 `hero-dispatch`（复制粘贴遗留）；`test_visibility.sh` 缺可执行位
  （与既有 755 不一致）。
- **Task 3**：6 条 lane 的 `## hero 露出` 节被插在 `# 主标题`**之前**——markdown 层级倒置；
  `STOP<n>` 模板对只读/两段式 lane（research/perf/security）**有误导**（它们只有单个无编号 STOP）。
  修法：层级移到 H1 之后；单门控 lane 改用无编号 `STOP`，mutate lane 保留 `STOP<n>`。
- **Task 4**：hero-prd-to-java 多确认门却漏了 `<n>`，补 `STOP<n>`。

**一次主动的"部分否决评审"**：Task 4 评审员建议给 hero-refresh 的 STOP 也加编号。但 Task 3
刚确立的规则是"单门控用无编号 STOP"，hero-refresh 只有一个评审 gate——**没有照搬评审建议**，
保持无编号，维护了跨任务的 STOP 编号一致性。评审是输入、不是命令。

**一次服务端故障的处理**：Task 1 的修复子 Agent 撞上 `API Error 529 Overloaded` 空手而归。
注释 + chmod 是纯机械改动，直接在主会话改掉、`--amend` 并入，没有为俩字符再耗一轮子 Agent。

---

## 4. 整体终审 + 收尾

`finishing-a-development-branch` 之前先做 **opus 整体终审**：对照 spec/plan 逐项核覆盖、
跨文件 token 与 STOP 规则一致性、markdown 层级、纯插入无删除、install 不受影响。
结论 **READY TO MERGE**，无 Critical/Important。

- 测试：hero-visibility **23 断言** + hero-dispatch **63 断言**（不回归）全绿，bash 3.2 兼容。
- 合并：`--no-ff` 并回 `main`，合并后测试复跑仍全绿，删除 feature 分支。

---

## 5. 交付物（已在 main）

```
skills/hero-conventions/SKILL.md      露出规范事实源：token 🦸 hero ▸ + 四时机模板 + 双保险分工
skills/hero-dispatch/SKILL.md         分诊/交接/派 agent 三处打点
skills/hero-dispatch/lanes/*.md (6)   进入/STOP/收尾/派 agent 打点（STOP 编号按 archetype 区分）
skills/hero-refresh/SKILL.md          启动/评审 STOP/收尾
skills/hero-prd-to-java/SKILL.md      启动/确认门/派 agent/收尾
agents/hero-java-*.md (9)             各内联自报家门
tests/hero-visibility/               assert/run/test_visibility（grep -qF 卡统一 token）
```

22 文件、纯插入 225 增 0 删（未破坏任何既有内容）。

---

## 6. 守住的红线（本次不做）

1. **不**做 statusline / 块状 banner / hook 兜底（只单行文案）。
2. **不**改 superpowers 自身的 skill。
3. **不**顺带细化 6 条 lane 的门控正文（那是 hero-dispatch build-log 第 7 节的独立 backlog）。

---

## 7. 留给后续的事

- token 是模型文本、靠合规——若实战中发现"漏打"频繁，再考虑 hook 兜底兜粗信息。
- 露出措辞可随保鲜周期统一打磨（如个别引导语"token 一字不改"提示的有无）。
- 这套"事实源 + 内联 + 测试卡 token"的模式，可作为未来跨 skill/agent 一致性约定的模板复用。
