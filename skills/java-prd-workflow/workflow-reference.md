# 工作流参考模板

各步的输入/输出格式与最佳实践。

## Step 0：PRD 摄入模板（lark-doc skill）

### 输出摘要（Claude 呈现给用户）

```
✓ PRD 已读取：[特性名]
✓ Worktree 已创建：.worktrees/prd-{name}-{yyyymmdd}/
✓ Registry 已注册：feature/prd-{name}

PRD 摘要
--------
功能清单：
  1. [用户故事 1]
  2. [用户故事 2]
  ...

非功能需求：
  - 性能：[需求]
  - 安全：[需求]
  - 兼容性：[需求]

初判涉及服务：
  - 主服务：[name]（订单相关）
  - 子服务 A：[name]（支付）
  - 子服务 B：[name]（库存）

⏸ STOP — 请确认特性名、初判服务列表，或要求修改后重新开始
```

## Step 1：设计文档模板（java-tech-lead）

### 输出文件：`docs/design-{name}-{yyyymmdd}.md`

```markdown
# 技术设计文档 - {特性名}

## 概述
[特性背景与目标]

## 服务架构

### 主服务：{name}
- 职责：[描述]
- 技术栈：Spring Boot + Apollo + Eureka + SkyWalking + JetCache
- 关键接口：
  - GET /api/xxx - [说明]
  - POST /api/yyy - [说明]

### 子服务 A：{name}
- 职责：[描述]
- 需要实现的接口（由主服务委托）：
  - GET /api/payment/check - 检查支付状态
  - POST /api/payment/execute - 执行支付

### 子服务 B：{name}
- ...

## 服务依赖关系

\`\`\`mermaid
graph LR
  Main[主服务] -->|Feign 调用| A[子服务A]
  Main -->|Feign 调用| B[子服务B]
  A -->|Feign 调用| B
  style Main fill:#f9f,stroke:#333
  style A fill:#bbf,stroke:#333
  style B fill:#bfb,stroke:#333
\`\`\`

## 数据模型

\`\`\`mermaid
erDiagram
    USER ||--o{ ORDER : places
    ORDER ||--o{ ORDER_ITEM : contains
    ORDER ||--|| PAYMENT : requires
    style USER fill:#f9f
    style ORDER fill:#bbf
    style PAYMENT fill:#bfb
\`\`\`

主要表：
- USER：[字段列表]
- ORDER：[字段列表]
- PAYMENT：[字段列表]

## 关键时序

\`\`\`mermaid
sequenceDiagram
    participant User
    participant Main as 主服务
    participant PaymentA as 子服务A（支付）
    participant StockB as 子服务B（库存）
    
    User ->> Main: 下订单
    Main ->> StockB: 检查库存
    StockB -->> Main: 库存足够
    Main ->> PaymentA: 执行支付
    PaymentA -->> Main: 支付成功
    Main ->> StockB: 扣减库存
    StockB -->> Main: 扣减成功
    Main -->> User: 订单创建成功
\`\`\`

## 中间件选型

| 中间件 | 用途 | 配置 |
|------|------|------|
| **Apollo** | 配置管理 | `common.order`、`common.payment` namespaces |
| **Eureka** | 服务发现 | 所有服务在 Eureka 注册，应用名 = `order-service`、`payment-service` 等 |
| **RocketMQ** | 异步消息 | 订单创建事件 → `ORDER_CREATED_TOPIC`；支付成功事件 → `PAYMENT_DONE_TOPIC` |
| **JetCache** | 缓存 | 用户信息 → `user:{userId}` (30min)；订单状态 → `order:{orderId}` (10min) |
| **SkyWalking** | APM | 服务名 = `order-service`、`payment-service`；TraceId 打日志 |

## 接口委托清单

主服务需要子服务实现的接口（合同）。

### 子服务 A（支付）需要实现

```java
// 检查支付状态
GET /api/payment/{orderId}
Response: { status: "PENDING|SUCCESS|FAILED", amount: 100.00 }

// 执行支付
POST /api/payment/execute
Request: { orderId: "xxx", amount: 100.00, userId: "yyy" }
Response: { paymentId: "zzz", status: "SUCCESS" }

// 退款
POST /api/payment/refund
Request: { paymentId: "zzz", amount: 50.00 }
Response: { status: "SUCCESS", refundId: "aaa" }
```

### 子服务 B（库存）需要实现

```java
// 检查库存
GET /api/stock/{sku}
Response: { available: 100 }

// 预留库存
POST /api/stock/reserve
Request: { sku: "xxx", quantity: 10, orderId: "yyy" }
Response: { reserveId: "zzz", status: "SUCCESS" }

// 扣减库存
POST /api/stock/deduct
Request: { reserveId: "zzz" }
Response: { status: "SUCCESS" }
```

## 假设 & 风险

- 假设：子服务 A / B 都已经注册到 Eureka（前提条件）
- 风险：RocketMQ 消费端幂等（需要在子服务消费端实现）
- 风险：跨服务调用超时设置要合理（建议 3s-5s，需在 Feign 配置中）
```

### 输出摘要

```
✓ 技术设计文档已生成：docs/design-order-refund-20260605.md

主服务：order-service
子服务：
  - payment-service（子服务A）：需实现 3 个接口
  - stock-service（子服务B）：需实现 3 个接口

中间件：Apollo / Eureka / RocketMQ / JetCache / SkyWalking

⏸ STOP — 请审阅设计，确认无遗漏，或返工修改
```

## Step 2：Sprint 规划模板（java-tech-lead）

### 输出文件：`docs/sprint-{name}-{yyyymmdd}.md`

```markdown
# Sprint 计划 - {特性名}

## 概述
预计 2 周（2 个 Sprint）完成。

## Sprint 1（2026-06-05 ~ 2026-06-12）

### 目标
完成所有子服务接口定义（Contract First），主服务 Feign 调用框架。

| # | 功能 / 任务 | 服务 | 估算 | Agent | 前置依赖 | 优先级 |
|---|-----------|-----|------|-------|---------|--------|
| 1 | 库存服务：接口定义 + 数据模型设计 | stock-service | 1d | java-tech-lead | - | P0 |
| 2 | 库存服务：Mapper + 基础 CRUD | stock-service | 2d | mybatis-data-engineer | 1 | P0 |
| 3 | 支付服务：接口定义 + 数据模型 | payment-service | 1d | java-tech-lead | - | P0 |
| 4 | 支付服务：Mapper + 基础 CRUD | payment-service | 2d | mybatis-data-engineer | 3 | P0 |
| 5 | 订单服务：Feign 调用框架 + Apollo / Eureka 接入 | order-service | 2d | java-backend-developer | 1,3 | P0 |

### Sprint 目标达成标准
- [ ] 库存 / 支付接口定义已完成并提交到 feature 分支
- [ ] 订单服务 Feign 调用编译通过（虽然后端实现未完成）
- [ ] 所有接口已在 Eureka 注册

---

## Sprint 2（2026-06-12 ~ 2026-06-19）

### 目标
完成业务实现、测试、审查、合并。

| # | 功能 / 任务 | 服务 | 估算 | Agent | 前置依赖 | 优先级 |
|---|-----------|-----|------|-------|---------|--------|
| 6 | 库存服务：业务逻辑（check / reserve / deduct） | stock-service | 2d | java-backend-developer | 2 | P0 |
| 7 | 支付服务：业务逻辑（check / execute / refund） | payment-service | 2d | java-backend-developer | 4 | P0 |
| 8 | 订单服务：业务逻辑（create / query / cancel） + RocketMQ 异步 | order-service | 3d | java-backend-developer | 5,6,7 | P0 |
| 9 | TDD 单测（所有服务） | - | 2d | java-test-engineer | 6,7,8 | P0 |
| 10 | BDD 验收场景 + 集成测试 | - | 1d | java-test-engineer | 9 | P0 |
| 11 | 代码审查（质量 + 安全） | - | 1d | java-code-reviewer, java-security-auditor | 10 | P0 |
| 12 | 汇总 + 合并 | - | 0.5d | java-tech-lead | 11 | P0 |

### Sprint 目标达成标准
- [ ] 所有业务逻辑已实现并测试通过
- [ ] 代码审查无 🔴 红线问题
- [ ] 跨服务集成测试通过
- [ ] 设计文档与实现一致

---

## Gantt 图

\`\`\`mermaid
gantt
    title {特性名} - 开发时间轴
    dateFormat YYYY-MM-DD
    section Sprint 1
    接口定义（stock）     :s1t1, 2026-06-05, 1d
    Mapper（stock）       :s1t2, after s1t1, 2d
    接口定义（payment）   :s1t3, 2026-06-05, 1d
    Mapper（payment）     :s1t4, after s1t3, 2d
    Feign 框架（order）   :s1t5, after s1t1, 2d
    section Sprint 2
    业务逻辑（stock）     :s2t6, after s1t2, 2d
    业务逻辑（payment）   :s2t7, after s1t4, 2d
    业务逻辑（order）     :s2t8, after s1t5, 3d
    单测                 :s2t9, after s2t8, 2d
    BDD + 集成           :s2t10, after s2t9, 1d
    审查                 :s2t11, after s2t10, 1d
    汇总合并             :s2t12, after s2t11, 0.5d
\`\`\`

---

## 注释 & 风险

- **RocketMQ 异步**：任务 8 需要消费端幂等，unit test 要 mock 消费场景
- **Eureka 继续列表初始化慢**：Spring Boot 启动可能卡 10-15s，单独考虑本地集成测试时间
- **库存预留与扣减竞争**：需要数据库锁或乐观锁处理，SQL 性能测试在 Sprint 2 进行
```

### 输出摘要

```
✓ Sprint 计划已生成：docs/sprint-order-refund-20260605.md

Sprint 1（1 周）：准备阶段（接口定义 + Feign 框架）
  - 任务数：5
  - 关键路径：库存 / 支付接口定义 → 订单 Feign 框架

Sprint 2（1 周）：实现 + 测试 + 审查阶段
  - 任务数：7
  - 关键路径：业务实现（order service） → 单测 → BDD → 审查 → 合并

总工期：2 周

⏸ STOP — 请审阅 Sprint 计划，确认估算与优先级合理，或调整后重做
```

## Step 3：分派清单模板

（可写成独立文档或追加到 sprint doc）

```
# 任务分派清单 - {特性名}

## 主服务（order-service）Tech Lead 职责

1. **接口协调**
   - 监控子服务 A、B 的接口定义进度
   - 确保接口定义与设计文档一致
   - 在子服务接口就绪后通知 backend-developer

2. **Feign 调用框架**
   - 实现 Feign client 定义（@FeignClient(name = "payment-service") 等）
   - 配置超时、重试、降级策略
   - 与 Eureka / Apollo 集成

3. **集成验收**
   - 监控单测 / BDD / 集成测试进度
   - 协调跨服务的契约验证

**期望完成时间**：Sprint 1 末尾（接口框架完成）

---

## 子服务 A（payment-service）Tech Lead 职责

1. **Contract First**
   - 按"接口委托清单"完成接口定义（DTO + REST 路径）
   - 数据模型设计（Payment 表）

2. **业务实现**
   - 实现支付检查 / 执行 / 退款逻辑
   - 与 Apollo / Eureka / SkyWalking 集成
   - 配置 RocketMQ 消费（如有异步需求）

**期望完成时间**：
- Sprint 1：接口定义 + Mapper（1d）
- Sprint 2：业务逻辑（2d）

---

## 子服务 B（stock-service）Tech Lead 职责

（类似上面 payment-service）

---

## AI Agent 与人工的分工

| 模块 | AI Agent | 人工（可选） |
|------|---------|-----------|
| 接口定义 | java-tech-lead | 人工审核 + 确认 |
| 数据模型 | java-tech-lead | 人工调整（如有性能考虑） |
| Mapper + CRUD | mybatis-data-engineer | 人工审核 SQL |
| 业务逻辑 | java-backend-developer | 人工处理复杂逻辑 / 文化因素 |
| 单测 / BDD | java-test-engineer | 人工补充缺失的场景 |
| 代码审查 | java-code-reviewer | 人工最终确认 |
| 安全审计 | java-security-auditor | 人工修复 🔴 问题 |
```

## Step 5-6：测试 & 审查

### 测试报告模板

```
# 测试报告 - {特性名}

## 单测结果

| 服务 | 测试数 | 通过 | 失败 | 覆盖率 |
|------|-------|------|------|--------|
| order-service | 24 | 24 | 0 | 85% |
| payment-service | 18 | 18 | 0 | 80% |
| stock-service | 20 | 20 | 0 | 82% |

## BDD 验收

\`\`\`
功能：订单创建与支付

  场景：正常订单流程
    当用户下订单时
    那么订单状态应为 CREATED
    且支付流程应被触发
    且库存应被预留
  
  ✓ 通过

  场景：支付失败降级
    当支付失败时
    那么订单状态应为 PAYMENT_FAILED
    且库存预留应被释放
  
  ✓ 通过
\`\`\`

## 集成测试

跨服务接口测试：
- order-service 调用 payment-service：✓ 通过
- order-service 调用 stock-service：✓ 通过
- payment-service 与 stock-service 顺序：✓ 通过

## 总体结论

所有测试通过，覆盖率达到预期。
```

### 审查报告模板

```
# 代码审查报告 - {特性名}

## 🔴 必须修复（3 项）

1. **order-service/OrderService.java:45** - SQL 注入
   ```java
   // ❌ 错误
   String sql = "SELECT * FROM order WHERE id = " + orderId;
   
   // ✓ 修复
   String sql = "SELECT * FROM order WHERE id = #{orderId}";
   ```

2. **payment-service/PaymentService.java:120** - 事务问题
   ```java
   // ❌ 问题：@Transactional 标注在 private 方法，自调用失效
   @Transactional
   private void executePayment() { ... }
   
   // ✓ 修复：移到 public 方法
   @Transactional
   public void executePayment() { ... }
   ```

3. **stock-service/StockService.java:80** - RocketMQ 幂等
   消息消费端缺少幂等检查，需补充去重逻辑（参考 rocketmq-messaging skill）

## 🟡 建议改进（2 项）

1. order-service 缺少 SkyWalking TraceId 日志打印（参考 skywalking-apm skill）
2. JetCache 配置的 TTL 过长（30min），建议降到 10min 以减少缓存不一致窗口

## 🟢 代码风格建议（1 项）

- 服务名建议统一大小写（当前混用 payment_service 和 paymentService）

---

## 安全审计报告

| 项目 | 状态 |
|------|------|
| 依赖 CVE 扫描 | ✓ 通过（无高危依赖） |
| SQL 注入 | ❌ 1 处需修复（见上）|
| 鉴权 / 越权 | ✓ 通过（正确检查用户归属） |
| 敏感信息 | ✓ 通过（日志无密码打印） |
| 反序列化 | ✓ 通过（无不可信序列化） |

---

## 总体评分

代码质量：B+（需修复 🔴 问题后升 A）
```
```

## Step 7：验收报告模板

（追加到 sprint doc 末尾）

```markdown
---

## 验收报告

**验收人**：Claude（java-tech-lead）
**验收日期**：2026-06-19
**完成度**：100%（所有任务已完成 + 代码审查通过）

### 设计文档一致性

- [x] 服务架构与实现一致
- [x] 接口契约已完整实现
- [x] 数据模型（ER 图）与数据库设计一致
- [x] 中间件选型与实现匹配（Apollo / Eureka / RocketMQ / JetCache / SkyWalking）
- [x] 时序流程与实现逻辑一致

### 测试覆盖

- [x] 单测覆盖率：80%+
- [x] BDD 关键场景全覆盖
- [x] 集成测试：主服务 ↔ 子服务通信通过

### 代码质量

- [x] 🔴 红线问题已修复：3 处 SQL 注入 / 事务 / 幂等
- [x] 🟡 建议项大部分已采纳
- [x] 安全审计通过

### Git 产物

代码变更：
```
src/main/java/com/team/order/...      +850 -120
src/main/java/com/team/payment/...    +620 -90
src/main/java/com/team/stock/...      +780 -110
src/test/...                           +1200 -0
docs/design-order-refund-*.md          +0 -0 (新增)
docs/sprint-order-refund-*.md          +0 -0 (新增)
```

### 存在的遗留 Issue

- [ ] none

### 后续建议

1. 部署前再跑一次全链路压测，确保 RocketMQ 消费端幂等在高并发下稳定
2. 库存扣减可考虑优化为异步（MQ 通知），降低订单服务响应时间
3. 监控面板（SkyWalking UI）配置：关键接口的 99 percentile 应在 500ms 以内

---

## ✓ 验收通过

该 PRD 已通过所有阶段，准备进入 Step 8（跨需求验证合并）。
```

---

## 常见模板内容注意

- **每步输出都是结构化的**，用户一眼能看清楚做了什么、下一步是啥
- **所有图（mermaid）都要写清图例与标签**，避免歧义
- **估算要有底线**，基于历史任务或团队经验给出
- **风险与假设不能忽略**，提前识别可能的问题点
- **所有产物都归档到 worktree 的 `docs/` 目录**，随 feature 分支提交，不污染 main
