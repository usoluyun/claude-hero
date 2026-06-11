---
name: hero-gradle
description: 当用户提到 gradle、gradlew、构建、wrapper、toolchain、Gradle配置时触发。
---

# Gradle 团队约定

团队 Maven 与 Gradle 并存。优先用项目自带的 **wrapper**（`./gradlew`），保证 Gradle 版本一致。

## gradle.properties

项目级 `gradle.properties`（或 `~/.gradle/gradle.properties`）：

```properties
# 锁定构建用 JDK（手动 JAVA_HOME 之外的稳妥做法，见 jdk-multiversion.md）
org.gradle.java.home=/path/to/jdk17

# 性能
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8

# 私服凭据（值从环境变量注入，不要硬编码提交）
nexusUser=
nexusPass=
```

## 私服镜像

`build.gradle` / `settings.gradle` 的 `repositories` 指向内部 Nexus：

```groovy
repositories {
    maven {
        url "https://nexus.内网域名/repository/maven-public/"
        credentials { username = nexusUser; password = nexusPass }
    }
    mavenCentral()   // 兜底，通常被私服代理
}
```

## 常用命令

```bash
./gradlew -v                   # Gradle 与 JDK 版本
./gradlew build                # 构建（含测试）
./gradlew build -x test        # 跳过测试
./gradlew bootJar              # Spring Boot 可执行 jar
./gradlew test                 # 跑测试
./gradlew dependencies         # 依赖树
./gradlew :模块:build           # 指定模块
./gradlew clean                # 清理
```

## 多 JDK（toolchain）

```groovy
java { toolchain { languageVersion = JavaLanguageVersion.of(17) } }
```

toolchain 比依赖 shell `JAVA_HOME` 更可靠，多模块/多版本优先用它。

## 约定

- 一律用 `./gradlew`（wrapper），不用本机全局 gradle，避免版本漂移。
- 依赖走私服，凭据用环境变量/`~/.gradle` 注入，不进 git。
- 构建前确认 JDK 版本（见 `jdk-multiversion.md`）。
