"""Claude Code JSONL log parser — scans ~/.claude/projects for hero markers."""

import json
import re
import logging
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

from src.models import SessionView, AgentView

logger = logging.getLogger(__name__)

# Hero marker regex:
#   🦸 hero ▸ <NAME>(<ID>)  or  🦸 hero ▸ <NAME>（<ID>）
# ID: must start with hero- or be a known short ID (kongming, wenyuan, etc.)
# Name: Unicode letters/CJK + word chars — excludes backticks, angle brackets
HERO_MARKER_RE = re.compile(
    r"🦸 hero ▸\s*([\w\u4e00-\u9fff]+)\s*[(（]([\w-]+)[)）]"
)

_KNOWN_SHORT_IDS = frozenset({
    "kongming", "wenyuan", "zichang", "xiren", "xuancheng",
    "pengju", "ziwen", "zhenghe", "xiake",
})


class ClaudeParser:
    """Parse Claude Code JSONL logs and return SessionView objects."""

    def __init__(self, base_dir: str | None = None):
        if base_dir is None:
            base_dir = str(Path.home() / ".claude" / "projects")
        self.base_dir = Path(base_dir).expanduser()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def parse_all(self, base_dir: str | None = None) -> List[SessionView]:
        """Scan all projects. Returns sessions that contain hero markers."""
        target = Path(base_dir).expanduser() if base_dir else self.base_dir
        sessions: Dict[str, SessionView] = {}

        if not target.is_dir():
            logger.warning("Base directory does not exist: %s", target)
            return []

        for project_dir in target.iterdir():
            if not project_dir.is_dir():
                continue
            for jsonl_file in project_dir.glob("*.jsonl"):
                session_id = jsonl_file.stem
                try:
                    session = self._parse_one_session(
                        jsonl_file, session_id, project_dir.name
                    )
                except Exception as exc:
                    logger.warning("Failed to parse %s: %s", jsonl_file, exc)
                    continue
                if session and session.agents:
                    sessions[session_id] = session

        return list(sessions.values())

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _parse_one_session(
        self, jsonl_file: Path, session_id: str, project_dir_name: str
    ) -> Optional[SessionView]:
        """Parse a single JSONL file. Returns SessionView or None."""
        project = self._directory_to_path(project_dir_name)
        project_short = self._shorten_project(project)

        cwd_seen: Optional[str] = None
        agent_activity: Dict[str, Dict] = {}
        latest_timestamp: Optional[datetime] = None

        with open(jsonl_file, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    logger.debug(
                        "Skipping malformed JSON in %s: %.80s",
                        jsonl_file,
                        line,
                    )
                    continue

                # Timestamp
                ts = self._parse_timestamp(entry.get("timestamp"))
                if ts and (latest_timestamp is None or ts > latest_timestamp):
                    latest_timestamp = ts

                # Track cwd
                cwd = entry.get("cwd")
                if cwd and not cwd_seen:
                    cwd_seen = cwd

                # Scan text for hero markers
                text = self._extract_text(entry)
                if text:
                    for match in HERO_MARKER_RE.finditer(text):
                        name = match.group(1).strip()
                        aid = match.group(2).strip()
                        if not self._is_valid_agent_id(aid):
                            continue
                        if aid not in agent_activity:
                            agent_activity[aid] = {
                                "name": name,
                                "last_active": ts,
                                "messages_count": 0,
                            }
                        agent_activity[aid]["messages_count"] += 1
                        if ts and (
                            agent_activity[aid]["last_active"] is None
                            or ts > agent_activity[aid]["last_active"]
                        ):
                            agent_activity[aid]["last_active"] = ts

        if not agent_activity or latest_timestamp is None:
            return None

        project_final = cwd_seen or project
        agents = []
        for aid, info in agent_activity.items():
            sprite_id = self._name_to_sprite_id(info["name"])
            agents.append(
                AgentView(
                    name=info["name"],
                    agent_id=f"claude::{session_id}::{aid}",
                    status="active",
                    last_active=info["last_active"] or latest_timestamp,
                    sprite_id=sprite_id,
                    messages_count=info["messages_count"],
                    tokens=0,
                )
            )

        return SessionView(
            session_id=session_id,
            source="claude",
            project=project_final,
            project_short=project_short,
            agents=agents,
            last_updated=latest_timestamp,
        )

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _parse_timestamp(ts_str: str | None) -> Optional[datetime]:
        """Parse ISO-8601 timestamp string."""
        if not ts_str:
            return None
        try:
            return datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        except (ValueError, AttributeError):
            return None

    @staticmethod
    def _is_valid_agent_id(aid: str) -> bool:
        return aid.startswith("hero-") or aid in _KNOWN_SHORT_IDS

    @staticmethod
    def _directory_to_path(dirname: str) -> str:
        """Convert project dir name to absolute path.

        ``-Users-luyun-Documents-ops-foo`` → ``/Users/luyun/Documents/ops/foo``
        """
        if dirname.startswith("-"):
            return "/" + dirname.lstrip("-").replace("-", "/")
        return dirname

    @staticmethod
    def _shorten_project(project_path: str) -> str:
        """Strip leading ``/Users/<user>/Documents/`` → ``ops/foo``."""
        parts = Path(project_path).parts
        try:
            idx = list(parts).index("Documents")
            remaining = parts[idx + 1 :]
            return "/".join(remaining) if remaining else parts[-1]
        except ValueError:
            return "/".join(parts[-2:]) if len(parts) >= 2 else (
                parts[-1] if parts else project_path
            )

    @staticmethod
    def _extract_text(entry: dict) -> str:
        """Pull text content from a JSONL entry (may be nested)."""
        parts: list[str] = []

        text = entry.get("text", "")
        if text and isinstance(text, str):
            parts.append(text)

        # attachment.content
        attachment = entry.get("attachment")
        if isinstance(attachment, dict):
            content = attachment.get("content", "")
            if content and isinstance(content, str):
                parts.append(content)

        # message.content — may be string or list of content blocks
        message = entry.get("message")
        if isinstance(message, dict):
            msg_content = message.get("content")
            if isinstance(msg_content, str):
                parts.append(msg_content)
            elif isinstance(msg_content, list):
                for block in msg_content:
                    if isinstance(block, dict):
                        block_text = block.get("text", "")
                        if block_text and isinstance(block_text, str):
                            parts.append(block_text)

        return " ".join(parts)

    @staticmethod
    def _name_to_sprite_id(name: str) -> str:
        """Map hero display name to sprite filename stem."""
        hero_map = {
            "孔明": "kongming",
            "文远": "wenyuan",
            "子长": "zichang",
            "希仁": "xiren",
            "玄成": "xuancheng",
            "鹏举": "pengju",
            "子文": "ziwen",
            "郑和": "zhenghe",
            "霞客": "xiake",
            "钢铁侠": "ironman",
            "蜘蛛侠": "spiderman",
            "海姆达尔": "heimdall",
            "奇异博士": "strange",
            "幻视": "vision",
            "神盾局长": "fury",
            "火箭浣熊": "rocket",
            "星爵": "starlord",
            "猎鹰": "falcon",
        }
        return hero_map.get(name, name.lower().replace(" ", "-"))
