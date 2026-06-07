# CodeQL — 深度数据流/污点分析（🔴 可选重档）

semgrep 之上的可选重档：跨过程污点分析，查越权链、注入污点从源到汇的传播。重、慢，按需用。

## 安装
下载 CodeQL CLI bundle（GitHub `github/codeql-action` 发行物），解压加入 PATH。

## 常用
- 建库：`codeql database create db --language=java --command='mvn -B compile'`
- 跑安全查询集：`codeql database analyze db codeql/java-queries:codeql-suites/java-security-extended.qls --format=sarif-latest --output=results.sarif`
- 看结果：解析 `results.sarif`（或导入 IDE）。

> 重，不作常规门槛步骤；仅在越权/注入需要污点级佐证时启用。日常用 `semgrep.md`。
