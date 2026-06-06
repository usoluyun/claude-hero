---
lane: research
archetype: readonly
intent_keywords: [调研, 评估, 能不能, 影响面, 怎么改, 要不要]
required_input: 问题/范围
---

# research lane（需求/变更调研 · readonly）

## hero 露出

按 `hero-conventions` 露出规范，本 lane 运作时打 `🦸 hero ▸` 标记（token 一字不改）：
- 进入：`🦸 hero ▸ research lane · <纪律/门控>`
- STOP 门：`🦸 hero ▸ STOP <门控> · <等什么>`
- 收尾：`🦸 hero ▸ research lane 完成 · 已交付，退出 hero 体系`
- 若派子 agent：派单处打 `🦸 hero ▸ <agent> 接手 · <职责>`

## 触发画像
用户要在动手前搞清「能不能做 / 影响多大 / 怎么改 / 要不要做」，产出是结论与选项，不改代码。

## 复用的 superpowers skill
- `superpowers:brainstorming`（探索问题空间与备选方案）

## 参与的角色 agent
- `hero-java-<proj>` 领航 agent（摸地图、圈影响面，只读）
- `hero-java-tech-lead`（可行性/风险/工作量评估，只读）

## 领航 agent 介入点
核心环节即领航 agent 摸地图 + `codegraph impact` 圈影响面（复用花名册）。

## 门控骨架
见 `SKILL.md` 的 **Archetype B（readonly）**。无 RED-GREEN，不产代码。
产物常作为后续走 prd 线或 mutate 线的输入。

## 交接产物
调研结论文档（现状 + 可行性 + 影响面 + 风险 + 工作量 + 备选方案与建议）。
