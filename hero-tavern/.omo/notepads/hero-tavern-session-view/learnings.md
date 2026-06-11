# Hero Tavern Session View — Implementation Learnings

## T7: 后端 API 实现
- **完成时间**: 2026-06-11
- **关键决策**:
  - 聚合器新增 `get_messages()`, `get_blocked()`, `get_history()` 方法，作为 API 的数据层
  - `main.py` 中添加 `_serialize()` 函数将 dataclass → dict，解决 FastAPI 自动序列化失败的问题
  - `_find_session()` 辅助函数在 `/api/messages` 中提供 404 语义
  - CORS 配置：`allow_credentials=True` 与 `allow_origins=["*"]` 冲突，Starlette 会反射 Origin，测试期望 `*`
  - Python 3.14 + Starlette TestClient 需要额外安装 `httpx2`
- **已知问题**:
  - `/api/history` 的 `total_tokens_out` 为近似值（`tokens // 2`），因为聚合器不区分 token 方向
  - `/api/blocked` 当前仅返回 error 状态的 agent，缺少 `waiting_for_input` 检测
  - 聚合器 `get_messages` 仅基于 agent 元数据生成内容摘要，而非真实历史消息
  - 单元测试通过 mock 绕过 dataclass 序列化问题，真实 API 需要 `_serialize`

## T15: E2E 测试发现修复
- **完成时间**: 2026-06-11
- **根因**: `pytest.ini` 的 `addopts` 中设置了 `--ignore=tests/e2e`，导致 pytest 在运行单元测试时主动跳过所有 E2E 目录
- **修复动作**:
  1. `pytest.ini`: 移除 `--ignore=tests/e2e`
  2. `test_session_cards.py`: 修复 3 处 JS 正则字面量语法错误（`/^east-/` → `r"^east-"`），Python 不支持 `/pattern/` 语法
  3. 使用 `-m "not e2e"` 替代 `--ignore` 来分离运行（但当前测试未标记 e2e marker，后续需加上）
- **验证结果**: `pytest tests/e2e/ --collect-only` 成功发现 **55 个 E2E 测试**（5 个模块，覆盖 API 轮询、交互弹窗、页面加载、CSS、Session 卡片），0 错误
- **发现**: 
  - 测试使用 `pytest-playwright` Python 绑定（非 JS Playwright），依赖 `chromium` 浏览器
  - 浏览器启动由 `pytest-playwright` 插件自动管理，无需手动安装
  - `conftest.py` 已有完整的 mock API 路由和 HTTP server fixture

## T9 & T11: Agent Cards + Sleeping Counter

完成时间: 2026-06-11

- **createAgentCard(agent, variant)** 实现了 mini/full 两种变体
  - 支持 sprite PNG 图片显示（`img/sprites/<sprite_id>.png`）
  - Fallback 机制：图片 404 时自动渲染 CSS pixel sprite
  - 显示内容：name、status (带彩色圆点)、tokens、last_active
  - 点击触发 showAgentModal() 弹窗
- **renderSessions() 重构**：
  - 拆分 sessions 为 activeSessions（有活跃 agent）和 sleepingSessions（所有 agent 都在打坐）
  - Active sessions 分别渲染到 heroes-container 和 deities-container
  - Sleeping sessions 按 source 归组，在每个 wing 底部生成一个 createSleepingCounter() 折叠行
- **Sleeping Counter**：
  - 显示 "N 个 session 在打坐" 文本
  - 可点击展开/折叠隐藏的 session 列表
  - 预渲染所有 sleeping session cards（性能可优化但目前可接受）
- **数据统计**（实时 API 574 sessions）：
  - 活跃：72 sessions（东厢 1 + 西厢 71）
  - 打坐：502 sessions（东厢 1 + 西厢 501）
  - Agent cards：~582 个（包含所有 sessions 中的 agents）
- **Status text 规范**：
  - 纯中文 + 彩色圆点（无 emoji）：论剑 ●、饮酒 ●、打坐 ●、走火入魔 ●
  - status-dot CSS 类名：status-dot-active/idle/sleeping/error
- **Playwright 验证**：
  - 展开 session card 显示 agent cards ✓
  - Sleeping counter click 展开/折叠功能 ✓
  - Sprite PNG 加载 + fallback ✓
  - Agent modal 弹窗 ✓
