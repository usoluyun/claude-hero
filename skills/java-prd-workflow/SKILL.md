---
name: hero-prd-to-java
description: Java 微服务 PRD 驱动开发工作流（整体编排）。触发词：hero 开发工作流/hero-prd-to-java /hero-prd-to-java <URL>。读取飞书 PRD → 技术设计 → Sprint 计划 → 多服务并行开发 → 测试 → 审查 → 合并。支持多需求并行隔离（git worktree）、每步确认门控、跨需求集成验证。
---

# Java PRD 开发工作流（hero-prd-to-java）

**核心价值**：一条命令启动完整的 Java 微服务开发流水线，从飞书 PRD 到最终合并，全程有确认
门控、支持多个需求并行隔离、自动生成设计与计划文档。

---

## 快速开始

```
hero 开发工作流 https://feishu.cn/docx/xxxxxxxxxxxxxx

或

/hero-prd-to-java https://feishu.cn/docx/xxxxxxxxxxxxxx
```

同时可以查看所有在飞的 PRD 及状态：

```
hero 工作流状态
```

或触发已准备就绪的需求跨需求合并验证：

```
hero 合并验证
```

---

## 工作流 8 步全景

### Step 0：PRD 摄入 & Worktree 初始化

**输入**：飞书 PRD 链接 + 特性名（可选）

**执行**：
1. 用 `lark-doc` skill 读取飞书文档，提取：
   - 功能清单 / 用户故事
   - 非功能需求（性能 / 安全 / 兼容性）
   - 业务规则与数据约束
   - 初判涉及的微服务（按功能域）
2. 按 `superpowers:using-git-worktrees` 创建隔离工作区：
   - 检测已有 worktree（避免嵌套）
   - 创建 `.worktrees/prd-{name}-{yyyymmdd}/` 目录
   - 创建 `feature/prd-{name}` 分支，检出到 worktree
   - 确保 `.worktrees/` 在 `.gitignore` 中
3. 初始化 `docs/.workflow-registry.json`，注册本 PRD：
   ```json
   {
     "name": "...",
     "branch": "feature/prd-...",
     "worktree": ".worktrees/prd-...",
     "prd_url": "...",
     "status": "intake",
     "current_step": 0,
     "started_at": "2026-06-05"
   }
   ```

**产物**：
- 隔离 worktree 分支已创建
- PRD 摘要（功能 + 涉及服务初判）

**⏸ STOP**

呈现给用户：
```
✓ Worktree 已创建：.worktrees/prd-{name}/
✓ 分支已创建：feature/prd-{name}
✓ PRD 摘要：[功能清单]
✓ 初判涉及服务：[服务列表]
✓ Registry 已注册：状态 = intake

→ 用户确认：继续 / 修改特性名重新开始 / 终止
```

### Step 1：技术设计（java-tech-lead，opus）

**输入**：Step 0 的 PRD 摘要 + 用户确认

**执行**：使用 `java-tech-lead` agent（在当前 worktree 内）：
- 根据功能清单 + 初判服务拆解成完整的微服务架构
- 画出服务依赖图（mermaid 图，支持 claude-mermaid 渲染）
- 设计接口契约（REST /API 路径 + Feign DTO）
- 设计数据模型（ER 图，说明涉及的表与字段）
- 画出关键业务时序（mermaid sequence diagram）
- 说明中间件选型（Apollo / Eureka / RocketMQ / JetCache / SkyWalking，参考对应 skills）

**产物**：`docs/design-{name}-{yyyymmdd}.md`（写入 worktree）

**产出内容包括**：
- 主服务名称 + 职责
- 子服务清单（按依赖关系排序）
- 接口委托清单：{主服务} 需要 {子服务} 实现的接口（REST 路径 + DTO 签名）
- 服务依赖图（mermaid）
- 数据模型 ER 图（mermaid）
- 关键业务时序图（mermaid）
- 中间件选型说明

**⏸ STOP**

呈现设计文档摘要给用户：
```
✓ 技术设计文档已生成：docs/design-{name}-{yyyymmdd}.md

主服务：[name]
子服务：[list]
关键接口委托：
  - 主服务 → 子服务A: [接口列表]
  - 主服务 → 子服务B: [接口列表]

中间件：Apollo / Eureka / RocketMQ / ...

→ 用户确认：继续 / 修改返工 / 保存设计止步
```

### Step 2：Sprint 规划（java-tech-lead，opus）

**输入**：Step 1 的设计文档

**执行**：基于设计拆解成任务清单，按 Sprint 规划：
- 任务清单（每项标明：功能 / 涉及服务 / 估算 / 优先级 / 前置依赖）
- Sprint 分配（1 周 = 1 Sprint，按依赖拓扑排序 —— 子服务接口定义先于主服务实现）
- 每任务指派对应的 agent（backend-developer / data-engineer / test-engineer）
- 风险 & 备注

**产物**：`docs/sprint-{name}-{yyyymmdd}.md`（写入 worktree）

**产出内容包括**：
- Sprint 1 / Sprint 2 / ... 任务清单（表格形式）
- 每个任务：功能 / 服务 / 估算（如：2d） / agent / 前置依赖 / 优先级
- Gantt 图（mermaid，展示 Sprint 时间轴）
- 假设 & 风险列表

**⏸ STOP**

呈现 Sprint 计划摘要给用户：
```
✓ Sprint 计划已生成：docs/sprint-{name}-{yyyymmdd}.md

Sprint 1（1 周）：[任务数] 任务，重点：子服务接口定义
  - Task 1: [description]
  - Task 2: ...

Sprint 2（1 周）：[任务数] 任务，重点：主服务实现 + 子服务业务
  ...

预估总工期：[X 周]

→ 用户确认：继续 / 调整工时/优先级后重做 / 止步
```

### Step 3：任务分派

**输入**：Sprint 计划 + 用户确认

**执行**：java-tech-lead 生成分派说明文档（写入 worktree，可独立保存或追加进 sprint doc）：
- **主服务 Tech Lead 的职责**：
  - 全局接口协调（确保子服务接口对齐）
  - 等待子服务接口定义就绪（Step 1 接口委托清单）后才开始主服务 Feign 调用实现
  - 监控集成测试通过情况
- **各子服务 Tech Lead 的职责**：
  - 接收委托接口清单
  - 完成接口定义（Contract First）
  - 驱动子服务业务实现

**产物**：`docs/dispatch-{name}-{yyyymmdd}.md`（可选，也可追加到 sprint doc 末尾）

**⏸ STOP**

呈现分派清单给用户：
```
✓ 任务分派已生成：docs/dispatch-{name}-{yyyymmdd}.md

主服务：[name]
  Tech Lead 负责协调，Stage 1：等待子服务接口完成
  → 期望完成日期：[date]

子服务 A：[name]
  接口定义清单：[GET /api/xxx, POST /api/yyy, ...]
  Tech Lead 负责 Contract First，完成后通知主服务
  → 期望完成日期：[date]

子服务 B：...

→ 用户确认：继续 / 调整职责分工 / 止步
```

### Step 4：并行开发

**输入**：分派清单 + 用户确认

**执行**：在同一个 worktree 内，并行调用多个 `java-backend-developer` + `mybatis-data-engineer` agent，
分别实现各服务：

- **子服务优先**：接口定义 → 子服务业务实现 → 通知主服务
- **主服务等待**：接收子服务接口 → 实现 Feign 调用 + 业务逻辑
- 每个服务的实现 agent 遵循 team-conventions + 相关 skills（Apollo / Eureka / RocketMQ / JetCache）

**产物**：`.worktrees/prd-{name}/src/` 下各服务的业务代码

**⏸ STOP**

呈现实现进度摘要给用户：
```
✓ 各服务实现已完成（概览）：

主服务 [name]：
  + java-backend-developer 实现的内容：[行数/功能数]
  + mybatis-data-engineer 实现的内容：[mapper 数/SQL 复杂度]

子服务 A：
  + java-backend-developer：[摘要]
  + mybatis-data-engineer：[摘要]

子服务 B：...

Git diff 概览：[+XXX -YYY 行]

→ 用户确认：继续 / 返工某服务 / 止步
```

### Step 5：测试

**输入**：各服务实现代码 + 用户确认

**执行**：`java-test-engineer` agent（在 worktree 内）：
- **TDD 单测**：JUnit 5 + Mockito + AssertJ（每服务独立跑 `mvn test` / `./gradlew test`）
- **BDD 验收**：用 `gherkin` skill 写 `.feature` 文件，实现 Cucumber-JVM step definitions，
  验证关键业务场景
- **集成测试**：主服务与子服务接口集成（模拟/Mock 子服务，确保调用契约）

**产物**：
- `src/test/` 下的单测代码（JUnit 5）
- `.feature` 文件 + step definitions
- 集成测试报告

**⏸ STOP**

呈现测试结果给用户：
```
✓ 测试执行完成：

单测结果：
  主服务：[X tests, 0 failures, Y% coverage]
  子服务 A：[X tests, 0 failures, Y% coverage]
  子服务 B：...

BDD 验收：
  场景数：[X]，通过：[X]，失败：[0]

集成测试：[通过 / 有 N 个失败]
  - [失败 1 摘要]
  - [失败 2 摘要]

→ 用户确认（失败必须修复后再确认）：继续 / 修复后重跑 / 止步
```

### Step 6：代码审查（并行，只读）

**输入**：完整实现代码 + 测试通过

**执行**：同时调用 `java-code-reviewer` 和 `java-security-auditor` agent（只读，不改代码）：

**java-code-reviewer**：
- 空指针 / Optional 误用
- 并发（线程池 / ThreadLocal 泄漏 / 共享可变状态）
- 事务（`@Transactional` 自调用失效 / 传播行为 / 大事务 / 事务内远程调用）
- MyBatis（`${}` SQL 注入 / N+1 / resultMap / 分页）
- 中间件用法（RocketMQ 幂等 / JetCache 穿透 / Apollo 热更新 / Eureka 容错）
- 可观测（SkyWalking TraceId / 日志 / 异常）
- 多 JDK 兼容（1.8 vs 11/17 API）
- 资源关闭

**java-security-auditor**：
- 依赖漏洞（CVE 扫描）
- SQL 注入
- 鉴权 / 越权
- 敏感信息泄漏（日志 / 异常 / 配置）
- 反序列化

**产物**：审查报告（每个问题标记严重级别）

**⏸ STOP**

呈现审查报告给用户：
```
✓ 代码审查完成：

🔴 必须修复（[X] 项）：
  1. [service/file:line] - [问题] - [建议]
  2. ...

🟡 建议改进（[Y] 项）：
  1. [service/file:line] - [问题] - [建议]
  2. ...

🟢 风格建议（[Z] 项）：
  ...

→ 用户确认（🔴 必须全部修完再确认）：继续 / 返工某服务修复 / 止步
```

### Step 7：汇总验收

**输入**：所有审查问题已修复

**执行**：`java-tech-lead` agent：
- 核对设计文档（`docs/design-*.md`）与实现一致性（接口 / 数据模型）
- 更新 `docs/sprint-*.md`，添加"验收报告"小节（完成日期 / 完成人 / 是否有遗留 issue）
- 所有产物 commit 到 feature/prd-{name} 分支
- 更新 registry 状态为 `ready-to-merge`

**产物**：
- feature/prd-{name} 分支包含所有产物（代码 + 文档）
- registry 中该 PRD 状态已更新为 `ready-to-merge`

**⏸ STOP**

呈现验收报告给用户：
```
✓ 验收报告已生成（追加到 docs/sprint-{name}-{yyyymmdd}.md）：

验收人：Claude（java-tech-lead）
验收日期：2026-06-10
完成度：100%（所有任务已完成 + 审查通过）

设计文档一致性：✓ 通过
  - 接口契约对齐：✓
  - 数据模型对齐：✓
  - 中间件选型对齐：✓

Git 产物：
  代码变更：[+XXX -YYY 行]
  设计文档：docs/design-{name}-*.md
  计划文档：docs/sprint-{name}-*.md

→ 用户确认是否进入合并流程：继续 (Step 8) / 打回某服务修改 / 止步
```

### Step 8：跨需求验证合并（可选或触发词触发）

**触发**：用户在 Step 7 确认继续，或手动 `hero 合并验证`

**执行**：
1. 列出所有 registry 中状态为 `ready-to-merge` 的 PRD
2. 创建临时验证分支 `validate/batch-{timestamp}`，将所有 ready PRD merge 进去
3. 在临时分支上跑**全量集成测试**（所有服务+跨服务调用）
4. 根据结果：
   - **✓ 成功**：按 started_at 时间顺序逐个 merge 到 main，删除 worktree，更新 registry 为 `merged`
   - **✗ 失败**：报告冲突，指明是哪两个 PRD 冲突，建议返工给对应 worktree（保留隔离，不影响其他）

**产物**：
- 成功：所有 ready PRD 已合并到 main，worktree 清理
- 失败：冲突报告 + 指导返工

**⏸ STOP**

呈现合并结果给用户：
```
✓ 跨需求验证完成：

待合并 PRD：[prd-a, prd-b, prd-c]

验证结果：✓ PASSED（全量集成测试通过）

合并进度：
  ✓ prd-a 已合并到 main
  ✓ prd-b 已合并到 main
  ✓ prd-c 已合并到 main

工作区清理：
  - 删除 .worktrees/prd-a
  - 删除 .worktrees/prd-b
  - 删除 .worktrees/prd-c

Registry 已更新：所有 PRD 状态 = merged

→ 完成！所有 PRD 已成功集成到 main。
```

若失败：
```
✗ 跨需求验证失败：

冲突检测：prd-a 与 prd-b 存在数据模型冲突
  - 都修改了 User 表的 email 字段定义
  - 冲突位置：src/main/resources/db/migration/V*.sql

建议：
  1. 在 prd-a 的 worktree 中调整 User 字段定义，与 prd-b 对齐
  2. 运行 `hero 合并验证` 重新尝试

保留隔离：prd-c 不受影响，可独立继续进行。
```

---

## 关键约定

### 一、Worktree 隔离

- **每个 PRD = 一个独立 worktree**：`.worktrees/prd-{name}-{yyyymmdd}/`
- **多个 PRD 可同时活跃**，互不干扰（每个有自己的 feature/* 分支）
- **`.worktrees/` 必须在 `.gitignore`**（install 脚本自动验证）
- **Worktree 自动清理**：Step 8 成功后删除目录与分支

### 二、STOP 与确认门控（Rigid 规则）

每步末尾都有 **`⏸ STOP — 等待用户确认`**，属于 **rigid（不可跳过）** 规则。
- Claude **不能** 自行跳过任何 STOP
- 用户必须显式回复"**继续**"、"**proceed**"或类似确认词
- 用户可以回复"**修改**"、"**返工**"，将流程回到某个之前的步骤重做
- 用户可以回复"**止步**"，结束流程（产物保留在 worktree 中）

### 三、子服务先行（契约先行）

- 子服务的**接口定义**（REST API 路径 + DTO）必须在 Step 4 开始时就完成
- 主服务 backend-developer 必须**等待**子服务接口就绪才开始实现 Feign 调用
- 子服务的**业务实现**可与主服务并行进行

### 四、委托清单驱动

- Step 3 的"接口委托清单"是**主服务 → 子服务的合同**
- 子服务 Tech Lead 只需实现清单里的接口，不需要了解主服务全貌
- 减少跨服务的信息耦合

### 五、产物管理

- **设计 + 计划文档**：保存在 worktree 内 `docs/design-*.md` 和 `docs/sprint-*.md`
- **代码**：在 feature/prd-{name} 分支，worktree 内 `src/` 目录
- **注册表**：`docs/.workflow-registry.json` 在 main 分支，记录所有在飞/已合并 PRD
- **Worktree 本身不提交**：`.worktrees/` 在 `.gitignore`

### 六、跨需求失败隔离

- Step 8 中，若 PRD-A 与 PRD-B 冲突，**只影响这两个**
- 其他已 ready 的 PRD（如 PRD-C）**保留隔离**，可等 PRD-A 和 PRD-B 修复后再统一验证合并
- 不会因为一个 PRD 的问题而破坏已验证的其他 PRD

---

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

---

## 触发词速查

| 目的 | 触发词 | 说明 |
|------|--------|------|
| 启动新 PRD | `hero 开发工作流 <URL>` | 自然语言，从 URL 提取特性名（可手动指定） |
| 启动新 PRD | `/hero-prd-to-java <URL>` | Slash 命令形式 |
| 查看在飞 PRD | `hero 工作流状态` | 列出 registry 中所有 active PRD + 当前步骤 |
| 触发跨需求验证 | `hero 合并验证` | 手动触发 Step 8（多 PRD 集成测试 + 合并） |

---

## 常见场景 FAQ

**Q：我有 3 个 PRD 同时在开发，怎么管理？**

A：每个 PRD 独占一个 worktree（`.worktrees/prd-a`, `.worktrees/prd-b`, `.worktrees/prd-c`），
互不干扰。可以在任意一个 worktree 中做修改，git status 只显示该 worktree 的内容。
所有人共享同一个 registry（`docs/.workflow-registry.json`），清晰看到每个 PRD 的进度。

**Q：PRD-A 的 Step 4 还没完成，PRD-B 已经到了 Step 7，能合并吗？**

A：可以。Step 8（跨需求验证）会列出所有已 `ready-to-merge` 的 PRD（比如 PRD-B），
单独或和其他 ready 的 PRD 一起合并。PRD-A 继续在自己的 worktree 里开发，不影响。

**Q：Step 4 开发时发现设计有问题，怎么回退？**

A：在该步 STOP 时，你回复"返工"或"修改设计"，指定返工给 Step 1。
java-tech-lead agent 重新执行 Step 1（新的设计文档），待用户确认后继续 Step 2。

**Q：Step 8 中两个 PRD 冲突了，我只想先合并一个，行吗？**

A：不行。Step 8 是原子操作（all or nothing）——要么所有 ready PRD 一起通过集成测试后全部合并，
要么因冲突都不合并。如果你想只合并其中一个，可以在 Step 7 确认时选择"止步"，等另一个 PRD
修好后再一起触发 `hero 合并验证`。

---

## 与其他 Agent 的协作

- **java-tech-lead**：Step 1/2/3/7，负责设计 + 规划 + 分派 + 验收
- **java-backend-developer**：Step 4，实现业务逻辑（主/子服务）+ 中间件接入
- **mybatis-data-engineer**：Step 4（按需），实现 MyBatis + SQL
- **java-test-engineer**：Step 5，TDD 单测 + BDD 验收 + 集成测试
- **java-code-reviewer**：Step 6（只读），代码审查
- **java-security-auditor**：Step 6（只读），安全审计

所有 agent 遵循 `team-conventions` + 对应 middleware skills（apollo-config / eureka-discovery 等）。

---

## 核心附言

这个 skill 是团队日常开发的**操作中心**。每个 PRD 从飞书文档到最终合并 main，
都在确认门控下逐步推进，支持多需求并行隔离与跨需求验证。
没有"自动跳过某个步骤"的逻辑——确认是强制的，修改是可选的，流程的所有权在用户手中。
