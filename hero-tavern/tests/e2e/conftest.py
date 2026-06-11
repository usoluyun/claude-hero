"""E2E test fixtures — starts static file server with Playwright route mocking."""
from __future__ import annotations

import json
import os
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import pytest


# ── Mock data fixtures ────────────────────────────────────────────────────

def _make_status():
    return {
        "east_wing": [
            {
                "id": "claude-1", "name": "Nick Fury", "wing": "east",
                "status": "active", "last_active": "2026-06-11T10:00:00+00:00",
                "tokens_in": 5000, "tokens_out": 3000, "current_task": "Assemble team",
                "recent_messages": [
                    {"content": "We need a plan", "timestamp": "2026-06-11T10:00:00+00:00"},
                ],
            },
            {
                "id": "claude-2", "name": "Iron Man", "wing": "east",
                "status": "idle", "last_active": "2026-06-11T09:30:00+00:00",
                "tokens_in": 2000, "tokens_out": 1500, "current_task": None,
                "recent_messages": [],
            },
        ],
        "west_wing": [
            {
                "id": "omo-1", "name": "Sisyphus", "wing": "west",
                "status": "active", "last_active": "2026-06-11T10:05:00+00:00",
                "tokens_in": 8000, "tokens_out": 6000, "current_task": "Building features",
                "recent_messages": [
                    {"content": "Executing task 11", "timestamp": "2026-06-11T10:05:00+00:00"},
                ],
            },
            {
                "id": "omo-2", "name": "Prometheus", "wing": "west",
                "status": "sleeping", "last_active": "2026-06-10T22:00:00+00:00",
                "tokens_in": 100, "tokens_out": 50, "current_task": None,
                "recent_messages": [],
            },
            {
                "id": "omo-3", "name": "Atlas", "wing": "west",
                "status": "error", "last_active": "2026-06-11T08:00:00+00:00",
                "tokens_in": 300, "tokens_out": 100, "current_task": "Error handling",
                "recent_messages": [
                    {"content": "error: connection refused", "timestamp": "2026-06-11T08:00:00+00:00"},
                ],
            },
        ],
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }


MESSAGES_FIXTURE = [
    {
        "agent_id": "claude-1", "agent_name": "Nick Fury",
        "content": "We need a plan", "timestamp": "2026-06-11T10:00:00+00:00",
    },
    {
        "agent_id": "omo-1", "agent_name": "Sisyphus",
        "content": "Executing task 11", "timestamp": "2026-06-11T10:05:00+00:00",
    },
]

BLOCKED_FIXTURE = [
    {
        "agent_id": "claude-1", "agent_name": "Nick Fury",
        "wing": "east", "reason": "waiting_for_input",
    },
]

HISTORY_FIXTURE = {
    "total_messages": 25, "total_tokens_in": 15000,
    "total_tokens_out": 10000, "active_agents": 2, "blocked_agents": 1,
}


# ── Helpers ───────────────────────────────────────────────────────────────

def _kill_process(proc: subprocess.Popen):
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        proc.wait(timeout=5)
    except (ProcessLookupError, TimeoutError):
        pass


def _wait_for_url(url: str, deadline: float) -> bool:
    import urllib.request
    while time.time() < deadline:
        try:
            urllib.request.urlopen(url, timeout=1)
            return True
        except Exception:
            time.sleep(0.2)
    return False


# ── Pytest fixtures ──────────────────────────────────────────────────────


@pytest.fixture(scope="session")
def api_port():
    return 18765


@pytest.fixture(scope="session")
def web_port():
    return 18766


@pytest.fixture(scope="session")
def base_url(web_port):
    return f"http://127.0.0.1:{web_port}"


@pytest.fixture(scope="session")
def web_server(web_port, api_port, tmp_path_factory):
    """Start http.server for static files, with API_BASE patched for tests."""
    web_root = Path(__file__).resolve().parent.parent.parent / "web" / "static"
    tmp_web = tmp_path_factory.mktemp("e2e_web")

    shutil.copytree(str(web_root), str(tmp_web), dirs_exist_ok=True)

    js_path = tmp_web / "js" / "tavern.js"
    content = js_path.read_text()
    content = content.replace(
        "const API_BASE = 'http://localhost:8000';",
        f"const API_BASE = 'http://127.0.0.1:{api_port}';",
    )
    js_path.write_text(content)

    proc = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(web_port)],
        cwd=str(tmp_web),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        preexec_fn=os.setsid,
    )

    if not _wait_for_url(f"http://127.0.0.1:{web_port}/", time.time() + 10):
        _kill_process(proc)
        pytest.fail(f"Web server did not start on port {web_port}")

    yield f"http://127.0.0.1:{web_port}"

    _kill_process(proc)


@pytest.fixture(scope="function")
def page(browser, base_url, web_server, api_port):
    """Create a Playwright page with mocked API routes."""
    context = browser.new_context(viewport={"width": 1280, "height": 900})
    page = context.new_page()

    # Intercept ALL API calls using glob pattern
    def handle_api(route):
        url = route.request.url
        if "api/health" in url:
            route.fulfill(json={"status": "ok"})
        elif "api/status" in url:
            route.fulfill(json=_make_status())
        elif "api/messages" in url:
            route.fulfill(json=MESSAGES_FIXTURE)
        elif "api/blocked" in url:
            route.fulfill(json=BLOCKED_FIXTURE)
        elif "api/history" in url:
            route.fulfill(json=HISTORY_FIXTURE)
        else:
            route.fulfill(status=404, json={"error": "unknown"})

    page.route("**/api/**", handle_api)

    page.goto(base_url, wait_until="domcontentloaded")
    # Wait for initial poll to complete (fetchStatus is async)
    page.wait_for_timeout(2000)
    yield page
    context.close()
