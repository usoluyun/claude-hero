# Draft: 领航 Agent 生命周期操作手册

> **状态**: 内容已完成，待执行代理移动到 `docs/navigator-lifecycle-handbook.md`。
> **目标位置**: `docs/navigator-lifecycle-handbook.md`（团队文档目录）
> **来源依据**: 基于 `scripts/hero-init.sh`、`skills/hero-refresh/SKILL.md`、`project-agent-cookbook.md`、`codegraph-agent-plan.md`、`hero-agent-roster.md`、`hero-agent-layers.md`、`.refresh-state.json` 等现有资产的完整梳理。

---

# 领航 Agent 生命周期操作手册

> 本手册是**新服务从零接入** + **已有服务持续保鲜** 的统一操作指南。
> 覆盖两大场景：`hero-init`（开荒）和 `hero-refresh`（保鲜）。
>
> 配套文档：
> - [`codegraph-agent-plan.md`](./codegraph-agent-plan.md) — 批量生成方案（为什么做、模板设计）
> - [`project-agent-cookbook.md`](./project-agent-cookbook.md) — 手动六步流程（原理 + 踩坑经验）
> - [`hero-agent-roster.md`](./hero-agent-roster.md) — 花名册（查已接入的 agent）
> - [`hero-agent-layers.md`](./hero-agent-layers.md) — 分层总图 + 能力矩阵

---

## 1. 两条路径速查

| 场景 | 触发方式 | 核心产物 | 何时用 |
|------|---------|---------|--------|
| **开荒（Init）** | `bash scripts/hero-init.sh <path> [花名]` | `agents/hero-java-<proj>.md` + Git 分支 + MR 指引 | 新服务首次接入，尚无领航 agent |
| **保鲜（Refresh）** | `hero 刷新 [<proj>]` | 重索引 + evidence pack + 漂移草稿（人工 gate） | 已有领航 agent，代码漂移后更新 |

**核心原则**：
- 开荒是**全自动**的（脚本完成 80%，人工 gate 20%）
- 保鲜是**两段式**的（确定性层自动 + 评审层人工 gate）
- 两者**解耦**：开荒完成后注册到 `.refresh-state.json`，才纳入保鲜范围

---

## 2. 开荒（Init）完整流程

### 2.1 前置条件

```bash
# 依赖工具（必须本地安装）
codegraph --version    # ≥ 0.9.7，支持 Java 语言解析
jq --version           # JSON 处理工具
git --version          # 版本控制

# 目标项目必须包含
ls <project_path>/pom.xml 2>/dev/null || ls <project_path>/build.gradle
ls <project_path>/src/main/java  # Java 源码目录
```

### 2.2 运行主脚本

```bash
bash scripts/hero-init.sh <project_path> [chinese_name]
```

**参数说明**：

| 参数 | 必填 | 说明 | 示例 |
|------|------|------|------|
| `project_path` | ✅ | 目标项目**绝对路径** | `~/Documents/ATLWork/owner-biz` |
| `chinese_name` | ⚪ 可选 | 花名（历史人物字号，必须唯一不可与现有 agent 冲突）。**留空时由脚本自动从字号池中分配一个未占用的花名** | `霞客`、`子文`、`郑和` |

**完整示例**：
```bash
# 显式指定花名
bash scripts/hero-init.sh ~/Documents/ATLWork/owner-biz 霞客

# 不指定花名，自动分配
bash scripts/hero-init.sh ~/Documents/ATLWork/owner-biz
```

### 2.3 六阶段执行过程

脚本按顺序执行以下 6 个 Phase，任一阶段失败会立即退出（`set -euo pipefail`）：

```
Phase 1: 布局检测
  ├─ detect_build_tool      — Maven / Gradle / 混合
  ├─ analyze_modules        — 单模块 / 多模块（含模块名列表）
  └─ get_project_name       — 从 pom.xml/artifactId 或目录名推导项目名

Phase 2: 技术栈检测
  ├─ detect_framework       — Spring Boot / Spring Cloud / 非 Spring
  └─ identify_middleware     — 中间件指纹（MQ / Cache / 注册中心 / ORM 等）

Phase 3: 代码证据收集
  ├─ collect_entry_points   — Controller / Service / Mapper / Listener / Job
  ├─ collect_config_files   — application.yml / logback.xml / build.gradle
  └─ collect_directory_structure — 目录树（深度 3，排除 target/.gradle/）

Phase 4: 模板填充
  └─ fill_template          — 读取 stack.json + layout.json + evidence.json →
                              填充 65+ 占位符 → agents/hero-java-<proj>.md

Phase 5: 反伪造验证
  ├─ verify_paths           — 引用的 Java 类是否真实存在（≥ 80% 命中率通过）
  ├─ verify_stack           — 声明的技术栈是否在 pom/gradle 中（≥ 70% 通过）
  └─ verify_keywords        — description 触发词是否规范

Phase 6: Git 分支创建
  ├─ create_branch          — feat/init-<proj>-<YYMMDD>
  ├─ commit_changes         — 自动 add + commit（agent.md + refresh-state）
  ├─ state_add              — 注册到 docs/.refresh-state.json（纳入保鲜范围）
  └─ print_mr_guidance      — 输出 push 命令 + MR URL + 描述模板
```

### 2.4 中间产物

脚本运行时产生的中间文件保存在 `.init-work/<proj>/`：

| 文件 | 内容 | 用途 |
|------|------|------|
| `layout.json` | 构建工具 + 模块信息 | Phase 4 模板填充 |
| `stack.json` | 框架 + 中间件指纹 | Phase 4 模板填充 |
| `evidence.json` | 代码入口 + 配置 + 目录树 | Phase 4 模板填充 |
| `checks.json` | Phase 5 验证结果摘要 | 人工评审参考 |

> 这些文件已 gitignore（`.gitignore: .init-work/`），不提交到仓库。

### 2.5 执行结果示例

```
$ bash scripts/hero-init.sh ~/Documents/ATLWork/some-service 文渊

🚀 开始生成导航 Agent: hero-java-some-service
项目路径: /Users/luyun/Documents/ATLWork/some-service
花名: 文渊

📊 Phase 1: 检测项目布局
✅ 构建工具: gradle
✅ 架构: 多模块（3 子模块）

📊 Phase 2: 检测技术栈
✅ 框架: spring-cloud
✅ Java: 17
✅ 中间件: 8 项

📊 Phase 3: 收集代码证据
✅ 控制器: 12
✅ 服务: 35
✅ Mapper: 22

📊 Phase 4: 填充模板
✅ 已生成: agents/hero-java-some-service.md

📊 Phase 5: 反伪造验证
✅ 路径验证通过（3/3 项检查）

📊 Phase 6: Git 分支与提交
✅ 分支: feat/init-some-service-260611

==========================================
  MR 创建指引
==========================================

步骤 1：推送分支
  git push -u origin feat/init-some-service-260611

步骤 2：创建 Merge Request
  MR URL: https://<git-host>/<org>/<repo>/-/merge_requests/new?merge_request[source_branch]=feat/init-some-service-260611

[... 描述模板 ...]

==========================================
🎉 导航 Agent 生成完成！
==========================================
```

### 2.6 开荒后的人工任务

脚本完成后，还有 **3 项人工任务** 不能自动化：

#### ① 注册花名册（必做）

在 `docs/hero-agent-roster.md` 的"花名册"表格追加一行。字段与现有 3 个 agent 对齐：

| Agent | proj | 中文名 | 业务关键词/别名 | 栈类型 | 项目路径 |

> **⚠️ 「业务关键词/别名」必须与 agent description「触发词：」那行保持一致**——这是 orchestrator 稳定路由的事实来源。

#### ② 登记能力矩阵（必做）

在 `docs/hero-agent-layers.md` 的两处各追一行：
- **「历史英雄代号映射」表** — Agent + 英雄代号 + 取名原因
- **「领航研究层」能力矩阵** — Agent + 英雄代号 + model + 触发词 + 应加载 skills + 该用 CLI + 怎么用

#### ③ 推送分支（按需）

脚本不会自动 push（决策 #2：安全推 MR）。手动执行：

```bash
git push -u origin feat/init-some-service-260611
```

---

## 3. 保鲜（Refresh）完整流程

### 3.1 触发方式

| 命令 | 作用 |
|------|------|
| `hero 刷新` | 刷新全部已接入项目（`.refresh-state.json`） |
| `hero 刷新 <proj>` | 只刷新单个项目 |
| `hero 刷新 评审` | 逐个过漂移草稿（人工 gate） |
| `hero 刷新 状态` | 列出已接入项目及其保鲜状态 |

### 3.2 两段式架构

```
┌─────────────────────────────────────────────────┐
│  确定性层（脚本自动，无人工干预）                    │
│  脚本：scripts/hero-refresh.sh [<proj>]           │
│                                                   │
│  - 重索引（codegraph init -i .）                  │
│  - 导出 evidence pack（结构/入口/依赖）             │
│  - 更新 .refresh-state.json                        │
│  - 抓 vendor docs（context7 文档缓存）             │
└──────────────────────┬──────────────────────────┘
                       │ 有漂移？
                       ▼
┌─────────────────────────────────────────────────┐
│  评审层（LLM 驱动，人工 gate 硬约束）               │
│  Skill：skills/hero-refresh/SKILL.md              │
│                                                   │
│  - 对比新 evidence vs 现有 agent                   │
│  - 无漂移 → 不生成草稿（仅索引刷新）                 │
│  - 有漂移 → 生成草稿到 .refresh-drafts/<proj>.md   │
│  - ⏸ STOP — 等用户确认后才覆盖线上 agent            │
└─────────────────────────────────────────────────┘
```

### 3.3 何时需要刷新？

| 触发条件 | 说明 |
|---------|------|
| 代码提交到 main 分支 | 脚本自动检测 `last_commit != HEAD` |
| 新增/删除 Controller 或 Feign Client | 结构性变更，agent ④需更新 |
| 顶层包结构变化 | 代码地图 ③需更新 |
| 依赖升级（框架版本/中间件） | 技术栈 ②需更新 |
| 定期保鲜（推荐每 2-4 周） | `hero 刷新 状态` 查看谁有新 commit |

### 3.4 什么不需要刷新？

以下变更**不**需要 agent 刷新（领域知识靠人工沉淀，脚本不碰语义）：

- 业务逻辑变更（状态机、实体关系）
- Bug fix、性能优化
- 配置文件调整（Apollo 配置项、JVM 参数）
- 纯 SQL 变更（mapper XML）

### 3.5 漂移判定标准

| 漂移类型 | 判定条件 |
|---------|---------|
| 入口变化 | evidence.entrypoints 出现 agent ④未记录的真实 Controller/Feign/MQ/Job |
| 入口消失 | agent ④记录的入口类在 evidence 中已不存在 |
| 包结构变化 | evidence.structure 顶层包与 agent ③不一致 |
| 技术栈变化 | 依赖指纹与 agent ②明显不一致 |

### 3.6 人工评审 Gate（rigid，不可跳过）

对每个草稿执行：

1. **展示漂移** — diff + 摘要
2. **反编造验证**（硬门槛）— 草稿引用的类必须 grep 零 MISSING：
   ```bash
   for c in <草稿引用的类名...>; do
     find <repo_path> -name "$c.java" >/dev/null 2>&1 && echo "OK $c" || echo "MISSING $c"
   done
   ```
3. **⏸ STOP — 等用户确认**：
   - 用户确认 → 覆盖 `agents/<agent>.md` + 删除草稿 + commit
   - 用户驳回 → 删除草稿，不动线上 agent
   - 用户修改 → 按反馈调整草稿，重新展示

> **每个项目的 agent 变更单独 commit**，始终有人工 gate——这是 rigid 规则。

---

## 4. 开荒 vs 保鲜：决策矩阵

```
新服务（尚无领航 agent）
    ↓
[开荒] bash scripts/hero-init.sh <path> [花名]
    ↓ Phase 6 产出 agent.md + Git 分支
    ↓ 人工：注册花名册 + 能力矩阵 + push
    ↓
已纳入保鲜范围（.refresh-state.json 自动注册）
    ↓
[保鲜] 定期/按需执行 hero 刷新
    ↓ 代码漂移 → 生成草稿 → 人工评审
    ↓
持续保鲜的生命周期
```

**判断标准**：
- 目标项目**没有** `agents/hero-java-<proj>.md` → 开荒
- 目标项目**已有** `agents/hero-java-<proj>.md` → 保鲜

---

## 5. 特殊场景处理

### 5.1 非 Spring 栈项目（如 BPM 平台）

**现象**：Phase 2 框架检测结果 `non-spring`，Phase 4 模板走"非 Spring"分支。

**已知案例**：`ecrm` — ActionSoft AWS BPM PaaS，`@Controller(type=OPENAPI) + @Mapping`，裸 DBSql。

**处理方式**：
- 脚本自动识别，模板生成"⚠️ 与团队 Spring 栈不同"警示
- 花名册登记时，栈类型标注 `⚠️` 并注明差异
- agent 正文列实际框架（不写"标准 Spring 栈"）

### 5.2 单体多业务域大项目

**现象**：`.java` > 1000，顶层包按业务域划分（banner / contract / telecom）。

**已知案例**：`owner-biz` — 1395 文件，23 个业务域，DDD 四层 + acl 防腐层。

**处理方式**：
- Phase 1 检测为单模块（非 Gradle 多模块，但包结构是多业务域）
- 脚本生成基础 agent，人工补充业务域列表（`BUSINESS_DOMAINS` 占位符）
- 如文件数 > 2000 或 > 15 顶层模块，考虑拆为多个 bounded-context agent：
  - 命名：`hero-java-<proj>-<domain>`
  - 阈值判断：参考 `docs/codegraph-agent-plan.md` 阶段 1

### 5.3 已有 agent 时需要重新生成（覆盖场景）

**现象**：`agents/hero-java-<proj>.md` 已存在，脚本报错退出。

**正确的做法**：
- 小更新 → 用保鲜流程（`hero 刷新`）
- 大改动 → 手动删除旧 agent → 重跑脚本（注意核对花名册和能力矩阵）

### 5.4 链式分支问题

**现象**：连续对多个项目运行脚本，第二个项目分支从第一个项目的分支创建。

**脚本已内置防护**（`hero-init.sh:257-258`）：
```bash
# 先切回 main，确保分支从 main 创建
git checkout main
```

---

## 6. 反伪造机制

**最高优先级约束**：agent 中引用的每个类/接口/方法必须真实存在。

### 6.1 脚本内置验证（Phase 5）

| 检查项 | 通过标准 | 失败处理 |
|--------|---------|---------|
| 路径检查 | 引用类 ≥ 80% 命中真实文件 | 输出 missing 列表，人工修正 |
| 技术栈检查 | 声明栈 ≥ 70% 在 pom/gradle 找到 | 输出 mismatches，核对依赖 |
| 关键词检查 | 触发词 ≥ 50% 合法（非纯标点/数字） | 输出 invalid 列表，补充关键词 |

### 6.2 人工反伪造（评审门控）

保鲜评审时，对草稿引用的每个类执行 grep 验证：

```bash
grep -Eo '(com\.[a-z0-9.]+\.[A-Z][a-zA-Z0-9]+)' <草稿>.md | sort -u | \
while read fqcn; do
  classname="${fqcn##*.}"
  find <repo_path> -name "${classname}.java" -print -quit 2>/dev/null \
    && echo "OK $classname" || echo "MISSING $classname"
done
```

> **零容忍**：任一 `MISSING` → 修正草稿再验，不得提交。

---

## 7. 状态追踪与故障排查

### 7.1 状态文件说明

`docs/.refresh-state.json` 记录每个已接入项目的保鲜状态：

| 字段 | 说明 |
|------|------|
| `repo_path` | 本地项目路径（`~` 展开为 `$HOME`） |
| `agent` | 对应领航 agent 名称 |
| `last_commit` | 上次保鲜时的 HEAD commit SHA（空 = 从未刷新） |
| `last_refreshed` | 最近一次刷新时间（ISO 8601） |

### 7.2 常见问题排查

| 问题 | 现象 | 原因 | 处理 |
|------|------|------|------|
| require_codegraph | 脚本启动失败 | codegraph 未安装 | `npm install -g codegraph` |
| 必须是绝对路径 | 脚本拒绝相对路径 | 传入了相对路径 | 改为绝对路径 |
| 未找到 .java 文件 | Phase 1 失败 | 目标目录无 Java | 检查路径；非 Java 项目不支持 |
| git 工作区有未提交变更 | Phase 6 失败 | claude-hero 仓库有改动 | 先 commit 或 stash |
| state_add: command not found | 注册失败 | refresh-state.sh 缺失 | 检查 `scripts/lib/refresh-state.sh` |
| Phase 5 MISSING 类 | 验证失败 | agent 编造了不存在的类 | 手动修正引用 |

### 7.3 中间文件清理

```bash
# 清理开荒中间产物（不影响线上 agent）
rm -rf .init-work/

# 清理保鲜中间产物
rm -rf docs/.refresh-work/

# 清理待审草稿（确认不需要评审后再清）
rm -rf docs/.refresh-drafts/
```

---

## 8. 命名规范

### 8.1 Agent 文件命名

**格式**：`hero-<lang>-<project_name>.md`

| 组成 | 规则 | 示例 |
|------|------|------|
| `hero-` | 固定前缀 | — |
| `<lang>` | 主要语言，小写 | `java`、`go`、`python` |
| `<project_name>` | 项目目录名，kebab-case 小写 | `owner-biz` |

**特殊**：单体多域拆分 → `hero-java-<proj>-<domain>.md`

### 8.2 花名规范

- 中文历史人物字号，2-4 字
- 不与现有花名册冲突
- 贴合项目业务特点

**已用花名**（查 `docs/hero-agent-roster.md` 确认最新）：
| 服务 | 花名 |
|------|------|
| ecrm | 子文 |
| hotel-product-center | 郑和 |
| owner-biz | 霞客 |

---

## 9. 依赖关系图

```
hero-init (开荒)
├── 产出 agents/hero-java-<proj>.md       — 领航 agent 定义
├── 更新 docs/.refresh-state.json         — 注册到保鲜范围（自动化）
├── 需人工更新 docs/hero-agent-roster.md  — 登记花名册
└── 需人工更新 docs/hero-agent-layers.md  — 登记能力矩阵

hero-refresh (保鲜)
├── 读写 docs/.refresh-state.json         — 保鲜进度
├── 读写 docs/.refresh-work/              — 临时 evidence
├── 读写 docs/.refresh-drafts/            — 待审草稿
├── 读写 docs/vendor-docs/                — 第三方文档缓存
└── 覆盖 agents/hero-java-<proj>.md       — 结构性漂移更新（人工 gate 后）

hero-prd-to-java (消费领航 agent)
└── 消费 agents/hero-java-<proj>.md       — 作为代码地图上下文
    （领航 agent 只读，PRD 工作流调用角色 agent 执行改动）
```

---

## 10. 快速命令索引

| 命令 | 作用 |
|------|------|
| `bash scripts/hero-init.sh <path> [花名]` | 开荒新服务（花名可选，留空自动分配） |
| `hero 刷新 [<proj>]` | 保鲜（全量或单项目） |
| `hero 刷新 评审` | 过漂移草稿（人工 gate） |
| `hero 刷新 状态` | 查看保鲜状态 |
| `cat docs/.refresh-state.json \| jq .projects.<proj>` | 查看某项目保鲜进度 |
| `ls docs/.refresh-drafts/` | 查看待审草稿 |
| `ls .init-work/` | 查看开荒中间产物 |
| `git log --oneline -- agents/hero-java-<proj>.md` | 查看某 agent 提交历史 |

---

## 附录 A：三个 Pilot 案例对比

| | ecrm | hotel-product-center | owner-biz |
|---|---|---|---|
| 开荒方式 | 手动六步 | 手动六步 | 脚本开荒 |
| 特殊性 | 非 Spring（ActionSoft BPM） | 标准 Spring Cloud | 单体多业务域 |
| 规模 | 35 文件 | 854 文件 | 1395 文件 |
| 栈 | ActionSoft BPM PaaS | Spring Boot 2.7.12/Java 17 | Spring Cloud 2.7.18 |
| 学习要点 | 脚本能识别非 Spring，花名册要标 ⚠️ | 验证脚本对标准栈处理 | 验证大单体，人工补业务域 |
| Phase 5 结果 | stack_check 误报（BPM 类非 Spring） | 3/3 通过 | 3/3 通过 |

---

*本手册由 Prometheus 于 2026-06-11 规划整理，内容基于完整的项目资产分析。*
