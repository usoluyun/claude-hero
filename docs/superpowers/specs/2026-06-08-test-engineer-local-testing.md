# 设计：蜘蛛侠 `hero-java-test-engineer` 本地测试能力重塑 + C-systemic 试点

> 状态：已 brainstorm 评审通过，待转 implementation plan。
> 日期：2026-06-08。
> 基线：`main`（capability-align + security-auditor 已并入）。

## 背景与目标

复盘执行层测试工程师发现两个问题：

1. **skills 够不着**：卡片正文点名要用 `superpowers:test-driven-development` / `gherkin` / `allure` 三个 skill，但 `tools:` 白名单无 `Skill` 工具、也无 `skills:` 字段 → 按已证实机制（见记忆 `subagent-skill-loading-mechanism`），**三个全加载不了**。蜘蛛侠是全队引用 skill 最多、受 C-systemic 影响最重的一例。
2. **测试类型不全 + 容器依赖**：现卡片只有单测/BDD/集成，靠 Testcontainers 起真中间件（需容器运行时）；缺接口测试与 E2E。

**目标**：把蜘蛛侠重塑为**纯本地测试工程师**，四类覆盖 + 报告，并借它**首次落地 `skills:` 预加载字段（C-systemic 试点）**：

| 测试类型 | 工具 | 加载机制 |
|---|---|---|
| 单元 | JUnit5 + Mockito + AssertJ + TDD 方法论 | `skills:` 预加载 `superpowers:test-driven-development` |
| BDD 验收 | Gherkin + Cucumber-JVM | `skills:` 预加载 `gherkin` |
| 接口冒烟 | httpie（`http` 命令） | Bash + `cli/httpie.md` |
| E2E（无头） | Playwright MCP | `tools:` 白名单 + `mcp/` 模板 |
| 报告 | Allure | `skills:` 预加载 `allure` + `cli/allure.md` |

## 决策（已与用户敲定）

1. **纯本地、无容器**：删 Testcontainers/Podman；集成测试改为本地（`@SpringBootTest` + mock / 内存库 H2）。
2. **接口测试 = httpie 冒烟探测**：起服务后 `http` 打 localhost 看响应；可重复的接口断言套件仍走 Java（MockMvc/REST Assured）属 TDD 范畴。
3. **E2E = Playwright MCP（无头）**：agent 直接驱动无头浏览器做端到端；选定 Playwright MCP（微软官方、无头、可访问性树、为 LLM 设计、确定性强）。
4. **skills 预加载**：用 `skills:` 字段预加载 `superpowers:test-driven-development, gherkin, allure`——本仓首次使用，兼作 C-systemic 试点。
5. **tools 白名单本次要动**：加 Playwright MCP 工具（其余 Read/Edit/Write/Grep/Glob/Bash 不变）。

## 设计

### ① 愿景重塑

蜘蛛侠 = **纯本地测试工程师**。覆盖单元（TDD）/ 验收（BDD）/ 接口冒烟（httpie）/ E2E（Playwright MCP 无头）四类 + Allure 报告。不依赖容器运行时。model 保持 sonnet。仍**不改业务实现**（发现问题报 backend/data 修）。

### ② skills 预加载（C-systemic 试点）

frontmatter 加 `skills:` 字段，预加载三个**真实存在且相关**的 skill：

```
skills: superpowers:test-driven-development, gherkin, allure
```

> 这是本仓首次用 `skills:` 字段。实现时**必须实跑验证预加载真生效**（字段格式正确、skill 内容确进上下文、不报错）——这一步同时证明 C-systemic 修法可推广到 tech-lead/backend。若 `skills:` 的字面格式（逗号分隔 vs YAML 列表）与本设计假设不符，以实跑为准修正格式。

### ③ tools 白名单（加 Playwright MCP）

```
tools: Read, Edit, Write, Grep, Glob, Bash, <Playwright MCP 浏览器工具集>
```

- Playwright MCP 工具前缀 `mcp__playwright__`（具体工具名如 `browser_navigate`/`browser_click`/`browser_snapshot`/`browser_type`/`browser_take_screenshot`/`browser_wait_for` 等）。**精确清单实现时从已配置的 server 枚举**（`tools:` 不支持通配，须逐个列）。
- 其余六个工具（Read/Edit/Write/Grep/Glob/Bash）不变；httpie/allure/mvn/gradle 都经 Bash。

### ④ mcp 模板（Playwright MCP）

新增 `mcp/servers/playwright.json` 模板（占位符、无密钥），README「已收录 server」表加一行。形如：

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}
```

> 同 context7：install.sh 以 template 模式处理、不自动写入；每个成员自行合并进 `~/.claude.json` 启用。卡片引用的 MCP 工具**启用后才真可用**。

### ⑤ CLI（httpie + allure）

新增两个 cli 文档 + README 两行：
- `cli/httpie.md`：`http`/`https` 命令做接口冒烟（GET/POST/JSON、看状态码与响应体）。
- `cli/allure.md`：`allure generate` / `allure serve` / `allure open` 生成与查看报告。

### ⑥ 卡片重写要点

- 删 Testcontainers/Podman 相关行；集成测试改"本地（`@SpringBootTest` + mock / 内存库 H2）"。
- 加「接口冒烟」段：先本地起服务（`mvn spring-boot:run` / `java -jar`），再 httpie 打 localhost 探接口。
- 加「E2E（无头）」段：被测 Web 前端+后端本地起着后，用 Playwright MCP 驱动无头浏览器走端到端流程。
- 报告段保留 Allure。
- `## hero 露出` 段（蜘蛛侠 token）**一字不动**。

### ⑦ 矩阵同步

`docs/hero-agent-layers.md` 执行层 test-engineer 行：「应加载 skills」列 = `superpowers:test-driven-development, gherkin, allure`（现在真预加载）；「该用 CLI」列加 `httpie, allure`，E2E 注明 Playwright MCP。加一条注脚说明 skills 经 `skills:` 字段预加载、Playwright MCP 经 tools 白名单。

## 仓库落点

| 动作 | 文件 |
|---|---|
| 卡片重写 + `skills:` + `tools:` | `agents/hero-java-test-engineer.md` |
| 矩阵同步 | `docs/hero-agent-layers.md` |
| MCP 模板 | `mcp/servers/playwright.json` + `mcp/README.md` 一行 |
| CLI 文档 | `cli/httpie.md`、`cli/allure.md` + `cli/README.md` 两行 |
| 防回退测试 | `tests/hero-agent-layers/test_layers.sh` |

## 组件边界

| 单元 | 职责 | 依赖 | 接口 |
|---|---|---|---|
| `agents/hero-java-test-engineer.md` | 四类本地测试 + 报告 | tdd/gherkin/allure skill、httpie/allure CLI、Playwright MCP | 产出测试与报告 |
| `mcp/servers/playwright.json` | Playwright MCP 启用模板 | @playwright/mcp | 成员合并进 ~/.claude.json |
| `cli/httpie.md` / `cli/allure.md` | CLI 用法 | 工具已装 | Bash 参照 |

## 验证（成功标准）

1. **skills 预加载生效（C-systemic 试点核心）**：`skills:` 字段格式正确，实跑一个最小 test-engineer 任务，确认 TDD/gherkin/allure skill 内容确被预加载、不报错。
2. **tools 含 Playwright MCP**：`tools:` 行含 `mcp__playwright__` 前缀的浏览器工具；Read/Edit/Write/Grep/Glob/Bash 仍在。
3. **四类齐 + 无容器**：卡片含单元(TDD)/BDD/接口冒烟(httpie)/E2E(Playwright MCP) 四段；**不再出现 Testcontainers/Podman**。
4. **本地起服务工作法**：卡片写明接口/E2E 前先本地起服务打 localhost。
5. **MCP 模板**：`mcp/servers/playwright.json` 存在（无密钥、`--headless`），README 收录。
6. **CLI 登记**：`cli/httpie.md`/`cli/allure.md` 存在，`cli/README.md` 收录两行。
7. **矩阵对齐 + 露出不破**：矩阵 test 行 skills/CLI 更新；蜘蛛侠 hero 露出行一字未动，visibility/layers 测试全绿。

## 非目标（YAGNI）/ 后续

- 不引入容器集成（Testcontainers/Podman）——纯本地。
- 不做 E2E 可重复套件的 Playwright-Java 代码化（本轮 E2E 走 MCP 驱动；可重复套件后续按需）。
- C-systemic 推广到 tech-lead/backend/data-engineer：**待本试点验证 `skills:` 字段生效后**再单独铺开。
- httpie 不替代 Java 接口断言套件（MockMvc/REST Assured 仍在 TDD 内）。
