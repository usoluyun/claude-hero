---
name: hero-site-deploy
description: 把项目的宣传主页 + 后端程序标准化部署到本机，由一个 Caddy(:10086) 统一对外。触发词：部署主页 / 部署 site / hero 部署 / 部署到本机 / deploy site / 把项目主页挂到本地。每个项目据 README 建宣传页放进 site/（视觉风格向用户确认），claude-hero 是默认页(root /)、其它项目走 /<name>/* 路由，落在 /var/www/hero-sites，Caddy + 后端开机自启。
---

# hero 本机项目主页部署（hero-site-deploy）

**核心价值**：每个项目据 README 建一个宣传主页，连同后端一起标准化部署到本机，一个 Caddy(:10086)
统一对外、开机自启。确定性脏活（建目录/软链/生成配置/起服务）交脚本；判断点（视觉风格、sudo 改系统目录、
写 LaunchAgent/brew services）走人工 gate。

设计依据：`docs/superpowers/specs/2026-06-12-hero-site-deploy-design.md`。

## hero 露出

按 `hero-conventions` 打 `🦸 hero ▸` 标记：
- 激活：`🦸 hero ▸ hero-site-deploy · 建页+部署+验证 / sudo·自启 门控`
- 风格 gate：`🦸 hero ▸ STOP1 风格确认 · 选视觉方向再建页`
- 自启 gate：`🦸 hero ▸ STOP2 自启确认 · 将写 LaunchAgent + brew services`
- 收尾：`🦸 hero ▸ hero-site-deploy 完成 · 已部署，退出 hero 体系`

## 触发词

`部署主页` / `部署 site` / `hero 部署` / `部署到本机` / `deploy site` / `把项目主页挂到本地`

## 部署约定（团队常量，勿改）

| 项 | 值 |
|---|---|
| 部署根 | `/var/www/hero-sites/`（首次需 sudo 建 + chown） |
| 端口 | `:10086` |
| 默认页 | claude-hero（root `/`，无前缀，`default:true`，全局唯一） |
| 其它项目 | 走 `/<name>/*` 路由 |
| master Caddyfile | `/var/www/hero-sites/Caddyfile`，**由脚本从 registry 生成，勿手改** |
| 单一真相源 | `/var/www/hero-sites/registry.json` |
| caddy 二进制 | **有就用**：跑着的 caddy > PATH 上的 caddy > 都没才 `brew install caddy` |
| 合并既有部署 | 首次把既有 `:10086` 块的内层路由原样抽到 `extra.caddy`，master `import` 它——**既有路由 / 默认页零影响**，hero 路由叠加在前 |
| 自启 | caddy：brew 的走 `brew services`，否则 `hero-caddy` LaunchAgent；每个后端走用户级 LaunchAgent |

## 每个项目自带 `site/`

```
<repo>/site/
  public/        # 从 README 构建的宣传主页（static_root 默认指这里）
  site.json      # 部署清单
```

`site/site.json` schema：

```json
{
  "name": "hero-tavern",          // 唯一名 = 软链名 = 路由前缀来源
  "default": false,                // true=默认页(root /，忽略 mount)，全局唯一
  "mount": "/tavern",              // 非默认项目的路由前缀，必填且以 / 开头
  "static_root": "web/static",     // 相对仓库根的静态目录，默认 site/public
  "backends": [                    // 可选：每项=一个反代+一个自启程序
    { "name": "tavern-api", "match": "/api/*", "port": 8000,
      "start": "uv run uvicorn app:app --port 8000" }
  ]
}
```

- backend `match` 是 mount 内的子路径（strip_prefix 后匹配），生成时排在静态 `handle` 之前。
- `start` 用于生成 LaunchAgent；假设运行环境（依赖/解释器）就绪，本 skill 不接管构建。

## 工作流（三阶段，全程门控）

**REQUIRED**：用 TodoWrite 给三阶段建 todo，逐项推进。

### 阶段 A · 建页（按项目，已有页可跳过）

1. 读项目 `README.md`，提炼卖点/特性/安装方式。
2. **STOP1 风格确认**：向用户确认视觉方向，再动手。默认沿用亚朵视觉——若属亚朵品牌页，**必须**用
   `atour-frontend-design` skill；备选极简 / 暗色 / 像素风等由用户选。
3. 生成 `site/public/`（HTML/CSS/资源）+ 写 `site/site.json`。

### 阶段 B · 部署（确定性层 `scripts/hero-deploy.sh`）

脚本子命令（详见 `scripts/hero-deploy.sh` 顶部用法）：

```bash
S=skills/hero-site-deploy/scripts/hero-deploy.sh   # 安装后在 ~/.claude/skills/hero-site-deploy/scripts/

bash "$S" init            # 首次：建 /var/www/hero-sites（sudo）+ registry —— STOP sudo
bash "$S" add <repo>      # 注册项目 + 软链 apps/<name> + 重生成 master（含合并既有 extra.caddy）
bash "$S" autostart       # 探测 caddy(有就用) + 应用合并 master + 后端/caddy 自启 —— STOP 自启
```

门控顺序：
1. `init` —— 首次创建 `/var/www` 需 sudo，**STOP** 让用户知悉/确认（仅首次）。
2. `add <repo>` —— 低风险，只动部署根。首次会从既有活动 Caddyfile 抽出 `:10086` 路由保留到
   `extra.caddy`，master `import` 它（既有部署零影响），再叠加 hero 路由 + 生成 master。
3. `autostart` —— 探测 caddy（跑着的 > PATH > brew install），`caddy validate` 通过后：写后端
   `~/Library/LaunchAgents/hero-*.plist`；caddy 自启按二进制来源分流——brew 的覆盖
   `$(brew --prefix)/etc/Caddyfile`（先备份）+ `brew services restart`，否则写 `hero-caddy` LaunchAgent
   并对运行中实例 `caddy reload`（不停机保留既有路由）。**改系统持久化状态，先列改动项 STOP 确认。**

### 阶段 C · 验证

```bash
bash "$S" verify     # caddy validate（失败不切换/不重启）+ curl 默认页 + 每个 /<mount> 探活
bash "$S" status     # 打印已部署清单 + 访问地址
```

逐条报通断，输出 `http://localhost:10086/...` 访问地址。

## 门控速查

| 动作 | 门控 |
|---|---|
| 视觉风格方向 | 建页前 STOP1 确认 |
| `sudo mkdir/chown /var/www`（首次） | STOP，仅首次 |
| 写 LaunchAgent + `brew services`/`hero-caddy`（持久化系统状态） | STOP，列出改动项再 `autostart` |
| 覆盖 `brew etc/Caddyfile` | 脚本自动先备份 `*.bak.<ts>` |
| 切换/重启/reload caddy | 先 `caddy validate`，失败不执行 |
| 合并既有 Caddyfile | 抽 body 存 `extra.caddy`，**只读源不改源**；既有路由 + 默认页保留 |

## 常见坑

- **Caddyfile 不支持单行 `{…}` 和 `;` 分隔**：每个 `handle`/`reverse_proxy` 块必须多行。脚本已处理，**勿手改生成的 master**。
- **合并保留靠源码顺序**：hero 路由排在 `import extra.caddy` 之前（更具体先匹配），既有的 catch-all 默认页留在最后兜底。所以 **hero 路由别用无 matcher 的 catch-all**，否则会盖掉既有默认页。
- **extra.caddy 只抽一次**：首次从既有活动配置抽取后就固定，之后 `regen` 复用不再重抽。既有部署若有变化、想重新捕获，删掉 `extra.caddy` 再 `regen`。
- **extra 已有顶层默认页时，hero 不再发自己的默认页**（即便 registry 里 claude-hero 是 `default`）——这是"不影响既有部署"的刻意取舍。要让 hero 默认页生效，先清掉 extra 里的旧默认。
- **caddy 有就用**：跑着的非 brew caddy（如 `~/.cargo/bin/caddy`）会被直接复用并 `reload` 到合并配置，不再要求停掉换 brew。
- **static_root 相对仓库根**，不是相对 `site/`。看板类静态在 `web/static` 要显式写。
- **后端 `start` 失败**不影响 caddy 起，但 `/<mount>/api` 会 502。看 `/tmp/hero-<name>.err.log`。

## 幂等

重复部署 = 更新 registry + 重生成 master + 覆盖软链/plist，安全可重入。`registry.json` 是单一真相源；
改了项目 `site.json` 后重跑 `add` 即生效。
