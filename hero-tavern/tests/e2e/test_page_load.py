"""E2E tests: page load, pixel CSS, responsive layout, empty/error states."""
from __future__ import annotations

import pytest
from playwright.sync_api import Page, expect


class TestPageLoad:
    """Verify page loads correctly with all key elements."""

    def test_page_title_is_hero_tavern(self, page: Page):
        """Page title should contain 'Hero Tavern'."""
        expect(page).to_have_title("🦸 Hero Tavern — Agent 监控看板")

    def test_header_is_visible(self, page: Page):
        """The tavern header with h1 is visible."""
        header = page.locator(".tavern-header h1")
        expect(header).to_be_visible()
        expect(header).to_contain_text("Hero Tavern")

    def test_three_wings_are_present(self, page: Page):
        """Page should have east, main-hall, and west sections."""
        expect(page.locator(".east-wing")).to_be_visible()
        expect(page.locator(".main-hall")).to_be_visible()
        expect(page.locator(".west-wing")).to_be_visible()

    def test_east_wing_has_correct_title(self, page: Page):
        """East wing heading is '东 厢 · 英 雄'."""
        heading = page.locator(".east-wing h2")
        expect(heading).to_contain_text("东 厢")

    def test_west_wing_has_correct_title(self, page: Page):
        """West wing heading is '西 厢 · 神 祇'."""
        heading = page.locator(".west-wing h2")
        expect(heading).to_contain_text("西 厢")


class TestPixelCSS:
    """Verify the pixel-art CSS is correctly applied."""

    def test_pixelated_image_rendering_is_set(self, page: Page):
        """Body should have pixelated image-rendering for retro style."""
        body = page.locator("body")
        rendering = body.evaluate("el => getComputedStyle(el).imageRendering")
        assert "pixelated" in rendering

    def test_css_variables_are_defined(self, page: Page):
        """Custom CSS variables for wood/ink/paper colors should exist."""
        bg = page.evaluate(
            "() => getComputedStyle(document.documentElement)"
            ".getPropertyValue('--wood-dark').trim()"
        )
        assert bg, "--wood-dark CSS variable should be defined"

    def test_custom_font_is_courier_new(self, page: Page):
        """Page uses Courier New / 宋体 monospace for retro feel."""
        font = page.evaluate(
            "() => getComputedStyle(document.body).fontFamily"
        )
        assert "Courier New" in font or "monospace" in font

    def test_lanterns_are_visible(self, page: Page):
        """The 5 lantern decorations in the header should be visible."""
        lanterns = page.locator(".lantern")
        expect(lanterns).to_have_count(5)

    def test_stats_panel_has_four_stats(self, page: Page):
        """Stats panel should show 4 stat blocks (active/idle/sleeping/error)."""
        stats = page.locator(".stat")
        expect(stats).to_have_count(4)


class TestResponsiveLayout:
    """Verify responsive behavior at mobile width."""

    def test_single_column_layout_at_mobile_width(self, page: Page):
        page.set_viewport_size({"width": 480, "height": 900})
        east_box = page.locator(".east-wing").bounding_box()
        west_box = page.locator(".west-wing").bounding_box()
        assert east_box and west_box
        assert west_box["y"] >= east_box["y"] + east_box["height"] - 1

    def test_mobile_viewport_shows_content(self, page: Page):
        """At 375px (iPhone) all wings should still be visible."""
        page.set_viewport_size({"width": 375, "height": 900})
        expect(page.locator(".east-wing")).to_be_visible()
        expect(page.locator(".main-hall")).to_be_visible()
        expect(page.locator(".west-wing")).to_be_visible()
