# Draft: claude-hero vs oh-my-claudecode Agent 管理对比

## 用户意图
参考 oh-my-claudecode (OMC) 的多 agent 管理模式，讨论如何改进 claude-hero 的 agent 管理体系。

## 研究发现

### OMC 架构亮点
- 19 个 agent，4 个 lane（Build/Analysis, Review, Domain, Coordination）
- Agent 文件：YAML frontmatter + XML 结构化 prompt body（Role → Constraints → Investigation_Protocol → Output_Format → Failure_Modes → Examples → Checklist）
- TypeScript 注册层 + 自动模型路由（opus/sonnet/haiku 三级）
- 状态持久化 `.omc/` 目录
- Team mode 5 阶段流水线：plan → prd → exec → verify → fix
- 每个 agent 有 benchmark 套件
- Per-agent `disallowedTools`

### claude-hero 现状
- 9 个 agent（6 角色型 + 3 项目型），双轴分层
- 47 个 skill 目录
- manifest.yaml + install.sh 安装
- hero-dispatch 意图分诊
- 花名体系（孔明/文远/子长/希仁/玄成/鹏举/子文/郑和/霞客）

## 关键差异点
1. Agent prompt 结构：claude-hero 用自由文本，OMC 用 XML 强结构化
2. 模型路由：OMC 有 TypeScript 自动路由，claude-hero 靠 frontmatter model 字段
3. 注册/发现：OMC 有 TypeScript `definitions.ts` 统一注册，claude-hero 靠目录扫描
4. 基准测试：OMC 有 per-agent benchmarks，claude-hero 没有
5. 状态管理：OMC 有 `.omc/state/` 持久化，claude-hero 没有
6. 团队协作：OMC 有 Team mode 5 阶段，claude-hero 有 hero-prd-to-java 工作流

## 开放问题
- 是否需要引入 XML 结构化 prompt？
- 是否需要注册层/发现机制？
- 是否需要 benchmark？
- 模型路由是否需要改进？

## 用户决策

### 决策 1: Agent Prompt 结构
- **选择**: 保持自由文本 + 强化模板
- **解读**: 不做 XML 结构化，但在 markdown 中定义固定章节模板。每个 agent prompt 必须包含：Success Criteria、Constraints、Failure Modes、Final Checklist。改动小，好维护。
- **参考 OMC 的**: `<Role>`, `<Success_Criteria>`, `<Constraints>`, `<Failure_Modes_To_Avoid>`, `<Final_Checklist>` 五个章节

### 决策 2: 注册/发现机制
- **选择**: 加 AGENTS.md 元数据文件（在 agents/ 目录下）
- **解读**: 创建 `agents/AGENTS.md`，作为 agent 目录级索引文件，记录每个 agent 的能力、触发关键词、依赖、模型、只读/执行标记。类似花名册但更程序化。
- **与 docs/hero-agent-roster.md 的关系**: roster 是给人看的花名表；AGENTS.md 是给 agent 系统读的能力注册表

### 决策 3: 状态持久化
- **选择**: 引入 .omo/state 目录
- **解读**: 建立通用状态层，记录 agent 执行历史、中间状态、错误恢复点。支持 agent 恢复、重放、调试。

### 从 OMC 还可借鉴但暂不引入
- **Per-agent benchmark**: 有 19 个 benchmark 套件，对 9 个 agent 暂不必要
- **TypeScript 运行时注册层**: 太重，claude-hero 是 markdown-first 理念
- **Team mode 5 阶段**: hero-prd-to-java 已覆盖 PRD 工作流，轻量任务走 dispatch lane 已够
- **跨 provider 协作（Codex/Gemini/Grok）**: 当前纯 Claude，不急于多模型
- **HUD statusline**: 团队规模暂不涉及
- **Magic keyword triggers**: hook 检测魔法关键词 → skill，目前靠 `/` 命令
