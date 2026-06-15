# scc — 代码统计与复杂度热点分析

> **cloc 的 Go 替代品**：极快（多核并行）、支持 100+ 语言、内置复杂度估算 + COCOMO 人天估算。
> 适合**摸项目全貌**：一眼看懂项目规模、语言构成、哪些文件最复杂、复杂度热点在哪。

## 安装

```bash
# macOS
brew install scc

# 或下载单二进制
curl -sL "https://github.com/boyter/scc/releases/download/v3.7.0/scc_Darwin_arm64.tar.gz" | tar xz
mv scc ~/.cargo/bin/

# 验证
scc --version
```

## 常用

### 项目总览（按语言聚合）

```bash
# 默认输出：语言 / 文件数 / 行数 / 空行 / 注释 / 代码 / 复杂度
scc .
```

输出样例：
```
─────────────────────────────────────────────────────────
Language         Files   Lines  Blanks  Comments  Code  Complexity
─────────────────────────────────────────────────────────
Java               240   38,210   4,212     3,099  30,899      4,210
XML                 32    1,044     102       113     829          0
YAML                15      862     109        42     711          0
─────────────────────────────────────────────────────────
Total              287   40,116   4,423     3,254  32,439      4,210
─────────────────────────────────────────────────────────
Estimated Cost to Develop (COCOMO): $438,912
Estimated Schedule Effort: 14.8 months
Estimated People Required: 5.2
```

### 按复杂度找热点文件（Demis Hassabis验收专用）

```bash
# 按复杂度降序排列的前 20 个文件
scc . --by-file -s complexity --limit 20
```

→ 一眼定位"哪些文件最复杂、最需要关注"，适合做设计评审时的风险排查。

### 只看 Java 代码

```bash
scc . --include-ext java
```

### 排除测试代码

```bash
scc . --exclude-dir test,tests,__pycache__,node_modules
```

### 输出 JSON（给 jq 进一步处理）

```bash
scc . --format json | jq '.'
```

### 比较两个版本

```bash
# 两个版本的代码量差异（注释/代码/空行变化）
scc --diff old-version/ new-version/
```

## Jeff Dean/Demis Hassabis实战场景

```bash
# 1. 接手旧项目前：先看规模
scc .

# 2. 设计评审前：定位复杂度热点
scc . --by-file -s complexity --limit 20

# 3. 估算人天（COCOMO）
scc . | grep -i "cost\|effort\|people"

# 4. 看重构前后代码量变化
scc --diff refactor-before/ refactor-after/

# 5. 只看业务代码（排除测试）
scc . --exclude-dir test,tests --include-ext java
```

## 参数速查

| 参数 | 用途 |
|------|------|
| `--by-file` | 按文件展示（不聚合到语言） |
| `-s complexity` | 按复杂度排序 |
| `--limit N` | 只显示前 N 条 |
| `--include-ext java` | 只看某种语言 |
| `--exclude-dir dir` | 排除目录 |
| `--format json` | JSON 输出 |
| `--diff A B` | 比较两个版本 |
| `--no-duplicates` | 去重（相同内容只计一次） |
| `--avg-wage N` | 设置平均工资（影响 COCOMO 金额） |

> 团队约定：接手不熟悉的项目时，先用 `scc . --by-file -s complexity --limit 20` 了解复杂度分布，再做设计。