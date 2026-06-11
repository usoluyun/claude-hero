# 🦸 Hero Tavern — Agent 监控看板

仙剑客栈风格的像素艺术监控看板，实时展示 Claude Code (hero) 和 OpenCode (omo) agent 状态。

## 功能特性

- 🎮 复古仙剑 DOS 风格像素界面
- ⚔️ 东西两厢分区（英雄 vs 神祇）
- 🔄 5 秒自动轮询刷新
- 📊 实时统计（活跃/空闲/休眠/异常）
- 📜 消息流 + 阻塞检测
- ⌨️ 快捷键（R 刷新 / ? 帮助 / Esc 关闭）
- 🖱️ 点击角色查看详情

## 前置条件

- Python 3.11+
- pip

## 安装

```bash
cd hero-tavern
pip install -r requirements.txt
```

## 配置

复制 `.env.example` 为 `.env` 并修改：

```bash
cp .env.example .env
# 编辑 .env 设置你的路径
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| CLAUDE_LOGS_PATH | ~/.claude/projects | Claude Code JSONL 日志目录 |
| OPENCODE_DB_PATH | ~/.opencode/opencode.db | OpenCode SQLite 数据库路径 |
| IDLE_THRESHOLD | 300 | 空闲判定秒数 |
| SLEEP_THRESHOLD | 3600 | 休眠判定秒数 |
| API_PORT | 8000 | API 服务端口 |

## 使用

### 方式一：一键启动

```bash
bash deploy.sh
```

### 方式二：手动启动

```bash
# 终端 1：启动后端 API
cd hero-tavern
python3 -m uvicorn src.api.main:app --port 8000

# 终端 2：启动前端
cd hero-tavern/web/static
python3 -m http.server 3000
```

然后在浏览器打开 http://localhost:3000

## API 文档

启动后端后访问 http://localhost:8000/docs 查看交互式 API 文档。

### 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/health | 健康检查 |
| GET | /api/status | 获取所有 agent 状态 |
| GET | /api/history | 24 小时统计 |
| GET | /api/messages?limit=20 | 最近消息 |
| GET | /api/blocked | 阻塞的 agent 列表 |

## 开发

```bash
# 运行测试
pip install -r requirements.txt
python3 -m pytest tests/ -v

# 带覆盖率
python3 -m pytest tests/ --cov=src --cov-report=html
```

## 技术栈

- **后端**: FastAPI + SQLite (WAL mode)
- **前端**: 纯 HTML/CSS/JS（无框架）
- **视觉**: CSS Grid 像素艺术（16×16，无外部资源）
- **测试**: pytest (76 tests, 90% coverage)

## 架构

```
hero-tavern/
├── src/
│   ├── parsers/
│   │   ├── claude_parser.py     # JSONL 流式解析
│   │   └── opencode_parser.py   # SQLite 查询
│   ├── aggregator/
│   │   └── aggregator.py        # 数据聚合 + 状态推断
│   └── api/
│       └── main.py              # FastAPI 端点
├── tests/                       # pytest 测试
└── web/static/
    ├── index.html               # 页面结构
    ├── css/
    │   ├── tavern.css           # 像素风场景
    │   ├── characters.css       # 角色卡 + 动画
    │   └── sprites.css          # 16×16 像素精灵
    └── js/
        └── tavern.js            # 前端逻辑 + 轮询
```

## License

MIT
