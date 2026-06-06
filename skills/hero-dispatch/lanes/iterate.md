---
lane: iterate
archetype: mutate
intent_keywords: [小迭代, 加个字段, 改个逻辑, 小改动, 加个开关, 微调]
required_input: 改动目标
---

# iterate lane（小迭代 · mutate）

## 触发画像
在既有功能上做小幅增量（加字段/加开关/改分支逻辑），范围清晰、不涉及跨服务重设计。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（强制先测后写）
- `superpowers:brainstorming`（仅当改动目标模糊时，先澄清再动手）

## 参与的角色 agent
- `hero-java-backend-developer` / `hero-java-data-engineer`
- `hero-java-test-engineer`

## 领航 agent 介入点
改存量服务时先调 `hero-java-<proj>` 领航 agent 确认改动该落在哪个类/包、影响哪些 caller。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。无额外特例。

## 交接产物
增量代码 + 覆盖新行为的测试 + 影响面复核结论。
