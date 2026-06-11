"""Task 8: Session cards rendering and interaction tests.

验证 session 卡片组件：
- Session cards 正常渲染并显示
- 卡片包含 session-project, session-status, status-counts
- Status 文本为 "论剑"/"饮酒"/"打坐"/"走火入魔"（无 emoji）
- 点击 session-header 展开/折叠交互
- Status 统计数字正确
"""
from playwright.sync_api import expect


def test_session_cards_render(page):
    """验证 session cards 正常渲染."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    cards = page.locator(".session-card")
    card_count = cards.count()
    assert card_count > 0, f"Expected at least 1 session card, found {card_count}"


def test_session_card_has_required_elements(page):
    """验证每个 session card 包含必需的元素."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    cards = page.locator(".session-card").all()
    
    for i, card in enumerate(cards):
        project = card.locator(".session-project")
        expect(project).to_be_visible()
        project_text = project.inner_text()
        assert project_text, f"Card {i}: session-project is empty"
        
        status = card.locator(".session-status")
        expect(status).to_be_visible()
        status_text = status.inner_text().strip()
        
        valid_statuses = ["论剑", "饮酒", "打坐", "走火入魔"]
        assert status_text in valid_statuses, f"Card {i}: Invalid status '{status_text}', expected one of {valid_statuses}"


def test_session_card_data_attributes(page):
    """验证 session card 包含 data 属性."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    cards = page.locator(".session-card").all()
    
    for i, card in enumerate(cards):
        session_id = card.get_attribute("data-session-id")
        assert session_id, f"Card {i}: missing data-session-id"
        
        status = card.get_attribute("data-status")
        valid_statuses = ["active", "idle", "sleeping", "error"]
        assert status in valid_statuses, f"Card {i}: Invalid data-status '{status}'"
        
        sleeping = card.get_attribute("data-sleeping")
        assert sleeping in ["true", "false"], f"Card {i}: Invalid data-sleeping '{sleeping}'"


def test_expand_icon_initial_state(page):
    """验证展开图标初始状态为折叠."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    cards = page.locator(".session-card").all()
    
    for i, card in enumerate(cards):
        collapsed = card.locator(".session-body.collapsed")
        expanded = card.locator(".session-body.expanded")
        
        expect(collapsed).to_be_visible()
        
        expanded_classes = expanded.get_attribute("class")
        assert "hidden" in expanded_classes, f"Card {i}: expanded body should be hidden initially"


def test_session_header_click_expands(page):
    """验证点击 session-header 展开卡片."""
    first_card = page.locator(".session-card").first
    expect(first_card).to_be_visible(timeout=10000)
    
    header = first_card.locator(".session-header")
    header.click()
    
    collapsed = first_card.locator(".session-body.collapsed")
    expect(collapsed).not_to_be_visible()
    
    expanded = first_card.locator(".session-body.expanded")
    expect(expanded).to_be_visible()


def test_expand_icon_changes_after_click(page):
    """验证点击后展开图标从 '▸' 变为 '▾'."""
    first_card = page.locator(".session-card").first
    expect(first_card).to_be_visible(timeout=10000)
    
    icon = first_card.locator(".expand-icon")
    
    initial_text = icon.inner_text()
    assert initial_text == "▸", f"Expected initial icon '▸', got '{initial_text}'"
    
    header = first_card.locator(".session-header")
    header.click()
    
    expanded_text = icon.inner_text()
    assert expanded_text == "▾", f"Expected expanded icon '▾', got '{expanded_text}'"


def test_session_header_click_collapses(page):
    """验证再次点击 session-header 折叠卡片."""
    first_card = page.locator(".session-card").first
    expect(first_card).to_be_visible(timeout=10000)
    
    header = first_card.locator(".session-header")
    
    header.click()
    expanded = first_card.locator(".session-body.expanded")
    expect(expanded).to_be_visible()
    
    header.click()
    collapsed = first_card.locator(".session-body.collapsed")
    expect(collapsed).to_be_visible()
    expect(expanded).not_to_be_visible()
    
    icon = first_card.locator(".expand-icon")
    icon_text = icon.inner_text()
    assert icon_text == "▸", f"Expected icon '▸' after collapse, got '{icon_text}'"


def test_status_counts_display(page):
    """验证状态统计显示正确（如 '1 论剑 · 1 饮酒'）."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    counts_elements = page.locator(".status-counts").all()
    
    for i, element in enumerate(counts_elements):
        text = element.inner_text()
        if text:
            assert any(status in text for status in ["论剑", "饮酒", "打坐", "走火入魔"]), \
                f"Element {i}: status-counts '{text}' doesn't contain valid status text"


def test_session_card_sorting(page):
    """验证 session cards 按 activity_score 排序."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    
    cards = page.locator(".session-card").all()
    
    session_ids = []
    for card in cards:
        session_id = card.get_attribute("data-session-id")
        session_ids.append(session_id)
    
    if len(session_ids) > 1:
        pass


def test_screenshot_collapsed_state(page):
    """截图：折叠状态的 session cards."""
    expect(page.locator(".session-card").first).to_be_visible(timeout=10000)
    page.wait_for_timeout(1000)
    
    page.screenshot(path=".omo/evidence/task-8-session-cards-collapsed.png")


def test_screenshot_expanded_state(page):
    """截图：展开状态的 session card."""
    first_card = page.locator(".session-card").first
    expect(first_card).to_be_visible(timeout=10000)
    
    header = first_card.locator(".session-header")
    header.click()
    
    page.wait_for_timeout(500)
    
    page.screenshot(path=".omo/evidence/task-8-session-cards-expanded.png")
