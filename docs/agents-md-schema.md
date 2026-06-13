# AGENTS.md YAML Schema

`agents/AGENTS.md` 是机器可读的 agent 注册表，供 `hero-dispatch` 和工具链解析使用。

---

## 整体结构

```yaml
---
agents:
  - name: hero-java-tech-lead
    # ... 条目字段
  - name: hero-java-backend-developer
    # ... 条目字段
  # ... 共 9 个条目
---

# Agent Registry

（机器可解析的注册表，人类可读的版本见 docs/hero-agent-roster.md）
```

---

## 字段定义

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 与 frontmatter `name` 字段完全一致 |
| `display_name` | string | ✅ | 中文花名（孔明、文远、子长…） |
| `model` | string | ✅ | `opus` / `sonnet` / `haiku` |
| `role_type` | enum | ✅ | `planner` / `executor` / `reviewer` / `navigator` |
| `readonly` | boolean | ✅ | `true` 表示 tools 字段不含 Write/Edit |
| `skills` | list[string] | ❌ | 常用 skill 名称列表 |
| `triggers` | list[string] | ❌ | 意图分诊触发关键词 |
| `tools_count` | integer | ❌ | tools 字段中工具的近似数量（仅文档用） |

---

## 示例条目

```yaml
agents:
  - name: hero-java-tech-lead
    display_name: 孔明
    model: opus
    role_type: planner
    readonly: false
    skills: [hero-prd-to-java, hero-dispatch]
    triggers: [设计, 架构, Sprint, 技术方案, PRD]
    tools_count: 9

  - name: hero-java-code-reviewer
    display_name: 玄成
    model: opus
    role_type: reviewer
    readonly: true
    skills: [hero-pmd, hero-spotbugs, hero-semgrep]
    triggers: [审查, review, 代码评审, code review]
    tools_count: 6

  - name: hero-java-ecrm
    display_name: 子文
    model: sonnet
    role_type: navigator
    readonly: true
    skills: [hero-codegraph]
    triggers: [ecrm, 企业CRM, 子文]
    tools_count: 4
```

---

## 与 docs/hero-agent-roster.md 的关系

- `agents/AGENTS.md` → **机器可读注册表**，hero-dispatch 解析使用，字段固定
- `docs/hero-agent-roster.md` → **人类可读花名表**，团队查阅使用，内容更丰富
- 两者以 `name` 字段对齐，AGENTS.md 为程序权威源
