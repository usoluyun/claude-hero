"""FastAPI application for Hero Tavern session view."""
from datetime import datetime
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from src.aggregator.aggregator import TavernAggregator
from src.models import SessionView, AgentView
from src.parsers.claude_parser import ClaudeParser
from src.parsers.opencode_parser import OpenCodeParser

app = FastAPI(title="Hero Tavern", version="0.1.0")

# CORS: allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize parsers and aggregator
claude_parser = ClaudeParser()
opencode_parser = OpenCodeParser()
aggregator = TavernAggregator(claude_parser, opencode_parser)


def _serialize(obj: Any) -> Any:
    """Convert dataclass objects to JSON-serializable dicts."""
    if isinstance(obj, dict):
        return {k: _serialize(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_serialize(element) for element in obj]
    if isinstance(obj, (SessionView, AgentView)):
        serialized = {}
        for field_name in obj.__dataclass_fields__:
            serialized[field_name] = _serialize(getattr(obj, field_name))
        return serialized
    if isinstance(obj, datetime):
        return obj.isoformat()
    return obj


def _find_session(session_id: str):
    """Look up a session by ID in the aggregator's current cache."""
    status = aggregator.get_status()
    for session in status.get("sessions", []):
        if session.session_id == session_id:
            return session
    return None


@app.get("/api/health")
async def health():
    return {"status": "ok"}


@app.get("/api/status")
async def get_status():
    return _serialize(aggregator.get_status())


@app.get("/api/messages")
async def get_messages(
    limit: int = Query(default=20, ge=1, le=100),
    session_id: str = Query(default=None),
):
    if session_id is not None:
        session = _find_session(session_id)
        if session is None:
            raise HTTPException(status_code=404, detail=f"Session not found: {session_id}")
        return aggregator.get_messages(limit=limit, session_id=session_id)
    return aggregator.get_messages(limit=limit)


@app.get("/api/blocked")
async def get_blocked():
    return aggregator.get_blocked()


@app.get("/api/history")
async def get_history(hours: int = Query(default=24, ge=1, le=168)):
    return aggregator.get_history(hours=hours)
