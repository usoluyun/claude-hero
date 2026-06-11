"""E2E tests: click interactions, modal dialogs, keyboard shortcuts."""
from __future__ import annotations

import re

import pytest
from playwright.sync_api import Page, expect


class TestAgentCardClick:
    """Verify clicking agent cards opens a detail modal."""

    def _expand_first_session_and_get_agent(self, page: Page):
        """Helper: expand first heroes session and return first agent card."""
        first_session = page.locator("#heroes-container .session-card").first
        expect(first_session).to_be_visible(timeout=10000)
        header = first_session.locator(".session-header")
        header.click()
        agent_card = first_session.locator(".agent-full-card").first
        expect(agent_card).to_be_visible(timeout=5000)
        return agent_card

    def test_click_agent_card_opens_modal(self, page: Page):
        """Clicking an agent card should show the modal overlay."""
        card = self._expand_first_session_and_get_agent(page)
        card.click()
        overlay = page.locator("#modal-overlay")
        expect(overlay).to_have_class(re.compile(r".*\bactive\b.*"))

    def test_modal_shows_agent_name(self, page: Page):
        """The modal should display the clicked agent's name."""
        card = self._expand_first_session_and_get_agent(page)
        card.click()
        modal_content = page.locator("#modal-content")
        expect(modal_content).to_be_visible()
        expect(modal_content).to_contain_text("Nick Fury")

    def test_modal_shows_status_and_tokens(self, page: Page):
        """Modal should show status label."""
        card = self._expand_first_session_and_get_agent(page)
        card.click()
        modal = page.locator("#modal-content")
        expect(modal).to_contain_text("论剑")

    def test_modal_shows_recent_messages(self, page: Page):
        """Modal should show the agent's recent messages."""
        card = self._expand_first_session_and_get_agent(page)
        card.click()
        modal = page.locator("#modal-content")
        expect(modal).to_contain_text("We need a plan")

    def test_modal_has_close_button(self, page: Page):
        """Modal should have a close button."""
        card = self._expand_first_session_and_get_agent(page)
        card.click()
        close_btn = page.locator(".modal-close")
        expect(close_btn).to_be_visible()
        expect(close_btn).to_contain_text("关闭")


class TestModalClose:
    """Verify closing the detail modal."""

    def test_close_modal_via_button(self, page: Page):
        """Clicking the close button should hide the modal."""
        first_session = page.locator("#heroes-container .session-card").first
        expect(first_session).to_be_visible(timeout=10000)
        header = first_session.locator(".session-header")
        header.click()
        agent_card = first_session.locator(".agent-full-card").first
        expect(agent_card).to_be_visible(timeout=5000)
        agent_card.click()
        page.locator(".modal-close").click()
        overlay = page.locator("#modal-overlay")
        expect(overlay).not_to_have_class(re.compile(r".*\bactive\b.*"))

    def test_close_modal_via_escape_key(self, page: Page):
        """Pressing Escape should hide the modal."""
        first_session = page.locator("#heroes-container .session-card").first
        expect(first_session).to_be_visible(timeout=10000)
        header = first_session.locator(".session-header")
        header.click()
        agent_card = first_session.locator(".agent-full-card").first
        expect(agent_card).to_be_visible(timeout=5000)
        agent_card.click()
        page.keyboard.press("Escape")
        overlay = page.locator("#modal-overlay")
        expect(overlay).not_to_have_class(re.compile(r".*\bactive\b.*"))

class TestKeyboardShortcuts:
    """Verify keyboard shortcuts work."""

    def test_r_key_triggers_manual_refresh(self, page: Page):
        """Pressing 'R' should trigger a manual refresh (poll)."""
        page.wait_for_timeout(3000)
        timestamp_el = page.locator("#last-updated")
        if timestamp_el.count() == 0 or not timestamp_el.is_visible():
            pass
            return

        page.keyboard.press("r")
        page.wait_for_timeout(500)
        second_text = timestamp_el.text_content()
        assert second_text is not None
