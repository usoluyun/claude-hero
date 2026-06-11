# Hero Tavern Session View - Learnings

## 2026-06-11: Task 1 - API Scaffold

### Structure
- Project root: `/Users/luyun/Documents/poc/claude-hero/hero-tavern/`
- `src/api/main.py` exposes FastAPI `app` with 5 routes (health, status, messages, blocked, history)
- Tests in `tests/test_api.py` mock `src.api.main.aggregator` — so `aggregator/aggregator.py` is imported as `src.api.main.aggregator` (module-level import)
- CORS middleware is required by tests (access-control-allow-origin: *)
- `/api/health` is tested but was NOT in the original spec — added it anyway since tests expect it
- Messages endpoint must validate `limit` param: 1-100, default 20 (tested with 422 for out-of-range)

### Key decisions
- Empty stubs for all non-API modules (T5/T7 will fill in)
- Added CORS middleware since tests check for it
- Added `/api/health` endpoint since tests check for it
- Port 8000 is the FastAPI backend port (frontend is separate)

## 2026-06-11: Task 3 - ClaudeParser Implementation

### Real JSONL structure
- Files at `~/.claude/projects/<dirname>/<session-id>.jsonl` (top-level) and `subagents/agent-<id>.jsonl` (nested)
- Top-level entries have: `sessionId`, `cwd`, `timestamp`, `type`, `message`
- `message.content` can be string or list of content blocks (dict with `text` key)
- Hero markers appear inside `message.content` text

### Hero marker format
- Actual markers: `🦸 hero ▸ 钢铁侠（hero-java-backend-developer）接手 · Controller/Service 实现，TDD-first`
- Both half-width `()` and full-width `（）` brackets are used in the wild
- Template placeholders like `🦸 hero ▸ <英雄名>（<agent>）` exist in spec docs — must NOT match these
- Solution: regex name group `[\w\u4e00-\u9fff]+` excludes `<` and backticks; post-filter requires ID to start with `hero-` or be in `_KNOWN_SHORT_IDS`

### Directory name → project path
- `-Users-luyun-Documents-ops-foo` → `/Users/luyun/Documents/ops/foo` (naive dash→slash)
- But `cwd` field in JSONL entries is more accurate — use it as override when available
- `_shorten_project` strips `/Users/<user>/Documents/` prefix → `ops/foo`

### Session count reality
- 110 JSONL files across all projects, but only 1 contains hero markers (the claude-hero project itself)
- The "≥10 sessions" requirement depends on data availability; currently only 1 session has hero markers
- That session contains 9 agents (all hero-java-* agents)

### Files created
- `src/models.py`: `AgentView` and `SessionView` dataclasses (was empty)
- `src/parsers/claude_parser.py`: `ClaudeParser` class with `parse_all()`, `_parse_one_session()`, helpers
- `tests/fixtures/claude_logs/-Users-luyun-Documents-ops-test-project/test-session-001.jsonl`
- `tests/test_claude_parser.py`: 13 tests across 4 test classes

## 2026-06-11: Task 4 - OpenCodeParser Implementation

### OpenCode DB schema
- Location: `~/.local/share/opencode/opencode.db` (774MB, 490 active sessions)
- Empty shell: `~/.opencode/opencode.db` (4KB) — must reject with helpful error
- Table `session` has all expected columns: `id`, `directory`, `agent`, `model`, `time_created`, `time_updated`, `tokens_input`, `tokens_output`, `tokens_reasoning`, `time_archived`, etc.
- `time_archived IS NULL` filters for active sessions
- Foreign key on `project_id` → `project` table

### Agent name normalization
- OpenCode stores agent names with suffixes: "Sisyphus - ultraworker", "Prometheus - Plan Builder", "Sisyphus-Junior"
- Regex `r"\s*-\s+.*$"` strips suffixes after ` - ` pattern
- "Sisyphus-Junior" stays intact (hyphen with no spaces = part of name)

### Timestamp handling
- Unix timestamps are in seconds (values ~1.7e9), not milliseconds
- Guard: if value > 1e12, treat as millis and divide by 1000

### Read-only access
- URI `file:{path}?mode=ro` works on macOS without WAL issues
- `PRAGMA query_only = ON` as extra safety
- WAL retry path exists for edge cases

### Test fixture padding
- Tests create tiny DB files (~12KB) that fail the 100KB guard
- Must pad fixture to >100KB with null bytes to test parse logic

### pytest.ini fix
- Added `pythonpath = .` to pytest.ini to resolve `ModuleNotFoundError: No module named 'src'`

### Files created/modified
- `src/models.py`: Was empty, now has `AgentView` and `SessionView` dataclasses
- `src/parsers/opencode_parser.py`: `OpenCodeParser` class with `parse_all()` and helpers
- `tests/test_opencode_parser.py`: 3 tests (parse_all, agent_name_normalization, empty_db_rejection)
- `pytest.ini`: Added `pythonpath = .`

## 2026-06-11: Task 2 - Models Module (Rewritten)

### What changed
- `src/models.py` completely rewritten from thin stubs to full data model with:
  - `AgentView` and `SessionView` dataclasses (from T3/T4 stubs, now with `role` field and `Literal` type constraints)
  - Pydantic v2 `AgentResponse`, `SessionResponse`, `StatusSummary`, `StatusApiResponse`, `BlockedResponse`, `HistoryResponse`
- `tests/test_models.py` added with 3 default-value tests
- `src/__init__.py` created (was missing)

### Key details
- Pydantic v2 uses `ConfigDict(arbitrary_types_allowed=True)` instead of `class Config`
- Mutable defaults use `field(default_factory=...)` — required for both dataclasses and Pydantic models
- Python 3.14 deprecates `datetime.utcnow()` — warnings present but non-blocking
- All 3 tests passing

## 2026-06-11: Task 10 - Pixel Sprite PNG Generation

### Approach
- Generated 16 pixel sprite sheets (96x32px each = 3×32x32 frames side-by-side) using Python + PIL
- Component assembly method: body → outfit → hair → accessory (layered in order)
- Each sprite has 3 animation frames: idle (standing), work (arms up), rest (shifted down)
- Max 9 colors per sprite enforced (actual range: 5-7 colors)

### Key decisions
- Used Endesga-32 inspired palette subset (defined in PALETTE dict)
- `primary_color` from `mapping.yaml` drives outfit color differentiation
- 5 outfit types: `robe`, `armor`, `warrior`, `scholar`, `hood`
- 7 accessories: `fan`, `sword`, `staff`, `book`, `hammer`, `scepter`, `none`
- 3 hair styles: `short`, `long`, `bun`
- 5 skin tones from design guide
- Role characteristics encoded in `parse_role_key()` function (name-based mapping)

### Animation frames
- Frame 0 (idle): No modification from base
- Frame 1 (work): Arms shifted up 2 pixels
- Frame 2 (rest): Entire body shifted down 2 pixels

### Color counts per sprite
- kongming: 6, wenyuan: 7, zichang: 6, xiren: 7
- xuancheng: 6, pengju: 7, ziwen: 7, zhenghe: 7, xiake: 5
- prometheus: 7, sisyphus: 5, atlas: 5, hephaestus: 7
- oracle: 6, explore: 5, librarian: 6

### Files created
- `sprites/generate_sprites.py`: Main generation script (~280 lines)
- `web/static/img/sprites/*.png`: 16 sprite sheets (16/16 verified)
- `.omo/evidence/task-10-sprite-validation.txt`: Validation report (ALL PASSED)

### Known limitations
- Animation is simplistic (pixel shifting rather than true sprite animation)
- Sprites are programmatically generated "placeholder-quality" rather than hand-crafted pixel art
- Future improvement: Use Piskel/LibreSprite to hand-craft detailed pixel art with unique poses
