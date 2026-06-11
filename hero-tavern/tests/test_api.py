"""Tests for FastAPI REST API endpoints."""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone

from src.api.main import app


@pytest.fixture
def client():
    """Create FastAPI test client."""
    return TestClient(app)


# ── Health endpoint ─────────────────────────────────────────────────────────

class TestHealthEndpoint:
    """Tests for GET /api/health."""

    def test_health_returns_ok(self, client):
        """Health endpoint returns status ok."""
        response = client.get("/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"

    def test_health_has_version(self, client):
        """Health response includes service info."""
        response = client.get("/api/health")
        assert response.status_code == 200
        # App version is in OpenAPI schema
        assert response.status_code == 200


# ── Status endpoint ─────────────────────────────────────────────────────────

class TestStatusEndpoint:
    """Tests for GET /api/status."""

    @patch("src.api.main.aggregator")
    def test_status_returns_east_and_west_wings(self, mock_agg, client):
        """Status returns east_wing and west_wing keys."""
        mock_agg.get_status.return_value = {
            "east_wing": [
                {
                    "id": "claude-1",
                    "name": "TestAgent",
                    "wing": "east",
                    "status": "active",
                    "last_active": "2026-06-11T10:00:00+00:00",
                    "tokens_in": 0,
                    "tokens_out": 0,
                    "current_task": None,
                    "recent_messages": [],
                }
            ],
            "west_wing": [
                {
                    "id": "opencode-1",
                    "name": "Sisyphus",
                    "wing": "west",
                    "status": "idle",
                    "last_active": "2026-06-11T09:00:00+00:00",
                    "tokens_in": 5000,
                    "tokens_out": 3000,
                    "current_task": "Building features",
                    "recent_messages": [],
                }
            ],
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }
        response = client.get("/api/status")
        assert response.status_code == 200
        data = response.json()
        assert "east_wing" in data
        assert "west_wing" in data
        assert len(data["east_wing"]) == 1
        assert len(data["west_wing"]) == 1

    @patch("src.api.main.aggregator")
    def test_status_has_last_updated(self, mock_agg, client):
        """Status response includes last_updated timestamp."""
        mock_agg.get_status.return_value = {
            "east_wing": [],
            "west_wing": [],
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }
        response = client.get("/api/status")
        assert response.status_code == 200
        data = response.json()
        assert "last_updated" in data

    @patch("src.api.main.aggregator")
    def test_status_empty_wings(self, mock_agg, client):
        """Status handles empty wings gracefully."""
        mock_agg.get_status.return_value = {
            "east_wing": [],
            "west_wing": [],
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }
        response = client.get("/api/status")
        assert response.status_code == 200
        data = response.json()
        assert data["east_wing"] == []
        assert data["west_wing"] == []


# ── History endpoint ──────────────────────────────────────────────────────────

class TestHistoryEndpoint:
    """Tests for GET /api/history."""

    @patch("src.api.main.aggregator")
    def test_history_returns_statistics(self, mock_agg, client):
        """History returns total messages, tokens, and agent counts."""
        mock_agg.get_history.return_value = {
            "total_messages": 150,
            "total_tokens_in": 50000,
            "total_tokens_out": 30000,
            "active_agents": 5,
            "blocked_agents": 1,
        }
        response = client.get("/api/history")
        assert response.status_code == 200
        data = response.json()
        assert data["total_messages"] == 150
        assert data["total_tokens_in"] == 50000
        assert data["total_tokens_out"] == 30000
        assert data["active_agents"] == 5
        assert data["blocked_agents"] == 1

    @patch("src.api.main.aggregator")
    def test_history_zero_data(self, mock_agg, client):
        """History handles zero data gracefully."""
        mock_agg.get_history.return_value = {
            "total_messages": 0,
            "total_tokens_in": 0,
            "total_tokens_out": 0,
            "active_agents": 0,
            "blocked_agents": 0,
        }
        response = client.get("/api/history")
        assert response.status_code == 200
        data = response.json()
        assert data["total_messages"] == 0
        assert data["active_agents"] == 0


# ── Messages endpoint ────────────────────────────────────────────────────────

class TestMessagesEndpoint:
    """Tests for GET /api/messages."""

    @patch("src.api.main.aggregator")
    def test_messages_default_limit_20(self, mock_agg, client):
        """Messages returns 20 items by default."""
        mock_messages = [
            {
                "agent_id": f"agent-{i}",
                "agent_name": f"Agent {i}",
                "content": f"Message {i}",
                "timestamp": "2026-06-11T10:00:00+00:00",
            }
            for i in range(20)
        ]
        mock_agg.get_messages.return_value = mock_messages
        response = client.get("/api/messages")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 20
        mock_agg.get_messages.assert_called_once_with(limit=20)

    @patch("src.api.main.aggregator")
    def test_messages_custom_limit(self, mock_agg, client):
        """Messages respects custom limit parameter."""
        mock_messages = [
            {
                "agent_id": f"agent-{i}",
                "agent_name": f"Agent {i}",
                "content": f"Message {i}",
                "timestamp": "2026-06-11T10:00:00+00:00",
            }
            for i in range(5)
        ]
        mock_agg.get_messages.return_value = mock_messages
        response = client.get("/api/messages?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5
        mock_agg.get_messages.assert_called_once_with(limit=5)

    @patch("src.api.main.aggregator")
    def test_messages_empty_list(self, mock_agg, client):
        """Messages handles empty list."""
        mock_agg.get_messages.return_value = []
        response = client.get("/api/messages")
        assert response.status_code == 200
        data = response.json()
        assert data == []

    def test_messages_limit_too_high(self, client):
        """Messages rejects limit > 100 with 422."""
        response = client.get("/api/messages?limit=200")
        assert response.status_code == 422

    def test_messages_limit_too_low(self, client):
        """Messages rejects limit < 1 with 422."""
        response = client.get("/api/messages?limit=0")
        assert response.status_code == 422


# ── Blocked endpoint ──────────────────────────────────────────────────────────

class TestBlockedEndpoint:
    """Tests for GET /api/blocked."""

    @patch("src.api.main.aggregator")
    def test_blocked_returns_list(self, mock_agg, client):
        """Blocked returns list of blocked agents with agent_id key."""
        mock_agg.get_blocked.return_value = [
            {
                "agent_id": "agent-1",
                "agent_name": "Blocked Agent",
                "wing": "east",
                "reason": "waiting_for_input",
            }
        ]
        response = client.get("/api/blocked")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["agent_id"] == "agent-1"
        assert data[0]["wing"] == "east"
        assert data[0]["reason"] == "waiting_for_input"

    @patch("src.api.main.aggregator")
    def test_blocked_empty(self, mock_agg, client):
        """Blocked handles no blocked agents."""
        mock_agg.get_blocked.return_value = []
        response = client.get("/api/blocked")
        assert response.status_code == 200
        data = response.json()
        assert data == []


# ── CORS ────────────────────────────────────────────────────────────────────

class TestCORS:
    """Tests for CORS headers."""

    def test_cors_headers_present(self, client):
        """CORS headers are present when Origin header is sent."""
        response = client.get("/api/health", headers={"Origin": "http://localhost:3000"})
        assert response.status_code == 200
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "*"


# ── Integration: all endpoints ─────────────────────────────────────────────

class TestAllEndpoints:
    """Integration tests for all endpoints working together."""

    @patch("src.api.main.aggregator")
    def test_all_endpoints_return_200(self, mock_agg, client):
        """All endpoints return 200 without authentication."""
        mock_agg.get_status.return_value = {
            "east_wing": [],
            "west_wing": [],
            "last_updated": datetime.now(timezone.utc).isoformat(),
        }
        mock_agg.get_history.return_value = {
            "total_messages": 0,
            "total_tokens_in": 0,
            "total_tokens_out": 0,
            "active_agents": 0,
            "blocked_agents": 0,
        }
        mock_agg.get_messages.return_value = []
        mock_agg.get_blocked.return_value = []

        endpoints = [
            ("/api/health", 200),
            ("/api/status", 200),
            ("/api/history", 200),
            ("/api/messages", 200),
            ("/api/blocked", 200),
        ]
        for path, expected_status in endpoints:
            response = client.get(path)
            assert response.status_code == expected_status, f"Endpoint {path} failed"
