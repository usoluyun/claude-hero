---
lane: refactor
archetype: mutate
intent_keywords: [重构, 抽方法, 改命名, 拆类, 消除重复, 整理代码]
required_input: 重构对象
---

# refactor lane（小重构 · mutate）

## 触发画像
不改变外部行为、只改善内部结构（抽取/改名/拆分/去重），范围限定在指定对象内。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（重构必须在测试保护下进行）

## 参与的角色 agent
- `hero-java-backend-developer`（执行重构）
- `hero-java-test-engineer`（补表征测试）

## 领航 agent 介入点
改存量服务时先调 `hero-java-<proj>` 领航 agent 圈出重构对象的全部 caller，防止漏改调用方。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。**特例**：REFACTOR 前提是已有测试覆盖；
若重构对象无测试，STOP① 后先补**表征测试（characterization test）**锁住现有行为，再重构。

## 交接产物
重构后代码 + 表征/回归测试（行为不变证明）+ 影响面复核结论。
