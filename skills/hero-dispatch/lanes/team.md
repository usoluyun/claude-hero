---
lane: team
archetype: setup
intent_keywords: [组队, team, 组队, 分屏, spawn, 多位 Hero, 团队作战]
required_input: (可选) 用户想要哪些角色参加
---

# team lane（Agent Teams 组队启动 · setup）

## hero 露出

按 `hero-conventions` 露出规范，本 lane 运作时打 `🦸 hero ▸` 标记：
- 进入：`🦸 hero ▸ team lane · Agent Teams 组队启动`
- 收尾：`🦸 hero ▸ team lane 完成 · 准备就绪，请切到目标 tmux pane 执行 claude`
- 退出：`🦸 hero ▸ team lane 退出 · 已交付启动指引`

## 触发画像

用户想**多位 Hero 在 tmux 分屏里并行协作**（孔明/文远/希仁 等同时推进）。本 lane 不改代码，只负责启动准备与环境自检。

## 复用

无 superpowers skill 依赖。

## 启动准备流程

1. **环境自检**
   - 检查 tmux 二进制：`command -v tmux &>/dev/null`
   - 若未装：提示用户 `brew install tmux`（macOS）或对应包管理器
   - 检查 `~/.claude/settings.json` 是否存在且包含:
     - `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`（env 字段）
     - `"teammateMode": "tmux"`
   - 若配置缺失：STOP，打印模板提示用户合并 `config/settings.json.example`

2. **确认组队意图**
   - 若用户未指明角色（只说"组队"），默认推荐：孔明（opus）+ 文远（sonnet）+ 希仁（sonnet）
   - 若用户指明了特定角色，按用户选择
   - STOP 确认最终角色列表

3. **生成启动指引**
   - 输出 tmux 启动命令（两步）：
     ```bash
     # 步骤 1：创建分屏会话
     tmux new -s work

     # 步骤 2：在每个 pane 里分别启动对应角色的 claude
     claude --agent hero-java-tech-lead
     claude --agent hero-java-backend-developer
     claude --agent hero-java-test-engineer
     ```
   - 提示：按 `Ctrl-b + %` / `Ctrl-b + "` 切分 tmux pane（水平/垂直），在每个 pane 用方向键切到目标 pane 后启动对应 `claude --agent ...`
   - 提示：用 `tmux list-panes` 查看当前 pane 列表

## 交接产物

启动指引 + 命令清单（markdown，可直接复制执行）。

## 退出

打印完指引后退场，不进入具体编码任务；用户按指引在 tmux 里各自启动。
