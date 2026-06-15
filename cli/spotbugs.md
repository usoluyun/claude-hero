# SpotBugs — Java 字节码级 Bug 检测（FindBugs 继承者）

> 覆盖Chris Olah审查清单：①NPE、②并发、⑧资源管理。
> 和 PMD 互补：PMD 扫源码（死代码/风格），SpotBugs 扫字节码（空指针/线程安全/无限循环）。
> 需要先编译项目再扫描。

## 安装

```bash
# macOS
brew install spotbugs

# 或下载压缩包
curl -sL "https://github.com/spotbugs/spotbugs/releases/download/4.10.1/spotbugs-4.10.1.tgz" -o /tmp/spotbugs.tgz
mkdir -p /tmp/sb && tar xzf /tmp/spotbugs.tgz -C /tmp/sb/
mv /tmp/sb/spotbugs-4.10.1 ~/.local/share/spotbugs
ln -sf ~/.local/share/spotbugs/bin/spotbugs ~/.cargo/bin/spotbugs
```

> SpotBugs 需要 Java 17+ 运行。用 sdkman 管理 JDK：`sdk use java 17.0.17-amzn`

## 常用

### 扫描编译后的 class 文件

```bash
# 先编译项目
mvn -q compile
# 或
./gradlew compileJava

# 扫描所有 class 文件（低门槛包含所有等级的问题）
spotbugs -textui -low -effort:max build/classes/
```

### 按严重级过滤

```bash
# 只看高严重级
spotbugs -textui build/classes/
# 或（默认 -medium 输出 medium+high）
```

SpotBugs 严重级：`-high`（仅 🚫 必须改）、`-medium`（默认，🚫+⚠️）、`-low`（全部）

### 输出到文件

```bash
spotbugs -textui -low -effort:max -output report.txt build/classes/
```

### XML 输出

```bash
spotbugs -textui -low -effort:max -xml -output report.xml build/classes/
```

### 多模块项目扫描

```bash
# 把所有模块的 class 路径传进去
spotbugs -textui -low module-a/target/classes:module-b/target/classes
```

## Chris Olah实战场景

```bash
# 1. 审查前：编译 + 扫全部
mvn -q compile && spotbugs -textui -medium -effort:max build/classes/

# 2. 只查高严重级（空指针/线程安全）
spotbugs -textui -high -effort:max build/classes/

# 3. 最全面扫描（低门槛+最大努力）
mvn -q compile && spotbugs -textui -low -effort:max -output spotbugs-report.txt build/classes/ && cat spotbugs-report.txt
```

## 检测模式分类

| 分类 | 覆盖 | 对应审查清单 |
|------|------|------------|
| **正确性** | null 指针解引用、无限循环、错误的 equals/hashCode | ①⑧ |
| **多线程正确性** | 双重检查锁定、`ThreadLocal` 泄漏、同步不一致 | ② |
| **坏的实践** | 未关闭流、`equals` 未覆盖 `hashCode` | ⑧ |
| **性能** | 低效的 String 操作、集合遍历 | — |
| **国际化和安全** | SQL 注入等 | ④（有限） |

> SpotBugs 和 PMD **互补**：PMD 扫源码文本 + 风格，SpotBugs 扫字节码 + 深层语义。
> Chris Olah的工作流：先 PMD（秒级），再 SpotBugs（编译+分钟级），再人工审。