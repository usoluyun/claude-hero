# 设计：鹏举 `hero-java-security-auditor` 系统设计安全门控强化

> 状态：已 brainstorm 评审通过，待转 implementation plan。
> 日期：2026-06-07。
> 基线：`feature/hero-agent-capability-align`（security-auditor 已含 WebSearch/WebFetch + context7）。

## 背景与目标

复盘评审门控层时发现：鹏举现状把审计重心放在**组件/依赖 CVE**（人肉 `mvn dependency:tree` + WebSearch 比对），而**系统设计安全**（未授权、越权、敏感信息未加密）只是清单里平铺的几条、无强制力。这与"安全门控"的愿景错位——真正该卡死的是系统设计安全问题，组件漏洞反而更适合"提醒+确认"。

**目标**：重塑鹏举为**系统设计安全门控**——

1. **重心搬移**：系统设计安全（认证/访问控制/敏感数据/注入/不安全设计）成为主战场。
2. **两档门槛**：系统设计安全 = 🔴 **强制门槛**（未解决/未显式豁免不得进下一步）；组件/依赖安全 = 🟡 **提醒+确认**（不阻断）。
3. **双模闭环**：设计时定门槛（评审 design 文档）+ 代码时验门槛（diff/grep + SAST）。
4. **能力补强**：引入 OWASP（context7）+ 合规口径（PCI/等保/PIPL）当清单骨架，semgrep/gitleaks/CodeQL 当自动化检测——**均经现有 Bash/Read，不改 tools 白名单**。

## 决策（已与用户敲定）

1. **介入时机 = 双模闭环**：设计时评审 `docs/design-*.md` 把 🔴 门槛定下来；代码时在 diff 上验证门槛真落实。
2. **强制门槛生效 = 两步走**：本轮做 agent **分级输出**（🔴 阻断标记）；把"接进 `hero-prd-to-java` 做硬 STOP gate"列为后续单独干。
3. **设计时读源 = 只读本地**：读 `docs/design-*.md` + 接口契约 + 代码，**不加飞书工具**；需 PRD 业务上下文走（未来的）business-docs 缓存。
4. **工具集 = 除 trivy 外全纳入**：OWASP + 合规口径 + semgrep + gitleaks + CodeQL 纳入；trivy 及 SCA 同类（grype/dependency-check/osv-scanner）整档**缓后**。
5. **保持自洽范式**：审计清单/方法论自带（不依赖外部 skill），`tools:` 白名单不变。

## 设计

### ① 愿景重塑

鹏举 = **系统设计安全门控**（设计时定门槛 + 代码时验门槛的双模闭环）。系统设计安全是主战场且**强制**；组件/依赖安全降为**提醒+确认、不阻断**。model 保持 opus（深度威胁推演）、只读 advisory。

### ② 两档分类

**🔴 强制门槛 —— 系统设计安全（未解决/未显式豁免，不得进下一步）**

| 类 | 覆盖 |
|---|---|
| 未授权 | 对外接口无认证、内部接口对外暴露、认证逻辑可绕过 |
| 越权 | 横向（按 ID 取/改数据不校验归属）、纵向（普通用户触达管理/内部功能）、功能级/数据级权限缺失 |
| 敏感数据未保护 | 敏感数据（密码/token/身份证/手机/支付卡/密钥）明文存/传、弱哈希存密码、密钥硬编码、日志/异常/错误响应泄漏 |
| 注入 | SQL（MyBatis `${}` 拼用户输入）、命令/LDAP/SpEL/表达式注入 |
| 不安全设计/信任边界 | 不可信数据**危险反序列化（用法缺陷，非版本）**、关键操作无审计留痕、跨信任边界数据无校验、敏感配置端点暴露（actuator `/env`/`/heapdump`）、CORS 过宽 |

**🟡 提醒确认 —— 组件/依赖安全（advisory，不阻断）**

| 类 | 覆盖 |
|---|---|
| 依赖 CVE | 老版本 fastjson/jackson/log4j/snakeyaml 等已知漏洞；`mvn dependency:tree` / `./gradlew dependencies` 定位 + WebSearch 核实编号与影响版本 + 建议升级。**需人确认：本期升级 / 记录接受** |

> **关键切分**：同是 fastjson——"用了有 RCE 的旧**版本**" = 🟡 组件；"把不可信数据直接反序列化"这种**用法/设计**缺陷 = 🔴 不安全设计。版本问题进 🟡，用法问题进 🔴。

**🟢 加固建议（可选，非门槛）**：纵深防御、安全调试开关等。

### ③ 双模工作法

**设计时**（读 `docs/design-*.md` + 接口契约）：
- 对照 OWASP/合规清单，逐对外接口/敏感数据字段/数据流核对：认证、鉴权、加密、审计、信任边界校验在设计里有没有。
- 产出"设计阶段 🔴 门槛清单"：哪些必须在设计里补齐才能进入开发。

**代码时**（diff + grep + SAST）：
- `semgrep`（跑 OWASP 规则集 + 团队自定义规则：抓 MyBatis `${}`、Controller 无鉴权注解）验注入/越权。
- `gitleaks`（密钥硬编码）。
- `CodeQL`（可选重档：越权/注入的深度污点分析）。
- grep + 人审验证设计时定的 🔴 门槛在代码里真落实（鉴权注解/归属校验真有、敏感字段真加密落库）。

**组件 🟡**：`mvn dependency:tree` + WebSearch 查 CVE（现状保留；自动化 SCA 缓后）。

### ④ 输出契约（分级 + 阻断标记）

- 🔴 **强制门槛**：每条给 位置（design 文档段 / `file:line`）+ 攻击场景 + **必须**的修复方案 + **⛔ 阻断**标记（「未解决/未显式豁免不得进入下一步」）。
- 🟡 **提醒确认**：每条给 依赖 + CVE/影响版本 + 建议升级版本 + 「请确认：本期处理 / 记录接受」——**不阻断**。
- 🟢 **加固建议**：可选。
- 全程中文输出；只做发现与加固建议，不产出可用于攻击的利用代码。

### ⑤ 知识骨架

**技术安全规范（OWASP，context7 已收 → 抓进 `docs/vendor-docs/`）**：
- OWASP Top 10 `/owasp/top10`、Cheat Sheet Series `/owasp/cheatsheetseries`、Developer Guide `/owasp/devguide`。
- 抓取方式：现有 vendor lane 是"项目依赖指纹驱动"，OWASP 非项目依赖 → 需**给 `refresh-vendor.sh` 加一个"安全标准常抓清单"**（固定抓 OWASP，独立于指纹），或首次手动抓。写进实现计划。

**业务/合规口径（context7 无 → 人工沉淀 `docs/security-standards.md`，团队共享/进 git）**：
- PCI-DSS（持卡人数据加密/访问控制——酒店收信用卡强相关）。
- 等保 2.0 + 个保法 PIPL（业主/会员 PII：哪些个人信息敏感、必须加密脱敏、必须访问控制）。
- GDPR（若有海外业务）。
- 该文档定义"什么算敏感数据 / 什么必须加密 / 什么必须鉴权"，填鹏举判定 🔴 的权威依据。

### ⑥ CLI 工具（经 Bash 调，收进 `cli/`）

| 工具 | 档 | 用途 | cli 文档 |
|---|---|---|---|
| semgrep | 🔴 | SAST：OWASP 规则 + 团队自定义规则（`${}`/无鉴权注解） | `cli/semgrep.md` |
| gitleaks | 🔴 | 密钥/token 硬编码扫描 | `cli/gitleaks.md` |
| CodeQL | 🔴（重，可选） | 越权/注入深度污点分析 | `cli/codeql.md` |

> trivy 及 SCA 同类不在本轮（🟡 组件档自动化缓后）。

## 仓库落点

| 动作 | 文件 |
|---|---|
| 重写卡片（愿景/两档清单/双模/输出契约/工作法） | `agents/hero-java-security-auditor.md` |
| 同步矩阵（security 行「怎么用」+ CLI 列 + 注脚） | `docs/hero-agent-layers.md` |
| 新增合规规范（人工沉淀，占位 + 框架） | `docs/security-standards.md` |
| 新增 CLI 文档 | `cli/semgrep.md`、`cli/gitleaks.md`、`cli/codeql.md` + `cli/README.md` 三行 |
| OWASP 入 vendor-docs（refresh-vendor 加"安全标准常抓清单"） | `scripts/lib/refresh-vendor.sh`（小扩展） |
| 防回退测试 | `tests/hero-agent-layers/test_layers.sh`（+断言） |

**`tools:` 白名单不变**：CLI 经现有 `Bash`、规范经现有 `Read`、CVE 经现有 `WebSearch`、OWASP/框架经现有 context7。无需新增工具。

## 组件边界（各单元一个职责）

| 单元 | 职责 | 依赖 | 接口 |
|---|---|---|---|
| `agents/hero-java-security-auditor.md` | 双模审计、两档分级、阻断标记 | design 文档、代码、OWASP/合规、semgrep/gitleaks | 输出风险清单（只读） |
| `docs/security-standards.md` | 合规口径（敏感数据/加密/鉴权定义） | 人工维护 | 鹏举 Read |
| `cli/semgrep.md` / `gitleaks.md` / `codeql.md` | CLI 用法 | 对应工具已装 | 鹏举 Bash 参照 |
| `refresh-vendor.sh` 安全标准清单 | 把 OWASP 抓进 vendor-docs | context7 | 写 `docs/vendor-docs/owasp-*.md` |

## 验证（成功标准）

1. **两档分明**：卡片明确 🔴 系统设计安全（含未授权/越权/敏感数据/注入/不安全设计）vs 🟡 组件依赖，分类无歧义。
2. **阻断标记**：🔴 项输出带 ⛔ 阻断标记 + 攻击场景 + 必须修复；🟡 项带"请确认"且不阻断。
3. **双模**：卡片含设计时（读 design 文档定门槛）与代码时（semgrep/gitleaks/grep 验门槛）两段工作法。
4. **反序列化切分**：版本问题归 🟡、用法问题归 🔴 在卡片写明。
5. **知识骨架**：`docs/security-standards.md` 存在且含 PCI/等保/PIPL 框架；OWASP 抓取路径在 refresh-vendor 落地。
6. **CLI 落地**：`cli/semgrep.md`/`gitleaks.md`/`codeql.md` 存在、`cli/README.md` 收录三行。
7. **tools 不变**：security-auditor `tools:` 白名单未新增条目（仍 Read/Grep/Glob/Bash + WebSearch/WebFetch + context7）。
8. **矩阵对齐 + 露出不破**：矩阵 security 行更新；hero 露出行（鹏举 token）一字不动，visibility/layers 测试全绿。

## 非目标（YAGNI）/ 后续

- **后续①**：把 🔴 项接进 `hero-prd-to-java` 做硬 STOP gate（决策2第二步，本轮只做分级输出）。
- **后续②**：组件 🟡 档自动化 SCA（trivy/grype/dependency-check/osv-scanner）。
- 不引入飞书 PRD 直读（设计时只读本地 design 文档）。
- 不改 `tools:` 白名单。
- 不替鹏举产出攻击利用代码（防御性审查边界）。
