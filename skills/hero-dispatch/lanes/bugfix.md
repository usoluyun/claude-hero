---
lane: bugfix
archetype: mutate
intent_keywords: [修bug, 报错, 异常, 复现, 修一下, 不对, 不生效]
required_input: 现象或复现路径
---

# bugfix lane（修 bug · mutate）

## 触发画像
用户报告某处行为错误/抛异常/不生效，目标是定位并修复单个缺陷（非新增功能）。

## 复用的 superpowers skill
- `superpowers:systematic-debugging`（强制：先稳定复现，禁止未复现就改）
- `superpowers:test-driven-development`（RED 用一个能复现 bug 的失败测试）

## 参与的角色 agent
- `hero-java-backend-developer` / `hero-java-data-engineer`（按缺陷在业务层还是数据层）
- `hero-java-test-engineer`（写复现测试 + 回归测试）

## 领航 agent 介入点
改存量服务时，先调对应 `hero-java-<proj>` 领航 agent 摸地图 + `codegraph` 圈影响面，
定位缺陷落点与受影响 caller（复用 `docs/hero-agent-roster.md` 花名册）。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。特例：步骤 1（勘察定位）须先用 systematic-debugging
稳定复现缺陷，复现不出来不得进入 STOP①。

## 交接产物
修复代码 + 复现/回归测试 + 影响面复核结论。
