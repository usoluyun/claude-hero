# allure — 测试报告生成与查看（test-engineer）

Percy Liang归集用例结果、附失败证据的报告工具。配合 JUnit5/Cucumber 产出的 `allure-results`。

## 安装
`brew install allure`。

## 常用
- 生成静态报告：`allure generate allure-results -o allure-report --clean`
- 本地起服务看报告：`allure serve allure-results`
- 打开已生成报告：`allure open allure-report`

> Maven/Gradle 接入 allure 适配器后，测试会产出 `allure-results`；上面命令把它渲染成可读报告。
> 用法细节以 `allure` skill 为准（test-engineer 已 `skills:` 预加载）。
