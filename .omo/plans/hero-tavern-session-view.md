# Hero Tavern Session View Refactoring

## TL;DR

> **Quick Summary**: Refactor the Hero Tavern (英雄客栈) monitoring dashboard to group agents by session, sort by activity, fold sleeping sessions into a counter, and represent every agent with a low-frame pixel sprite character.
>
> **Deliverables**:
> - Python backend (`src/`) for unified session API (was never committed — must be written fresh)
> - Refactored frontend: session group view with click-to-expand, pixel sprites per agent
> - ~15 pixel sprite characters via component-assembly method (32x32, 2-3 frames)
> - Updated API + E2E tests covering new session-based contract
>
> **Estimated Effort**: Medium (backend + frontend + sprite design)
> **Parallel Execution**: YES — 3 waves + final verification
> **Critical Path**: T1 (scaffold) → T5 (aggregator) → T8 (API) → T9 (session card) → T16 (smoke test)

---

## Context

### Original Request
User wants Hero Tavern to:
1. Be grouped by **session** (not by wing or agent type)
2. Sort by **activity** (most active first)
3. On expand, show 论剑 / 饮酒 agent cards individually
4. **打坐** sessions aggregated into a total count, expandable
5. Each agent represented by a **pixel-style animated character**
6. Keep status labels simple (Chinese text + color dots, no emoji/icons)

### Interview Summary
**Key decisions**:
- Display grouping: by session
- Pixel sprite method: **Option A — Component assembly** (body, hair, outfit, accessory, color)
- Frame count: **Low (2-3 frames)**
- Status display: **Preserve current** (text: 论剑/饮酒/打坐/走火入魔 + color dots, no emoji)
- Thresholds: remain configurable via `.env` (`IDLE_THRESHOLD=300`, `SLEEP_THRESHOLD=3600`)
- Activity sort formula: `score = messages * 10 + tokens / 100 + recency_bonus`

**Research findings**:
- `src/` directory in hero-tavern was **never committed to git** — must be built from scratch based on test contracts
- East Wing source: `~/.claude/projects/**/<session-id>.jsonl` (31 projects, 247 sessions) — JSONL structure includes `sessionId`, `cwd`, `timestamp`, `type`, `gitBranch`, `version`
- West Wing source: `~/.local/share/opencode/opencode.db` (774MB, 445 sessions) — `session` table has `id`, `directory`, `agent`, `model`, `time_created`, `time_updated`, token counts
- Do NOT fall back to `~/.opencode/opencode.db` (4KB empty shell — known prior bug)
- Distinct OpenCode agents observed: Sisyphus, Prometheus, Metis, Momus, Atlas, Hephaestus, oracle, plan, librarian, explore, feishu-driver, doc-analyzer-curator, multimodal-looker, feishu-obsidian-sync, Sisyphus-Junior (16 total)
- Distinct Claude hero-java agents: 9 (孔明/文远/子长/希仁/玄成/鹏举/子文/郑和/霞客)
- Initial sprite budget: ~15 unique sprites (9 heroes + 5-6 common OMO agents)

---

## Work Objectives

### Core Objective
Ship a refactored Hero Tavern dashboard where sessions are the primary grouping unit, sorted by activity, with pixel sprite characters representing every agent and status logic preserved.

### Concrete Deliverables
- `src/api/main.py` — FastAPI with `/api/status`, `/api/messages`, `/api/blocked`, `/api/history`
- `src/aggregator/aggregator.py` — `TavernAggregator` + `_infer_status()` + activity_score
- `src/parsers/claude_parser.py` — JSONL walker with session grouping
- `src/parsers/opencode_parser.py` — SQLite query with session list
- `src/models.py` — `SessionView`, `AgentView` dataclasses
- `web/static/js/tavern.js` — rewritten for session-based view
- `web/static/index.html` — restructured layout
- `web/static/css/tavern.css` — session card styles (was missing)
- `web/static/css/sprites.css` — updated to support sprite sheets with 2-3 frames
- `web/static/img/sprites/` — ~15 PNG sprite sheets (32x32 × 2-3 frames)
- `sprites/design-guide.md` — component assembly spec + Piskel templates
- `tests/test_api.py` — updated to new response shape
- `tests/e2e/conftest.py` — updated fixtures
- `tests/e2e/test_session_grouping.py` — new: session-based scenarios

### Definition of Done
- `pytest tests/` passes 100% with the new API contract
- `bash deploy.sh` brings up FastAPI on `:8000` and static on `:3000`
- `curl localhost:8000/api/status | jq` shows session-grouped response with both wings
- Opening browser on `:3000` shows sessions sorted by activity, expandable rows, pixel sprites rendering correctly, sleeping counter collapsed

### Must Have
- Sessions as primary grouping (not agents, not projects, not wings)
- Sort descending by activity score (tie-break by recency)
- Click to expand session — reveals 论剑 + 饮酒 agent cards
- Sleeping sessions folded into collapsible counter
- Pixel sprite for every agent (component assembly, 32x32, 2-3 frames)
- Status inference logic preserved exactly (time thresholds + error keywords)
- Configurable thresholds via `.env`
- Two data sources fully integrated (Claude JSONL + OpenCode SQLite)

### Must NOT Have (Guardrails)
- Emoji in status labels (text + color dot only)
- Agent-type-based grouping (session-based only)
- Icon additions to status
- AI-generated individual sprites (use component assembly)
- Pure code SVG replacement of PNG sprite sheets
- Changes to status threshold logic or defaults
- Agent `.md` frontmatter refactoring (out of scope)
- Dispatch lane / archetype changes (out of scope)
- Infrastructure/deploy changes beyond running the service

---

## Verification Strategy (MANDATORY)

> **ZERO HUMAN INTERVENTION** — all verification is agent-executed. Acceptance criteria requiring "user manually tests" are forbidden.

### Test Decision
- **Infrastructure exists**: YES — `pytest` + FastAPI + Playwright E2E are already configured in tests directory
- **Automated tests**: Tests-after (implementation first, then tests — given scope includes both frontend refactor and new backend)
- **Framework**: pytest (backend API) + Playwright (E2E)
- **Agent-Executed QA**: Every task has scenarios run by the executing agent

### QA Policy
- **Backend**: Use `curl` / `httpx` against running FastAPI on `:8000` — assert JSON response shape, status codes, field types
- **Frontend**: Use Playwright — navigate to `:3000`, click session rows, assert DOM content, screenshot states
- **Integration**: Use real DB copy of test fixture — verify both wings populate
- **Sprite rendering**: Use Playwright screenshot — confirm pixel sprites appear in DOM without broken images

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — can all run in parallel):
├── 1. Project scaffold + API skeleton [quick]
├── 2. Data model (SessionView, AgentView) [quick]
├── 3. Claude JSONL parser [unspecified-high]
├── 4. OpenCode SQLite parser [unspecified-high]
├── 5. Aggregator + status + activity score [deep]
└── 6. Pixel sprite component design guide [visual-engineering]

Wave 2 (Feature work — depends on Wave 1):
├── 7. Backend API endpoints (1, 2, 3, 4, 5) [deep]
├── 8. Frontend session card component (6) [visual-engineering]
├── 9. Frontend agent card with sprite (6) [visual-engineering]
└── 10. Pixel sprite PNG generation — 15 sprites (6) [visual-engineering]

Wave 3 (Integration — depends on Wave 2):
├── 11. Frontend sort + fold sleeping counter (8) [visual-engineering]
├── 12. Frontend click-to-expand interaction (8, 9) [visual-engineering]
├── 13. index.html restructure + tavern.css (8, 9, 11, 12) [quick]
├── 14. API tests update (7) [test-automation]
└── 15. E2E tests update (11, 12) [test-automation]

Wave 4 (Smoke — depends on Wave 3):
└── 16. End-to-end smoke test with real data (13, 14, 15) [unspecified-high]

Final Wave (4 parallel reviews + user okay):
├── F1. Plan compliance audit (oracle)
├── F2. Code quality review (unspecified-high)
├── F3. Real manual QA (unspecified-high + playwright)
└── F4. Scope fidelity check (deep)

Critical Path: 1 → 5 → 7 → 8 → 11 → 16 → F1-F4
Max Concurrent: 6 (Wave 1)
```

### Dependency Matrix

- 1: — → 7
- 2: — → 7
- 3: — → 7
- 4: — → 7
- 5: — → 7
- 6: — → 8, 9, 10
- 7: 1, 2, 3, 4, 5 → 14
- 8: 6 → 11, 12, 13
- 9: 6 → 12
- 10: 6 → 13
- 11: 8 → 13, 15
- 12: 8, 9 → 13, 15
- 13: 8, 9, 10, 11, 12 → 16
- 14: 7 → 16
- 15: 11, 12 → 16
- 16: 13, 14, 15 → F1-F4
- F1-F4: 16 → user okay

### Agent Dispatch Summary

- **Wave 1 (6)**: T1 quick, T2 quick, T3 unspecified-high, T4 unspecified-high, T5 deep, T6 visual-engineering
- **Wave 2 (4)**: T7 deep, T8 visual-eng, T9 visual-eng, T10 visual-eng
- **Wave 3 (5)**: T11 visual-eng, T12 visual-eng, T13 quick, T14 test-automation, T15 test-automation
- **Wave 4 (1)**: T16 unspecified-high
- **Final (4)**: F1 oracle, F2 unspecified-high, F3 unspecified-high, F4 deep

---

## TODOs

> Implementation + Test = ONE Task. Never separate.
> TODO labels: bare numbers ("1.", "2."). Final wave: "F1.", "F2.", etc.

- [x] 1. **项目脚手架 + API 骨架**

  **What to do**:
  - 在 `/Users/luyun/Documents/poc/claude-hero/hero-tavern/` 下创建 `src/` 目录结构:
    ```
    src/
    ├── __init__.py
    ├── api/
    │   ├── __init__.py
    │   └── main.py          # FastAPI app + 路由占位
    ├── aggregator/
    │   ├── __init__.py
    │   └── aggregator.py    # 占位
    ├── parsers/
    │   ├── __init__.py
    │   ├── claude_parser.py # 占位
    │   └── opencode_parser.py # 占位
    └── models.py            # 占位 dataclass
    ```
  - 创建 `requirements.txt` (fastapi, uvicorn, python-dotenv, pytest, httpx, playwright)
  - 创建 `.env.example` 含 `IDLE_THRESHOLD=300`, `SLEEP_THRESHOLD=3600`, `OPENCODE_DB_PATH=~/.local/share/opencode/opencode.db`
  - 创建 `src/api/main.py` 包含 4 个路由占位 (GET /api/status, /api/messages, /api/blocked, /api/history) — 全部返回 mock 空数据 `{}`/`[]`
  - 运行 `uvicorn src.api.main:app --port 8000` 验证启动 + curl 4 个路由返回 200

  **Must NOT do**:
  - Don't write real business logic (just scaffolds)
  - Don't include auth/rate-limit (out of scope)
  - Don't modify existing test files yet (T14/T15 will)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pure scaffolding, boilerplate files, no business logic
  - **Skills**: `[]` — no specialized skills needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None

  **References**:
  - `tests/test_api.py` — shows the 4 endpoints expected (`/api/status`, `/api/messages`, `/api/blocked`, `/api/history`); match these exact paths
  - `.env.example` convention from project's existing README.md (`IDLE_THRESHOLD`, `SLEEP_THRESHOLD` variables)
  - FastAPI quickstart: `https://fastapi.tiangolo.com/tutorial/first-steps/` — basic structure reference

  **Acceptance Criteria**:
  - [ ] Directory `src/` exists with 4 sub-modules (api, aggregator, parsers, models.py)
  - [ ] `curl localhost:8000/api/status` returns JSON 200
  - [ ] Same for /api/messages, /api/blocked, /api/history
  - [ ] `python -c "from src.api.main import app; print(app)"` doesn't raise

  **QA Scenarios (MANDATORY)**:

  Scenario: API scaffold smoke test
  Tool: Bash (curl + uvicorn)
  Preconditions: No other process on port 8000
  Steps:
    1. Run `cd /Users/luyun/Documents/poc/claude-hero/hero-tavern && source .venv/bin/activate 2>/dev/null || python3 -m venv .venv && source .venv/bin/activate && pip install fastapi uvicorn` then start server in background: `uvicorn src.api.main:app --port 8000 &` and sleep 3
    2. Run `curl -s http://localhost:8000/api/status`; expect JSON object with `sessions` key or empty `{}`
    3. Run `curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/messages`; expect `200`
    4. Clean up: `pkill -f "uvicorn src.api.main"`
  Expected Result: All 4 endpoints return 200 with JSON
  Failure Indicators: 404, connection refused, or non-JSON response
  Evidence: `.omo/evidence/task-1-api-scaffold.txt` (capture curl outputs)

  **Commit**: YES (after Wave 3 complete — group with T16)
  - Message: `feat(tavern): project scaffold + api skeleton`
  - Files: `src/, requirements.txt, .env.example`
  - Pre-commit: `python -c "import src.api.main"`

- [x] 2. **数据模型 (SessionView, AgentView)**

  **What to do**:
  - Create `src/models.py` with two dataclasses:
    ```python
    from dataclasses import dataclass, field
    from datetime import datetime
    from typing import Literal
    
    @dataclass
    class AgentView:
        name: str                     # Display name (e.g. "孔明")
        agent_id: str                 # Source ID
        status: Literal["active", "idle", "sleeping", "error"]
        last_active: datetime
        sprite_id: str                # Maps to sprites/{id}.png
        messages_count: int = 0
        tokens: int = 0
        role: str = ""                # Optional display role
    
    @dataclass
    class SessionView:
        session_id: str
        source: Literal["claude", "opencode"]
        project: str                  # Absolute path
        project_short: str            # e.g. "ops/feishu_things"
        agents: list[AgentView] = field(default_factory=list)
        last_updated: datetime = field(default_factory=datetime.utcnow)
        activity_score: float = 0.0
        status_counts: dict = field(default_factory=lambda: {
            "active": 0, "idle": 0, "sleeping": 0, "error": 0
        })
    ```
  - Add pydantic models for API serialization (Pydantic v2): `SessionResponse` that wraps list of SessionView + `last_updated` field + `status_summary` (total counts)
  - Write 3 unit tests in `tests/test_models.py` covering construction + defaults

  **Must NOT do**:
  - Don't add ORM persistence (just in-memory dataclasses)
  - Don't add async IO (that's in parsers)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple data definitions, no I/O
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None

  **References**:
  - `tests/e2e/conftest.py` — shows expected fields like `id`, `name`, `wing`, `status`, `last_active`, `tokens_in`, `tokens_out`, `current_task`; adapt to new model
  - Python docs: `https://docs.python.org/3/library/dataclasses.html` — dataclass reference
  - Pydantic v2 serialization: `https://docs.pydantic.dev/latest/concepts/serialization/`

  **Acceptance Criteria**:
  - [ ] `from src.models import SessionView, AgentView` imports cleanly
  - [ ] Constructing a SessionView with no agents defaults to zero status counts
  - [ ] API schema accepts a list of SessionView objects
  - [ ] `pytest tests/test_models.py` passes (3 tests)

  **QA Scenarios (MANDATORY)**:

  Scenario: Model construction + defaults
  Tool: Bash (pytest)
  Preconditions: T1 complete
  Steps:
    1. Run `python3 -c "from src.models import SessionView, AgentView; from datetime import datetime; s = SessionView(session_id='test', source='claude', project='/p', project_short='p'); print(s.status_counts)"` — expect `{'active': 0, 'idle': 0, 'sleeping': 0, 'error': 0}`
    2. Run `pytest tests/test_models.py -v` — expect 3 passed
  Expected Result: Models construct correctly; tests pass
  Failure Indicators: ImportError, missing defaults, assertion failures
  Evidence: `.omo/evidence/task-2-models.txt`

  **Commit**: NO (group with T16)

- [x] 3. **Claude JSONL 解析器**

  **What to do**:
  - Implement `src/parsers/claude_parser.py`:
    - Class `ClaudeParser` with `parse_all(base_dir='~/.claude/projects')` returning list of `SessionView`
    - Scan `base_dir/**/` recursively for `*.jsonl` files
    - For each jsonl file: session_id = filename (without .jsonl), project path from directory name (`-` → `/`) and confirmed via first `cwd` field read
    - For each line: parse JSON, collect `timestamp`, track agent markers (`🦸 hero ▸ <name>(<id>)` regex supporting both `()` and `（）` full-width)
    - Group agent markers by session — each marker occurrence updates that agent's `last_active` and `messages_count`
    - Extract `gitBranch`, `version` into optional SessionView fields
    - Filter out zero-agent sessions (sessions with no hero markers)
  - Handle malformed JSON lines gracefully (log warning, skip line)
  - Write 4 unit tests in `tests/test_claude_parser.py` using small fixture JSONL files

  **Must NOT do**:
  - Don't implement incremental parsing (full scan each time; cache handled by aggregator)
  - Don't try to support non-JSONL formats
  - Don't hardcode project names

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Moderate complexity (regex, file system walk, JSON parsing, grouping logic)
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None (T2 can be done in parallel or before; parser uses its own dataclass import)

  **References**:
  - `~/.claude/projects/-Users-luyun-Documents-ops-feishu_things/*.jsonl` — real data to test against; first file shows JSON lines with `sessionId`, `cwd`, `timestamp`, `type`, `attachment` fields
  - Original parser plan: `/Users/luyun/Documents/poc/claude-hero/.omo/plans/hero-tavern-fix.md` — mentions full-width bracket regex support requirement, directory recursion bug to avoid
  - Python pathlib: `https://docs.python.org/3/library/pathlib.html` — `glob('**/*.jsonl')` pattern

  **Acceptance Criteria**:
  - [ ] `ClaudeParser().parse_all()` on user's `~/.claude/projects/` returns ≥ 10 sessions with `agents` populated
  - [ ] Full-width `（）` and half-width `()` marker regex both work
  - [ ] `project_short` derived correctly (strip `/Users/<user>/Documents/` → `ops/foo`)
  - [ ] Malformed JSON lines don't crash the parser
  - [ ] `pytest tests/test_claude_parser.py` passes (4 tests)

  **QA Scenarios (MANDATORY)**:

  Scenario: Real data parse
  Tool: Bash (python REPL)
  Preconditions: User home has `~/.claude/projects/` populated
  Steps:
    1. `python3 -c "from src.parsers.claude_parser import ClaudeParser; from pathlib import Path; p = ClaudeParser(); sessions = p.parse_all(str(Path.home() / '.claude/projects')); print(f'Found {len(sessions)} sessions'); [print(f'  {s.session_id[:8]}.. {s.project_short} agents={len(s.agents)}') for s in sessions[:5]]"`
  Expected Result: ≥ 10 sessions returned, printout shows project paths + agent counts
  Failure Indicators: Empty list, KeyError, regex mismatch
  Evidence: `.omo/evidence/task-3-claude-real.txt`

  Scenario: Malformed JSON handling
  Tool: Bash (pytest)
  Steps:
    1. Write a test fixture `tests/fixtures/bad.jsonl` with 3 lines: 1 valid, 1 garbage (`not_json{{{`), 1 valid
    2. Run parser against that directory
  Expected Result: Parser returns session with 2 valid lines parsed, no exception raised
  Evidence: `.omo/evidence/task-3-malformed.txt`

  **Commit**: NO (group with T7)

- [x] 4. **OpenCode SQLite 解析器**

  **What to do**:
  - Implement `src/parsers/opencode_parser.py`:
    - Class `OpenCodeParser` with `parse_all(db_path=None)` returning list of `SessionView`
    - Default `db_path`: read from env `OPENCODE_DB_PATH` or `~/.local/share/opencode/opencode.db`
    - **Critical**: Validate db exists AND is > 100KB (detect the 4KB empty shell bug)
    - SQL query:
      ```sql
      SELECT id, directory, agent, model, time_created, time_updated,
             tokens_input, tokens_output, tokens_reasoning
      FROM session
      WHERE time_archived IS NULL
      ORDER BY time_updated DESC
      ```
    - Group by `id` (each row = one session)
    - `agent` column maps to AgentView.name (strip prefixes like "Sisyphus - ultraworker" → "Sisyphus")
    - `model` column maps to AgentView.model
    - `time_updated` (unix timestamp int) → `last_active` datetime
    - `directory` → `project` / `project_short`
  - Handle locked DB gracefully (sqlite3.OperationalError → retry with WAL mode)
  - Write 3 unit tests in `tests/test_opencode_parser.py` with fixture SQLite

  **Must NOT do**:
  - Don't modify the DB (read-only mode via `PRAGMA query_only`)
  - Don't cache at this layer (aggregator handles cache)
  - Don't filter by agent name (let aggregator/sorter decide)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: SQLite + unix timestamps + empty-shell detection + agent name normalization
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None

  **References**:
  - `~/.local/share/opencode/opencode.db` — real DB to test against (774MB, 445 sessions)
  - Schema inspection commands used during interview:
    ```sql
    SELECT DISTINCT agent FROM session WHERE agent IS NOT NULL;
    SELECT directory, time_updated FROM session WHERE time_updated > datetime('now', '-1 day') ORDER BY time_updated DESC LIMIT 5;
    ```
  - Python sqlite3 docs: `https://docs.python.org/3/library/sqlite3.html` — connection, row_factory, PRAGMA

  **Acceptance Criteria**:
  - [ ] `OpenCodeParser().parse_all()` on user's `~/.local/share/opencode/opencode.db` returns ≥ 100 sessions
  - [ ] `OPENCODE_DB_PATH=$HOME/.opencode/opencode.db` raises clear ValueError ("empty DB, expected > 100KB")
  - [ ] Agent names normalized: "Sisyphus - ultraworker" → "Sisyphus", "Prometheus - Plan Builder" → "Prometheus"
  - [ ] `pytest tests/test_opencode_parser.py` passes (3 tests)

  **QA Scenarios (MANDATORY)**:

  Scenario: Real DB parse
  Tool: Bash (python REPL)
  Steps:
    1. `python3 -c "from src.parsers.opencode_parser import OpenCodeParser; p = OpenCodeParser(); sessions = p.parse_all(); print(f'Found {len(sessions)} sessions'); [print(f'  {s.session_id[:8]}.. agent={a.name} model={a.model}') for s in sessions[:3] for a in s.agents[:1]]"`
  Expected Result: ≥ 100 sessions, agent names stripped of suffixes
  Evidence: `.omo/evidence/task-4-opencode-real.txt`

  Scenario: Empty DB rejection
  Tool: Bash
  Steps:
    1. `sqlite3 $HOME/.opencode/test_empty.db "CREATE TABLE dummy(x)"` — create < 100KB DB
    2. `python3 -c "from src.parsers.opencode_parser import OpenCodeParser; p = OpenCodeParser('$HOME/.opencode/test_empty.db'); p.parse_all()"` — expect ValueError
  Expected Result: ValueError raised with helpful message
  Evidence: `.omo/evidence/task-4-reject.txt`

  **Commit**: NO (group with T7)

- [x] 5. **聚合器 + 状态推断 + 活跃度评分**

  **What to do**:
  - Implement `src/aggregator/aggregator.py`:
    - Class `TavernAggregator` with methods:
      - `get_status()` returning dict `{"sessions": [...], "last_updated": iso8601, "status_summary": {...}}`
      - `_infer_status(last_active_dt, messages)` — exact logic preserved:
        ```
        if any(kw in messages for kw in ["error","exception","failed","crash","traceback"]):
            return "error"
        elapsed = (now - last_active_dt).total_seconds()
        if elapsed < IDLE_THRESHOLD: return "active"
        elif elapsed < SLEEP_THRESHOLD: return "idle"
        else: return "sleeping"
        ```
      - `_calibrate_activity_score(s: SessionView)` — formula:
        ```
        recency_bonus = 100 if last < 5min else 50 if last < 1hr else 0
        score = sum(a.messages_count * 10 + a.tokens / 100 for a in s.agents) + recency_bonus
        ```
      - 30 秒内存缓存 (TTL) via `datetime` comparison
    - `__init__(claude_parser, opencode_parser)` — accepts parsers for testability
    - Sort sessions by `activity_score DESC, last_updated DESC`
    - Compute `status_counts` per session by iterating agents
  - Write 5 unit tests in `tests/test_aggregator.py`:
    - Test status transitions at threshold boundaries
    - Test error detection overrides time
    - Test cache TTL (call twice within 30s returns same object)
    - Test sort order (active first, sleeping last)
    - Test activity score formula

  **Must NOT do**:
  - Don't change threshold logic (preserved from spec)
  - Don't add ML / heuristic beyond formula
  - Don't persist cache to disk (in-memory only)
  - Don't modify status label strings (论剑/饮酒/打坐/走火入魔 in frontend only)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Core business logic with multiple interacting concerns (status, scoring, cache, sort)
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: YES (within Wave 1)
  - **Parallel Group**: Wave 1
  - **Blocks**: T7
  - **Blocked By**: None (uses T2 models via import; can write concurrently)

  **References**:
  - Original aggregator logic: `/Users/luyun/Documents/poc/claude-hero/.omo/plans/opencode-hero-tavern.md` — `_infer_status` spec
  - Prior fix plan: `/Users/luyun/Documents/poc/claude-hero/.omo/plans/hero-tavern-fix.md` — confirmed status inference unchanged
  - Test fixtures: `tests/e2e/conftest.py` — sample agent/session dicts for mocking
  - Python `functools.lru_cache` (NOT used here — manual datetime TTL for test clarity)

  **Acceptance Criteria**:
  - [ ] `_infer_status(datetime.now() - timedelta(seconds=100), [])` returns `"active"`
  - [ ] `_infer_status(datetime.now() - timedelta(hours=2), [])` returns `"sleeping"`
  - [ ] `_infer_status(datetime.now(), ["failed to open"])` returns `"error"`
  - [ ] `get_status()` returns sessions sorted by score DESC
  - [ ] 30s cache works: two calls within window return identical `last_updated`
  - [ ] `pytest tests/test_aggregator.py` passes (5 tests)

  **QA Scenarios (MANDATORY)**:

  Scenario: Full aggregation on real data
  Tool: Bash (python REPL)
  Steps:
    1. `python3 -c "
from src.parsers.claude_parser import ClaudeParser
from src.parsers.opencode_parser import OpenCodeParser
from src.aggregator.aggregator import TavernAggregator
agg = TavernAggregator(ClaudeParser(), OpenCodeParser())
status = agg.get_status()
print(f\"Sessions: {len(status['sessions'])}\")
for s in status['sessions'][:3]:
    print(f\"  {s.session_id[:8]} score={s.activity_score:.1f} counts={s.status_counts}\")"`
  Expected Result: ≥ 50 sessions, scores computed, status_counts sum to agent count
  Evidence: `.omo/evidence/task-5-aggregate.txt`

  Scenario: Cache behavior
  Tool: Bash (pytest)
  Steps:
    1. Instantiate aggregator with mock parsers
    2. Call `get_status()` twice in < 30s window — expect same `last_updated`
    3. Mock time jump past 30s — expect fresh `last_updated`
  Evidence: `.omo/evidence/task-5-cache.txt`

  **Commit**: NO (group with T7)

- [x] 6. **像素精灵组件设计规范 + 模板**

  **What to do**:
  - Create `sprites/design-guide.md` documenting the component assembly method:
    - Canvas: 32x32 pixels, transparent background
    - 4 animation frames per state: idle (standing), work (active motion), rest (sitting), sleep (lying)
    - Component grid showing variant options:
      ```
      Body types: standard | thin | tall | short | strong (5)
      Skin tones: #ffdbac | #f1c27d | #e0ac69 | #c68642 | #8d5524 (5)
      Hair colors: black | brown | blonde | red | grey | purple (6)
      Outfits: robe | armor | suit | hood | scholar | warrior (6)
      Accessories: staff | sword | book | hammer | scepter | fan | none (7)
      ```
    - Palette rule: 6-9 colors max per sprite (retro authenticity)
    - Animation rules:
      - Idle: 2-frame bob (2 pixels vertical)
      - Work: 3-frame cycle (arm up → mid → strike)
      - Rest: 2-frame sway (head tilt left/right)
      - Sleep: 2-frame (zzz opacity toggle)
  - Create `sprites/templates/` with Piskel project files:
    - `base.piskel` — base body template (standard + scholar outfit, for copying)
    - `template-guide.png` — visual reference for layer ordering (body → outfit → hair → accessory on top)
  - Create `sprites/mapping.yaml` mapping agent_id → sprite filename:
    ```yaml
    heroes:
      kongming: kongming.png       # 孔明 - scholar outfit + fan
      wenyuan: wenyuan.png         # 文远 - warrior outfit + sword
      zichang: zichang.png         # 子长 - scholar + book
      xiren: xiren.png             # 希仁 - armor + hammer
      xuancheng: xuancheng.png     # 玄成 - scholar + book
      pengju: pengju.png           # 鹏举 - warrior + sword
      ziwen: ziwen.png             # 子文 - scholar + staff
      zhenghe: zhenghe.png         # 郑和 - scholar + scepter
      xiaké: xiaké.png             # 霞客 - hood + staff
    deities:
      prometheus: prometheus.png     # torch accessory
      sisyphus: sisyphus.png         # hammer (rolling boulder)
      atlas: atlas.png               # bare arms (carrying)
      hephaestus: hephaestus.png     # hammer + apron
      oracle: oracle.png             # staff + hood
      explore: explore.png           # hood + staff
    ```
  - Write test `tests/test_sprite_manifest.py` validating:
    - Every entry in `mapping.yaml` has a corresponding PNG (placeholder acceptable)
    - All PNGs are valid 32x32 (or 96x32 with 3 frames of 32x32 each)

  **Must NOT do**:
  - Don't create final pixel art yet (T10 will produce actual sprites based on this guide)
  - Don't change the 32x32 resolution
  - Don't use > 9 colors per sprite

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Design documentation, pixel art conventions, sprite sheet format
  - **Skills**: `[]` — frontend-design skill not triggered (this is a design **guide**, not a UI)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T8, T9, T10
  - **Blocked By**: None

  **References**:
  - Piskel docs: `https://www.piskelapp.com/` — pixel editor with animation
  - LibreSprite: `https://libresprite.github.io/` — offline alternative
  - Retro pixel conventions: `https://lospec.com/palette-list` — curated retro palettes (use "Endesga 32" or "Sweetie 16")
  - Existing sprite usage: `tavern.js:HERO_SPRITE_MAP` and `DEITY_SPRITE_MAP` for current sprite ID patterns

  **Acceptance Criteria**:
  - [ ] `sprites/design-guide.md` exists and documents all component categories
  - [ ] `sprites/mapping.yaml` has ≥ 15 entries (9 heroes + ≥ 6 deities)
  - [ ] `sprites/templates/base.piskel` exists (or equivalent template file)
  - [ ] `pytest tests/test_sprite_manifest.py` passes when placeholder PNGs are in place

  **QA Scenarios (MANDATORY)**:

  Scenario: Manifest validation
  Tool: Bash (pytest)
  Steps:
    1. Create placeholder PNGs for all 15 mapped IDs: `for id in kongming wenyuan zichang xiren xuancheng pengju ziwen zhenghe xiaké prometheus sisyphus atlas hephaestus oracle explore; do convert -size 96x32 xc:none sprites/${id}.png; done` (using ImageMagick, or skip if not available and use PIL)
    2. Run `pytest tests/test_sprite_manifest.py -v`
  Expected Result: All manifest entries validate against placeholder PNGs
  Evidence: `.omo/evidence/task-6-manifest.txt`

  **Commit**: NO (group with T16)

- [x] 7. **后端 API 端点实现**

  **What to do**:
  - Implement `src/api/main.py` fully:
    - Wire up real `TavernAggregator` (from T5) with parsers from T3 and T4
    - `GET /api/status`:
      - Returns `{"sessions": [...SessionView...], "last_updated": iso8601, "status_summary": {"active": N, "idle": N, "sleeping": N, "error": N, "total_sessions": N}}`
      - Each `SessionView` serialized with: `session_id, source, project_short, agents (list of AgentView), last_updated, activity_score, status_counts`
    - `GET /api/messages`:
      - Query parameter `?session_id=xxx`; return last 50 messages for that session
      - Implementation: re-scan JSONL or query OpenCode `session_message` table
    - `GET /api/blocked`:
      - Filter sessions where any agent's recent message matches "waiting for user input" / "🦸 hero ▸ STOP" / OpenCode `time_updated` stalled > 10min
    - `GET /api/history`:
      - 24h aggregate: total active/idle/sleeping session counts, total tokens, top project
  - Add CORS middleware for `localhost:3000` → `localhost:8000` dev environment
  - Configure OpenCode DB path from env var with fallback
  - Write/extend `tests/test_api.py` with 6 endpoint tests covering happy paths + 404 for unknown session_id

  **Must NOT do**:
  - Don't add authentication/authorization
  - Don't add rate limiting
  - Don't write WebSocket push (polling per existing frontend contract)
  - Don't modify the parsers (T3, T4 are complete)
  - Don't modify the aggregator's status logic (preserved as per spec)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Integrates 4 prior modules (models + both parsers + aggregator), defines public API surface
  - **Skills**: `[]`

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (depends on T1, T2, T3, T4, T5)
  - **Blocks**: T14
  - **Blocked By**: T1, T2, T3, T4, T5

  **References**:
  - `tests/test_api.py` — existing test structure for the 4 endpoints (to be extended)
  - `tests/e2e/conftest.py` — shows expected JSON response shape (adapt to session group)
  - FastAPI TestClient: `https://fastapi.tiangolo.com/tutorial/testing/` — `from fastapi.testclient import TestClient`
  - Pydantic v2 model_dump: `https://docs.pydantic.dev/latest/concepts/serialization/#modelmodel_dump`

  **Acceptance Criteria**:
  - [ ] `curl localhost:8000/api/status | jq '.sessions | length'` returns ≥ 10
  - [ ] `curl localhost:8000/api/status | jq '.status_summary'` returns all 4 status keys
  - [ ] `curl localhost:8000/api/messages?session_id=xxx` returns JSON for valid session, 404 for invalid
  - [ ] `curl localhost:8000/api/blocked` returns array (may be empty)
  - [ ] `curl localhost:8000/api/history` returns 24h summary
  - [ ] `pytest tests/test_api.py` passes (≥ 6 tests)

  **QA Scenarios (MANDATORY)**:

  Scenario: Happy path all endpoints
  Tool: Bash (curl + uvicorn)
  Steps:
    1. Start server: `uvicorn src.api.main:app --port 8000 &` sleep 3
    2. `curl -s localhost:8000/api/status | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['sessions']), 'sessions'); print(d['status_summary'])"`
    3. Pick first session_id: `SID=$(curl -s localhost:8000/api/status | python3 -c "import sys,json; print(json.load(sys.stdin)['sessions'][0]['session_id'])")`; `curl -s "localhost:8000/api/messages?session_id=${SID}" | head -c 200`
    4. `curl -s localhost:8000/api/blocked | python3 -c "import sys,json; print(len(json.load(sys.stdin)), 'blocked')"`
    5. `curl -s localhost:8000/api/history | python3 -c "import sys,json; print(json.load(sys.stdin))"`
    6. `pkill -f "uvicorn src.api.main"`
  Expected Result: All endpoints return valid JSON with expected shape
  Evidence: `.omo/evidence/task-7-api-happy.txt`

  Scenario: 404 for invalid session
  Tool: Bash (curl)
  Steps:
    1. `curl -s -o /dev/null -w "%{http_code}" "localhost:8000/api/messages?session_id=nonexistent"`
  Expected Result: 404
  Evidence: `.omo/evidence/task-7-api-404.txt`

  **Commit**: YES (milestone commit after Wave 2)
  - Message: `feat(tavern): complete session-grouped backend`
  - Files: `src/**, tests/test_api.py, tests/test_aggregator.py, tests/test_claude_parser.py, tests/test_opencode_parser.py, tests/test_models.py`
  - Pre-commit: `pytest tests/test_api.py tests/test_aggregator.py`

- [x] 8. **前端 Session 卡片组件**

  **What to do**:
  - Refactor `web/static/js/tavern.js`:
    - Replace `renderAgents()` with `renderSessions(sessions)` that iterates sessions (already sorted by score)
    - New `createSessionCard(session)` function generating:
      ```html
      <div class="session-card" data-session-id="${id}" data-status="${dominant_status}">
        <div class="session-header">
          <span class="project-path">${project_short}</span>
          <span class="activity-score">${score.toFixed(1)}</span>
          <span class="status-summary">
            <span class="count active">${counts.active} 论剑</span>
            <span class="count idle">${counts.idle} 饮酒</span>
          </span>
          <span class="expand-icon">▸</span>
        </div>
        <div class="session-body collapsed">
          <!-- Mini agent cards (collapsed view) -->
        </div>
        <div class="session-body expanded hidden">
          <!-- Full agent cards (expanded view) — T9 populates -->
        </div>
      </div>
      ```
    - Dominant status logic: if any agent is `active` → `active`; elif any `idle` → `idle`; else `sleeping`. `error` overrides all.
    - Click handler on `.session-header` toggles the `collapsed`/`expanded` classes
    - Sleeping-only sessions get `data-sleeping="true"` and render as collapsed counter row (T11 handles fold logic)
  - Update `fetchStatus()` to read new API shape (nested `sessions[].agents[]`)
  - Preserve existing `statusLabels` dict (论剑/饮酒/打坐/走火入魔) — do not change

  **Must NOT do**:
  - Don't add emoji or icons to status
  - Don't change status label text
  - Don't render sprite images yet (T9 handles AgentMiniCard sprite)
  - Don't implement sort controls (already sorted by backend)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Core UI component work, interaction design, DOM structure
  - **Skills**: `[]` — frontend-design might help aesthetics but scope is functional

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T9, T10 once T6 done)
  - **Parallel Group**: Wave 2
  - **Blocks**: T11, T12, T13
  - **Blocked By**: T6 (need design tokens/conventions)

  **References**:
  - `web/static/js/tavern.js:544` — current `statusLabels` and `createAgentCard()` to preserve semantics
  - `web/static/js/tavern.js` `fetchStatus()` — current polling logic to adapt
  - `tests/e2e/test_api_polling.py` — asserts on DOM selectors; adapt to new structure in T15

  **Acceptance Criteria**:
  - [ ] Opening `http://localhost:3000` shows session cards sorted by score (mock data with Playwright or curl)
  - [ ] Clicking a session-header expands to show session-body; clicking again collapses
  - [ ] Each `session-card` has `data-session-id`, `data-status`, `data-sleeping` attributes
  - [ ] Status counts render per session (e.g. "2 论剑 · 1 饮酒")
  - [ ] No emoji or icons in status text

  **QA Scenarios (MANDATORY)**:

  Scenario: Session card rendering + expand
  Tool: Playwright (browser automation)
  Steps:
    1. Launch browser, navigate to `http://localhost:3000`
    2. Mock `/api/status` response via `page.route()` returning 2 active sessions + 1 sleeping session
    3. Wait for `.session-card` to appear; count elements — expect 3
    4. Click first `.session-header`; assert `.session-body.expanded` visible
    5. Click again; assert `.session-body.expanded` hidden
  Expected Result: Cards render, expand/collapse toggle works
  Failure Indicators: Cards not rendered, click has no effect, attributes missing
  Evidence: `.omo/evidence/task-8-session-cards.png` (screenshot)

  **Commit**: NO (group with T13 commit)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents in PARALLEL. ALL must APPROVE. Present results to user and get explicit "okay" before marking done.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read plan end to end. For each "Must Have": verify implementation exists in codebase. For each "Must NOT Have": search for forbidden patterns and reject with file:line if found. Check evidence files in `.omo/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `pytest tests/`. Review all new files for: dead imports, empty except, print() in prod, commented-out code, unused vars. Check AI slop (excessive comments, generic names like `data`/`result`/`item`).
  Output: `Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high` + `playwright` skill
  Start fresh state. Run every QA scenario from every task. Capture evidence. Save to `.omo/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do" and read actual diff. Verify 1:1 — no missing, no creep. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | VERDICT`

---

## Commit Strategy

- **Task 7**: After backend API endpoints work with `curl` smoke test
  - Message: `feat(tavern): add session-grouped API endpoints`
  - Files: `src/*, tests/test_api.py`
  - Pre-commit: `pytest tests/test_api.py`

- **Task 12**: After frontend interactions work in Playwright
  - Message: `feat(tavern): session-grouped frontend with sprite rendering`
  - Files: `web/static/**, sprites/**`
  - Pre-commit: `pytest tests/e2e/`

- **Task 16**: After smoke test passes end-to-end
  - Message: `chore(tavern): end-to-end smoke verified`
  - Files: remaining test updates, docs
  - Pre-commit: `pytest tests/`

---

## Success Criteria

### Verification Commands
```bash
# Backend
curl -s localhost:8000/api/status | jq '.sessions | length'    # Expected: ≥ 1
curl -s localhost:8000/api/status | jq '.sessions[0].agents'   # Expected: array of agents

# Frontend
# Open http://localhost:3000/ — see session list sorted by activity
# Click a session row — see expandable agent cards with pixel sprites
# Sleeping sessions folded into "N 个 session 在打坐" counter (expandable)

# Tests
pytest tests/                                                   # Expected: all pass
```

### Final Checklist
- [ ] All 16 tasks implemented with acceptance criteria met
- [ ] All 4 final wave reviews APPROVED
- [ ] User explicit okay given
- [ ] No forbidden patterns (emoji in status, agent-type grouping, high frame count)
- [ ] Status logic preserved (text only + color dots)
- [ ] Both data sources (Claude JSONL + OpenCode SQLite) populated
- [ ] Sorting by activity works; sleeping counter fold/expand works
- [ ] ~15 pixel sprites rendering correctly
