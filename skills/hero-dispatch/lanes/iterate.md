---
lane: iterate
archetype: mutate
intent_keywords: [小迭代, 加个字段, 改个逻辑, 小改动, 加个开关, 微调]
required_input: 改动目标
---

# iterate lane（小迭代 · mutate）

## hero 露出

按 `hero-conventions` 露出规范，本 lane 运作时打 `🦸 hero ▸` 标记（token 一字不改）：
- 进入：`🦸 hero ▸ iterate lane · <纪律/门控>`
- 每个 STOP 门：`🦸 hero ▸ STOP<n> <门控> · <等什么>`
- 收尾：`🦸 hero ▸ iterate lane 完成 · 已交付，退出 hero 体系`
- 若派子 agent：派单处打 `🦸 hero ▸ <agent> 接手 · <职责>`

## 触发画像
在既有功能上做小幅增量（加字段/加开关/改分支逻辑），范围清晰、不涉及跨服务重设计。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（强制先测后写）
- `superpowers:brainstorming`（仅当改动目标模糊时，先澄清再动手）

## 参与的角色 agent
- `hero-java-backend-developer` / `hero-java-data-engineer`（按改动在业务层还是数据层）
- `hero-java-test-engineer`

## 领航 agent 介入点
改存量服务时先调 `hero-java-<proj>` 领航 agent 确认改动该落在哪个类/包、影响哪些 caller。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。无额外特例。

## 交接产物
增量代码 + 覆盖新行为的测试 + 影响面复核结论。
