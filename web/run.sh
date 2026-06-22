#!/usr/bin/env bash
# 构建并直接以单容器方式启动 claude-hero 宣传站（不走 compose）。
# 用法：bash run.sh   —— 重建镜像、替换旧容器、起新容器
set -euo pipefail
cd "$(dirname "$0")"

IMAGE="claude-hero-site:latest"
NAME="claude-hero-site"
PORT="10086"

echo "==> 构建镜像 $IMAGE"
podman build -t "$IMAGE" .

echo "==> 移除旧容器（若有）"
podman rm -f "$NAME" 2>/dev/null || true

echo "==> 启动容器 $NAME（:$PORT）"
podman run -d \
  --name "$NAME" \
  --restart unless-stopped \
  -p "${PORT}:80" \
  "$IMAGE"

echo "==> 就绪：http://localhost:${PORT}/"
podman ps --filter "name=$NAME" --format '{{.Names}}  {{.Status}}  {{.Ports}}'
