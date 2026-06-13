# omo/state Directory Schema

`.omo/state/` 是 claude-hero 的状态持久化层，从 `docs/` 下分散的状态文件迁移而来。

---

## 目录结构

```
.omo/state/
├── refresh-state.json          # Git 追踪：codegraph 索引刷新历史
├── workflow-registry.json      # Git 追踪：PRD 工作流注册表
├── agent-executions.json       # Git 追踪：agent 执行历史（新）
└── .cache/                     # Git 忽略：本地临时缓存（不共享）
```

---

## refresh-state.json

**来源**：从 `docs/.refresh-state.json` 迁移  
**写入者**：`scripts/lib/refresh-state.sh`、`hero-refresh.sh`  
**读取者**：`config/hooks/hero-refresh-check.sh`（SessionStart 漂移检测）

```json
{
  "$schema": "omo-state/refresh-state",
  "projects": [
    {
      "name": "owner-biz",
      "repo_path": "/path/to/owner-biz",
      "last_commit": "abc123def",
      "last_refreshed": "2026-06-10T08:30:00Z"
    }
  ]
}
```

---

## workflow-registry.json

**来源**：从 `docs/.workflow-registry.json` 迁移  
**写入者**：`hero-prd-to-java` skill（工作流执行时）  
**读取者**：`hero-prd-to-java` skill（恢复工作流时）

```json
{
  "$schema": "omo-state/workflow-registry",
  "active": [
    {
      "url": "https://open.feishu.cn/docx/xxx",
      "title": "PRD 标题",
      "worktree": "/path/to/worktree",
      "status": "design-phase",
      "created_at": "2026-06-10T10:00:00Z"
    }
  ],
  "merged": []
}
```

---

## agent-executions.json（新）

**写入者**：atlas 执行器（任务完成时追加）  
**读取者**：审计/复盘工具

```json
{
  "$schema": "omo-state/agent-executions",
  "executions": [
    {
      "agent_name": "hero-java-backend-developer",
      "timestamp": "2026-06-13T09:15:00Z",
      "task_description": "重写 文远 到 5 章节模板",
      "duration_ms": 120000,
      "status": "completed"
    }
  ]
}
```

---

## .cache/ 目录（Git 忽略）

用于本地临时文件（如 codegraph 临时输出、LLM 响应缓存）。  
在 `.gitignore` 中添加：

```
.omo/state/.cache/
```

---

## Git 追踪策略

| 文件 | 追踪 | 说明 |
|------|------|------|
| refresh-state.json | ✅ | 团队共享刷新状态 |
| workflow-registry.json | ✅ | 团队共享工作流进度 |
| agent-executions.json | ✅ | 团队共享执行历史 |
| .cache/* | ❌ | 个人本地缓存 |
