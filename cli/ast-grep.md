# ast-grep（`sg`）— 结构化代码搜索与改写

> **grep 的升级版**：不是搜文本，是搜 AST（抽象语法树）。写代码模式匹配，不是正则。
> Rust 写的，极快，支持 Java / TypeScript / Python / Go / 20+ 语言。
> 日常编码找模式、批量重构、写 lint 规则——一个工具全搞定。

## 安装

```bash
# macOS
brew install ast-grep

# 或 pip
pip3 install ast-grep-cli

# 或 npm
npm install -g @ast-grep/cli

# 验证
ast-grep --version
# 或短名
sg --version
```

## 文档

> 文档详见：[ast-grep 官方文档](https://ast-grep.github.io/)
> VSCode 插件：[ast-grep-vscode](https://marketplace.visualstudio.com/items?itemName=ast-grep.ast-grep-vscode)

## 常用命令

### 基本搜索（`ast-grep run`）

```bash
# 找所有 @GetMapping 注解（Java）
sg -p '@GetMapping($$$)' -l java

# 找所有 @Transactional 注解（Java）
sg -p '@Transactional' -l java

# 找所有 @Value 注解
sg -p '@Value($$$)' -l java
```

**模式语法**：

| 符号 | 含义 | 示例 |
|------|------|------|
| `$MATCH` | 匹配任意单个 AST 节点 | `@GetMapping($PATH)` 匹配 `@GetMapping("/users")` |
| `$$$` | 匹配任意多个 AST 节点 | `@GetMapping($$$)` 匹配 `@GetMapping(value = "/users", produces = "json")` |

### 带上下文的搜索

```bash
# 显示匹配前后 2 行
sg -p '@GetMapping($$$)' -l java -C 2

# 输出 JSON 格式（供 jq 进一步处理）
sg -p '@GetMapping($$$)' -l java --json | jq '.'
```

### 结构化改写（`ast-grep run --rewrite`）

```bash
# 把 @ApiOperation 替换为 @Operation（Swagger 3 迁移）
sg -p '@ApiOperation($$$)' -l java -r '@Operation($$$)'

# 交互式确认
sg -p '@ApiOperation($$$)' -l java -r '@Operation($$$)' --interactive

# 全部直接应用
sg -p '@ApiOperation($$$)' -l java -r '@Operation($$$)' -U
```

### 高级匹配：元变量和条件

```bash
# 找所有返回 ResponseEntity 的方法
sg -p 'public ResponseEntity<$RET> $METHOD($$$)' -l java

# 找所有没有 @Valid 的 Controller 方法参数
sg -p 'public $$$ $$$(@RequestBody $$$ $ARG)' -l java
# 再配合管道过滤不带 @Valid 的
```

### 配置化规则（`ast-grep scan`）

用 YAML 配置文件管理规则，类似 ESLint：

```yaml
# sgconfig.yml
ruleDirs:
  - rules
```

```yaml
# rules/no-sql-injection.yml
id: no-sql-injection
message: 发现 MyBatis ${} 拼接，有 SQL 注入风险
severity: error
language: Java
rule:
  pattern: ${$PARAM}
  inside:
    kind: string
    stopBy: end
```

```bash
# 扫描整个项目
ast-grep scan
```

### 调试模式

```bash
# 查看匹配模式被解析成了什么 AST
sg -p '@GetMapping($$$)' -l java --debug-query
```

## Jeff Dean实战场景

```bash
# 1. 找所有 Controller 的 @RequestMapping 根路径
sg -p '@RequestMapping($$$)' -l java src/main/java/com/**/controller/

# 2. 找所有没用 @Valid 的 @RequestBody 参数
sg -p 'public $$$ $$$(@RequestBody $ARG)' -l java src/main/java/com/**/controller/

# 3. 找所有 MyBatis ${} 拼接（SQL 注入风险）
sg -p '${$PARAM}' -l java src/main/resources/

# 4. 找所有 catch 没打日志
sg -p 'catch($EXC) { $$$ }' -l java
# 再过滤看有没有 log.error 或 logger.error

# 5. 批量重构：把 Feign 接口的 @RequestParam 改成 @PathVariable
sg -p '@RequestParam($$$)' -l java -r '@PathVariable($$$)' --interactive
```

## 和 grep 的对比

| 场景 | grep | ast-grep |
|------|------|----------|
| 找 @GetMapping("/users") | 搜文本即可 | 懂 AST，不会匹配注释里的 |
| 找 @GetMapping(任何路径) | 需写正则 `/@GetMapping\([^)]+\)/` | 写 `@GetMapping($$$)` 即可 |
| 找 Controller 中没 @Valid 的参数 | 极复杂 | 元变量 + 条件 |
| 批量替换 @ApiOperation → @Operation | 正则，易误伤 | AST 感知，不会错改注释里的 |
| 多文件交互式重构 | 无 | `--interactive` 模式 |
| 写自定义 lint 规则 | 不可能 | YAML 规则文件 |