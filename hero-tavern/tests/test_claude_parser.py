"""Unit tests for ClaudeParser — hero marker extraction from JSONL logs."""

import json
from pathlib import Path
from datetime import datetime

import pytest

from src.parsers.claude_parser import ClaudeParser, HERO_MARKER_RE
from src.models import SessionView, AgentView

FIXTURES_DIR = Path(__file__).parent / "fixtures" / "claude_logs"


# ---------------------------------------------------------------------------
# Test 1: Correct session count from fixture
# ---------------------------------------------------------------------------

class TestSessionCount:
    def test_parse_all_returns_correct_count(self):
        parser = ClaudeParser(base_dir=str(FIXTURES_DIR))
        sessions = parser.parse_all()
        # Fixture has one project dir with one JSONL file containing hero markers
        assert len(sessions) == 1
        assert sessions[0].session_id == "test-session-001"

    def test_parse_all_skips_empty_sessions(self, tmp_path):
        """A JSONL with no hero markers should produce no sessions."""
        project_dir = tmp_path / "-Users-luyun-Documents-ops-empty"
        project_dir.mkdir()
        jsonl = project_dir / "no-heroes.jsonl"
        jsonl.write_text(
            '{"type":"progress","timestamp":"2026-06-10T08:00:00.000Z",'
            '"message":{"role":"user","content":"just a normal line"}}\n',
            encoding="utf-8",
        )
        parser = ClaudeParser(base_dir=str(tmp_path))
        sessions = parser.parse_all()
        assert len(sessions) == 0


# ---------------------------------------------------------------------------
# Test 2: Both bracket styles detected
# ---------------------------------------------------------------------------

class TestBracketStyles:
    def test_half_width_brackets_detected(self):
        text = "🦸 hero ▸ 孔明(kongming) 接手"
        matches = list(HERO_MARKER_RE.finditer(text))
        assert len(matches) == 1
        assert matches[0].group(1).strip() == "孔明"
        assert matches[0].group(2) == "kongming"

    def test_full_width_brackets_detected(self):
        text = "🦸 hero ▸ 文远（wenyuan）接手"
        matches = list(HERO_MARKER_RE.finditer(text))
        assert len(matches) == 1
        assert matches[0].group(1).strip() == "文远"
        assert matches[0].group(2) == "wenyuan"

    def test_fixture_detects_both_bracket_styles(self):
        parser = ClaudeParser(base_dir=str(FIXTURES_DIR))
        sessions = parser.parse_all()
        assert len(sessions) == 1
        agent_ids = {a.agent_id for a in sessions[0].agents}
        # kongming uses half-width, wenyuan uses full-width
        assert any("kongming" in aid for aid in agent_ids)
        assert any("wenyuan" in aid for aid in agent_ids)


# ---------------------------------------------------------------------------
# Test 3: project_short is correctly stripped
# ---------------------------------------------------------------------------

class TestProjectShort:
    def test_shorten_project_strips_documents_prefix(self):
        result = ClaudeParser._shorten_project("/Users/luyun/Documents/ops/foo")
        assert result == "ops/foo"

    def test_shorten_project_deep_path(self):
        result = ClaudeParser._shorten_project(
            "/Users/luyun/Documents/ATLWork/app-api"
        )
        assert result == "ATLWork/app-api"

    def test_shorten_project_no_documents_fallback(self):
        result = ClaudeParser._shorten_project("/opt/deploy/my-service")
        assert result == "deploy/my-service"

    def test_directory_to_path_conversion(self):
        result = ClaudeParser._directory_to_path(
            "-Users-luyun-Documents-ops-test-project"
        )
        assert result == "/Users/luyun/Documents/ops/test/project"

    def test_fixture_session_has_correct_project_short(self):
        parser = ClaudeParser(base_dir=str(FIXTURES_DIR))
        sessions = parser.parse_all()
        assert len(sessions) == 1
        # Directory name -Users-luyun-Documents-ops-test-project → /Users/luyun/Documents/ops/test/project
        # But cwd overrides: /Users/luyun/Documents/ops/test-project
        # _shorten_project on cwd path: strip /Users/luyun/Documents/ → ops/test-project
        # Actually cwd_seen takes precedence over directory name
        assert "ops" in sessions[0].project_short


# ---------------------------------------------------------------------------
# Test 4: Malformed JSON lines don't crash
# ---------------------------------------------------------------------------

class TestMalformedResilience:
    def test_malformed_line_skipped_gracefully(self, tmp_path):
        project_dir = tmp_path / "-Users-luyun-Documents-ops-resilience"
        project_dir.mkdir()
        jsonl = project_dir / "mixed.jsonl"
        lines = [
            '{"type":"progress","timestamp":"2026-06-10T09:00:00.000Z",'
            '"message":{"role":"user","content":"🦸 hero ▸ 孔明(kongming) 接手"}}',
            "not_json{{{",
            '{"type":"progress","timestamp":"2026-06-10T09:01:00.000Z",'
            '"message":{"role":"assistant","content":"🦸 hero ▸ 文远（wenyuan）接手"}}',
        ]
        jsonl.write_text("\n".join(lines) + "\n", encoding="utf-8")

        parser = ClaudeParser(base_dir=str(tmp_path))
        sessions = parser.parse_all()

        # Should get 1 session with 2 agents despite malformed line
        assert len(sessions) == 1
        assert len(sessions[0].agents) == 2

    def test_empty_file_produces_no_session(self, tmp_path):
        project_dir = tmp_path / "-Users-luyun-Documents-ops-empty2"
        project_dir.mkdir()
        jsonl = project_dir / "empty.jsonl"
        jsonl.write_text("", encoding="utf-8")

        parser = ClaudeParser(base_dir=str(tmp_path))
        sessions = parser.parse_all()
        assert len(sessions) == 0

    def test_nonexistent_base_dir_returns_empty(self):
        parser = ClaudeParser(base_dir="/nonexistent/path")
        sessions = parser.parse_all()
        assert sessions == []
