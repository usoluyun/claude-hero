# 轻量 Lane Playbook 对比解读

> **权威源**：[`skills/hero-dispatch/lanes/`](../../skills/hero-dispatch/lanes/)
> **范围**：本文对比解读 7 个轻量 lane playbook（bugfix/iterate/refactor/research/perf/security/team），不覆盖 prd/refresh 两条重型线。

## 一句话引言

7 个轻量 lane playbook 共享同一个设计骨架：**触发画像（archetype）→ 门控骨架 → STOP 决策点 → 角色 agent 分工 → 交接产物**。差异在于"这条 lane 关心什么"和"怎么停、停几次"。

## 覆盖范围

hero-dispatch 路由表共 9 条 lane，但 **playbook 只覆盖其中 7 条**：

| Lane | 有 playbook？ | 说明 |
|------|-------------|------|
| bugfix / iterate / refactor / research / perf / security / team | ✅ 有 | 轻量线，加载 `lanes/*.md` 即走 |
| prd / refresh | ❌ 没有 | 重型线，委派 `hero-prd-to-java` / `hero-refresh` 独立 skill |

所以本文覆盖的 7 条 lane 对应 7 个 playbook 文件（`skills/hero-dispatch/lanes/*.md`）。

## 统一结构

每篇 playbook 都有 5 个关键段，字段名和含义完全一致：

| 段 | 说明 |
|----|------|
| **archetype** | 走什么流程模板（mutate / readonly / two-phase / setup） |
| **intent_keywords** | 触发关键词列表，命中即路由到该 lane |
| **required_input** | 进入 lane 前必须补齐的最小输入 |
| **hero 露出** | `🦸 hero ▸` 标记的 4 个时机（进入/STOP/收尾/派 agent） |
| **门控骨架** | 引用 SKILL.md 的 archetype 父类定义 + 本 lane 特例 |

门控骨架是 playbook 的核心：它定义了 lane 的执行节奏和用户介入点。

## 按 archetype 分组解读

7 个 playbook 按流程模板（archetype）分 4 组。archetype 回答的是"怎么走流程"，而不是"做什么事"；一个 archetype 可服务多个 lane。

### 1. Mutate（改代码线）— 3 个 lane

> 完整骨架见 SKILL.md 的 Archetype A：**勘察定位 → STOP①（方案确认）→ RED（先写失败测试）→ GREEN（实现到通过）→ REFACTOR（清理）→ STOP②（改动+测试结果确认）**。

| Lane | 与 mutate 骨架的差异 |
|------|-------------------|
| **bugfix** | 勘察定位前强制 `superpowers:systematic-debugging`，**复现不出来不得进入 STOP①**。RED 测试内容是"复现 bug 的失败测试" |
| **iterate** | 无额外特例。RED 测试内容是"覆盖新行为的失败测试"。若改动目标模糊，先调 `superpowers:brainstorming` 澄清 |
| **refactor** | 关键前提：**重构对象无测试时，STOP① 后必须先补表征测试（characterization test）锁住现有行为**，再进 RED-GREEN-REFACTOR。交接产物含"行为不变证明" |

三个 lane 都走同一条 2-STOP 流程，但 RED 测试的语义完全不同：bugfix 是"让 bug 暴露"，iterate 是"让新行为可验证"，refactor 是"锁住旧行为不被改动破坏"。

### 2. Readonly（只读线）— 1 个 lane

> 完整骨架见 SKILL.md 的 Archetype B：**调查（领航 agent 摸地图 + codegraph，只读）→ 分析（影响面/可行性/风险/工作量）→ STOP（结论 + 选项 + 建议）**。

**research** 是唯一的 readonly lane。不改代码、不写测试、不产 PR。它的产物是"调研结论文档"，通常作为后续 prd 线或 mutate 线的输入。参与角色全部只读：领航 agent 摸地图 + Demis Hassabis（tech-lead）做可行性/风险评估。

### 3. Two-phase（两段式）— 2 个 lane

> 完整骨架见 SKILL.md 的 two-phase：**B 段诊断（只读）→ STOP「清单」→ 用户确认要不要改 → 转 A 段 TDD-first 修复**。

| Lane | B 段（诊断） | STOP 产物 | A 段（修复） |
|------|------------|----------|------------|
| **perf** | 诊断热点路径 + 慢查询执行计划 | 瓶颈清单 + 优化项建议 | 以**基准测试**为 RED，优化到基准达标为 GREEN |
| **security** | 审计（security-auditor 只读，产风险清单） | 分级风险清单（攻击场景 + 修复建议） | 以**漏洞复现测试**为 RED，修到测试转绿 |

两段式的核心价值是**防过度改**：先诊断出"到底有哪些问题"，让用户挑"要不要改、改哪些"，再进入 TDD 修复。perf 诊断用 `systematic-debugging`，security 审计用 `hero-java-security-auditor`。

### 4. Setup（启动即退出）— 1 个特殊情况

**team** lane 不属于上述三个 archetype，它是独立的 **setup** 原型：环境自检 → STOP 角色确认 → 生成启动指引 → 退场。不改代码、不写测试、不委派子 agent。

流程极简：检查 tmux 是否安装、`settings.json` 是否配置了 Agent Teams → 确认组队角色（默认Demis Hassabis+Jeff Dean+Percy Liang）→ 输出 tmux 启动命令清单 → 退出。后续用户在 tmux 里自行启动各 agent。

## 对比表

| Lane | Archetype | RED 测试内容 | STOP 数量 | 特殊产物 |
|------|-----------|-------------|---------|---------|
| bugfix | mutate | 复现 bug 的失败测试 | 2 | 复现/回归测试 |
| iterate | mutate | 覆盖新行为的失败测试 | 2 | 增量代码+测试 |
| refactor | mutate | **表征测试**（锁现有行为） | 2 | 行为不变证明 |
| research | readonly | 无（不写代码） | 1 | 调研结论文档 |
| perf | two-phase | 基准测试（响应 ≤ X ms） | 1+2 | 基准对比 |
| security | two-phase | 漏洞复现测试 | 1+2 | 分级风险清单 |
| team | setup | 无（不改代码） | 2（自检+角色确认） | 启动命令清单 |

> STOP 列中 `1+2` 表示 B 段诊断 1 个 STOP + A 段修复 2 个 STOP，共 3 个门控点。

## 每类 archetype 示例

### Mutate 示例（bugfix）

```
hero login 报 NPE
  → 勘察：领航 agent 摸地图 + systematic-debugging 复现
  → ⏸ STOP①：缺陷定位 + 修复方案确认
  → RED：Percy Liang写复现测试（触发 NPE 的失败用例）
  → GREEN：Jeff Dean修代码，测试转绿
  → REFACTOR：清理
  → ⏸ STOP②：改动 + 测试结果 + 影响面复核报告
```

### Readonly 示例（research）

```
hero 加个缓存行不行
  → 调查：领航 agent 摸地图 + codegraph 圈调用热点
  → 分析：Demis Hassabis评估可行性 / 风险 / 工作量
  → ⏸ STOP：结论 + 缓存方案选项 + 建议（不改代码）
```

### Two-phase 示例（perf）

```
hero 登录接口 3 秒
  → B 段诊断：领航 agent 定位热点 + Fei-Fei Li查慢查询执行计划
  → ⏸ STOP：瓶颈清单（慢 SQL / N+1 / 未索引字段）
  → 用户挑：只优化索引，不改连接池
  → A 段：RED（基准测试：响应 ≤ 500ms）→ GREEN 优化 → 基准达标
```

### Setup 示例（team）

```
hero 组队 3 位 Agent
  → 环境自检：tmux ✓ / settings.json ✓
  → ⏸ STOP：确认角色（Demis Hassabis opus + Jeff Dean sonnet + Percy Liang sonnet）
  → 输出 tmux 启动命令 → 退场
```

## 设计哲学

- **RED 测试语义不同**：每个 mutate/two-phase lane 的 RED 测试都反映该 lane 的关切，不是普通的单元测试。bugfix 的 RED 是"让 bug 可复现"，refactor 的 RED 是"锁住旧行为不被破坏"，perf 的 RED 是"当前性能指标不达标"。

- **领航 agent 标配**：改存量服务时，先调对应 `hero-java-<proj>` 领航 agent 用 codegraph 摸地图、圈影响面。这是所有 mutate/two-phase lane 的第一步，避免"不知道在哪改、改了影响谁"。

- **不确定就停**：每个 lane 至少一个 STOP 门控，让用户做决策。mutate 线 2 个 STOP（方案确认 + 结果确认），readonly 线 1 个 STOP（结论确认），two-phase 线 3 个 STOP（诊断确认 + 方案确认 + 结果确认）。

- **两段式防过度改**：perf/security 必须先诊断输出清单，用户挑要不要改、改哪些。不假设"每个瓶颈都要优化"或"每个风险都要修"。

- **setup 独立成型**：team lane 不走 mutate/readonly/two-phase 任何一条模板，它是独立的 setup 原型。把组队流程混入业务 lane 会让流程混乱，所以专门一个模板，启动即退场。
