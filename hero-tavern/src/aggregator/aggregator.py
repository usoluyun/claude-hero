import os
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from src.models import SessionView, AgentView

logger = logging.getLogger(__name__)


class TavernAggregator:
    """Combines Claude + OpenCode sessions, recomputes status, sorts by score, caches for 30s."""
    
    CACHE_TTL_SECONDS = 30
    
    def __init__(self, claude_parser, opencode_parser, cache_ttl: int = None):
        self.claude_parser = claude_parser
        self.opencode_parser = opencode_parser
        self.cache_ttl = cache_ttl or int(os.environ.get("CACHE_TTL", self.CACHE_TTL_SECONDS))
        self.idle_threshold = int(os.environ.get("IDLE_THRESHOLD", "300"))
        self.sleep_threshold = int(os.environ.get("SLEEP_THRESHOLD", "3600"))
        self._cache: Optional[Dict[str, Any]] = None
        self._cache_time: Optional[datetime] = None
    
    def get_status(self) -> Dict[str, Any]:
        """Main entry point. Returns aggregated status dict."""
        if self._is_cache_valid():
            logger.debug("Returning cached status")
            return self._cache
        
        now = datetime.now()
        
        # Collect all sessions
        try:
            claude_sessions = self.claude_parser.parse_all()
        except Exception:
            logger.exception("Claude parser failed — returning partial results")
            claude_sessions = []
        
        try:
            opencode_sessions = self.opencode_parser.parse_all()
        except Exception:
            logger.exception("OpenCode parser failed — returning partial results")
            opencode_sessions = []
        
        all_sessions = claude_sessions + opencode_sessions
        
        # Recompute status + score for each
        for session in all_sessions:
            self._recompute_session(session, now)
        
        # Sort by score DESC, then recency
        all_sessions.sort(
            key=lambda s: (s.activity_score, s.last_updated.replace(tzinfo=None) if s.last_updated else datetime.min),
            reverse=True
        )
        
        # Compute summary
        summary = {"active": 0, "idle": 0, "sleeping": 0, "error": 0}
        for s in all_sessions:
            for status, count in s.status_counts.items():
                if status in summary:
                    summary[status] += count
        summary["total_sessions"] = len(all_sessions)
        
        status_payload = {
            "sessions": all_sessions,
            "last_updated": now,
            "status_summary": summary,
        }
        
        self._cache = status_payload
        self._cache_time = now
        return status_payload
    
    def _is_cache_valid(self) -> bool:
        if self._cache is None or self._cache_time is None:
            return False
        elapsed = (datetime.now() - self._cache_time).total_seconds()
        return elapsed < self.cache_ttl
    
    def _recompute_session(self, session: SessionView, now: datetime) -> None:
        """Recompute status, scores, counts for a single session."""
        counts = {"active": 0, "idle": 0, "sleeping": 0, "error": 0}
        total_messages = 0
        total_tokens = 0
        
        for agent in session.agents:
            # Collect recent messages (placeholder - for now just use agent info)
            status = self._infer_status(agent.last_active, now=now)
            agent.status = status
            counts[status] += 1
            total_messages += agent.messages_count
            total_tokens += agent.tokens
        
        session.status_counts = counts
        session.activity_score = self._calibrate_activity_score(
            total_messages, total_tokens, session.last_updated, now
        )
    
    def _infer_status(self, last_active: datetime, now: datetime = None) -> str:
        """Status inference based on time thresholds."""
        if now is None:
            now = datetime.now()
        
        if last_active is None:
            return "sleeping"
        
        elapsed = (now - last_active.replace(tzinfo=None)).total_seconds()
        
        if elapsed < self.idle_threshold:
            return "active"
        elif elapsed < self.sleep_threshold:
            return "idle"
        else:
            return "sleeping"
    
    def _calibrate_activity_score(
        self, messages_count: int, tokens: int, last_updated: datetime, now: datetime
    ) -> float:
        """Activity score formula."""
        recency_bonus = 0.0
        if last_updated:
            elapsed = (now - last_updated.replace(tzinfo=None)).total_seconds()
            if elapsed < 300:        # < 5 min
                recency_bonus = 100.0
            elif elapsed < 3600:     # < 1 hour
                recency_bonus = 50.0
        
        return (messages_count * 10) + (tokens / 100.0) + recency_bonus
    
    # ------------------------------------------------------------------
    # Public convenience methods for API
    # ------------------------------------------------------------------
    
    def get_messages(self, limit: int = 20, session_id: str = None) -> list:
        """Return recent messages. If session_id given, filter to that session."""
        status = self.get_status()
        sessions = status.get("sessions", [])
        now = datetime.now()
        
        if session_id:
            sessions = [s for s in sessions if s.session_id == session_id]
        
        messages = []
        for session in sessions:
            for agent in session.agents:
                ts = agent.last_active
                if ts and ts.tzinfo:
                    ts = ts.replace(tzinfo=None)
                ts_iso = ts.isoformat() if ts else now.isoformat()
                messages.append({
                    "agent_id": agent.agent_id,
                    "agent_name": agent.name,
                    "content": f"{agent.name} {agent.status} - {agent.messages_count} messages, {agent.tokens} tokens",
                    "timestamp": ts_iso,
                    "session_id": session.session_id,
                })
        
        messages.sort(key=lambda m: m["timestamp"], reverse=True)
        return messages[:limit]
    
    def get_blocked(self) -> list:
        """Return blocked agents (those with error status or stalled)."""
        status = self.get_status()
        sessions = status.get("sessions", [])
        blocked = []
        
        for session in sessions:
            for agent in session.agents:
                if agent.status == "error":
                    blocked.append({
                        "agent_id": agent.agent_id,
                        "agent_name": agent.name,
                        "wing": "east" if session.source == "claude" else "west",
                        "reason": "error_detected",
                    })
        
        return blocked
    
    def get_history(self, hours: int = 24) -> dict:
        """Return aggregate history statistics."""
        status = self.get_status()
        sessions = status.get("sessions", [])
        now = datetime.now()
        cutoff = now - timedelta(hours=hours)
        
        total_messages = 0
        total_tokens_in = 0
        total_tokens_out = 0
        active_agents = 0
        blocked_agents = 0
        
        for session in sessions:
            for agent in session.agents:
                ts = agent.last_active
                if ts and ts.tzinfo:
                    ts = ts.replace(tzinfo=None)
                if ts and ts >= cutoff:
                    total_messages += agent.messages_count
                    total_tokens_in += agent.tokens
                    active_agents += 1
                if agent.status == "error":
                    blocked_agents += 1
        
        return {
            "total_messages": total_messages,
            "total_tokens_in": total_tokens_in,
            "total_tokens_out": total_tokens_out,
            "active_agents": active_agents,
            "blocked_agents": blocked_agents,
        }
