# web/ —— claude-hero 宣传站（容器化交付）

团队 Claude Code 资产仓库的对外宣传站，作为项目代码的一部分交付。
**Caddy 静态托管，跑在单个 podman 容器里**（不走 compose），本机 `http://localhost:10086/` 对外。

## 目录

```
web/
├── Containerfile        # FROM caddy:2-alpine，COPY public + Caddyfile
├── Caddyfile            # 容器内 :80 file_server /srv
├── run.sh               # 一键：构建镜像 + 替换并启动单容器
├── README.md            # 本文
└── public/              # 静态站点（HTML / css / pages / icons / js）
```

## 构建 & 启动

一键（推荐）：

```bash
cd web
bash run.sh                        # 构建镜像 + 起单容器，:10086
curl -s http://localhost:10086/ | grep '<title>'   # 验证
```

或手动：

```bash
cd web
podman build -t claude-hero-site:latest .
podman run -d --name claude-hero-site --restart unless-stopped -p 10086:80 claude-hero-site:latest
```

常用运维：

```bash
podman ps                          # 看容器状态
podman logs claude-hero-site       # 看日志
podman rm -f claude-hero-site      # 停止并移除
bash run.sh                        # 改完内容后重建重启（内部已先 rm -f 旧容器）
```

> macOS 上 podman 跑在 VM 里，`restart: unless-stopped` 仅在 podman machine 运行时生效；
> 机器重启后需先 `podman machine start`（**未配开机自启**）。

## CSS 版本管理（破缓存，务必遵守）

`public/css/*.css` 的引用必须带 `?v=YYYYMMDD<letter>` 做 cache bust
（如 `tokens.css?v=20260614b`）。**改任何 CSS 后必须递增所有引用它的 HTML 里的版本号**，
否则中间层/浏览器缓存会让用户滞后看到旧样式。Caddyfile 未配 cache-control，全靠 query string 破缓存。

每页 5 个 css 链接：`index.html` = tokens/main/docs/gitlab；其余页 = tokens/main/mechanism/docs。
