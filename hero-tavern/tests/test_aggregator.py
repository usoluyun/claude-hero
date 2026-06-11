import pytest
from datetime import datetime, timedelta
from unittest.mock import MagicMock
from src.aggregator.aggregator import TavernAggregator
from src.models import SessionView, AgentView


def _make_agent(name, status="active", minutes_ago=0, messages=1, tokens=100):
    return AgentView(
        name=name, agent_id=name, status=status,
        last_active=datetime.now() - timedelta(minutes=minutes_ago),
        sprite_id=name.lower(), messages_count=messages, tokens=tokens,
    )


def _make_session(sid, agents, source="claude"):
    return SessionView(
        session_id=sid, source=source, project="/p", project_short="p",
        agents=agents, last_updated=max(a.last_active for a in agents),
    )


def _make_agg_with_sessions(sessions):
    mock_cp = MagicMock()
    mock_cp.parse_all.return_value = [s for s in sessions if s.source == "claude"]
    mock_op = MagicMock()
    mock_op.parse_all.return_value = [s for s in sessions if s.source == "opencode"]
    return TavernAggregator(mock_cp, mock_op)


def test_status_active_within_5min():
    agg = _make_agg_with_sessions([])
    recent = datetime.now() - timedelta(seconds=100)
    assert agg._infer_status(recent) == "active"


def test_status_sleeping_over_1hour():
    agg = _make_agg_with_sessions([])
    old = datetime.now() - timedelta(hours=2)
    assert agg._infer_status(old) == "sleeping"


def test_status_idle_between_5min_and_1hour():
    agg = _make_agg_with_sessions([])
    mid = datetime.now() - timedelta(minutes=30)
    assert agg._infer_status(mid) == "idle"


def test_status_none_last_active_is_sleeping():
    agg = _make_agg_with_sessions([])
    assert agg._infer_status(None) == "sleeping"


def test_cache_ttl_returns_same_object():
    sessions = [_make_session("s1", [_make_agent("a")])]
    agg = _make_agg_with_sessions(sessions)
    r1 = agg.get_status()
    r2 = agg.get_status()
    assert r1 is r2     # same dict object within cache window


def test_sort_by_activity_score_desc():
    now = datetime.now()
    high_score = _make_session("high", [_make_agent("a", messages=100, tokens=10000, minutes_ago=1)])
    low_score = _make_session("low", [_make_agent("b", messages=1, tokens=100, minutes_ago=10)])
    agg = _make_agg_with_sessions([low_score, high_score])    # pass in reverse order
    result = agg.get_status()
    assert result["sessions"][0].session_id == "high"
    assert result["sessions"][1].session_id == "low"
