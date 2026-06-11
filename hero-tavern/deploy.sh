#!/bin/bash
# Hero Tavern — One-command deployment
set -e

echo "🦸 Hero Tavern — 启动中..."

# Check prerequisites
if ! command -v python3 &> /dev/null; then
    echo "❌ 需要 Python 3.11+"; exit 1
fi

# Get script directory
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Install dependencies
echo "📦 安装依赖..."
pip install -q -r requirements.txt

# Load env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

API_PORT=${API_PORT:-8000}
FRONTEND_PORT=${FRONTEND_PORT:-3000}

# Start backend
echo "⚙️  启动后端 API (port $API_PORT)..."
python3 -m uvicorn src.api.main:app --host 127.0.0.1 --port "$API_PORT" &
BACKEND_PID=$!

# Wait for backend
echo "⏳ 等待后端就绪..."
for i in $(seq 1 15); do
    if curl -s "http://127.0.0.1:$API_PORT/api/health" > /dev/null 2>&1; then
        echo "✅ 后端就绪"
        break
    fi
    sleep 1
done

# Start frontend
echo "🎨 启动前端 (port $FRONTEND_PORT)..."
cd web/static
python3 -m http.server "$FRONTEND_PORT" &
FRONTEND_PID=$!

echo "🏮 Hero Tavern 已启动！"
echo "   前端: http://localhost:$FRONTEND_PORT"
echo "   API:  http://localhost:$API_PORT/docs"
echo ""
echo "按 Ctrl+C 停止"

# Trap cleanup
cleanup() {
    echo ""
    echo "🛑 停止服务..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

wait
