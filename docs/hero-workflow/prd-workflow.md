> **权威源**：[`skills/hero-prd-to-java/SKILL.md`](../../skills/hero-prd-to-java/SKILL.md)
> **范围**：本文解读 PRD 驱动开发的 8 步流水线机制，不复制 SKILL.md 全文。

---

## 一句话引言

`hero 开发工作流 <飞书PRD链接>` 一条命令启动完整的 Java 微服务开发流水线，从飞书 PRD 读取到多服务并行开发、测试、审查、合并，全流程由 AI agent 协作完成，人只需在每步末尾回复"继续/返工/止步"。

## 8 步全景

| Step | 一句话要点 | 产物 | 主要 Agent |
|---|---|---|---|
| 0 | PRD 摄入 & Worktree 初始化 | `.worktrees/prd-{name}/` + registry 注册 | -- |
| 1 | 技术设计（先勘察存量现状，再增量设计） | `docs/design-*.md` | tech-lead |
| 2 | Sprint 规划 | `docs/sprint-*.md` | tech-lead |
| 3 | 任务分派（接口委托清单） | `docs/dispatch-*.md` | tech-lead |
| 4 | 并行开发（子服务先行） | 业务代码 | backend-dev + data-engineer |
| 5 | 测试（TDD + BDD + 集成） | 测试代码 + `.feature` | test-engineer |
| 6 | 代码审查（并行只读） | 审查报告 | code-reviewer + security-auditor |
| 7 | 汇总验收（更新 registry） | feature 分支完整产物 | tech-lead |
| 8 | 跨需求验证合并（可选触发） | main 合并 + worktree 清理 | -- |

Step 0 到 7 在 `feature/prd-{name}` 分支上线性推进。Step 8 是可选的最终集成步骤，支持多个 ready-to-merge 的 PRD 一起验证后批量合并到 main。

## 状态机

```
intake (Step 0)
  ↓
designing (Step 1)
  ↓
planning (Step 2)
  ↓
dispatched (Step 3)
  ↓
developing (Step 4)
  ↓
testing (Step 5)
  ↓
reviewing (Step 6)
  ↓
ready-to-merge (Step 7)
  ↓ (可选 Step 8，或多个 ready-to-merge PRD 一起触发)
merged (Step 8 成功)
```

9 个状态全在 `feature/prd-{name}` 分支上流转。registry（`docs/.workflow-registry.json`，main 分支）同步记录每一步的状态变更。跨需求失败不会污染全局状态：PRD-A 与 PRD-B 冲突只影响这两个，PRD-C 保留隔离。

## Worktree 隔离机制

每个 PRD 独占一个独立的 worktree，多个 PRD 可同时活跃、互不干扰：

- 目录命名：`.worktrees/prd-{name}-{yyyymmdd}/`
- 对应分支：`feature/prd-{name}`
- `.worktrees/` 必须在 `.gitignore` 中，worktree 本身不提交
- 所有设计/计划/代码/测试产物都落在 worktree 内，隔离于 main 分支
- Step 8 成功后自动清理：删除 worktree 目录 + 删除 feature 分支

多个 PRD 并行时的目录结构示意：

```
.worktrees/
  prd-user-auth-20260610/    ← PRD-A 的隔离区
  prd-order-flow-20260611/   ← PRD-B 的隔离区
  prd-payment-v2-20260612/   ← PRD-C 的隔离区
```

## 子服务先行 & 委托清单驱动

Step 3 产出的"接口委托清单"是主服务与子服务之间的合同。子服务 Tech Lead 按清单完成接口定义（Contract First），主服务 backend-dev 等待子服务接口就绪后才开始实现 Feign 调用。这样做的好处：

- 子服务只需关心清单里的接口，不需要了解主服务全貌
- 减少跨服务的信息耦合
- 接口契约先行，避免后期联调返工

## STOP 门控（rigid，不可跳过）

每步末尾都有一个 `⏸ STOP`，等待用户显式确认。这是 rigid 规则，Claude 不能自行跳过任何 STOP。

用户可以回复三种指令：

| 回复 | 效果 |
|---|---|
| **继续** / proceed | 进入下一步 |
| **返工** / 修改 | 回到之前的某个 Step 重做（如"返工 Step 1"） |
| **止步** | 结束流程，产物保留在 worktree 中 |

## 触发词速查

| 目的 | 触发词 |
|---|---|
| 启动新 PRD | `hero 开发工作流 <URL>` 或 `/hero-prd-to-java <URL>` |
| 查看在飞 PRD | `hero 工作流状态` |
| 触发跨需求验证 | `hero 合并验证` |

## 领航 agent 的 4 个插入点

领航 agent（`hero-java-<proj>`）是单服务、只读、codegraph 驱动的知识层，在 8 步流水线中有 4 个关键插入点：

| Step | 领航 agent 的角色 |
|---|---|
| 0 | **服务识别**：比对花名册（`docs/hero-agent-roster.md`），命中存量服务并记下对应领航 agent |
| 1 | **现状勘察**：用 codegraph 摸地图，产出勘察报告（现有入口/接口契约/影响面/领域坑），喂给 tech-lead 做增量设计 |
| 4 | **开发导航**：实现 agent 动手前取定位——"在哪改、影响谁"——领航喂定位，角色 agent 写代码 |
| 6 | **影响面复核**：用 `codegraph impact` 复核全部受影响 caller 是否都被审查与测试覆盖，防漏改老调用方 |

领航 agent 只负责"懂该服务、带路、圈影响面"，不写代码。跨服务的整体拆分、契约对齐、拓扑排序归 tech-lead 统一完成。

## 常见场景 FAQ

**Q: Step 4 开发中发现了设计缺陷，能回退吗？**

可以。在当前 Step 的 STOP 时回复"返工 Step 1"，工作流会回到设计阶段重新勘察和调整设计文档，已产生的代码保留在 worktree 中作为参考。调整设计后按正常流程推进。

**Q: 多个 PRD 同时在开发，怎么管理？**

每个 PRD 独占一个 worktree（`.worktrees/prd-{name}-{yyyymmdd}/`），分支隔离、互不干扰。通过 `hero 工作流状态` 查看 registry 中所有在飞 PRD 的当前步骤。Step 8 合并时，多个 ready-to-merge 的 PRD 可以一起验证，单个冲突不影响其他 PRD。
