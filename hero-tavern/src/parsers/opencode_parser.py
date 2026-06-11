"""Parser for OpenCode's SQLite session database."""
from __future__ import annotations

import os
import sqlite3
import logging
import re
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Optional

from src.models import SessionView, AgentView

logger = logging.getLogger(__name__)

# Known suffixes to strip: "- ultraworker", "- Plan Builder", etc.
AGENT_NAME_SUFFIX_RE = re.compile(r"\s*-\s+.*$")

# Known OMO agent → sprite mapping (module-level to avoid re-creation per call)
_OMO_SPRITE_MAP = {
    "Prometheus": "prometheus",
    "Atlas": "atlas",
    "Sisyphus": "sisyphus",
    "Hephaestus": "hephaestus",
    "oracle": "oracle",
    "explore": "explore",
    "librarian": "librarian",
    "Metis": "metis",
    "Momus": "momus",
    "plan": "plan",
    "general": "general",
}


class OpenCodeParser:
    """Queries the OpenCode SQLite database and returns list[SessionView]."""

    def __init__(self, db_path: Optional[str] = None):
        if db_path is None:
            db_path = os.environ.get(
                "OPENCODE_DB_PATH",
                str(Path.home() / ".local" / "share" / "opencode" / "opencode.db"),
            )
        self.db_path = Path(db_path).expanduser()

    def parse_all(self, db_path: Optional[str] = None) -> List[SessionView]:
        """Query OpenCode DB. Returns list of SessionView."""
        target = Path(db_path).expanduser() if db_path else self.db_path

        if not target.exists():
            raise FileNotFoundError(f"OpenCode DB not found: {target}")

        size = target.stat().st_size
        if size < 100 * 1024:  # 100KB
            raise ValueError(
                f"empty DB, expected > 100KB — "
                f"OpenCode DB at {target} is only {size} bytes. "
                f"Is OPENCODE_DB_PATH correct?"
            )

        sessions: List[SessionView] = []

        try:
            conn = sqlite3.connect(f"file:{target}?mode=ro", uri=True)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()

            # Read-only pragma
            cur.execute("PRAGMA query_only = ON")

            cur.execute("""
                SELECT id, directory, agent, model, time_created, time_updated,
                       tokens_input, tokens_output, tokens_reasoning
                FROM session
                WHERE time_archived IS NULL
                ORDER BY time_updated DESC
            """)

            for row in cur:
                sid = row["id"]
                directory = row["directory"] or "/"
                agent_raw = row["agent"] or "unknown"
                time_created = self._unix_to_dt(row["time_created"])
                time_updated = self._unix_to_dt(row["time_updated"])
                tokens_in = row["tokens_input"] or 0
                tokens_out = row["tokens_output"] or 0

                agent_name = self._normalize_agent_name(agent_raw)
                sprite_id = self._name_to_sprite_id(agent_name)
                project_short = self._shorten_project(directory)

                agent = AgentView(
                    name=agent_name,
                    agent_id=f"opencode::{sid}::{agent_raw}",
                    status="active",  # placeholder; aggregator recomputes
                    last_active=time_updated,
                    sprite_id=sprite_id,
                    messages_count=1,
                    tokens=tokens_in + tokens_out,
                )

                sessions.append(SessionView(
                    session_id=sid,
                    source="opencode",
                    project=directory,
                    project_short=project_short,
                    agents=[agent] if agent_name else [],
                    last_updated=time_updated,
                ))

            conn.close()
        except sqlite3.OperationalError as e:
            logger.warning(f"DB access issue with {target}: {e}. Trying WAL mode.")
            # Retry with WAL — but still read-only
            try:
                conn = sqlite3.connect(str(target))
                conn.row_factory = sqlite3.Row
                cur = conn.cursor()
                cur.execute("PRAGMA journal_mode=WAL")
                cur.execute("PRAGMA query_only = ON")
                cur.execute("SELECT COUNT(*) FROM session WHERE time_archived IS NULL")
                count = cur.fetchone()[0]
                conn.close()
                logger.info(f"DB accessible after WAL mode: {count} sessions")
            except Exception:
                logger.exception("WAL retry failed for %s", target)
                raise

        return sessions

    def _unix_to_dt(self, unix_ts) -> datetime:
        if unix_ts is None:
            return datetime.now(timezone.utc).replace(tzinfo=None)
        if isinstance(unix_ts, str) and unix_ts.isdigit():
            unix_ts = int(unix_ts)
        if isinstance(unix_ts, (int, float)):
            # Try millis first if value is too large for seconds
            if unix_ts > 1e12:
                unix_ts = unix_ts / 1000
            return datetime.fromtimestamp(unix_ts)
        logger.warning("Could not parse timestamp value: %s", unix_ts)
        return datetime.now(timezone.utc).replace(tzinfo=None)

    def _normalize_agent_name(self, raw: str) -> str:
        """Strip suffixes: 'Sisyphus - ultraworker' → 'Sisyphus'"""
        return AGENT_NAME_SUFFIX_RE.sub("", raw).strip()

    def _shorten_project(self, path: str) -> str:
        parts = Path(path).parts
        try:
            idx = list(parts).index("Documents")
            return "/".join(parts[idx + 1:])
        except ValueError:
            return "/".join(parts[-2:]) if len(parts) >= 2 else path

    def _name_to_sprite_id(self, name: str) -> str:
        return _OMO_SPRITE_MAP.get(name, name.lower().replace(" ", "-"))
