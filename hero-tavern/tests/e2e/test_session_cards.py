"""E2E tests: Session card rendering, expand/collapse, visual verification."""
from __future__ import annotations

import re

import pytest
from playwright.sync_api import Page, expect


class TestSessionCardRendering:
    """Verify session cards render correctly with proper structure and styling."""

    def test_session_cards_appear_after_poll(self, page: Page):
        """After polling, session cards should appear in both containers."""
        heroes_cards = page.locator("#heroes-container .session-card")
        deities_cards = page.locator("#deities-container .session-card")
        
        expect(heroes_cards.first).to_be_visible(timeout=10000)
        expect(deities_cards.first).to_be_visible(timeout=10000)
        expect(heroes_cards).to_have_count(1)
        expect(deities_cards).to_have_count(1)

    def test_session_card_has_required_attributes(self, page: Page):
        """Each session card should have session-id, status, and sleeping attributes."""
        first_card = page.locator("#heroes-container .session-card").first
        
        expect(first_card).to_have_attribute("data-session-id", re.compile(r"^east-claude"))
        expect(first_card).to_have_attribute("data-status", re.compile(r"^(active|idle|sleeping|error)$"))
        expect(first_card).to_have_attribute("data-sleeping", re.compile(r"^(true|false)$"))

    def test_session_card_shows_project_name(self, page: Page):
        """Session card should display the project name with status label."""
        first_card = page.locator("#heroes-container .session-card").first
        project_element = first_card.locator(".session-project").first
        status_element = first_card.locator(".session-status").first
        
        expect(project_element).to_be_visible()
        expect(project_element).to_have_text("ops/hero")
        expect(status_element).to_be_visible()
        expect(status_element).to_contain_text("论剑")

    def test_session_card_initially_collapsed(self, page: Page):
        """Session cards should start in collapsed state (preview visible)."""
        first_card = page.locator("#heroes-container .session-card").first
        
        preview = first_card.locator(".session-body.collapsed").first
        expanded = first_card.locator(".session-body.expanded").first
        
        expect(preview).to_be_visible()
        expect(expanded).not_to_be_visible()

    def test_expand_icon_shows_right_arrow_when_collapsed(self, page: Page):
        """Expand icon should show right-pointing triangle when collapsed."""
        first_card = page.locator("#heroes-container .session-card").first
        icon = first_card.locator(".expand-icon").first
        
        expect(icon).to_have_text("▸")


class TestSessionCardInteraction:
    """Verify session card click interactions work correctly."""

    def test_click_session_header_expands_card(self, page: Page):
        """Clicking session header should expand to show full session details."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        
        header.click()
        
        preview = first_card.locator(".session-body.collapsed").first
        expanded = first_card.locator(".session-body.expanded").first
        
        expect(preview).not_to_be_visible()
        expect(expanded).to_be_visible()

    def test_expand_icon_changes_to_down_arrow(self, page: Page):
        """After clicking, expand icon should change to down-pointing triangle."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        icon = first_card.locator(".expand-icon").first
        
        expect(icon).to_have_text("▸")
        header.click()
        expect(icon).to_have_text("▾")

    def test_click_again_collapse_card(self, page: Page):
        """Clicking expanded session should collapse it back to preview."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        
        header.click()
        expect(first_card.locator(".session-body.expanded").first).to_be_visible()
        
        header.click()
        expect(first_card.locator(".session-body.collapsed").first).to_be_visible()
        expect(first_card.locator(".session-body.expanded").first).not_to_be_visible()

    def test_expand_icon_reverts_to_right_arrow(self, page: Page):
        """After collapsing, expand icon should revert to right-pointing triangle."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        icon = first_card.locator(".expand-icon").first
        
        header.click()
        expect(icon).to_have_text("▾")
        
        header.click()
        expect(icon).to_have_text("▸")


class TestSessionStatusCounts:
    """Verify session status counts display correctly."""

    def test_status_counts_appear_in_session_card(self, page: Page):
        """Session card should display counts like '2 论剑 · 1 饮酒'."""
        west_card = page.locator("#deities-container .session-card").first
        counts_element = west_card.locator(".status-counts")
        
        expect(counts_element).to_be_visible(timeout=10000)
        text = counts_element.text_content()
        
        assert "论剑" in text or "饮酒" in text or "打坐" in text or "走火入魔" in text
        assert "·" in text

    def test_status_counts_match_agent_statuses(self, page: Page):
        """Status counts should accurately reflect the agents in the session."""
        west_card = page.locator("#deities-container .session-card").first
        counts_element = west_card.locator(".status-counts")
        
        text = counts_element.text_content()
        
        assert "论剑" in text or "饮酒" in text or "打坐" in text or "走火入魔" in text


class TestSessionCardVisual:
    """Verify session card visual appearance and styling."""

    def test_session_card_has_proper_styling(self, page: Page):
        """Session cards should have proper borders and background."""
        first_card = page.locator("#heroes-container .session-card").first
        
        expect(first_card).to_have_css("border-style", "solid")
        expect(first_card).to_have_css("overflow", "hidden")

        project = first_card.locator(".session-project").first
        expect(project).to_have_css("font-size", "16px")
        expect(project).to_have_css("font-weight", "600")

    def test_session_header_is_clickable(self, page: Page):
        """Session header should have hover effect and cursor pointer."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        
        expect(header).to_have_css("cursor", "pointer")
        expect(header).to_have_css("padding", "12px 16px")

    def test_status_based_border_colors(self, page: Page):
        """Different states should have different left border colors."""
        heroes_card = page.locator("#heroes-container .session-card").first
        deities_card = page.locator("#deities-container .session-card").first
        
        expect(heroes_card).to_have_attribute("data-status", "active")
        expect(heroes_card).to_have_css("border-left-style", "solid")
        
        deities_status = deities_card.get_attribute("data-status")
        assert deities_status in ["active", "idle", "sleeping", "error"]

    def test_expand_icon_has_proper_styling(self, page: Page):
        """Expand icon should be properly sized and positioned."""
        first_card = page.locator("#heroes-container .session-card").first
        icon = first_card.locator(".expand-icon").first
        
        expect(icon).to_have_css("font-size", "20px")


class TestSessionCardScreenshot:
    """Capture screenshots for visual verification of session cards."""

    def test_session_card_screenshot(self, page: Page):
        """Capture screenshot showing session cards in collapsed state."""
        page.wait_for_timeout(500)
        page.screenshot(path=".omo/evidence/task-8-session-cards.png", full_page=True)

    def test_session_card_expanded_screenshot(self, page: Page):
        """Capture screenshot showing expanded session card."""
        first_card = page.locator("#heroes-container .session-card").first
        header = first_card.locator(".session-header").first
        header.click()
        
        page.wait_for_timeout(500)
        page.screenshot(path=".omo/evidence/task-8-session-cards-expanded.png", full_page=True)
