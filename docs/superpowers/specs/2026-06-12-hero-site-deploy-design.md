# 设计：`hero-site-deploy` 本机项目主页部署

## 背景与目标

团队每个项目都可以根据 `README.md` 构建一个宣传性的**项目主页**，连同后端程序一起部署到
**本机**，用一个 Caddy 统一对外。当前 claude-hero 仓库已有 `site/`（亚朵视觉宣传页）与 hero-tavern
（英雄看板，像素风 + `:8000` API），现有 `site/Caddyfile` 监听 `:10086`、`/tavern/*` 路由到看板、
默认 `handle` 指向主页——但路径写得不一致（`…/poc/…` vs `…/ops/…`）、靠手工维护、无开机自启。

**目标**：建一个 `hero-site-deploy` skill，指导 agent 把"类似 claude-hero 的项目主页 + 程序"标准化部署到本机：

- 每个项目据 README 构建宣传主页放进 `site/`，**视觉风格向用户确认**。
- 本机起一个 Caddy（默认 `:10086`），claude-hero 是**默认页**（root `/`，无前缀），其它项目走 `/<name>/*` 路由。
- 部署落到**标准系统目录** `/var/www/hero-sites/`，Caddy 从这里挂载。
- Caddy 与相关后端程序**开机自启**。

### 核心约束：两段式（确定性层 vs 人工 gate）

沿用 hero 体系惯例——确定性脏活（建目录、软链、生成配置、起服务）交脚本；判断点（视觉风格、
sudo 改系统目录、写 LaunchAgent/brew services 这类持久化系统状态）走人工确认 gate。

## 决策（已与用户敲定）

| 决策点 | 选定 |
|---|---|
| 部署根目录 | `/var/www/hero-sites/`（标准系统目录，首次需 sudo 建并 chown 给当前用户） |
| master Caddyfile 组装 | **注册表驱动生成**：从 `registry.json` 整体生成 master，claude-hero 默认 `handle` 永远拼最后 |
| 开机自启 | **brew services**（Caddy）+ **用户级 LaunchAgent**（每个后端程序），均无需 root |
| skill 范围 | **建页 + 部署 + 验证全流程**（三阶段） |
| 每项目路由真相源 | **`site/site.json` 清单**（可移植，不把绝对路径泄进项目仓库；master 由 skill 从清单生成） |
| 默认端口 | `:10086` |

## 架构

### ① 部署根布局（团队常量 `/var/www/hero-sites/`）

```
/var/www/hero-sites/
  Caddyfile            # master，:10086，【由 skill 生成，勿手改】
  apps/
    claude-hero -> <claude-hero repo>   # default: true，root /
    projB       -> <projB repo>          # mount /projB
  registry.json        # 已部署项目清单【单一真相源】
```

- `apps/<name>` 是指向项目仓库根的软链，保证 Caddy 的 root 是稳定绝对路径。
- `/opt/homebrew/etc/Caddyfile` 软链 → 本 master，使 `brew services` 拉起的 caddy 用它。

### ② 每项目自带（项目仓库内 `site/`）

```
<repo>/site/
  public/        # 从 README 构建的宣传主页（HTML/CSS/资源）；static_root 可指向别处（如看板 web/static）
  site.json      # 部署清单
```

`site/site.json` schema：

```json
{
  "name": "hero-tavern",
  "default": false,
  "mount": "/tavern",
  "static_root": "web/static",
  "backends": [
    { "name": "tavern-api", "match": "/api/*", "port": 8000, "start": "uv run uvicorn app:app --port 8000" }
  ]
}
```

字段说明：
- `name`：唯一名，= `apps/<name>` 软链名 = 路由前缀来源。
- `default`：true 表示默认页（root `/`，忽略 `mount`）；全局**有且仅一个** default（claude-hero）。
- `mount`：非默认项目的路由前缀，如 `/tavern`。
- `static_root`：相对项目仓库根的静态目录（默认 `site/public`）。
- `backends[]`：可选。每项一个反代 + 一个自启程序；`match` 是该 mount 下的子路径匹配，`port` 反代目标，`start` 启动命令（用于生成 LaunchAgent）。

### ③ master Caddyfile 生成规则（确定性）

遍历 `registry.json`：

```caddyfile
:10086 {
    # —— 非默认项目（有 mount 的，逐个 handle，顺序无所谓，互斥）——
    handle /tavern/* {
        uri strip_prefix /tavern
        handle /api/* { reverse_proxy 127.0.0.1:8000 }   # 来自 backends，先于静态
        handle { root * /var/www/hero-sites/apps/hero-tavern/web/static; file_server }
    }
    # —— 默认页永远最后（catch-all，无 matcher）——
    handle {
        root * /var/www/hero-sites/apps/claude-hero/site/public
        file_server
    }
}
```

- backend 的 `handle /api/*` 必须排在该 mount 内静态 `handle` 之前（顺序敏感）。
- 默认页 `handle` 无 matcher，必须是整个 site block 的最后一个。
- root 用部署根下的绝对路径（经 `apps/<name>` 软链），与项目仓库实际位置解耦。

### ④ 开机自启（用户级，无需 root）

- **Caddy**：`/opt/homebrew/etc/Caddyfile` 软链 → master（已存在先备份 `*.bak.<ts>`），`brew services restart caddy`。brew services 即为开机自启。
- **后端程序**：每个 `backends[].start` 生成 `~/Library/LaunchAgents/hero-<backend-name>.plist`（`RunAtLoad=true`、`KeepAlive=true`、`WorkingDirectory` = 项目仓库），`launchctl bootstrap`/`load`。

### ⑤ 工作流（三阶段）

**阶段 A · 建页**（按项目，可跳过已有页）
1. 读项目 `README.md` 提炼卖点。
2. **STOP 风格确认 gate**：向用户确认视觉方向（默认沿用亚朵视觉，复用 `atour-frontend-design`；备选极简/暗色/像素风等）。
3. 生成 `site/public/` 主页 + 写 `site/site.json`。

**阶段 B · 部署**（确定性层 `scripts/hero-deploy.sh`）
1. 确保部署根：首次 `sudo mkdir -p /var/www/hero-sites && sudo chown $USER` —— **STOP sudo gate**。
2. 软链 `apps/<name>` → 项目仓库根。
3. upsert `registry.json`（读 `site.json` 写入）。
4. 重新生成 master Caddyfile（规则见 ③）。
5. 软链 `/opt/homebrew/etc/Caddyfile` → master（已存在先备份）。
6. 每个 backend 生成 LaunchAgent 并 load —— **STOP 自启 gate**（列出将写的 plist + brew services 改动，确认后执行）。
7. `brew services restart caddy`。

**阶段 C · 验证**
1. `caddy validate --config /var/www/hero-sites/Caddyfile`（先校验，失败不切换/不重启）。
2. `curl` 默认页 + 每个 `/<mount>` + 每个 backend `/api`，逐条报通断。
3. 输出已部署清单 + 访问地址（`http://localhost:10086/...`）。

### ⑥ 门控与安全（mutate 纪律）

| 动作 | 门控 |
|---|---|
| 视觉风格方向 | 建页前 STOP 确认 |
| `sudo mkdir/chown /var/www`（首次） | STOP 确认，仅首次 |
| 写 LaunchAgent + `brew services`（持久化系统状态） | 部署前列出改动项，STOP 确认 |
| 覆盖 `/opt/homebrew/etc/Caddyfile` | 先备份 `*.bak.<ts>` |
| 切换/重启 caddy | 先 `caddy validate`，失败不执行 |

## 组件边界（各单元一个职责）

- **`SKILL.md`**：触发词、露出、三阶段工作流、门控、`site.json` schema、约定速查。语义判断（建页风格、确认）在此。
- **`scripts/hero-deploy.sh`**：确定性层。子命令 `init`（建部署根）/ `add <repo>`（注册+软链+生成+自启）/ `regen`（仅重生成 master）/ `verify`（curl 检查）/ `status`（读 registry）。无 LLM 判断。
- **`templates/`**：master Caddyfile 片段模板、LaunchAgent plist 模板。
- **`registry.json`**：单一真相源，记 name/default/mount/static_root/backends + last_deployed。

## hero 露出（按 `hero-conventions`）

- 激活：`🦸 hero ▸ hero-site-deploy · 建页+部署+验证 / sudo·自启 门控`
- 风格 gate：`🦸 hero ▸ STOP1 风格确认 · 选视觉方向再建页`
- 部署 gate：`🦸 hero ▸ STOP2 自启确认 · 将写 LaunchAgent + brew services`
- 收尾：`🦸 hero ▸ hero-site-deploy 完成 · 已部署，退出 hero 体系`

## 验证（成功标准）

1. 对 claude-hero 跑一次：`/var/www/hero-sites/` 建好、`apps/claude-hero` 软链、master 生成、`registry.json` 有记录。
2. `caddy validate` 通过；`brew services list` 显示 caddy started。
3. `curl localhost:10086/` 返回主页；`curl localhost:10086/tavern/` 返回看板；`curl localhost:10086/tavern/api/...` 反代到 `:8000`。
4. 重启本机后（或 `launchctl`/brew services 复查）caddy + tavern 后端自启在跑。
5. 再 `add` 第二个项目后，master 重生成且默认页仍在最后，两个路由都通。

## 非目标（YAGNI）

- 不做远程/容器部署（podman 另有 `podman-deploy` skill）。
- 不做 HTTPS/域名（本机 `:10086` HTTP 即可）。
- 不做多端口/多 Caddy 实例。
- 不接管项目后端的构建/依赖安装（`start` 命令由项目自带，假设环境就绪）。
- 不自动改项目仓库 README。

## 未来增强（不在本期）

- `hero-refresh` 联动：代码漂移后自动重生成主页/重部署。
- 部署根可配置（环境变量覆盖 `/var/www/hero-sites`）。
- 健康检查 + 自动回滚到上一个 master 备份。
