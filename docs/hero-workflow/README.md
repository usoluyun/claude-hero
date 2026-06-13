> **权威源**：本目录 7 个机制文档的总入口
> **范围**：本文是 hero 工作流机制的导航索引，不含机制细节解读

# Hero 工作流机制指南

本目录收录 7 个机制文档，覆盖 hero 系统的触发、路由、执行、露出、保鲜全链路。

## 推荐阅读顺序

根据你的角色选择路径：

| 角色 | 阅读路径 |
|------|----------|
| **用户** | [lane-routing](lane-routing.md) → [playbook](playbook.md) → [hero-markers](hero-markers.md) |
| **贡献者** | [lane-routing](lane-routing.md) → [playbook](playbook.md) → [hero-markers](hero-markers.md) → 按需查阅 issue-dispatch / prd-workflow / refresh / codegraph |
| **架构师** | [lane-routing](lane-routing.md) → [codegraph](codegraph.md) → [prd-workflow](prd-workflow.md) → [refresh](refresh.md) |
| **测试工程师** | [playbook](playbook.md) → [prd-workflow](prd-workflow.md) → [issue-dispatch](issue-dispatch.md) |

## 文档清单

| 文档 | 主题 | 行数 | 权威源 |
|------|------|------|--------|
| [issue-dispatch.md](issue-dispatch.md) | GitLab Issue 触发词机制 | 141 | skills/hero-issue-dispatch/SKILL.md |
| [lane-routing.md](lane-routing.md) | hero-dispatch 意图分诊 | 126 | skills/hero-dispatch/SKILL.md |
| [playbook.md](playbook.md) | 7 个轻量 lane playbook 对比 | 140 | skills/hero-dispatch/lanes/*.md |
| [hero-markers.md](hero-markers.md) | 🦸 hero ▸ 标记规范 + 英雄名映射 | 138 | skills/hero-conventions/SKILL.md |
| [prd-workflow.md](prd-workflow.md) | PRD 驱动开发 8 步流水线 | 118 | skills/hero-prd-to-java/SKILL.md |
| [refresh.md](refresh.md) | 两段式保鲜（确定性脚本 + 漂移评审） | 114 | skills/hero-refresh/SKILL.md |
| [codegraph.md](codegraph.md) | codegraph 知识底座（领航 agent） | 126 | docs/codegraph-agent-plan.md |

## 系统全景（文字概览）

```
用户输入
  │
  ├─ hero <意图> ──────► hero-dispatch（lane-routing）
  │                        │
  │                        ├─ 重型线 ──► skill（hero-prd-to-java / hero-refresh）
  │                        └─ 轻量线 ──► playbook（bugfix/iterate/refactor/...）
  │
  └─ issue <command> ──► hero-issue-dispatch
                          │
                          └─ 读取标签 ──► 路由到对应 agent（花名映射）
```

执行时每个 lane 会打 `🦸 hero ▸` 标记，让用户感知 hero 体系接管。

## 与其他文档关系

- **SKILL.md 文件**：本目录 7 篇是对现有 SKILL.md 的**解读和补充**，不替代。每个文档开头有明确权威源声明。
- **现有文档**：`docs/hero-agent-layers.md`、`docs/hero-agent-roster.md`、`docs/codegraph-agent-plan.md` 等保持不变，本目录链接引用。
- **可视化页**：`site/public/mechanism.html` 提供机制可视化，本文档提供深度文字解读。

## 更新原则

- 每篇文档有明确的权威源 SKILL.md，修改 SKILL.md 时需同步更新对应文档
- 新增机制 → 新建文档 + 本 README 添加索引
- 删除机制 → 删除文档 + 本 README 移除索引
