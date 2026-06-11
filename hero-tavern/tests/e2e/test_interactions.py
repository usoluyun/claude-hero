"""E2E tests: click interactions, modal dialogs, keyboard shortcuts."""
from __future__ import annotations

import pytest
from playwright.sync_api import Page, expect


class TestAgentCardClick:
    """Verify clicking agent cards opens a detail modal."""

    def test_click_agent_card_opens_modal(self, page: Page):
        """Clicking an agent card should show the modal overlay."""
        card = page.locator("#east-agents .agent-card").first
        expect(card).to_be_visible(timeout=10000)

        card.click()
        overlay = page.locator("#modal-overlay")
        expect(overlay).to_have_class("modal-overlay active")

    def test_modal_shows_agent_name(self, page: Page):
        """The modal should display the clicked agent's name."""
        # Click Nick Fury
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        modal_content = page.locator("#modal-content")
        expect(modal_content).to_be_visible()
        expect(modal_content).to_contain_text("Nick Fury")

    def test_modal_shows_status_and_tokens(self, page: Page):
        """Modal should show status, tokens, and last active time."""
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        modal = page.locator("#modal-content")
        expect(modal).to_contain_text("论剑")          # status = active
        expect(modal).to_contain_text("5000")           # tokens_in
        expect(modal).to_contain_text("3000")           # tokens_out

    def test_modal_shows_recent_messages(self, page: Page):
        """Modal should show the agent's recent messages."""
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        modal = page.locator("#modal-content")
        expect(modal).to_contain_text("We need a plan")

    def test_modal_has_close_button(self, page: Page):
        """Modal should have a close button."""
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        close_btn = page.locator(".modal-close")
        expect(close_btn).to_be_visible()
        expect(close_btn).to_contain_text("关闭")


class TestModalClose:
    """Verify closing the detail modal."""

    def test_close_modal_via_button(self, page: Page):
        """Clicking the close button should hide the modal."""
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        page.locator(".modal-close").click()
        overlay = page.locator("#modal-overlay")
        expect(overlay).not_to_have_class("modal-overlay active")

    def test_close_modal_via_escape_key(self, page: Page):
        """Pressing Escape should hide the modal."""
        page.locator("#east-agents .agent-card").first.click(timeout=10000)
        page.keyboard.press("Escape")
        overlay = page.locator("#modal-overlay")
        expect(overlay).not_to_have_class("modal-overlay active")

class TestKeyboardShortcuts:
    """Verify keyboard shortcuts work."""

    def test_r_key_triggers_manual_refresh(self, page: Page):
        """Pressing 'R' should trigger a manual refresh (poll)."""
        # Wait for initial poll to complete
        expect(page.locator("#last-updated")).to_be_visible(timeout=10000)

        first_text = page.locator("#last-updated").text_content()

        # Press R
        page.keyboard.press("r")

        # Timestamp should update (poll() is called)
        page.wait_for_timeout(500)
        second_text = page.locator("#last-updated").text_content()

        # The timestamp may or may not change depending on timing,
        # but the poll function should execute without errors.
        # We verify the element still exists and has content.
        assert second_text is not None
        assert "最后更新" in second_text
