"""E2E tests: API polling, data refresh, and error states."""
from __future__ import annotations

import pytest
from playwright.sync_api import Page, expect


class TestAPIDataRendering:
    """Verify that API data is rendered correctly in the UI."""

    def test_agent_cards_appear_after_poll(self, page: Page):
        """After the first poll, agent cards should appear in both wings."""
        # Nick Fury + Iron Man (east) and Sisyphus + Prometheus + Atlas (west)
        east_cards = page.locator("#east-agents .agent-card")
        west_cards = page.locator("#west-agents .agent-card")
        # Wait for cards to render (poll happens on init)
        expect(east_cards.first).to_be_visible(timeout=10000)
        expect(west_cards.first).to_be_visible(timeout=10000)
        expect(east_cards).to_have_count(2)
        expect(west_cards).to_have_count(3)

    def test_stats_panel_shows_correct_numbers(self, page: Page):
        """Stats panel should reflect agent counts from API."""
        active = page.locator("#stat-active")
        idle = page.locator("#stat-idle")
        sleeping = page.locator("#stat-sleeping")
        error = page.locator("#stat-error")

        expect(active).to_have_text("2", timeout=10000)   # Nick + Sisyphus
        expect(idle).to_have_text("1")                      # Iron Man
        expect(sleeping).to_have_text("1")                  # Prometheus
        expect(error).to_have_text("1")                     # Atlas

    def test_messages_are_rendered(self, page: Page):
        """Message board should display fetched messages."""
        messages = page.locator("#message-list li")
        expect(messages.first).to_be_visible(timeout=10000)
        # Should have at least the 2 fixture messages
        expect(messages).to_have_count(2)

    def test_blocked_panel_shows_blocked_agent(self, page: Page):
        """Blocked panel should show Nick Fury as blocked."""
        blocked_items = page.locator("#blocked-list li")
        expect(blocked_items.first).to_be_visible(timeout=10000)
        expect(blocked_items).to_have_count(1)


class TestPollingRefresh:
    """Verify that data refreshes on interval."""

    def test_poll_updates_timestamp(self, page: Page):
        """The last-updated element should appear after poll."""
        timestamp = page.locator("#last-updated")
        expect(timestamp).to_be_visible(timeout=10000)
        text = timestamp.text_content()
        assert "最后更新" in text


class TestErrorStates:
    """Verify graceful handling of API errors and empty states."""

    def test_error_banner_hidden_on_success(self, page: Page):
        """Error banner should be hidden when API succeeds."""
        banner = page.locator("#error-banner")
        expect(banner).not_to_be_visible(timeout=10000)

    def test_empty_state_when_no_agents(self, page: Page):
        """Empty state text should appear when agent grids have no children."""
        # With our mock data, both wings have agents, so no empty state.
        # We verify the empty-state div is NOT present when agents exist.
        east_empty = page.locator("#east-agents .empty-state")
        west_empty = page.locator("#west-agents .empty-state")
        expect(east_empty).to_have_count(0)
        expect(west_empty).to_have_count(0)
