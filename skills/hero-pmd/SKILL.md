---
name: hero-pmd
description: 当用户提到 pmd、静态代码分析、死代码检测、空catch、复杂度检测、代码审查时触发。
---

# PMD — 静态代码分析（死代码/空 catch/复杂度）

> 覆盖玄成审查清单：⑧资源管理、⑥可观测（空 catch）、⑨可读性（死代码/复杂度）。
> 零门槛：安装即用，支持 100+ 规则，支持 Java/JS/Python/等。

## 安装

```bash
# macOS
brew install pmd

# 或下载单压缩包（推荐，无需 brew）
curl -sL "https://github.com/pmd/pmd/releases/download/pmd_releases/7.25.0/pmd-dist-7.25.0-bin.zip" -o /tmp/pmd.zip
unzip /tmp/pmd.zip -d ~/.local/share/
ln -sf ~/.local/share/pmd-bin-7.25.0/bin/pmd ~/.cargo/bin/pmd
```

> PMD 需要 Java 17+ 运行。用 sdkman 管理 JDK：`sdk use java 17.0.17-amzn`

## 常用

### 最佳实践检查（空 catch、资源关闭）

```bash
pmd check -d src/main/java -R category/java/bestpractices.xml -f text
```

检出：空 catch 块、未关闭的流/连接、`return` in `finally` 等。

### 设计检查（死代码、过长方法）

```bash
pmd check -d src/main/java -R category/java/design.xml -f text
```

检出：未使用的私有字段/方法、过长方法、过高循环复杂度。**适合审代码前先扫一遍**。

### 错误处理检查

```bash
pmd check -d src/main/java -R category/java/errorprone.xml -f text
```

检出：空 catch `catch(Exception e){}`、`null` 指针风险、错误的 equals 实现。

### 性能检查

```bash
pmd check -d src/main/java -R category/java/performance.xml -f text
```

检出：`String` 循环拼接、低效的集合操作。

### 组合检查（一次性全部）

```bash
pmd check -d src/main/java \
  -R category/java/bestpractices.xml \
  -R category/java/design.xml \
  -R category/java/errorprone.xml \
  -R category/java/performance.xml \
  -f text
```

### JSON 格式输出

```bash
pmd check -d src/main/java \
  -R category/java/bestpractices.xml \
  -R category/java/errorprone.xml \
  -f json > pmd-report.json
```

## 玄成实战场景

```bash
# 1. 审全量代码前：先扫空 catch 和死代码
pmd check -d src/main/java -R category/java/bestpractices.xml,design.xml -f text

# 2. 重点关注错误处理
pmd check -d src/main/java -R category/java/errorprone.xml -f text

# 3. 查复杂度热点
pmd check -d src/main/java -R category/java/design.xml -f text | grep -i "cyclo\|complexity\|long\|GodClass"

# 4. 批量出 JSON 报告
pmd check -d src/main/java -R category/java/bestpractices.xml,design.xml,errorprone.xml -f json
```

## 常用规则集

| 规则集 | 覆盖 | 对应审查清单 |
|--------|------|------------|
| `bestpractices.xml` | 空 catch、资源关闭、异常吞没 | ⑥⑧ |
| `design.xml` | 死代码、过长方法、God Class、循环复杂度 | ⑨ |
| `errorprone.xml` | 空指针、错误的 equals、close 遗漏 | ①⑧ |
| `performance.xml` | String 拼接、集合性能 | — |
| `multithreading.xml` | 线程安全、锁使用 | ② |

> PMD 规则是 100+ 的，以上只是最常用的 Java 规则集。更多见 [PMD 官方规则文档](https://docs.pmd-code.org/latest/pmd_rules_java.html)。
