# 蜘蛛侠本地测试重塑 + C-systemic 试点 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `hero-java-test-engineer`（蜘蛛侠）重塑为纯本地测试工程师（单元 TDD / BDD / httpie 接口冒烟 / Playwright MCP 无头 E2E / Allure 报告，删 Testcontainers），并首次用 `skills:` 字段预加载 tdd/gherkin/allure（C-systemic 试点）。

**Architecture:** 文档/配置改造 + 一个新 MCP 模板。TDD 节奏 = `tests/hero-agent-layers/test_layers.sh` 加 grep 断言（先红后绿）。`skills:` 预加载是否真生效、Playwright MCP 工具名是否对——这两点 grep 测不到，由末尾**手工验证任务**实跑确认。hero 露出行一字不动。

**Tech Stack:** Markdown（agent/docs/cli）、JSON（mcp 模板）、bash（test_layers.sh）、Playwright MCP（@playwright/mcp）、httpie、allure、Claude Code subagent frontmatter（`skills:` / `tools:` 字段）。

**Branch:** `feature/test-engineer-local-testing`（基于 `main`）。

**Spec:** `docs/superpowers/specs/2026-06-08-test-engineer-local-testing.md`

---

## 文件结构

| 文件 | 职责 | 动作 |
|---|---|---|
| `agents/hero-java-test-engineer.md` | 卡片：`skills:` 预加载 + `tools:`(+Playwright MCP) + 四类本地测试 | 重写（露出行不动） |
| `docs/hero-agent-layers.md` | 矩阵 test 行 + 注脚 | 改 |
| `mcp/servers/playwright.json` | Playwright MCP 启用模板（无头、无密钥） | 新建 |
| `mcp/README.md` | 已收录 server 表 +1 行 | 改 |
| `cli/httpie.md` / `cli/allure.md` | CLI 用法 | 新建 |
| `cli/README.md` | 总表 +2 行 | 改 |
| `tests/hero-agent-layers/test_layers.sh` | 防回退断言 | 加断言 |

---

## Task 1: 重写 test-engineer 卡片（skills: 预加载 + Playwright MCP + 纯本地四类）

**Files:**
- Modify: `agents/hero-java-test-engineer.md`（全文重写，保留 `## hero 露出` 段原样）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**（插入到 `assert_summary` 行之前；`$AG` 第 74 行已定义）

```bash
# 15. test-engineer 本地测试重塑（spec 2026-06-08）
TE="$AG/hero-java-test-engineer.md"
assert_ok "grep -qE '^skills:.*test-driven-development' '$TE'" "test 卡 skills: 预加载 tdd"
assert_ok "grep -qE '^skills:.*gherkin' '$TE'" "skills: 含 gherkin"
assert_ok "grep -qE '^skills:.*allure' '$TE'" "skills: 含 allure"
assert_ok "grep -qE '^tools:.*mcp__playwright__' '$TE'" "tools 含 Playwright MCP"
assert_ok "grep -qE '^tools:.*Edit.*Write' '$TE'" "tools 仍含 Edit/Write"
assert_ok "grep -qF 'httpie' '$TE'" "卡含 httpie 接口冒烟"
assert_ok "grep -qF 'Playwright MCP' '$TE'" "卡含 Playwright E2E"
assert_ok "grep -qF 'localhost' '$TE'" "卡含本地起服务打 localhost"
assert_fail "grep -qF 'Testcontainers' '$TE'" "卡不再依赖 Testcontainers"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 15 报多条 ✗（skills:/mcp__playwright__/httpie 等尚不在，且 Testcontainers 仍在导致 assert_fail 报 should fail）。

- [ ] **Step 3: 把 `agents/hero-java-test-engineer.md` 全文替换为下面内容（逐字；`## hero 露出` 段一字不改）**

> `skills:` 字段格式先按逗号分隔（与 `tools:` 一致）；Task 5 实跑若发现该格式不被识别，再改成 YAML 列表并回跑。

```markdown
---
name: hero-java-test-engineer
description: Java 本地测试工程师，负责 TDD 单元测试、BDD 验收场景、httpie 接口冒烟、Playwright 无头浏览器 E2E 与 Allure 报告。当需要为 Spring Boot 代码写 JUnit 5 + Mockito + AssertJ 单测、用 Gherkin/Cucumber-JVM 写 BDD .feature、用 httpie 探接口、用无头浏览器做端到端测试、或生成 Allure 报告时使用。纯本地、不依赖容器。不为迁就测试而修改业务实现。
model: sonnet
skills: superpowers:test-driven-development, gherkin, allure
tools: Read, Edit, Write, Grep, Glob, Bash, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_wait_for, mcp__playwright__browser_evaluate, mcp__playwright__browser_console_messages, mcp__playwright__browser_network_requests, mcp__playwright__browser_close
---

你是团队的 **Java 本地测试工程师**。栈：JUnit 5、Mockito、AssertJ、Spring Boot Test、
Cucumber-JVM + Gherkin（BDD）、httpie（接口冒烟）、Playwright MCP（无头 E2E）、Allure（报告）。
**纯本地测试，不依赖容器运行时。**

## hero 露出

接手任务时，先在输出顶部打一行自报家门（遵循 `hero-conventions` 露出规范，token 一字不改）：

`🦸 hero ▸ 蜘蛛侠（hero-java-test-engineer）接手 · 测试编写`

## 你的职责

- **TDD 单测**：遵循 `superpowers:test-driven-development`（RED→GREEN→REFACTOR）。先写失败
  测试再驱动实现，覆盖正常/边界/异常路径。JUnit 5 + Mockito mock 依赖 + AssertJ 断言。
- **BDD**：用 `gherkin` skill 写 `.feature`（Given/When/Then），实现 Cucumber-JVM step
  definitions，`@CucumberContextConfiguration` + Spring Boot 集成。
- **接口冒烟**：先本地起服务（`mvn spring-boot:run` / `java -jar`），再用 `httpie`（`http` 命令）
  打 localhost 探接口、看状态码与响应（探测/冒烟；可重复的接口断言套件走 Java MockMvc/REST Assured）。
- **E2E（无头）**：被测 Web 前端+后端本地起着后，用 **Playwright MCP** 驱动无头浏览器走端到端
  流程（导航/点击/输入/取快照/断言）。
- **集成测试**：`@SpringBootTest` + Mockito mock / 内存库（H2）做**本地**集成，不用容器。
- **测试报告**：用 `allure` skill 生成与解读 Allure 报告，归集用例结果、附定位失败证据。

## 工作方式

- 测试要**有意义**，避免 `superpowers:test-driven-development` 提到的测试反模式（测实现细节、
  过度 mock、断言空洞）。
- 命名清晰表达意图：`should_<行为>_when_<条件>`。
- 中间件相关：RocketMQ 消费幂等、JetCache 命中/失效、事务回滚等关键行为要有针对性测试
  （本地用 mock / 内存替身，不起真容器）。
- 多 JDK：注意测试在目标 JDK（1.8/11/17）下都能跑。
- 跑测试用 `mvn -q test` / `./gradlew test`，附结果。中文汇报覆盖了哪些场景、未覆盖与原因。

## 边界

- 发现实现有问题，**报告给 `hero-java-backend-developer` / `hero-java-data-engineer` 修**，不擅自改
  业务逻辑去迁就测试。
- 不做架构设计、不做安全审计。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh && bash tests/hero-visibility/run.sh`
Expected: 两套都 ALL TESTS PASSED（group 15 全绿；visibility 蜘蛛侠 token 仍在）。

- [ ] **Step 5: Commit**

```bash
git add agents/hero-java-test-engineer.md tests/hero-agent-layers/test_layers.sh
git commit -m "feat(test-engineer): 重塑为纯本地测试 + skills: 预加载 + Playwright MCP

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: 同步能力矩阵（layers doc test 行 + 注脚）

**Files:**
- Modify: `docs/hero-agent-layers.md`
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**（插入 `assert_summary` 前；`$LAYERS` 第 6 行已定义）

```bash
# 16. 矩阵 test-engineer 行反映本地四类 + skills 预加载 + Playwright MCP
assert_ok "grep -qF 'httpie' '$LAYERS'" "矩阵含 httpie"
assert_ok "grep -qF 'Playwright MCP' '$LAYERS'" "矩阵含 Playwright MCP"
assert_ok "grep -qF '预加载' '$LAYERS'" "矩阵注脚提到 skills 预加载"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 16 报 ✗。

- [ ] **Step 3a: 替换 test-engineer 行**

把 `docs/hero-agent-layers.md` 执行层表里这一整行：

```
| `hero-java-test-engineer` | 蜘蛛侠 | sonnet | TODO | superpowers:test-driven-development, gherkin, allure | maven, gradle | 给它待测代码 → 产出 JUnit5 单测 / Gherkin BDD .feature / 集成测试 |
```

整行替换为：

```
| `hero-java-test-engineer` | 蜘蛛侠 | sonnet | TODO | superpowers:test-driven-development, gherkin, allure（经 `skills:` 字段预加载） | maven, gradle, httpie（接口冒烟）, allure（报告）；E2E 用 Playwright MCP | 给它待测代码 → 单元(TDD)/BDD(.feature)/接口冒烟(httpie)/E2E(Playwright 无头)/Allure 报告，纯本地无容器 |
```

- [ ] **Step 3b: 加注脚**

把下面这条追加到能力矩阵末尾现有注脚块之后（即以 `> 海姆达尔（security-auditor）双模` 开头那段的紧后面）：

```
> 蜘蛛侠（test-engineer）的 skills（tdd/gherkin/allure）经 frontmatter `skills:` 字段**预加载**（本仓首次用该字段，
> C-systemic 试点）；E2E 的 Playwright MCP 经 `tools:` 白名单（`mcp__playwright__*`）+ `mcp/servers/playwright.json` 模板启用。
> 纯本地测试、不依赖容器。详见 spec `2026-06-08-test-engineer-local-testing.md`。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 16 全绿；group 2 仍 grep 到 `hero-java-test-engineer`）。

- [ ] **Step 5: Commit**

```bash
git add docs/hero-agent-layers.md tests/hero-agent-layers/test_layers.sh
git commit -m "docs(hero-agent-layers): 矩阵同步 test-engineer 本地四类+skills 预加载

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: 新增 Playwright MCP 模板

**Files:**
- Create: `mcp/servers/playwright.json`
- Modify: `mcp/README.md`（已收录 server 表 +1 行）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**（插入 `assert_summary` 前）

```bash
# 17. Playwright MCP 模板
PW="$REPO/mcp/servers/playwright.json"
assert_ok "[ -f '$PW' ]" "playwright.json 存在"
assert_ok "grep -qF 'playwright' '$PW'" "含 playwright server"
assert_ok "grep -q 'headless' '$PW'" "无头模式"
assert_ok "grep -qF 'playwright' '$REPO/mcp/README.md'" "mcp README 收录 playwright"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 17 报 ✗。

- [ ] **Step 3a: 创建 `mcp/servers/playwright.json`（无密钥、无头）**

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

- [ ] **Step 3b: 改 `mcp/README.md`**

在「已收录的 server」表里 `| <name> | <作用> | 用户级/项目级 | <env> |` 占位行**之前**插入一行：

```
| playwright | 无头浏览器自动化（E2E 测试，给 AI 驱动） | 用户级 | 需 Node/npx；首次自动装浏览器 |
```

并在该表后补一句说明（紧接表格的注脚区）：

```
> **playwright** 给 `hero-java-test-engineer` 做无头 E2E；install.sh 以 template 模式处理、不自动写入，
> 成员自行把 `servers/playwright.json` 合并进 `~/.claude.json` 后，卡片里的 `mcp__playwright__*` 工具才真可用。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 17 全绿）。

- [ ] **Step 5: Commit**

```bash
git add mcp/servers/playwright.json mcp/README.md tests/hero-agent-layers/test_layers.sh
git commit -m "feat(mcp): 新增 Playwright MCP 模板（无头 E2E，给 test-engineer）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: 新增 httpie + allure CLI 文档

**Files:**
- Create: `cli/httpie.md`、`cli/allure.md`
- Modify: `cli/README.md`（总表 +2 行）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**（插入 `assert_summary` 前）

```bash
# 18. CLI httpie + allure
for c in httpie allure; do
  assert_ok "[ -f '$REPO/cli/$c.md' ]" "cli/$c.md 存在"
  assert_ok "grep -qF '$c' '$REPO/cli/README.md'" "cli README 含 $c"
done
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 18 报 ✗。

- [ ] **Step 3a: 创建 `cli/httpie.md`（逐字）：**

```markdown
# httpie — 接口冒烟探测（test-engineer）

蜘蛛侠做接口冒烟/手探的 CLI HTTP 客户端：起服务后打 localhost，看状态码与响应体。
可重复的接口断言套件仍走 Java（MockMvc / REST Assured）。

## 安装
`brew install httpie`（提供 `http` / `https` 命令）。

## 常用
- GET：`http :8080/api/health`（`:8080` 即 `localhost:8080`）
- 带查询：`http :8080/api/users id==1 active==true`
- POST JSON：`http POST :8080/api/users name=alice age:=30`（`:=` 传非字符串）
- 带 header / token：`http :8080/api/me Authorization:"Bearer xxx"`
- 只看响应头/状态：`http --headers :8080/api/health` / `http --print=h ...`

> 前提：先本地起服务（`mvn spring-boot:run` / `java -jar`）。冒烟探测用，不替代结构化接口断言。
```

- [ ] **Step 3b: 创建 `cli/allure.md`（逐字）：**

```markdown
# allure — 测试报告生成与查看（test-engineer）

蜘蛛侠归集用例结果、附失败证据的报告工具。配合 JUnit5/Cucumber 产出的 `allure-results`。

## 安装
`brew install allure`。

## 常用
- 生成静态报告：`allure generate allure-results -o allure-report --clean`
- 本地起服务看报告：`allure serve allure-results`
- 打开已生成报告：`allure open allure-report`

> Maven/Gradle 接入 allure 适配器后，测试会产出 `allure-results`；上面命令把它渲染成可读报告。
> 用法细节以 `allure` skill 为准（test-engineer 已 `skills:` 预加载）。
```

- [ ] **Step 3c: 改 `cli/README.md` 总表**

在 `| **codegraph** | ... |` 行之后（或表内任意合适处）插入两行：

```
| **httpie** | 接口冒烟探测（`http` 命令打 localhost） | `brew install httpie` | test-engineer 接口冒烟，见 `httpie.md` |
| **allure** | 测试报告生成/查看 | `brew install allure` | test-engineer 报告，见 `allure.md` |
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 18 全绿）。

- [ ] **Step 5: Commit**

```bash
git add cli/httpie.md cli/allure.md cli/README.md tests/hero-agent-layers/test_layers.sh
git commit -m "docs(cli): 新增 httpie/allure 文档（test-engineer 接口冒烟+报告）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: 手工验证（C-systemic 试点核心）+ 全量回归

**Files:** 无改动（除非验证失败需回修 Task 1 的 `skills:` 格式）。

- [ ] **Step 1: 四套测试全绿**

Run:
```bash
for s in hero-agent-layers hero-visibility hero-dispatch hero-refresh; do
  echo "== $s =="; bash tests/$s/run.sh | tail -1; done
```
Expected: 四套都 ALL TESTS PASSED。

- [ ] **Step 2: install dry-run（确认新增 mcp/cli/docs 不破软链）**

Run: `CLAUDE_HOME=/tmp/te-install-check bash install.sh && echo "DRYRUN OK"`
Expected: `DRYRUN OK`（mcp 走 template 模式不自动写；cli/docs 属既有目录类别，无需改 manifest）。

- [ ] **Step 3: 手工验证 `skills:` 预加载真生效（C-systemic 试点）**

由执行控制者（非本任务子 agent）**派一个 `hero-java-test-engineer` 子 agent**，给极简 prompt：
> 「只回答：你当前已预加载了哪些 skill？分别用一句话说明每个 skill 的核心方法（不要执行任何测试任务）。」

判定：
- ✅ **通过**：它能列出 `superpowers:test-driven-development`（RED→GREEN→REFACTOR / 测试反模式）、`gherkin`（Given/When/Then 语法、scenario outline 等）、`allure`（allure generate/serve 等），且内容是 skill 级细节（非泛泛而谈）→ 证明 `skills:` 字段预加载生效，C-systemic 修法成立。
- ❌ **不通过**（它说不知道有预加载 skill / 内容是通用常识）：说明 `skills:` 逗号分隔格式未被识别。**回到 Task 1**，把 frontmatter 改成 YAML 列表格式：
  ```
  skills:
    - superpowers:test-driven-development
    - gherkin
    - allure
  ```
  重跑 `bash tests/hero-agent-layers/run.sh`（group 15 的 `^skills:.*` 断言需相应调整为匹配多行列表：改成 `grep -qF 'superpowers:test-driven-development' '$TE'` 等不带 `^skills:` 锚的形式），再重做 Step 3 验证，直到 ✅。

- [ ] **Step 4: 记录验证结论**

把 Step 3 的判定结果（✅/❌ 及最终采用的 `skills:` 格式）追加到 spec 文件 `docs/superpowers/specs/2026-06-08-test-engineer-local-testing.md` 末尾「## 试点验证结论」一节，并提交：

```bash
git add docs/superpowers/specs/2026-06-08-test-engineer-local-testing.md
git commit -m "docs(test-engineer): 记录 skills: 预加载试点验证结论

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

> 若 Step 3 一次通过、无文件改动，则本任务仅产生 Step 4 这一个 commit（结论记录）。

---

## 后续（不在本计划）

- C-systemic 推广：试点 ✅ 后，给 tech-lead（brainstorming/writing-plans）、backend（tdd）、data-engineer（hero-conventions）加 `skills:` 字段。
- E2E 可重复套件的 Playwright-Java 代码化（本轮 E2E 走 MCP 驱动）。
- httpie 之外的结构化接口断言（MockMvc/REST Assured）属 TDD 范畴、已在卡片内。
