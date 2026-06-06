---
lane: security
archetype: two-phase
intent_keywords: [安全, 越权, 注入, 漏洞, CVE, 敏感信息]
required_input: 审计范围
---

# security lane（信息安全问题优化 · two-phase）

## 触发画像
怀疑/排查安全风险（越权、注入、漏洞依赖、敏感信息泄漏），先审计、再按需修复。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（修复段：漏洞复现测试当 RED，修到测试转绿）

## 参与的角色 agent
- 审计：`hero-java-security-auditor`（只读，产风险清单）
- 修复：`hero-java-backend-developer` / `hero-java-data-engineer` + `hero-java-test-engineer`

## 领航 agent 介入点
审计/修复涉及存量服务时，调 `hero-java-<proj>` 领航 agent 圈出受影响入口与调用方。

## 门控骨架
见 `SKILL.md` 的 **two-phase**：[B]审计（security-auditor 只读）─⏸STOP「风险清单」─→
[A]TDD-first 修复（漏洞复现测试当 RED）。用户挑修哪些。仅授权的内部防御性审查。

## 交接产物
审计段：分级风险清单（攻击场景 + 修复建议）；修复段（若执行）：修复代码 + 复现测试 + 影响面复核。
