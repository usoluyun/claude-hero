# 鹏举系统设计安全门控强化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `hero-java-security-auditor`（鹏举）从"组件 CVE 审计员"重塑为"系统设计安全门控"：系统设计安全（未授权/越权/敏感数据/注入/不安全设计）= 🔴 强制门槛，组件依赖 CVE = 🟡 提醒确认；双模闭环（设计时定门槛 + 代码时验门槛）。

**Architecture:** 纯文档/配置改造——重写 agent 卡片正文，同步能力矩阵，新增合规规范文档 + 3 个 CLI 用法文档，给 refresh-vendor 加"安全标准常抓清单"。TDD 节奏 = 在 `tests/` 加 grep 断言（先红后绿）。`tools:` 白名单不变（CLI 经 Bash、规范经 Read、CVE 经 WebSearch、OWASP 经 context7），hero 露出行一字不动。

**Tech Stack:** Markdown（agent/docs/cli）、bash 3.2（refresh-vendor.sh、test_*.sh）、context7 MCP、semgrep/gitleaks/CodeQL（外部 CLI，仅文档化用法）。

**Branch:** `feature/security-auditor-design-gate`（基于 `feature/hero-agent-capability-align`）。

**Spec:** `docs/superpowers/specs/2026-06-07-security-auditor-design-gate.md`

---

## 文件结构

| 文件 | 职责 | 动作 |
|---|---|---|
| `agents/hero-java-security-auditor.md` | 卡片：愿景/两档/双模/输出契约/工作法 | 重写正文（frontmatter tools 不变、露出行不变） |
| `docs/hero-agent-layers.md` | 矩阵 security 行 + 注脚 | 改 |
| `docs/security-standards.md` | 合规口径（PCI/等保/PIPL）骨架 | 新建 |
| `cli/semgrep.md` / `gitleaks.md` / `codeql.md` | 安全 CLI 用法 | 新建 |
| `cli/README.md` | 总表 +3 行 | 改 |
| `scripts/lib/refresh-vendor.sh` | 安全标准常抓清单（抓 OWASP 进 vendor-docs） | 加函数 |
| `tests/hero-agent-layers/test_layers.sh` | 卡片/矩阵/规范/CLI 防回退断言 | 加断言 |
| `tests/hero-refresh/test_vendor.sh` | 安全标准清单断言 | 加断言 |

---

## Task 1: 重写 security-auditor 卡片（两档 + 双模 + 输出契约）

**Files:**
- Modify: `agents/hero-java-security-auditor.md`（全文重写正文，保留 frontmatter `tools:` 与 `## hero 露出` 段原样）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**

在 `tests/hero-agent-layers/test_layers.sh` 的 `assert_summary` 行**之前**插入：

```bash
# 12. security-auditor 系统设计安全门控强化（spec 2026-06-07）
SA="$AG/hero-java-security-auditor.md"
assert_ok "grep -qF '🔴 强制门槛' '$SA'" "security 卡含 🔴 强制门槛"
assert_ok "grep -qF '🟡 提醒确认' '$SA'" "security 卡含 🟡 提醒确认"
assert_ok "grep -qF '⛔ 阻断' '$SA'" "security 卡含 ⛔ 阻断标记"
assert_ok "grep -qF '设计时' '$SA'" "security 卡含设计时工作法"
assert_ok "grep -qF '代码时' '$SA'" "security 卡含代码时工作法"
assert_ok "grep -qF 'semgrep' '$SA'" "security 卡引用 semgrep"
assert_ok "grep -qF 'gitleaks' '$SA'" "security 卡引用 gitleaks"
assert_ok "grep -qF 'security-standards.md' '$SA'" "security 卡引用合规规范"
assert_ok "grep -qE '^tools:.*WebSearch.*context7' '$SA'" "security tools 仍含 WebSearch+context7"
assert_fail "grep -qE '^tools:.*(Skill|Edit|Write)' '$SA'" "security tools 未引入 Skill/Edit/Write"
```

> `$AG` 已在文件第 74 行定义为 `$REPO/agents`，`assert_*` 与 `assert_summary` 沿用现有。

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: `test_layers.sh` 报多条 ✗（🔴 强制门槛 / ⛔ / semgrep 等尚不存在），整体 SOME TESTS FAILED。

- [ ] **Step 3: 重写卡片正文**

把 `agents/hero-java-security-auditor.md` 全文替换为（**frontmatter `tools:` 一字不改，`## hero 露出` 段一字不改**）：

```markdown
---
name: hero-java-security-auditor
description: Java 应用系统设计安全审计专家（只读）。当需要从安全角度审查 Java/Spring Boot 的系统设计与代码时使用，重心在系统设计安全（未授权、越权、敏感数据未加密、注入、不安全设计）——这些作强制门槛；组件/依赖漏洞（CVE）只提醒确认、不阻断。设计时评审 design 文档定门槛、代码时验门槛。只报风险与修复建议、不改代码。仅用于授权的内部防御性安全审查。
model: opus
tools: Read, Grep, Glob, Bash, WebSearch, WebFetch, mcp__plugin_context7_context7__resolve-library-id, mcp__plugin_context7_context7__query-docs
---

你是团队的 **Java 系统设计安全审计专家**，对内部代码与设计做**防御性安全审查**。**只读**，输出风险与
修复建议，不直接改代码。栈：Spring Boot、MyBatis、MySQL/SQLServer、RocketMQ、JetCache、
Apollo、Eureka。

**定位**：系统设计安全是主战场、作**强制门槛**；组件/依赖安全只**提醒+确认、不阻断**。
双模闭环——**设计时定门槛 + 代码时验门槛**。

## hero 露出

接手任务时，先在输出顶部打一行自报家门（遵循 `hero-conventions` 露出规范，token 一字不改）：

`🦸 hero ▸ 鹏举（hero-java-security-auditor）接手 · 安全审计`

## 🔴 强制门槛 —— 系统设计安全（未解决/未显式豁免，不得进下一步）

1. **未授权**：对外接口无认证、内部接口对外暴露、认证逻辑可绕过。
2. **越权**：横向（按 ID 取/改数据不校验归属）、纵向（普通用户触达管理/内部功能）、功能级/数据级权限缺失。
3. **敏感数据未保护**：敏感数据（密码/token/身份证/手机/支付卡/密钥）明文存储或传输（HTTP）、
   弱哈希存密码（MD5/SHA1）、密钥硬编码、日志/异常/错误响应泄漏。
4. **注入**：MyBatis `${}` 拼用户输入（SQL 注入）、动态表名/列名未白名单、命令/LDAP/SpEL/表达式注入。
5. **不安全设计 / 信任边界**：不可信数据**危险反序列化（用法缺陷）**、关键操作无审计留痕、
   跨信任边界数据无校验、敏感配置端点暴露（actuator `/env`、`/heapdump`）、CORS 过宽。

> 判定"什么算敏感数据 / 什么必须加密鉴权"以 `docs/security-standards.md`（PCI-DSS / 等保 2.0 /
> 个保法 PIPL 口径）+ OWASP（`docs/vendor-docs/owasp-*.md` 本地缓存）为准。

## 🟡 提醒确认 —— 组件/依赖安全（不阻断）

1. **依赖 CVE**：老版本 fastjson/jackson/log4j/snakeyaml 等已知漏洞；`mvn dependency:tree` /
   `./gradlew dependencies` 定位 + WebSearch 查 NVD/官方公告核实编号与影响版本 + 建议升级版本。
   **需人确认：本期升级 / 记录接受**，不阻断。

> 切分：同是 fastjson——旧**版本**已知 RCE = 🟡 组件；把不可信数据直接**反序列化（用法）** =
> 🔴（上方不安全设计）。版本问题进 🟡，用法问题进 🔴。

## 双模工作法

**设计时**（读 `docs/design-*.md` + 接口契约）：
- 对照 OWASP/合规清单，逐对外接口、敏感字段、数据流核对认证·鉴权·加密·审计·信任边界。
- 产出"设计阶段 🔴 门槛清单"：哪些必须在设计里补齐才能进入开发。

**代码时**（diff + SAST + grep）：
- `semgrep`（OWASP 规则集 + 团队自定义规则：抓 MyBatis `${}`、Controller 无鉴权注解）验注入/越权。
- `gitleaks`（密钥/token 硬编码扫描）。
- `CodeQL`（可选重档：越权/注入深度污点分析）。
- grep + 人审验证设计时定的 🔴 门槛在代码里真落实（鉴权注解/归属校验真有、敏感字段真加密落库）。
- 聚焦本次变更与依赖面，结合 `git diff`。

## 输出契约

- 🔴 **强制门槛**：位置（design 文档段 / `file:line`）+ 攻击场景 + **必须**的修复 +
  **⛔ 阻断**（未解决/未显式豁免不得进入下一步）。
- 🟡 **提醒确认**：依赖 + CVE/影响版本 + 建议升级 + 「请确认：本期处理 / 记录接受」——不阻断。
- 🟢 **加固建议**：可选。
- 中文输出；只做发现与加固建议，不产出可用于攻击的利用代码。

## 边界

- 不改代码、不写实现。指明修复应由哪个专家执行（多数交 backend-developer / data-engineer）。
- 审计清单/方法论本卡自带，不依赖外部 skill。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh && bash tests/hero-visibility/run.sh`
Expected: 两套都 ALL TESTS PASSED（group 12 全绿；visibility 鹏举 token 仍在）。

- [ ] **Step 5: Commit**

```bash
git add agents/hero-java-security-auditor.md tests/hero-agent-layers/test_layers.sh
git commit -m "feat(security-auditor): 卡片重塑为系统设计安全门控（两档+双模）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: 同步能力矩阵（layers doc security 行 + 注脚）

**Files:**
- Modify: `docs/hero-agent-layers.md`（security-auditor 行 + 新增注脚）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**

在 `tests/hero-agent-layers/test_layers.sh` 的 `assert_summary` 行**之前**插入：

```bash
# 13. 矩阵 security 行反映双模 + 强制门槛 + SAST 工具
assert_ok "grep -qF 'semgrep' '$LAYERS'" "矩阵含 semgrep"
assert_ok "grep -qF 'gitleaks' '$LAYERS'" "矩阵含 gitleaks"
assert_ok "grep -qF '设计时' '$LAYERS'" "矩阵含双模（设计时）"
assert_ok "grep -qF '强制门槛' '$LAYERS'" "矩阵含强制门槛"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 13 报 ✗（semgrep/gitleaks/设计时/强制门槛 尚不在矩阵）。

- [ ] **Step 3: 改矩阵 security 行 + 注脚**

把 `docs/hero-agent-layers.md` 里 security-auditor 那一行（评审门控层表，当前「怎么用」为
`给它代码/配置 → 产出安全风险（CVE/注入/越权）与修复建议（只读）`）整行替换为：

```markdown
| `hero-java-security-auditor` | 鹏举 | opus（只读） | TODO | —（自带审计 checklist + OWASP/合规清单骨架，不依赖外部 skill） | semgrep, gitleaks（🔴 设计安全）；maven/gradle 依赖树 + WebSearch（🟡 CVE） | **设计时**评审 design 文档定 🔴 门槛 + **代码时** semgrep/gitleaks/grep 验门槛。系统设计安全（未授权/越权/敏感数据/注入/不安全设计）= 🔴 强制门槛（⛔阻断）；组件 CVE = 🟡 提醒确认（不阻断） |
```

并把下面这条注脚**追加到能力矩阵末尾的现有注脚块之后**（即以 `> **框架/库文档核实**统一分层…`
开头那段的紧后面，保持注脚集中）：

```markdown
> 鹏举（security-auditor）双模：设计时读 `docs/design-*.md` 定 🔴 门槛、代码时验；🔴=系统设计安全（强制），
> 🟡=组件依赖 CVE（提醒确认）。CLI（semgrep/gitleaks/CodeQL）经 Bash、OWASP 经 context7→`vendor-docs`、
> 合规口径见 `docs/security-standards.md`——`tools:` 白名单不变。详见 spec `2026-06-07-security-auditor-design-gate.md`。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 13 全绿；group 2 仍能 grep 到 `hero-java-security-auditor`）。

- [ ] **Step 5: Commit**

```bash
git add docs/hero-agent-layers.md tests/hero-agent-layers/test_layers.sh
git commit -m "docs(hero-agent-layers): 矩阵同步 security 双模+两档门槛

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: 新增合规规范文档 `docs/security-standards.md`

**Files:**
- Create: `docs/security-standards.md`
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**

在 `assert_summary` 前插入：

```bash
# 14. 合规规范文档（鹏举判定敏感/加密/鉴权的权威口径）
STD="$REPO/docs/security-standards.md"
assert_ok "[ -f '$STD' ]" "security-standards.md 存在"
assert_ok "grep -qF 'PCI-DSS' '$STD'" "含 PCI-DSS"
assert_ok "grep -qF '等保' '$STD'" "含 等保"
assert_ok "grep -qF 'PIPL' '$STD'" "含 PIPL"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 14 报 ✗（文件不存在）。

- [ ] **Step 3: 创建 `docs/security-standards.md`**

```markdown
# 安全合规口径（鹏举判定基线）

> `hero-java-security-auditor` 判定"什么算敏感数据 / 什么必须加密 / 什么必须鉴权"的**权威依据**。
> 人工沉淀、随合规要求更新；与 OWASP（`docs/vendor-docs/owasp-*.md`）互补——OWASP 给技术做法，本文件给合规口径。

## 敏感数据分级（什么必须加密/脱敏）

| 级别 | 数据 | 要求 |
|---|---|---|
| 高 | 支付卡号/CVV、密码、密钥/token、身份证号 | 禁明文存储/传输；密码用强哈希加盐（禁 MD5/SHA1）；密钥进 Apollo 加密、禁硬编码 |
| 中 | 手机号、邮箱、住址、业主/会员 PII | 存储加密或脱敏；日志/响应脱敏；传输走 HTTPS |
| 低 | 昵称、公开展示字段 | 按需 |

## PCI-DSS（持卡人数据——酒店收信用卡强相关）

- 持卡人数据（PAN/CVV/有效期）禁明文存储；传输强加密；最小化留存。
- 访问按需授权（least privilege）、审计留痕。
- 适用范围：任何接触支付卡数据的接口/服务 → 列 🔴 强制门槛。

## 网络安全等级保护 等保 2.0（中国境内系统）

- 身份鉴别、访问控制、安全审计、数据完整性/保密性为基本要求项。
- 个人信息与重要数据存储/传输加密；操作可审计、可追溯。
- 亚朵系统境内运营 → 鉴权/审计/加密缺失列 🔴 强制门槛。

## 个人信息保护法 PIPL（业主/会员 PII）

- 个人信息处理需最小必要、目的明确；敏感个人信息（身份证、生物特征、金融账户等）加严。
- 存储加密/脱敏、访问控制、可审计；跨境传输另有要求。
- 业主/会员 PII 明文存储或越权可读 → 🔴 强制门槛。

## GDPR（若有海外业务）

- 数据主体权利、加密与假名化、违规上报。仅对涉欧业务适用。

---

> 维护：随合规要求/审计反馈更新；新增敏感数据类型先更"敏感数据分级"表。
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 14 全绿）。

- [ ] **Step 5: Commit**

```bash
git add docs/security-standards.md tests/hero-agent-layers/test_layers.sh
git commit -m "docs(security): 新增合规口径 security-standards.md（PCI/等保/PIPL）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: 新增安全 CLI 文档 + README 收录

**Files:**
- Create: `cli/semgrep.md`、`cli/gitleaks.md`、`cli/codeql.md`
- Modify: `cli/README.md`（总表 +3 行）
- Test: `tests/hero-agent-layers/test_layers.sh`

- [ ] **Step 1: 写失败断言**

在 `assert_summary` 前插入：

```bash
# 15. 安全 CLI 文档 + README 收录
for c in semgrep gitleaks codeql; do
  assert_ok "[ -f '$REPO/cli/$c.md' ]" "cli/$c.md 存在"
  assert_ok "grep -qF '$c' '$REPO/cli/README.md'" "cli README 含 $c"
done
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: group 15 报 ✗（三个 cli 文件不存在）。

- [ ] **Step 3a: 创建 `cli/semgrep.md`**

```markdown
# semgrep — SAST 静态安全扫描（🔴 设计安全）

鹏举代码时验 🔴 门槛的主力：跑规则集找注入/越权/危险模式。开源、本地单命令、可写自定义规则。

## 安装
`brew install semgrep` 或 `pipx install semgrep`。

## 常用
- 跑安全规则集：`semgrep --config p/owasp-top-ten <path>`
- 跑 Java/Spring 规则：`semgrep --config p/java --config p/spring <path>`
- 只看高危：`semgrep --config p/owasp-top-ten --severity ERROR <path>`
- 输出 JSON 供进一步处理：`semgrep --config p/owasp-top-ten --json <path>`

## 团队自定义规则（抓本团队红线）
写 `rules.yml`，例如抓 MyBatis `${}` 拼接：

\```yaml
rules:
  - id: mybatis-dollar-injection
    languages: [generic]
    severity: ERROR
    message: MyBatis ${} 拼接疑似 SQL 注入（应使用 #{}）
    pattern-regex: '\$\{[^}]+\}'
    paths:
      include: ['*.xml']
\```

跑：`semgrep --config rules.yml <path>`

> 用法/规则语法以 context7 `/semgrep/semgrep-docs` 为准。CodeQL 见 `codeql.md`（深度污点分析）。
```

- [ ] **Step 3b: 创建 `cli/gitleaks.md`**

```markdown
# gitleaks — 密钥/凭据硬编码扫描（🔴 敏感数据）

鹏举查 🔴"密钥硬编码"：扫源码与 git 历史里的 token/密钥/口令。

## 安装
`brew install gitleaks`。

## 常用
- 扫工作区：`gitleaks dir <path>`
- 扫 git 历史：`gitleaks git <repo>`
- 只看本次变更（结合 diff）：`git diff | gitleaks stdin`
- 输出报告：`gitleaks dir <path> --report-path leaks.json`

> 命中即列 🔴 强制门槛；密钥应进 Apollo 加密、禁入码。误报用 `.gitleaks.toml` allowlist 收敛。
```

- [ ] **Step 3c: 创建 `cli/codeql.md`**

```markdown
# CodeQL — 深度数据流/污点分析（🔴 可选重档）

semgrep 之上的可选重档：跨过程污点分析，查越权链、注入污点从源到汇的传播。重、慢，按需用。

## 安装
下载 CodeQL CLI bundle（GitHub `github/codeql-action` 发行物），解压加入 PATH。

## 常用
- 建库：`codeql database create db --language=java --command='mvn -B compile'`
- 跑安全查询集：`codeql database analyze db codeql/java-queries:codeql-suites/java-security-extended.qls --format=sarif-latest --output=results.sarif`
- 看结果：解析 `results.sarif`（或导入 IDE）。

> 重，不作常规门槛步骤；仅在越权/注入需要污点级佐证时启用。日常用 `semgrep.md`。
```

- [ ] **Step 3d: 改 `cli/README.md` 总表**

在 `| **codegraph** | ... |` 行**之后**插入三行：

```markdown
| **semgrep** | SAST：注入/越权/危险模式扫描（🔴 设计安全） | `brew install semgrep` | 鹏举代码时验门槛主力，见 `semgrep.md` |
| **gitleaks** | 密钥/凭据硬编码扫描（🔴 敏感数据） | `brew install gitleaks` | 命中即 🔴 强制门槛，见 `gitleaks.md` |
| **codeql** | 深度污点分析（🔴 可选重档） | 见详情 | 越权/注入污点佐证，见 `codeql.md` |
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-agent-layers/run.sh`
Expected: ALL TESTS PASSED（group 15 全绿）。

- [ ] **Step 5: Commit**

```bash
git add cli/semgrep.md cli/gitleaks.md cli/codeql.md cli/README.md tests/hero-agent-layers/test_layers.sh
git commit -m "docs(cli): 新增 semgrep/gitleaks/codeql 安全 CLI 文档

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: refresh-vendor 安全标准常抓清单（抓 OWASP 进 vendor-docs）

**Files:**
- Modify: `scripts/lib/refresh-vendor.sh`（加 `_security_standard_libs` + `refresh_security_standards`）
- Test: `tests/hero-refresh/test_vendor.sh`

- [ ] **Step 1: 写失败断言**

在 `tests/hero-refresh/test_vendor.sh` 的 `assert_summary` 行**之前**插入：

```bash
# 安全标准常抓清单（独立于项目指纹，固定抓 OWASP）
stds="$(_security_standard_libs)"
assert_ok "grep -qi 'owasp' <<<\"\$stds\"" "安全标准清单含 OWASP"
assert_eq "owasp-top-10" "$(vendor_slug 'OWASP Top 10')" "OWASP slug 正确"
assert_ok "declare -f refresh_security_standards >/dev/null" "refresh_security_standards 已定义"
```

- [ ] **Step 2: 跑测试确认变红**

Run: `bash tests/hero-refresh/run.sh`
Expected: `test_vendor.sh` 报 ✗（`_security_standard_libs`/`refresh_security_standards` 未定义）。

- [ ] **Step 3: 在 `scripts/lib/refresh-vendor.sh` 加函数**

在 `refresh_vendor_docs()` 函数定义**之后**（文件末尾）追加：

```bash
# 安全标准常抓清单：独立于项目技术栈指纹，固定抓 OWASP 进 vendor-docs（全局一次，非按项目）。
# 供鹏举（security-auditor）本地读 docs/vendor-docs/owasp-*.md。
_security_standard_libs() {
  cat <<'EOF'
OWASP Top 10
OWASP Cheat Sheet Series
OWASP Developer Guide
EOF
}

refresh_security_standards() {  # 抓 OWASP 标准进 vendor-docs
  local vendor_dir lib id out
  vendor_dir="$(repo_root)/docs/vendor-docs"
  mkdir -p "$vendor_dir"
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    out="${vendor_dir}/$(vendor_slug "$lib").md"
    id="$(context7_resolve "$lib")"
    if [[ -z "$id" ]]; then echo "  · $lib：未解析到 context7 id，跳过" >&2; continue; fi
    if context7_fetch "$id" "$out"; then echo "  ✓ $lib → $out";
    else echo "  · $lib：抓取失败，跳过" >&2; fi
  done < <(_security_standard_libs)
}
```

- [ ] **Step 4: 跑测试确认变绿**

Run: `bash tests/hero-refresh/run.sh`
Expected: ALL TESTS PASSED（`_security_standard_libs` 输出含 OWASP、slug=`owasp-top-10`、函数已定义）。

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/refresh-vendor.sh tests/hero-refresh/test_vendor.sh
git commit -m "feat(hero-refresh): vendor lane 加安全标准常抓清单（OWASP）

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 6: 全量回归 + 安装演练

**Files:** 无改动，纯验证。

- [ ] **Step 1: 四套测试全绿**

Run:
```bash
for s in hero-agent-layers hero-visibility hero-dispatch hero-refresh; do
  echo "== $s =="; bash tests/$s/run.sh | tail -1; done
```
Expected: 四套都 ALL TESTS PASSED。

- [ ] **Step 2: install dry-run（确认新增 docs/cli 不破软链）**

Run: `CLAUDE_HOME=/tmp/hero-install-check bash install.sh && echo "DRYRUN OK"`
Expected: 无报错、`DRYRUN OK`（新增的 `docs/security-standards.md`、`cli/*.md` 属既有目录类别，不需改 manifest）。

- [ ] **Step 3: 人工抽查 tools 白名单未变**

Run: `grep -m1 '^tools:' agents/hero-java-security-auditor.md`
Expected: `tools: Read, Grep, Glob, Bash, WebSearch, WebFetch, mcp__plugin_context7_context7__resolve-library-id, mcp__plugin_context7_context7__query-docs`（与改造前完全一致）。

- [ ] **Step 4:（无新增改动则免提交）**

若 Step 1–3 全过，本任务无文件改动、不产生 commit。如发现问题回对应 Task 修复。

---

## 后续（不在本计划）

- 把 🔴 项接进 `hero-prd-to-java` 做硬 STOP gate（spec 决策2第二步）。
- 组件 🟡 档自动化 SCA（trivy/grype/dependency-check/osv-scanner）。
- `hero 刷新` 调 `refresh_security_standards`（本计划只加函数；接入刷新命令编排属 hero-refresh 后续）。
