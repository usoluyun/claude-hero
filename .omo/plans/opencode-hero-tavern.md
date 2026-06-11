# Hero Tavern - 仙剑客栈 Agent 监控看板

## TL;DR

> **Quick Summary**: 构建仙剑奇侠传风格的 Web 看板，实时展示 Claude Code (hero 漫威英雄) 和 OpenCode (omo 希腊神祇) 两批 agent 的运行状态，通过东西两厢分区呈现
>
> **Deliverables**:
> - 三层酒楼 Web 界面（HTML/CSS/JS，无框架）
> - FastAPI 后端（数据聚合 + 5 秒轮询刷新）
> - 18 个角色 sprite（9 漫威英雄 + 9 希腊神祇）
> - 4 种状态动画（active/idle/sleeping/error）
> - 完整测试套件（后端 TDD + 前端 E2E）
>
> **Estimated Effort**: Large (60 小时)
> **Parallel Execution**: YES - 3 waves，最大并行 4 个任务
> **Critical Path**: Claude Parser → Data Aggregator → API Endpoints → Frontend Integration

---

## Context

### Original Request

用户希望构建一个实时监控看板，展示 OpenCode 和 Claude Code 两套系统中 agent 的运行状态。要求仙剑奇侠传风格、东西两厢分区、Web 页面形式、5-10 秒定时轮询刷新、TDD 全流程测试。

### Interview Summary

**Key Discussions**:
- **技术栈**: 用户选择 FastAPI + 原生 HTML/CSS/JS，理由是轻量、无框架依赖、动画控制灵活
- **实时性**: 5-10 秒轮询，平衡实时性与性能消耗
- **视觉区分**: 东厢（金色朱红武侠风 + 漫威兵器架）vs 西厢（青紫银白神殿风 + 希腊神话元素）
- **测试策略**: TDD 全流程，后端单元测试 + Playwright E2E
- **功能边界**: 只读监控，不含控制、通知、多用户、历史趋势

**Research Findings**:
- **Claude Code 数据**: JSONL 文件存储在 `~/.claude/projects/{project}/*.jsonl`，包含 `sessionId`, `timestamp`, `message.content` 等字段，但**没有显式 agent 字段**，需要从 content 中匹配 "🦸 hero ▸ <AgentName>" 格式
- **OpenCode 数据**: SQLite 数据库在 `~/.opencode/opencode.db`，`session` 表有明确的 `agent` 字段、`time_updated`、`tokens_input/output`
- **状态推断**: 两个系统都没有原生 status 字段，需要基于最后活动时间阈值推断（active: <5min, idle: 5min-1h, sleeping: >1h, error: 检测异常消息）
- **阻塞检测**: Claude Code 检测 "waiting for user input" 模式，OpenCode 检测 `status="waiting"` 或 `time_updated` 超过 10 分钟无变化

### Metis Review

**Identified Gaps** (addressed):
- **数据源格式不明确**: 已通过探查确认 JSONL schema 和 SQLite 表结构，详见 "Work Objectives → References"
- **状态定义不严谨**: 已定义 4 种状态的明确时间阈值和检测逻辑
- **项目结构未规划**: 已确定标准 Python 项目结构（`src/`, `tests/`, `web/static/`）
- **性能考量缺失**: 已添加 SQLite WAL 模式、JSONL 流式解析、内存缓存等优化
- **错误处理不完善**: 已添加数据源不存在、格式错误、权限不足的降级策略

---

## Work Objectives

### Core Objective

构建一个仙剑客栈风格的 Web 看板，实时展示 Claude Code hero 系列（9 个漫威英雄）和 OpenCode omo 系列（9 个希腊神祇）agent 的运行状态、历史统计、消息流和阻塞提示。

### Concrete Deliverables

1. **后端 API 服务** (FastAPI)
   - 数据聚合层：解析 Claude Code JSONL + 查询 OpenCode SQLite
   - 状态推断引擎：基于时间阈值的 4 状态检测（active/idle/sleeping/error）
   - RESTful API：`/api/status`, `/api/history`, `/api/messages`, `/api/blocked`
   - 5 秒轮询刷新：`/api/status` 定时拉取最新数据
   - 配置管理：环境变量控制数据源路径、轮询间隔、状态阈值

2. **前端看板界面** (HTML/CSS/JS)
   - 三层酒楼场景（东厢/中央/西厢）
   - 18 个角色 sprite + 4 种状态动画
   - 实时数据绑定（轮询刷新）
   - 交互式面板（点击查看任务详情）
   - 历史统计图表（今日任务数、成功率、Token 消耗）

3. **测试套件**
   - 后端单元测试（80%+ 覆盖率）
   - API 端点集成测试
   - 前端 E2E 测试（Playwright）

### Definition of Done

- [x] 后端服务启动无错误，所有 API 端点正常响应
- [x] 前端页面加载成功，东西两厢正确渲染 18 个角色
- [x] 状态自动更新（5-10 秒间隔），4 种状态动画正确播放
- [x] 历史统计、消息流、阻塞提示面板数据准确
- [x] 测试套件全部通过（`pytest` + `playwright test`）
- [x] 代码覆盖率 ≥ 80%（后端服务层）
- [x] 性能符合预期（API 响应 < 200ms，页面渲染 < 3s）

### Must Have

- **数据源集成**: 正确解析 Claude Code JSONL 和 OpenCode SQLite
- **状态推断**: 基于时间阈值的 4 状态检测（active/idle/sleeping/error）
  - **实时刷新**: 轮询模式，间隔 5-10 秒
- **视觉区分**: 东厢（武侠金色）vs 西厢（神殿银色），色调 + 装饰差异
- **角色映射**: hero 系列 9 个漫威英雄 + omo 系列 9 个希腊神祇
- **历史统计**: 今日任务数、成功率、Token 消耗、消息流（最近 20 条）
- **阻塞提示**: 检测 Claude Code "waiting for user input" + OpenCode `status="waiting"`
- **错误降级**: 数据源不存在/格式错误/权限不足时显示友好提示
- **TDD 测试**: 后端单元测试 + API 集成测试 + 前端 E2E 测试

### Must NOT Have (Guardrails)

- **不包含 agent 控制**: 只读监控，不提供启动/停止/重启功能
- **不包含通知系统**: 不发送邮件/Slack/飞书通知
- **不包含多用户支持**: 单用户本地运行，无登录/权限管理
- **不包含历史趋势**: 仅展示今日统计，不保存历史数据
- **不包含主题切换**: 固定仙剑客栈风格，不支持换肤
- **不包含自定义指标**: 不暴露 Prometheus metrics 或 Grafana 集成
- **不包含移动端适配**: 桌面浏览器优先，不针对手机/平板优化

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision

- **Infrastructure exists**: YES (pytest + Playwright)
- **Automated tests**: TDD (test-first approach)
- **Framework**: pytest (backend) + Playwright (frontend E2E)
- **TDD**: Each backend task follows RED (failing test) → GREEN (minimal impl) → REFACTOR

### QA Policy

Every task MUST include agent-executed QA scenarios. Evidence saved to `.omo/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Backend**: Use Bash (curl) - Send requests, assert status + response fields
- **Frontend**: Use Playwright - Navigate, interact, assert DOM, screenshot
- **Test Suite**: Use Bash (pytest/playwright) - Run tests, assert pass rate

---

## Execution Strategy

### Parallel Execution Waves

> Maximize throughput by grouping independent tasks into parallel waves.
> Each wave completes before the next begins.
> Target: 4 tasks per wave.

```
Wave 1 (Start Immediately - foundation + parsers):
├── Task 01: Project Scaffolding [quick]
├── Task 02: Claude Code Parser [deep]
├── Task 03: OpenCode SQLite Parser [deep]
└── Task 04: Frontend Scaffolding [quick]

Wave 2 (After Wave 1 - aggregation + API + scene):
├── Task 05: Data Aggregator & Status Inference (depends: 02, 03) [deep]
├── Task 06: API Endpoints (depends: 05) [unspecified-high]
├── Task 07: Tavern Scene Rendering (depends: 04) [visual-engineering]
└── Task 08: Character Sprites & Animations (depends: 07) [visual-engineering]

Wave 3 (After Wave 2 - integration + testing):
  ├── Task 09: Real-time Updates (Polling) (depends: 06, 08) [deep]
├── Task 10: Interactive Panels (depends: 09) [visual-engineering]
├── Task 11: Performance Optimization (depends: 10) [unspecified-high]
└── Task 12: Documentation & Deployment (depends: 06) [quick]

Wave FINAL (After ALL tasks — 4 parallel reviews, then user okay):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 02 → Task 05 → Task 06 → Task 09 → Task 10 → F1-F4 → user okay
Parallel Speedup: ~40% faster than sequential
Max Concurrent: 4 (Waves 1 & 2)
```

### Dependency Matrix (abbreviated - show ALL tasks in your generated plan)

- **01**: - - 05, 1
- **02**: - - 05, 1
- **03**: - - 05, 1
- **04**: - - 07, 1
- **05**: 02, 03 - 06, 2
- **06**: 05 - 09, 2
- **07**: 04 - 08, 2
- **08**: 07 - 09, 2
- **09**: 06, 08 - 10, 3
- **10**: 09 - 11, 3
- **11**: 10 - F1-F4, 3
- **12**: 06 - F1-F4, 3

> This is abbreviated for reference. YOUR generated plan must include the FULL matrix for ALL tasks.

### Agent Dispatch Summary

- **1**: **4** - T01 → `quick`, T02 → `deep`, T03 → `deep`, T04 → `quick`
- **2**: **4** - T05 → `deep`, T06 → `unspecified-high`, T07 → `visual-engineering`, T08 → `visual-engineering`
- **3**: **4** - T09 → `deep`, T10 → `visual-engineering`, T11 → `unspecified-high`, T12 → `quick`
- **FINAL**: **4** - F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

> Implementation + Test = ONE Task. Never separate.
> EVERY task MUST have: Recommended Agent Profile + Parallelization info + QA Scenarios.
> **A task WITHOUT QA Scenarios is INCOMPLETE. No exceptions.**
> **FORMAT**: Task labels MUST use bare numbers: `01.`, `02.`, `03.` — NOT `T1.`, `Task 1.`, `Phase 1:`.

- [x] 01. Project Scaffolding & Configuration

  **What to do**:
  - Create project directory structure: `hero-tavern/` with `src/`, `tests/`, `web/static/`
  - Initialize virtual environment with `requirements.txt`
  - Create `.env.example` with configuration keys
  - Add `__init__.py` files to make `src/` a proper Python package

  **Must NOT do**:
  - Don't create nested package structures (keep flat)
  - Don't add unnecessary dependencies (only FastAPI/uvicorn/pytest/playwright)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `superpowers:test-driven-development` - for test-first setup
  - **Skills Evaluated but Omitted**: `frontend-nextjs-developer` - not needed for plain HTML/JS frontend

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 02, 03, 04)
  - **Blocks**: Task 05, 09, 12
  - **Blocked By**: None (can start immediately)

  **References**:
  - Standard Python project layout: `src/`, `tests/`, `web/` for separation
  - `.env.example` should include: `CLAUDE_LOGS_PATH`, `OPENCODE_DB_PATH`, `POLL_INTERVAL`

  **Acceptance Criteria**:
  ```
  Scenario: Project structure verification
    Tool: Bash
    Steps:
      1. Check directory exists: hero-tavern/src/, hero-tavern/tests/, hero-tavern/web/static/
      2. Check __init__.py exists in src/
      3. Check requirements.txt contains: fastapi, uvicorn, pytest, playwright
      4. Check .env.example contains all required configuration keys
    Expected: All checks pass
  ```

**Commit**: `chore(hero-tavern): initialize project structure`

---

- [x] 02. Claude Code JSONL Parser

  **What to do**:
  - Implement `src/parsers/claude_parser.py` with function `parse_claude_logs()`
  - Parse JSONL files from `~/.claude/projects/{project}/*.jsonl`
  - Extract: `sessionId`, `timestamp`, `message.content`, `message.tool_use_name`
  - Match hero agent pattern: "🦸 hero ▸ <AgentName>(<agent-id>)" in message content
  - Filter logs by time range (default: last 24 hours)
  - Return list of `{agent_id, agent_name, last_active, messages: []}` objects

  **Must NOT do**:
  - Don't load entire JSONL into memory (use streaming parser)
  - Don't hardcode file paths (use config.CLAUDE_LOGS_PATH)
  - Don't include messages without agent identification

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: `superpowers:test-driven-development` - TDD workflow
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 01, 03, 04)
  - **Blocks**: Task 05
  - **Blocked By**: None

  **References**:
  - Actual JSONL fields discovered: `uuid`, `parentUuid`, `type`, `timestamp`, `sessionId`, `message`, `userType`, `cwd`, `gitBranch`, `slug`
  - Message structure: `{role, content, tool_use: {name, input}}`
  - Hero agent pattern: "🦸 hero ▸ <Marvel Name>(<agent-id>)" in `message.content`
  - Example: "🦸 hero ▸ Iron Man(hero-java-backend-developer)"

  **Acceptance Criteria**:
  ```
  Scenario: Parse sample JSONL file
    Tool: Bash (pytest)
    Steps:
      1. Create test fixture with sample JSONL data (3 sessions, 5 messages each)
      2. Run pytest tests/test_claude_parser.py -v
      3. Verify output contains correct agent_id, agent_name, last_active
      4. Verify hero agent pattern matching (Iron Man, Spider-Man detected)
      5. Verify time filtering (messages older than 24h excluded)
    Expected: All tests pass, 5 assertions minimum

  Scenario: Handle missing/corrupt JSONL
    Tool: Bash (pytest)
    Steps:
      1. Test with non-existent path → should return empty list
      2. Test with corrupt JSON line → should skip line and continue parsing
      3. Test with empty file → should return empty list
    Expected: Graceful degradation, no exceptions raised
  ```

**Commit**: `feat(hero-tavern): implement Claude Code JSONL parser`

---

- [x] 03. OpenCode SQLite Parser

  **What to do**:
  - Implement `src/parsers/opencode_parser.py` with function `query_opencode_sessions()`
  - Connect to SQLite database at `~/.opencode/opencode.db` with WAL mode enabled
  - Query `session` table: `id`, `agent`, `time_updated`, `tokens_input`, `tokens_output`, `status`
  - Map agent names to Greek mythology characters:
    - "Sisyphus - ultraworker" → "Sisyphus"
    - "Prometheus - Plan Builder" → "Prometheus"
    - "Hephaestus" → "Hephaestus"
    - etc.
  - Filter by time range (default: last 24 hours)
  - Return list of `{agent_id, agent_name, last_active, tokens_in, tokens_out}` objects

  **Must NOT do**:
  - Don't hold database connection open (use context manager)
  - Don't hardcode database path (use config.OPENCODE_DB_PATH)
  - Don't include raw agent strings (normalize to character names)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: `superpowers:test-driven-development` - TDD workflow
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 01, 02, 04)
  - **Blocks**: Task 05
  - **Blocked By**: None

  **References**:
  - SQLite schema: `session` table with `id TEXT`, `agent TEXT`, `time_updated INTEGER`, `tokens_input INTEGER`, `tokens_output INTEGER`, `status TEXT`
  - Actual agent names: "Sisyphus - ultraworker", "Prometheus - Plan Builder", "Hephaestus", "Atlas - Plan Executor", "Metis - Plan Consultant", "Momus - Plan Critic", "explore", "librarian", "oracle", "plan", "build", "feishu-driver", "feishu-obsidian-sync", "doc-analyzer-curator"
  - WAL mode: `PRAGMA journal_mode=WAL;` for concurrent read access

  **Acceptance Criteria**:
  ```
  Scenario: Query sample SQLite database
    Tool: Bash (pytest)
    Steps:
      1. Create test fixture with sample SQLite database (5 sessions)
      2. Run pytest tests/test_opencode_parser.py -v
      3. Verify output contains correct agent_id, agent_name, last_active, tokens
      4. Verify agent name normalization (Sisyphus - ultraworker → Sisyphus)
      5. Verify time filtering (sessions older than 24h excluded)
    Expected: All tests pass, 5 assertions minimum

  Scenario: Handle missing/corrupt database
    Tool: Bash (pytest)
    Steps:
      1. Test with non-existent database → should return empty list
      2. Test with corrupt database → should return empty list with log warning
      3. Test with empty database → should return empty list
    Expected: Graceful degradation, no exceptions raised
  ```

**Commit**: `feat(hero-tavern): implement OpenCode SQLite parser`

---

- [x] 04. Frontend Project Scaffolding

  **What to do**:
  - Create `web/static/` directory structure: `css/`, `js/`, `assets/`
  - Create `web/static/index.html` with basic HTML5 structure
  - Create `web/static/css/tavern.css` with CSS Grid layout (3 columns: East Wing, Main Hall, West Wing)
  - Create `web/static/js/tavern.js` with placeholder scene rendering function
  - Add basic color scheme: East Wing (gold/red #D4AF37, #B22222), West Wing (silver/blue #C0C0C0, #4169E1)

  **Must NOT do**:
  - Don't add frontend frameworks (React/Vue/Angular)
  - Don't add build tools (webpack/vite) - use plain HTML/CSS/JS
  - Don't add npm/Node.js dependencies

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-design` - for UI/UX guidance
  - **Skills Evaluated but Omitted**: `frontend-nextjs-developer` - not needed for plain JS

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 01, 02, 03)
  - **Blocks**: Task 07
  - **Blocked By**: None

  **References**:
  - CSS Grid layout for 3-column structure
  - Color palette: East Wing (#D4AF37 gold, #B22222 crimson), West Wing (#C0C0C0 silver, #4169E1 royal blue)
  - Tavern aesthetic: wooden textures, lantern glow, ink wash style

  **Acceptance Criteria**:
  ```
  Scenario: Frontend structure verification
    Tool: Bash
    Steps:
      1. Check directory exists: web/static/css/, web/static/js/, web/static/assets/
      2. Check index.html contains: <div class="tavern-scene">, <div class="east-wing">, <div class="west-wing">
      3. Check tavern.css contains grid-template-columns with 3 columns
      4. Check tavern.js exports renderScene() function
    Expected: All checks pass

  Scenario: Visual structure verification
    Tool: Playwright
    Steps:
      1. Start dev server: python -m http.server 3000
      2. Load http://localhost:3000/static/index.html
      3. Screenshot: .omo/evidence/task-04-visual-structure.png
      4. Verify 3-column layout renders correctly
    Expected: Screenshot shows 3 distinct sections with correct color coding
  ```

**Commit**: `feat(hero-tavern): scaffold frontend project structure`

---

- [x] 05. Data Aggregator & Status Inference

  **What to do**:
  - Implement `src/aggregator/aggregator.py` with class `TavernAggregator`
  - Aggregate data from both parsers: `claude_agents` + `opencode_agents`
  - Implement 4-state inference logic based on `last_active` timestamp:
    - `active`: last_active < 5 minutes ago
    - `idle`: last_active between 5 minutes and 1 hour ago
    - `sleeping`: last_active > 1 hour ago
    - `error`: detect error keywords in messages ("error", "exception", "failed", "crash")
  - Merge agent lists into unified format: `{id, name, wing: "east"|"west", status, last_active, tokens, messages}`
  - Add memory cache with 30-second TTL to avoid re-parsing on every poll

  **Must NOT do**:
  - Don't cache for longer than 30 seconds (stale data risk)
  - Don't include agents without any activity in the time window
  - Don't normalize status to lowercase (keep as enum: ACTIVE/IDLE/SLEEPING/ERROR)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: `superpowers:test-driven-development` - test state transitions
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (with Tasks 06, 07, 08)
  - **Blocks**: Task 06, 09
  - **Blocked By**: Task 02, Task 03

  **References**:
  - State transition thresholds: active (<5min), idle (5min-1h), sleeping (>1h)
  - Error detection: scan message content for "error", "exception", "failed", "crash", "traceback"
  - Cache strategy: 30-second TTL, invalidate on manual refresh
  - Data structure: `AgentStatus(id, name, wing, status, last_active, tokens_in, tokens_out, messages)`

  **Acceptance Criteria**:
  ```
  Scenario: Aggregate agents from both sources
    Tool: Bash (pytest)
    Steps:
      1. Create test fixtures: 3 Claude agents, 3 OpenCode agents
      2. Run aggregator.aggregate_agents()
      3. Verify output contains 6 agents with correct wing assignment
      4. Verify East Wing agents: claude_agents (wing="east")
      5. Verify West Wing agents: opencode_agents (wing="west")
    Expected: All assertions pass

  Scenario: Status inference logic
    Tool: Bash (pytest)
    Steps:
      1. Test with last_active = now - 2 minutes → should be ACTIVE
      2. Test with last_active = now - 10 minutes → should be IDLE
      3. Test with last_active = now - 2 hours → should be SLEEPING
      4. Test with message containing "error" → should be ERROR
    Expected: All 4 status transitions correct

  Scenario: Cache behavior
    Tool: Bash (pytest)
    Steps:
      1. Call aggregate_agents() twice within 30 seconds
      2. Verify second call returns cached data (same object id)
      3. Wait 31 seconds, call again
      4. Verify fresh data fetched (different object id)
    Expected: Cache hits within TTL, cache miss after TTL
  ```

**Commit**: `feat(hero-tavern): implement data aggregator with status inference`

---

- [x] 06. RESTful API Endpoints (FastAPI)

  **What to do**:
  - Implement `src/api/main.py` with FastAPI application
  - Create 4 API endpoints:
    - `GET /api/status` → current aggregate status (all agents)
    - `GET /api/history` → historical statistics (last 24h)
    - `GET /api/messages` → recent messages (last 20)
    - `GET /api/blocked` → agents waiting for user input or stalled
  - Add CORS middleware for cross-origin requests
  - Add request logging middleware
  - Implement blocked agent detection:
    - Claude: messages with "waiting for user input" or "🦸 hero ▸ STOP"
    - OpenCode: `status="waiting"` or no activity for >10 minutes despite active session

  **Must NOT do**:
  - Don't add authentication/authorization (single-user local tool)
  - Don't add rate limiting (local tool, no public exposure)
  - Don't return raw JSONL/SQLite data (always transformed by aggregator)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `superpowers:test-driven-development` - API endpoint tests
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (with Tasks 05, 07, 08)
  - **Blocks**: Task 09
  - **Blocked By**: Task 05

  **References**:
  - FastAPI docs: https://fastapi.tiangolo.com/
  - CORS setup: `from fastapi.middleware.cors import CORSMiddleware`
  - Blocked detection patterns:
    - Claude: "waiting for user input", "🦸 hero ▸ STOP", "awaiting confirmation"
    - OpenCode: `status="waiting"`, `time_updated` gap >10 minutes with active session

  **Acceptance Criteria**:
  ```
  Scenario: GET /api/status endpoint
    Tool: Bash (curl + pytest)
    Steps:
      1. Start API: python -m uvicorn src.api.main:app --reload
      2. Call: curl http://localhost:8000/api/status
      3. Verify response structure: {east_wing: [], west_wing: [], last_updated: timestamp}
      4. Verify each agent has: id, name, status, last_active, tokens
    Expected: 200 OK, valid JSON, correct schema

  Scenario: GET /api/history endpoint
    Tool: Bash (curl + pytest)
    Steps:
      1. Call: curl http://localhost:8000/api/history
      2. Verify response contains: total_messages, total_tokens_in, total_tokens_out, duration_hours
    Expected: 200 OK, statistical data present

  Scenario: GET /api/messages endpoint
    Tool: Bash (curl + pytest)
    Steps:
      1. Call: curl http://localhost:8000/api/messages?limit=20
      2. Verify response contains array of messages
      3. Verify each message has: agent_id, agent_name, content, timestamp
      4. Verify max 20 messages returned
    Expected: 200 OK, messages array, max 20 items

  Scenario: GET /api/blocked endpoint
    Tool: Bash (curl + pytest)
    Steps:
      1. Create test fixture with blocked agents (1 Claude waiting, 1 OpenCode stalled)
      2. Call: curl http://localhost:8000/api/blocked
      3. Verify response contains blocked agents with reason
    Expected: 200 OK, blocked agents listed with reasons
  ```

**Commit**: `feat(hero-tavern): implement FastAPI endpoints`

---

- [x] 07. Pixel Art Tavern Scene (复古仙剑 DOS 风格)

  **What to do**:
  - Rewrite `web/static/css/tavern.css` to create a pixel art tavern scene (NO 3D/WebGL)
  - Use CSS grid layout with 3-column structure (East Wing, Main Hall, West Wing)
  - Implement pixel art decorative elements using simple divs with solid colors (no gradients)
  - Add lantern elements as 4x8 pixel div grids with red/gold colors
  - Create wooden beams as rectangular divs with wood-tone background colors
  - Add floor texture using CSS repeating-linear-gradient (no external images)
  - Implement responsive design (768px breakpoint: stack vertically)
  - Use "复古仙剑 DOS 风" color palette:

  **Color Palette (DOS 复古风)**:
  ```
  /* 客栈基础色 */
  --wood-dark: #3d2817;      /* 深木（横梁） */
  --wood-mid: #6b4423;       /* 中木（柱子） */
  --wood-light: #8b6335;     /* 浅木（地板） */
  --lantern-red: #c41e3a;    /* 灯笼红 */
  --lantern-gold: #d4af37;   /* 灯笼金边 */
  --paper-cream: #e8d9a8;    /* 宣纸米色（文字） */
  --ink-black: #1a0f08;      /* 墨黑（背景） */

  /* 英雄（东厢） */
  --hero-bg: #4a1f1f;        /* 暗红底 */
  --hero-primary: #c41e3a;   /* 朱红 */
  --hero-secondary: #d4af37; /* 金色 */

  /* 神祇（西厢） */
  --deity-bg: #1f2f4a;       /* 深蓝底 */
  --deity-primary: #7b68ee;  /* 宝蓝 */
  --deity-secondary: #c0c0c0; /* 银色 */
  ```

  **Must NOT do**:
  - Don't use CSS 3D transforms (no perspective, no rotateX/Y)
  - Don't use gradients (solid colors only, except floor)
  - Don't add complex animations (save for Task 08)
  - Don't use external image assets
  - Don't use box-shadow (DOS style has no shadows)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-design` - pixel art UI polish
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (with Tasks 05, 06, 08)
  - **Blocks**: Task 08, 09
  - **Blocked By**: Task 04

  **References**:
  - 复古仙剑 DOS 风格：参考《仙剑奇侠传》DOS 版界面（暖色调、像素字体、简单色块）
  - 像素尺寸：基础网格 8x8 或 16x16（用于灯笼、柱子等元素）
  - 字体建议：Courier New 或系统 monospace（模拟 DOS 终端感）

  **Acceptance Criteria**:
  ```
  Scenario: Pixel art tavern scene renders
    Tool: Playwright
    Steps:
      1. Load http://localhost:3000/static/index.html
      2. Screenshot: .omo/evidence/task-07-pixel-tavern.png
      3. Verify 3-column layout (East Wing / Main Hall / West Wing)
      4. Verify color palette matches DOS style (warm reds/golds East, cool blues/silvers West)
      5. Verify decorative elements: lanterns (red/gold divs), beams (wood divs), floor texture
    Expected: Screenshot shows pixel art tavern with DOS aesthetic

  Scenario: Responsive layout (768px breakpoint)
    Tool: Playwright
    Steps:
      1. Set viewport to 1200x800
      2. Screenshot: .omo/evidence/task-07-layout-desktop.png
      3. Verify 3-column layout
      4. Set viewport to 768x600
      5. Screenshot: .omo/evidence/task-07-layout-mobile.png
      6. Verify single-column stacked layout
    Expected: Both screenshots show proper responsive behavior
  ```

**Commit**: `feat(hero-tavern): implement pixel art tavern scene (DOS style)`

---

- [x] 08. Character Sprites & State Animations

  **What to do**:
  - Create `web/static/css/characters.css` with character sprite definitions
  - Implement 18 character sprites (9 East Wing heroes + 9 West Wing deities)
  - Use CSS-drawn characters (circles/rectangles with distinctive features)
  - Implement 4 state animations per character:
    - `active`: breathing/pulsing animation (scale 1.0 → 1.05 → 1.0, 2s loop)
    - `idle`: gentle sway (rotate -2deg → 2deg, 3s loop)
    - `sleeping`: slow fade in/out (opacity 0.5 → 1.0, 4s loop)
    - `error`: shake + red glow (translate X ±5px, box-shadow red, 0.5s loop)
  - Add character labels below sprites (name + status)

  **Must NOT do**:
  - Don't use external sprite sheets (keep it self-contained)
  - Don't use complex SVG paths (simple CSS shapes only)
  - Don't add sound effects (out of scope)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-design` - animation polish
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (with Tasks 05, 06, 07)
  - **Blocks**: Task 09
  - **Blocked By**: Task 07

  **References**:
  - Character roster:
    - East Wing: Nick Fury, Iron Man, Vision, Spider-Man, Doctor Strange, Heimdall, Rocket, Star-Lord, Falcon
    - West Wing: Sisyphus, Prometheus, Hephaestus, Atlas, Metis, Momus, explore, librarian, oracle
  - Animation specifications:
    - active: `@keyframes breathe { 0%, 100% { transform: scale(1); } 50% { transform: scale(1.05); } }`
    - idle: `@keyframes sway { 0%, 100% { transform: rotate(-2deg); } 50% { transform: rotate(2deg); } }`
    - sleeping: `@keyframes sleep { 0%, 100% { opacity: 0.5; } 50% { opacity: 1; } }`
    - error: `@keyframes shake { 0%, 100% { transform: translateX(0); } 25% { transform: translateX(-5px); } 75% { transform: translateX(5px); } }`

  **Acceptance Criteria**:
  ```
  Scenario: Character sprite rendering
    Tool: Playwright
    Steps:
      1. Load page with 18 characters (9 East, 9 West)
      2. Screenshot: .omo/evidence/task-08-character-sprites.png
      3. Verify all 18 characters visible in correct wings
      4. Verify each character has name label below sprite
    Expected: All characters rendered with labels

  Scenario: State animations
    Tool: Playwright
    Steps:
      1. Set 1 character to ACTIVE state
      2. Record 3-second video: .omo/evidence/task-08-animation-active.mp4
      3. Set 1 character to IDLE state
      4. Record 3-second video: .omo/evidence/task-08-animation-idle.mp4
      5. Set 1 character to SLEEPING state
      6. Record 4-second video: .omo/evidence/task-08-animation-sleeping.mp4
      7. Set 1 character to ERROR state
      8. Record 2-second video: .omo/evidence/task-08-animation-error.mp4
      9. Verify animations match spec (breathe, sway, sleep, shake)
    Expected: All 4 animations play correctly
  ```

**Commit**: `feat(hero-tavern): implement character sprites and state animations`

---

- [x] 09. Frontend-Backend Integration (Real-time Updates)

  **What to do**:
  - Refactor `web/static/js/tavern.js` to fetch data from API endpoints
  - Implement polling mechanism (5-second interval) to `GET /api/status`
  - Update character states based on API response
  - Render recent messages in Main Hall bulletin board
  - Add loading states and error handling
  - Implement "last updated" timestamp display

  **Must NOT do**:
  - Don't use WebSocket/SSE (stick with polling for simplicity)
  - Don't cache API responses in frontend (always fetch fresh)
  - Don't add retry logic (if API fails, show error state)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: `superpowers:test-driven-development` - integration tests
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (with Tasks 10, 11, 12)
  - **Blocks**: Task 10
  - **Blocked By**: Task 06, Task 08

  **References**:
  - Polling implementation: `setInterval(() => fetch('/api/status'), 5000)`
  - State update logic: compare `last_active` timestamps to detect changes
  - Error states: API unavailable, no data, parsing errors
  - Message rendering: format timestamps, truncate long content, highlight mentions

  **Acceptance Criteria**:
  ```
  Scenario: API polling and state updates
    Tool: Playwright
    Steps:
      1. Start backend API
      2. Load frontend page
      3. Wait 5 seconds for first poll
      4. Verify character states update from API data
      5. Verify "last updated" timestamp displays
      6. Modify test fixture data, wait 5 seconds
      7. Verify frontend reflects updated data
    Expected: Characters update automatically every 5 seconds

  Scenario: Error handling
    Tool: Playwright
    Steps:
      1. Stop backend API
      2. Load frontend page
      3. Verify error message displays: "API unavailable"
      4. Restart backend API, wait 5 seconds
      5. Verify error message disappears, data loads
      6. Screenshot: .omo/evidence/task-09-error-recovery.png
    Expected: Graceful degradation and recovery

  Scenario: Message board rendering
    Tool: Playwright
    Steps:
      1. Load page with test messages
      2. Verify messages display in Main Hall bulletin board
      3. Verify message format: timestamp, agent name, content preview
      4. Verified max 20 messages shown
      5. Screenshot: .omo/evidence/task-09-message-board.png
    Expected: Messages render correctly in bulleting board
  ```

**Commit**: `feat(hero-tavern): integrate frontend with backend API`

---

- [x] 10. Interactive Features (Click Handlers, Tooltips, Keyboard Shortcuts)

  **What to do**:
  - Implement click handlers for each character sprite
  - Create modal/popup showing detailed agent info:
    - Agent name and status
    - Last active timestamp
    - Token usage (input/output)
    - Recent messages (last 5)
    - Current status description
  - Add tooltips on hover (brief status summary)
  - Implement keyboard shortcuts:
    - `R` - manual refresh
    - `?` - show help modal
    - `Escape` - close modals
  - Add visual feedback for interactions (cursor change, hover effects)

  **Must NOT do**:
  - Don't add modal animations (keep it simple)
  - Don't allow editing/modifying agent state (read-only)
  - Don't add mobile touch gestures (desktop-only)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `frontend-design` - interaction polish
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (with Tasks 09, 11, 12)
  - **Blocks**: Task 11
  - **Blocked By**: Task 09

  **References**:
  - Modal structure: `position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);`
  - Tooltip positioning: absolute, relative to character sprite
  - Keyboard event handling: `document.addEventListener('keydown', handler)`
  - Visual feedback: `cursor: pointer`, `:hover` pseudo-class

  **Acceptance Criteria**:
  ```
  Scenario: Character click modal
    Tool: Playwright
    Steps:
      1. Load page with test data
      2. Click on character sprite
      3. Verify modal opens with agent details
      4. Verify modal contains: name, status, tokens, messages
      5. Click outside modal or press Escape
      6. Verify modal closes
      7. Screenshot: .omo/evidence/task-10-modal-popup.png
    Expected: Modal opens/closes correctly, displays all info

  Scenario: Hover tooltips
    Tool: Playwright
    Steps:
      1. Hover over character sprite
      2. Wait 500ms for tooltip to appear
      3. Verify tooltip displays: name, status, last active
      4. Move mouse away
      5. Verify tooltip disappears
      6. Screenshot: .omo/evidence/task-10-tooltip-hover.png
    Expected: Tooltips appear on hover, disappear on mouseout

  Scenario: Keyboard shortcuts
    Tool: Playwright
    Steps:
      1. Press 'R' key
      2. Verify manual refresh triggers (loading state, data update)
      3. Press '?' key
      4. Verify help modal opens with shortcut list
      5. Press 'Escape' key
      6. Verify help modal closes
      7. Screenshot: .omo/evidence/task-10-help-modal.png
    Expected: All keyboard shortcuts work correctly
  ```

**Commit**: `feat(hero-tavern): add interactive features and keyboard shortcuts`

---

- [x] 11. Automated Testing Suite (Backend + End-to-End)

  **What to do**:
  - Create `tests/unit/` directory for backend unit tests
  - Implement unit tests for JSONL parser:
    - File not found handling
    - Malformed JSON handling
    - Agent pattern matching
    - Time range filtering
  - Implement unit tests for aggregator:
    - State inference logic (all 4 states)
    - Agent merging and deduplication
    - Cache behavior
  - Create `tests/e2e/` directory for Playwright tests
  - Implement end-to-end tests:
    - Page loads successfully
    - Characters render in correct wings
    - API polling works
    - Modal interactions work
    - Keyboard shortcuts work
  - Add pytest configuration (`pytest.ini`) and coverage reporting

  **Must NOT do**:
  - Don't mock API responses in E2E tests (use real backend)
  - Don't skip tests that fail (fix the code instead)
  - Don't add integration tests (unit + E2E is sufficient)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `test-automation-engineer` - test strategy
  - **Skills Evaluated but Omitted**: `playwright` - already included in test-automation-engineer

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (with Tasks 09, 10, 12)
  - **Blocks**: Task 12
  - **Blocked By**: Task 10

  **References**:
  - pytest structure: `tests/unit/test_parser.py`, `tests/unit/test_aggregator.py`
  - Playwright structure: `tests/e2e/test_scene.py`, `tests/e2e/test_interactions.py`
  - Coverage threshold: 80% (configure in `pytest.ini`)
  - Test fixtures: `tests/fixtures/sample.jsonl`, `tests/fixtures/sample.db`

  **Acceptance Criteria**:
  ```
  Scenario: Unit tests pass
    Tool: Bash
    Steps:
      1. Run unit tests: pytest tests/unit/ -v
      2. Verify all tests pass (expected: 15+ tests)
      3. Verify no skipped or xfailed tests
    Expected: 100% pass rate

  Scenario: End-to-end tests pass
    Tool: Bash
    Steps:
      1. Start backend API
      2. Run E2E tests: playwright test tests/e2e/
      3. Verify all scenarios pass (expected: 10+ scenarios)
      4. Check test artifacts: videos/screenshots saved
    Expected: 100% pass rate

  Scenario: Code coverage
    Tool: Bash
    Steps:
      1. Run with coverage: pytest --cov=src tests/unit/
      2. Generate report: pytest --cov=src --cov-report=html tests/unit/
      3. Verify coverage >= 80%
      4. Open report: open htmlcov/index.html
      5. Screenshot: .omo/evidence/task-11-coverage-report.png
    Expected: Coverage >= 80%, report generated
  ```

**Commit**: `test(hero-tavern): complete automated testing suite`

---

- [x] 12. Documentation & Deployment Script

  **What to do**:
  - Create `README.md` in `hero-tavern/` directory with:
    - Project overview and features
    - Prerequisites (Python 3.8+, Node.js 18+ for Playwright)
    - Installation instructions (virtual environment, dependencies)
    - Configuration (environment variables)
    - Usage (start backend, open frontend)
    - API documentation (endpoints, response formats)
    - Development guide (running tests, adding features)
    - Troubleshooting (common issues)
  - Create `deploy.sh` script to:
    - Check prerequisites
    - Create virtual environment if not exists
    - Install dependencies
    - Start backend API
    - Wait for API to be ready
    - Open frontend in default browser
  - Add inline code comments for complex logic

  **Must NOT do**:
  - Don't add Docker/containerization (local tool only)
  - Don't add CI/CD pipeline (local development only)
  - Don't add API versioning (single version)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: None (documentation task)
  - **Skills Evaluated but Omitted**: None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (with Tasks 09, 10, 11)
  - **Blocks**: Final Verification
  - **Blocked By**: Task 06 (API endpoints must be finalized before writing documentation)
- **Can Start**: Immediately after Task 06 completes, can run in parallel with Tasks 07-11

  **References**:
  - README structure: Overview → Prerequisites → Installation → Configuration → Usage → API Docs → Development → Troubleshooting
  - Environment variables: `CLAUDE_LOGS_PATH`, `OPENCODE_DB_PATH`, `API_PORT`, `POLL_INTERVAL`
  - API endpoints: `/api/status`, `/api/history`, `/api/messages`, `/api/blocked`

  **Acceptance Criteria**:
  ```
  Scenario: Documentation completeness
    Tool: Bash
    Steps:
      1. Check README.md exists in hero-tavern/
      2. Verify sections: Overview, Prerequisites, Installation, Configuration, Usage, API Docs, Development, Troubleshooting
      3. Verify deploy.sh exists and is executable
      4. Verify inline comments in complex code sections (parser, aggregator)
    Expected: All documentation present and complete

  Scenario: One-command deployment
    Tool: Bash
    Steps:
      1. Run: bash hero-tavern/deploy.sh
      2. Verify virtual environment created
      3. Verify dependencies installed
      4. Verify backend API starts
      5. Verify frontend opens in browser
      6. Verify tavern scene displays correctly
    Expected: Full deployment with one command

  Scenario: README accuracy
    Tool: Bash
    Steps:
      1. Follow installation instructions in README manually
      2. Verify all commands work as documented
      3. Verify environment variables match actual config
      4. Verify API examples match actual responses
    Expected: README instructions accurate and reproducible
  ```

**Commit**: `docs(hero-tavern): complete documentation and deployment script`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval before marking work complete.**
> **Never mark F1-F4 as checked before getting user's okay.** Rejection or user feedback -> fix -> re-run -> present again -> wait for okay.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, curl endpoint, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .omo/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `pytest` + `ruff` + `mypy`. Review all changed files for: bare `except`, empty catches, `print()` in production code, commented-out code, unused imports. Check AI slop: excessive comments, over-abstraction, generic names (data/result/item/temp).
  Output: `Build [PASS/FAIL] | Lint [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high` (+ `playwright` skill if UI)
  Start from clean state. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration (features working together, not isolation). Test edge cases: empty state, invalid input, rapid actions. Save to `.omo/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Detect cross-task contamination: Task N touching Task M's files. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Success Criteria

### Verification Commands

```bash
# Backend service startup
cd hero-tavern && python -m uvicorn src.api.main:app --reload
# Expected: Application startup complete, Uvicorn running on http://127.0.0.1:8000

# API health check
curl http://localhost:8000/api/health
# Expected: {"status": "ok", "data_sources": {"claude": "connected", "opencode": "connected"}}

# Status endpoint
curl http://localhost:8000/api/status
# Expected: JSON with hero_agents, omo_agents, last_updated fields

# Polling verification
curl http://localhost:8000/api/status  # 连续调用验证 5 秒间隔数据更新
# Expected: JSON responses, data refreshes every 5-10 seconds

# Test suite
pytest tests/ -v --cov=src --cov-report=html
# Expected: All tests pass, coverage ≥ 80%

# Frontend E2E
playwright test tests/e2e/
# Expected: All scenarios pass

# Frontend dev server
cd hero-tavern/web && python -m http.server 3000
# Expected: Server running at http://localhost:3000

# Manual verification (browser)
open http://localhost:3000
# Expected: Tavern scene loads, both wings render characters, status updates every 5-10s
```

### Final Checklist

- [x] All "Must Have" present
- [x] All "Must NOT Have" absent
- [x] All tests pass (backend + E2E)
- [x] Code coverage ≥ 80%
- [x] Performance OK (API < 200ms, page < 3s)
- [x] Documentation complete (README, API docs)
