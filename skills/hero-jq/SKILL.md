---
name: hero-jq
description: 当用户提到 jq、JSON处理、API响应提取、JSON格式化、命令行JSON处理、文远实战场景时触发。
---

# jq — JSON 命令行处理器

> 写接口 / 调 API / 处理响应的**日常必备**。maven/gradle/curl 输出的 JSON 全靠它提取字段、过滤、格式化。

## 安装

```bash
# macOS（通常已预装）
brew install jq

# 验证
jq --version
```

## 常用

### 格式化 JSON（让 JSON 可读）

```bash
curl http://localhost:8080/api/users | jq .
```

### 提取字段

```bash
# 提取数组里所有 id
curl http://localhost:8080/api/users | jq '.[].id'

# 提取嵌套字段
curl http://localhost:8080/api/users/1 | jq '{id, name, email}'

# 按条件过滤
curl http://localhost:8080/api/users | jq '.[] | select(.status == "ACTIVE")'
```

### 格式化 + 截取

```bash
# 取数组长度
cat response.json | jq 'length'

# 取第一条
cat response.json | jq '.[0]'

# 取字段去重
cat response.json | jq '[.[].status] | unique'
```

### 配合构建工具

```bash
# Maven 依赖树只输出 scope 为 compile 的（简化阅读）
mvn dependency:tree -DoutputType=json | jq '.dependencies[] | select(.scope == "compile")'

# 只输出有 CVE 的依赖（配合 osv-scanner）
osv-scanner scan --format=json pom.xml | jq '.results[].packages[] | select(.groups[].max_severity | tonumber >= 7.0)'
```

### 批量处理

```bash
# 逐条处理数组中的每个元素
cat users.json | jq -c '.[]' | while read line; do
  echo "Processing: $(echo $line | jq -r '.name')"
done
```

## 常用参数

| 参数 | 用途 |
|------|------|
| `jq .` | 格式化输出 |
| `jq -r '.field'` | 原始输出（去掉引号） |
| `jq -c '.[]'` | 每行一条（compact） |
| `jq --arg v "val" 'select(.f == $v)'` | 传变量 |
| `jq -f filter.jq data.json` | 从文件读 filter |

## 文远实战场景

```bash
# 写完接口自测：调用并格式化响应
http :8080/api/orders/100 | jq .

# 看批量接口返回了多少条
http :8080/api/orders | jq 'length'

# 检查错误响应格式
http :8080/api/orders/999999 | jq '{code, message}'
```

> 团队约定：API 响应统一格式 `{code, message, data}`，用 jq 提取 `data` 字段即可忽略外层包装看业务数据。
