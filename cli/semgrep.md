# semgrep — SAST 静态安全扫描（🔴 设计安全）

Jan Leike代码时验 🔴 门槛的主力：跑规则集找注入/越权/危险模式。开源、本地单命令、可写自定义规则。

## 安装
`brew install semgrep` 或 `pipx install semgrep`。

## 常用
- 跑安全规则集：`semgrep --config p/owasp-top-ten <path>`
- 跑 Java/Spring 规则：`semgrep --config p/java --config p/spring <path>`
- 只看高危：`semgrep --config p/owasp-top-ten --severity ERROR <path>`
- 输出 JSON 供进一步处理：`semgrep --config p/owasp-top-ten --json <path>`

## 团队自定义规则（抓本团队红线）
写 `rules.yml`，例如抓 MyBatis `${}` 拼接（下面是一个 yaml 代码块）：

```yaml
rules:
  - id: mybatis-dollar-injection
    languages: [generic]
    severity: ERROR
    message: MyBatis ${} 拼接疑似 SQL 注入（应使用 #{}）
    pattern-regex: '\$\{[^}]+\}'
    paths:
      include: ['*.xml']
```

跑：`semgrep --config rules.yml <path>`

> 用法/规则语法以 context7 `/semgrep/semgrep-docs` 为准。CodeQL 见 `codeql.md`（深度污点分析）。
