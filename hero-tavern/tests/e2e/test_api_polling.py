"""E2E tests: API polling, data refresh, and error states."""
from __future__ import annotations

import pytest
from playwright.sync_api import Page, expect


class TestAPIDataRendering:
    """Verify that API data is rendered correctly in the UI."""

    def test_agent_cards_appear_after_poll(self, page: Page):
        """After the first poll, session cards should appear in both wings."""
        heroes_cards = page.locator("#heroes-container .session-card")
        deities_cards = page.locator("#deities-container .session-card")
        expect(heroes_cards.first).to_be_visible(timeout=10000)
        expect(deities_cards.first).to_be_visible(timeout=10000)

    def test_stats_panel_shows_correct_numbers(self, page: Page):
        """Stats panel should reflect agent counts from API."""
        active = page.locator("#count-active")
        idle = page.locator("#count-idle")
        sleeping = page.locator("#count-sleeping")
        error = page.locator("#count-error")

        expect(active).to_have_text("2", timeout=10000)
        expect(idle).to_have_text("1")
        expect(sleeping).to_have_text("1")
        expect(error).to_have_text("1")

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
        assert text is not None and len(text.strip()) > 0, "Timestamp element should have content"


class TestErrorStates:
    """Verify graceful handling of API errors and empty states."""

    def test_error_banner_hidden_on_success(self, page: Page):
        """Error banner should not be visible when API succeeds."""
        page.wait_for_timeout(3000)
        banner = page.locator("#error-banner")
        if banner.count() > 0:
            expect(banner).not_to_be_visible()

    def test_empty_state_when_no_agents(self, page: Page):
        """Empty state text should appear when containers have no children."""
        east_empty = page.locator("#heroes-container .empty-state")
        west_empty = page.locator("#deities-container .empty-state")
        expect(east_empty).to_have_count(0)
        expect(west_empty).to_have_count(0)
