# 5-Chapter Template Specification

所有 `agents/hero-*.md` 的 prompt body 必须包含下列 5 个章节（按顺序）。

---

## 1. `## Role`

**目的**：用一句话定义这个 agent 的核心身份和职责。

**内容要求**：
- 明确说明：这个 agent 是谁、为谁服务、解决什么问题
- 角色型 agent：强调职责范围（如"负责 Controller/Service 实现"）
- 领航型 agent：强调绑定服务和只读职责

**示例**（来自Demis Hassabis）：
```
你是Demis Hassabis——团队的战略架构师，负责将飞书 PRD 拆解为可执行的技术方案，规划 Sprint 节奏，协调Jeff Dean/Fei-Fei Li/Percy Liang等多位 Hero 并行推进。
```

---

## 2. `## Success Criteria`

**目的**：明确任务完成的可验证标准。

**内容要求**：
- 列出 3-5 条具体、可检验的输出结果
- 每条用 checkbox 格式 `[ ]`
- 必须是执行者自己可以验证的（不依赖外部审批）

**示例**（来自Jeff Dean）：
```markdown
- [ ] 代码已写入正确的包路径，无编译错误
- [ ] 单元测试通过（如有）
- [ ] 符合项目代码规范（无 PMD/SpotBugs 警告）
- [ ] 接口契约与 PRD 一致
```

---

## 3. `## Constraints`

**目的**：列出工具使用限制和行为边界。

**内容要求**：
- 所有 agent：说明 `tools:` 字段的实际含义（如"本 agent 没有 Write 权限"）
- 只读型 agent：**必须**显式声明只读约束（Chris Olah/Jan Leike/John Schulman/Oriol Vinyals/David Silver）
- 角色型 agent：说明可执行的工具范围
- 其他约束：禁止触碰的文件、禁止的操作等

**只读 agent 示例**：
```
- 本 agent 的 `tools:` 白名单不含 Write/Edit，即**只读**
- 只能通过 Bash 执行只读命令（ls, cat, grep, find）
- 不得通过 Bash 执行 git add/commit/push
- 不直接修复 Bug，只报告问题并推荐标准 Hero
```

---

## 4. `## Failure Modes`

**目的**：描述常见失败场景和恢复策略。

**内容要求**：
- 列出 2-3 个该角色容易犯的错误
- 每条配一个恢复策略
- 格式：失败场景 → 恢复动作

**示例**（来自Fei-Fei Li）：
```markdown
- 执行 `DROP TABLE` 或不可逆 DDL → STOP，确认是否有备份
- MyBatis `#{}` 写成 `${}` → 立即修复（SQL 注入风险）
- 事务注解未加 → 检查 Service 层，补 `@Transactional`
```

---

## 5. `## Final Checklist`

**目的**：提交前的自检清单。

**内容要求**：
- 列出 4-6 个必须在结束前完成的检查项
- 包含工具清理（如"关闭所有已打开的文件"）
- 包含进度报告（"报告完成进度，等待协调者分发下一任务"）
- 用 checkbox 格式 `[ ]`

**示例**（通用）：
```markdown
- [ ] 所有改动已保存，无未提交的文件
- [ ] 无遗留 `FIXME` 或 `TODO` 标记
- [ ] 已更新进度报告（`.omo/work-plan.md` 中对应的 checkbox）
- [ ] 报告任务结果，等待协调者分发下一任务
```

---

## 通用格式规则

1. 章节标题必须是 markdown 二级标题 `##`
2. 5 个章节的顺序**不可变**：Role → Success Criteria → Constraints → Failure Modes → Final Checklist
3. frontmatter 保持不变（name、description、model、tools、skills 字段）
4. 章节之间用一个 `---` 分隔线隔开（可选，但推荐）
