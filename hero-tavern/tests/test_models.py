from datetime import datetime, timezone
from src.models import AgentView, SessionView


def test_agent_view_defaults():
    now = datetime.now(timezone.utc)
    a = AgentView(name="test", agent_id="t1", status="active", last_active=now, sprite_id="test")
    assert a.messages_count == 0
    assert a.tokens == 0
    assert a.role == ""


def test_session_view_default_status_counts():
    s = SessionView(session_id="s1", source="claude", project="/p", project_short="p")
    assert s.status_counts == {"active": 0, "idle": 0, "sleeping": 0, "error": 0}
    assert s.activity_score == 0.0
    assert s.agents == []
