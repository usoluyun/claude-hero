# hero-issue-dispatch：GitLab Issue 触发词机制解读

> **权威源**：[`skills/hero-issue-dispatch/SKILL.md`](../../skills/hero-issue-dispatch/SKILL.md)
> **范围**：本文解读 GitLab Issue 触发词 → 加载 SKILL.md → 路由 agent 的机制，不复制 SKILL.md 全文。

---

## 一句话引言

`hero-issue-dispatch` 是一个**三层触发机制**：用户在 Claude Code 中输入 Issue 相关命令 → Claude 引擎根据 SKILL.md 的 `description` 字段做语义匹配 → 加载完整 SKILL.md → 按路由表派发给对应的角色 agent 执行。用户不必知道每个 agent 负责什么，说一句命令就够了。

---

## 第一层：Claude Code 的 Skill 触发机制

Claude Code 通过每个 Skill 文件 frontmatter（文件头部的 YAML 区块）里的 `description` 字段来做关键词和语义匹配。当用户输入的内容与某个 Skill 的 `description` 匹配度最高时，Claude Code 会自动加载该 Skill 的完整 `SKILL.md`。

这一层是 **Claude 引擎自动完成的**，开发者只需把触发关键词塞进 `description` 字段即可，无需写任何匹配规则。

---

## 第二层：SKILL.md 的 description 怎么写

`hero-issue-dispatch` 的 `description` 字段同时塞入了三类触发词，目的是**最大化触发覆盖率**：

| 类别 | 示例 | 用途 |
|------|------|------|
| **英文命令** | `issue claim`, `issue done`, `glab`, `gitlab issue` | 精确匹配用户输入的命令式语句 |
| **中文自然语言** | `「认领 #456」`, `「完成 #789」`, `「拆解主 Issue」` | 覆盖中文用户的口语表达 |
| **标签名** | `hero::status`, `hero::agent`, `hero::type` | 当对话上下文中出现这些标签时也能触发 |

实际 frontmatter 内容（节选自 `SKILL.md:1-9`）：

```yaml
description: GitLab Issue 命令路由。当用户输入 Issue 相关操作时，根据命令类型和
Issue 标签自动路由到对应角色 agent。触发关键词包括：issue pull/claim/done/decompose/
list/view/status/review/audit、glab、gitlab issue、hero::status、hero::agent、hero::type。
支持中文自然语言如「拉取待办 Issue」「认领 #456」「完成 #789」「拆解主 Issue」
「审查代码」「代码审计」等。
```

**核心机制亮点**：`description` 字段越丰富（中英文关键词塞满），触发率越高。这不是精确字符串匹配，而是 Claude 的语义理解在起作用——即使你说「帮我把 #456 认领一下」，引擎也能匹配到 `issue claim` 的语义。

---

## 第三层：加载后怎么路由

SKILL.md 被加载后，Claude 会按其中的路由逻辑决定交给哪个 agent 执行。

### 路由规则（ASCII 流程图）

```
命令进入
  │
  ├─ decompose → 强制路由 tech-lead（Demis Hassabis），不管标签
  │
  ├─ claim / done → 读取 Issue 标签 hero::agent:<name>
  │     ├─ 有标签 → 路由到对应 agent
  │     └─ 无标签 → 路由 tech-lead（Demis Hassabis）分配
  │
  ├─ pull → 触发轮询脚本，每个 Issue 按标签路由
  │
  ├─ review → 强制路由 code-reviewer（Chris Olah），只读
  │
  ├─ audit → 强制路由 security-auditor（Jan Leike），只读
  │
  └─ list / view / status → 不路由 agent，直接查询
```

### Agent 映射表

| Issue 标签 `hero::agent:` | 花名 | 角色 | Agent 文件 |
|---|---|---|---|
| `kongming` | Demis Hassabis | tech-lead | `agents/hero-java-tech-lead.md` |
| `wenyuan` | Jeff Dean | backend-dev | `agents/hero-java-backend-developer.md` |
| `zichang` | Fei-Fei Li | data-engineer | `agents/hero-java-data-engineer.md` |
| `xiren` | Percy Liang | test-engineer | `agents/hero-java-test-engineer.md` |
| `xuancheng` | Chris Olah | code-reviewer | `agents/hero-java-code-reviewer.md` |
| `pengju` | Jan Leike | security-auditor | `agents/hero-java-security-auditor.md` |
| （无标签） | Demis Hassabis | tech-lead | `agents/hero-java-tech-lead.md` |

标签名使用花名拼音（如 `wenyuan`），与 `hero-glab` skill 中的 Label 命名空间保持一致。

---

## 完整示例

用户输入 `issue claim #456`，假设 Issue #456 的标签是 `hero::agent:wenyuan`：

```
用户输入: issue claim #456
    │
    ▼
① Claude 语义匹配 → 命中 hero-issue-dispatch 的 description
    │
    ▼
② 加载 SKILL.md 全文
    │
    ▼
③ SKILL.md 路由表
    读取 Issue #456 的标签 hero::agent:<name>
    ├─ hero::agent:wenyuan  → 路由到Jeff Dean（backend-dev）
    ├─ hero::agent:zichang  → 路由到Fei-Fei Li（data-engineer）
    └─ 无标签              → 降级到Demis Hassabis（tech-lead）
    │
    ▼
④ Jeff Dean认领，更新状态
    glab issue update 456 --label "hero::status:in_progress"
    输出确认：「🦸 hero ▸ Jeff Dean（hero-java-backend-developer.md）接手 · 已认领 #456，开始工作」
```

同理，`issue done #456 "修复完成"` 会走相同的路由逻辑，由对应 agent 执行完成汇报和关闭操作。`issue decompose #1` 则不管 Issue 标签，强制交给Demis Hassabis（tech-lead）拆解为子任务。

---

## 边界与降级

| 场景 | 行为 |
|------|------|
| Issue 无 `hero::agent` 标签 | 降级到Demis Hassabis（tech-lead），由Demis Hassabis判断后分配 |
| 用户说中文自然语言 | `「认领 #456」` / `「拉取待办 Issue」` 等也能命中 description 触发 |
| 主 Issue（`hero::type:epic`） | `issue done` 会检查标签，epic 类型拒绝自动关闭，只能人手动关 |
| 审查 / 审计命令 | `issue review` 和 `issue audit` 只读执行（不改 Issue 状态），由Chris Olah/Jan Leike处理 |

---

## 支持的命令速查

| 命令 | 用途 | 路由目标 |
|------|------|---------|
| `issue pull` | 拉取待处理 Issue | 轮询脚本 → 各 agent |
| `issue claim <iid>` | 认领 Issue | 按 `hero::agent` 标签路由 |
| `issue done <iid> [msg]` | 完成并关闭 Issue | 按 `hero::agent` 标签路由 |
| `issue decompose <iid>` | 拆解为子任务 | 强制Demis Hassabis（tech-lead） |
| `issue list <agent>` | 列出 agent 待办 | 直接查询 |
| `issue view <iid>` | 查看详情 | 直接查看 |
| `issue status` | 全局任务分布 | 直接统计 |
| `issue review <iid>` | 代码审查（只读） | 强制Chris Olah（code-reviewer） |
| `issue audit <iid>` | 安全审计（只读） | 强制Jan Leike（security-auditor） |

> 每个命令的详细执行流程参见 [`skills/hero-issue-dispatch/SKILL.md`](../../skills/hero-issue-dispatch/SKILL.md)。
