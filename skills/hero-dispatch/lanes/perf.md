---
lane: perf
archetype: two-phase
intent_keywords: [慢, 性能, 瓶颈, 优化耗时, 压测, 超时]
required_input: 慢的位置或指标
---

# perf lane（性能瓶颈与优化 · two-phase）

## 触发画像
某处响应慢/超时/资源占用高，需先诊断瓶颈、再按需优化。

## 复用的 superpowers skill
- `superpowers:systematic-debugging`（诊断段：用证据定位瓶颈，不臆测）
- `superpowers:test-driven-development`（优化段：基准测试当 RED，优化到达标）

## 参与的角色 agent
- 诊断：`hero-java-<proj>` 领航 agent + `hero-java-data-engineer`（慢查询/执行计划）
- 优化：`hero-java-backend-developer` / `hero-java-data-engineer` + `hero-java-test-engineer`

## 领航 agent 介入点
诊断段调领航 agent 摸地图定位热点路径与受影响调用链。

## 门控骨架
见 `SKILL.md` 的 **two-phase**：[B]诊断瓶颈 ─⏸STOP「瓶颈 + 优化项」─→ [A]TDD-first 优化
（以基准测试为 RED，优化后基准达标为 GREEN）。用户挑要不要优化、优化哪些。

## 交接产物
诊断段：瓶颈清单 + 优化项建议；优化段（若执行）：优化代码 + 基准对比 + 影响面复核。
