from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Literal, List, Dict


@dataclass
class AgentView:
    name: str                                              # Display name (e.g. "孔明")
    agent_id: str                                          # Source-specific ID
    status: Literal["active", "idle", "sleeping", "error"]
    last_active: datetime
    sprite_id: str                                         # Maps to sprites/{id}.png
    messages_count: int = 0
    tokens: int = 0
    role: str = ""                                         # Optional display role


@dataclass
class SessionView:
    session_id: str
    source: Literal["claude", "opencode"]
    project: str                                           # Absolute path
    project_short: str                                     # e.g. "ops/feishu_things"
    agents: List[AgentView] = field(default_factory=list)
    last_updated: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    activity_score: float = 0.0
    status_counts: Dict[str, int] = field(default_factory=lambda: {
        "active": 0, "idle": 0, "sleeping": 0, "error": 0
    })

