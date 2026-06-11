---
name: hero-jdk-multiversion
description: 当用户提到 jdk切换、JAVA_HOME、多JDK版本、JDK 1.8/11/17、sdkman替代、toolchains配置、查看已装JDK、项目锁定JDK版本时触发。
---

# 多 JDK 手动切换（1.8 / 11 / 17）

团队不使用 sdkman/jenv，统一**手动管理 `JAVA_HOME`**。本文给出 macOS 下的约定。

## 查看已装 JDK

```bash
/usr/libexec/java_home -V          # 列出所有已安装 JDK 及路径
/usr/libexec/java_home -v 1.8      # 取某版本的 home 路径
/usr/libexec/java_home -v 11
/usr/libexec/java_home -v 17
```

JDK 一般装在 `/Library/Java/JavaVirtualMachines/`（Oracle/Zulu/Temurin 等）。

## 在 ~/.zshrc 加切换函数

```bash
# 手动切换 JAVA_HOME
jdk() {
  if [ -z "$1" ]; then echo "用法: jdk 1.8|11|17"; /usr/libexec/java_home -V; return; fi
  export JAVA_HOME="$(/usr/libexec/java_home -v "$1" 2>/dev/null)"
  if [ -z "$JAVA_HOME" ]; then echo "未找到 JDK $1"; return 1; fi
  echo "JAVA_HOME=$JAVA_HOME"
  java -version
}
alias jdk8='jdk 1.8'
alias jdk11='jdk 11'
alias jdk17='jdk 17'
```

`source ~/.zshrc` 后用 `jdk8` / `jdk11` / `jdk17` 切换，`jdk` 无参列出所有版本。

> 注意：切换只影响当前 shell 会话。新开终端会回到默认（`~/.zshrc` 里如设了默认 `JAVA_HOME`
> 则以它为准）。给 Claude Code 跑构建前，先在该会话切到项目所需版本。

## 锁定项目 JDK（避免切错）

**Maven —— toolchains**（`~/.m2/toolchains.xml`，让不同模块用指定 JDK 编译）：

```xml
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides><version>1.8</version></provides>
    <configuration><jdkHome>/path/to/jdk8</jdkHome></configuration>
  </toolchain>
  <toolchain>
    <type>jdk</type>
    <provides><version>17</version></provides>
    <configuration><jdkHome>/path/to/jdk17</jdkHome></configuration>
  </toolchain>
</toolchains>
```

配合 `maven-compiler-plugin` 的 `maven-toolchains-plugin` 指定版本。

**Gradle**（`gradle.properties`）：

```properties
org.gradle.java.home=/path/to/jdk17
```

或在 `build.gradle` 用 toolchain：

```groovy
java { toolchain { languageVersion = JavaLanguageVersion.of(17) } }
```

## 团队约定

- 每个仓库 README 注明所需 JDK 版本；构建前先 `jdkXX` 切到对应版本。
- 多模块/多服务版本不一时，优先用 Maven toolchains / Gradle toolchain **在构建配置里锁定**，
  减少"忘了切版本"导致的编译失败。
- 让 Claude Code 构建前确认 `java -version` 与项目要求一致。

## 常见坑

- `java -version` 与 `JAVA_HOME` 不一致：PATH 里另有 java。确认 `which java` 指向
  `$JAVA_HOME/bin/java`，必要时 `export PATH="$JAVA_HOME/bin:$PATH"`。
- IDE（IDEA）的 Project SDK 与命令行 `JAVA_HOME` 是两套，需各自设置。
- 高版本 JDK 编译的 class 在低版本运行报 `UnsupportedClassVersionError`，注意 target 版本。
