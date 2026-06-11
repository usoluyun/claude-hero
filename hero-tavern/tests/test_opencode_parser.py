"""Tests for src/parsers/opencode_parser.py"""
from __future__ import annotations

import sqlite3
import pytest
from pathlib import Path


# ---------------------------------------------------------------------------
# Fixture: in-memory SQLite DB mimicking the OpenCode session table schema
# ---------------------------------------------------------------------------

@pytest.fixture
def opencode_db(tmp_path):
    """Create a test SQLite DB with 3 sessions and enough padding to pass the 100KB guard."""
    db_path = tmp_path / "test.db"
    conn = sqlite3.connect(str(db_path))
    conn.execute("""
        CREATE TABLE session (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            parent_id TEXT,
            slug TEXT NOT NULL,
            directory TEXT NOT NULL,
            title TEXT NOT NULL,
            version TEXT NOT NULL,
            share_url TEXT,
            summary_additions INTEGER,
            summary_deletions INTEGER,
            summary_files INTEGER,
            summary_diffs TEXT,
            revert TEXT,
            permission TEXT,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            time_compacting INTEGER,
            time_archived INTEGER,
            workspace_id TEXT,
            path TEXT,
            agent TEXT,
            model TEXT,
            cost REAL DEFAULT 0 NOT NULL,
            tokens_input INTEGER DEFAULT 0 NOT NULL,
            tokens_output INTEGER DEFAULT 0 NOT NULL,
            tokens_reasoning INTEGER DEFAULT 0 NOT NULL,
            tokens_cache_read INTEGER DEFAULT 0 NOT NULL,
            tokens_cache_write INTEGER DEFAULT 0 NOT NULL,
            metadata TEXT
        )
    """)
    # Insert 3 test sessions
    conn.execute("""
        INSERT INTO session (id, project_id, slug, directory, title, version,
                             agent, model, time_created, time_updated,
                             tokens_input, tokens_output)
        VALUES
            ('s1', 'p1', 'slug1', '/Users/luyun/Documents/ops/feishu_things',
             'Test1', '1.0', 'Sisyphus - ultraworker', 'sonnet',
             1718000000, 1718100000, 1000, 500),
            ('s2', 'p1', 'slug2', '/Users/luyun/Documents/poc/claude-hero',
             'Test2', '1.0', 'Prometheus - Plan Builder', 'opus',
             1718200000, 1718300000, 2000, 1000),
            ('s3', 'p1', 'slug3', '/Users/luyun/Documents/poc/ex-pertie',
             'Test3', '1.0', 'oracle', 'opus',
             1718400000, 1718500000, 500, 300)
    """)
    conn.commit()
    conn.close()

    # Pad the file so it exceeds the 100KB guard
    with open(db_path, "ab") as f:
        f.write(b"\x00" * (110 * 1024 - db_path.stat().st_size))

    return str(db_path)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_parses_all_sessions(opencode_db):
    from src.parsers.opencode_parser import OpenCodeParser
    p = OpenCodeParser(opencode_db)
    sessions = p.parse_all()
    assert len(sessions) == 3
    # Sessions should be ordered by time_updated DESC
    assert sessions[0].session_id == "s3"
    assert sessions[1].session_id == "s2"
    assert sessions[2].session_id == "s1"


def test_agent_name_normalized(opencode_db):
    from src.parsers.opencode_parser import OpenCodeParser
    p = OpenCodeParser(opencode_db)
    sessions = p.parse_all()
    names = {s.agents[0].name for s in sessions if s.agents}
    assert "Sisyphus" in names
    assert "Prometheus" in names
    assert "Sisyphus - ultraworker" not in names
    assert "Prometheus - Plan Builder" not in names


def test_empty_db_rejected(tmp_path):
    from src.parsers.opencode_parser import OpenCodeParser
    db_path = tmp_path / "empty.db"
    conn = sqlite3.connect(str(db_path))
    conn.execute("CREATE TABLE dummy(x)")
    conn.commit()
    conn.close()
    p = OpenCodeParser(str(db_path))
    # File is tiny (<100KB) so it should raise ValueError
    with pytest.raises(ValueError, match="empty DB"):
        p.parse_all()
