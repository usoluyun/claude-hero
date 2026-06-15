---
name: hero-sca
description: 当用户提到 osv-scanner、SCA扫描、依赖扫描、CVE检测、组件安全、依赖漏洞时触发。
---

# OSV-Scanner — 组件/依赖安全自动化 SCA（🟡 提醒确认）

> 选型结论：`osv-scanner`（Google）vs `trivy`（Aqua）vs `grype`（Anchore）vs `dependency-check`（OWASP）。
> **osv-scanner 胜出原因**：单二进制无需 brew/无本地依赖/无需本地漏洞库下载、在线查 Google OSV 库（结果最新）、支持 `pom.xml` 直接扫描。开销最小、最快上手。

用于替代Jan Leike组件档的**人肉 `mvn dependency:tree` + WebSearch 方案**，属于 🟡 提醒确认档（不阻断，仅 advisory）。

## 安装

```bash
# macOS arm64 — 单二进制下载（无需 brew、无需 python、无需本地漏洞库）
curl -sL "https://github.com/google/osv-scanner/releases/download/v2.3.8/osv-scanner_darwin_arm64" -o ~/.cargo/bin/osv-scanner
chmod +x ~/.cargo/bin/osv-scanner
osv-scanner --version
```

其他架构 / 平台 → 从 [osv-scanner releases](https://github.com/google/osv-scanner/releases) 下载对应二进制。

## 常用

### 扫描单个 pom.xml（快速查依赖 CVE）

```bash
osv-scanner scan pom.xml
```

### 递归扫描整个项目目录（推荐——最实用户用法）

```bash
osv-scanner scan -r .
```

### JSON 格式输出（供后续分析/拼接）

```bash
osv-scanner scan --format=json -r . > sca-results.json
# 用 jq 筛选高严重性：
jq '.results[].packages[] | select(.groups[].max_severity | tonumber >= 7.0)' sca-results.json
```

### 仅扫关键字段（跳过测试依赖，更快）

```bash
osv-scanner scan pom.xml --skip-git --no-config
```

## 输出说明

每条结果含：

| 字段 | 说明 |
|------|------|
| `package.name` | Maven 坐标（group:artifact） |
| `package.version` | 当前版本 |
| `groups[].ids` | GHSA / CVE 编号 |
| `groups[].max_severity` | CVSS 最高分（0-10） |
| `vulnerabilities` | 完整漏洞详情（影响范围、修复版本、源链接） |

## Jan Leike集成建议

security-auditor 的组件扫描步骤：

```
1. osv-scanner scan --format=json -r . > /tmp/sca-results.json
2. jq 筛选 high/critical（severity >= 7.0）项
3. 每条给出：依赖名 + GHSA/CVE + 当前版本 + 修复版本 + 「请确认：本期升级 / 记录接受」
4. 输出格式同 🟡 档：不阻断、需人确认
```

## 对比

| 特性 | osv-scanner | trivy | grype | dependency-check |
|------|------------|-------|-------|-----------------|
| 安装 | 单二进制 | 单二进制 | 需 brew | 需 java/brew |
| 本地漏洞库 | 无（在线查 OSV） | 有（首次下载大） | 有（需更新） | 有（需更新 NVD） |
| pom.xml 支持 | ✅ | ✅ | ⬜（需转 SBOM） | ✅ |
| 扫描速度 | 快（秒级） | 中（首次下载慢） | 中 | 慢（更新 NVD 久） |
| 结果实时性 | 最新（在线查） | 依赖库更新频率 | 依赖库更新频率 | 依赖 NVD 更新 |

> **开销最小 = osv-scanner**。如需离线环境（无互联网），换 trivy（需首次 `trivy image --download-db-only` 下载漏洞库到本地）。
