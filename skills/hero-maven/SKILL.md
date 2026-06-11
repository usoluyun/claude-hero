---
name: hero-maven
description: 当用户提到 maven、mvn、构建、依赖管理、settings.xml、私服配置时触发。
---

# Maven 团队约定

## settings.xml（`~/.m2/settings.xml`）

私服镜像 + 代理。**真实地址/凭据按内部环境填，不要提交真实值到本仓库。**

```xml
<settings>
  <mirrors>
    <mirror>
      <id>team-nexus</id>
      <name>内部私服</name>
      <url>https://nexus.内网域名/repository/maven-public/</url>
      <mirrorOf>*</mirrorOf>
    </mirror>
  </mirrors>

  <servers>
    <server>
      <id>team-nexus</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASS}</password>
    </server>
  </servers>

  <!-- 代理：命令行走 7890；内网域名加 nonProxyHosts -->
  <proxies>
    <proxy>
      <id>http-proxy</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>127.0.0.1</host>
      <port>7890</port>
      <nonProxyHosts>*.yaduo.com|*.at-our.com|localhost|127.0.0.1</nonProxyHosts>
    </proxy>
  </proxies>
</settings>
```

> 私服一般在内网，多数情况走私服**不需要**外网代理；代理主要给少数需翻墙的插件/依赖。
> 按实际网络决定是否开 `<proxies>`。

## 常用命令

```bash
mvn -v                         # 确认 Maven 与 JDK 版本
mvn clean package -DskipTests  # 打包跳过测试（团队约定：本地快速构建可跳，CI 不跳）
mvn clean install -pl 模块 -am # 只构建某模块及其依赖
mvn test                       # 跑测试
mvn dependency:tree            # 依赖树（排冲突/查 CVE 依赖）
mvn versions:display-dependency-updates  # 可升级依赖
```

## 多 JDK（toolchains）

见 `jdk-multiversion.md`。用 `~/.m2/toolchains.xml` + `maven-toolchains-plugin` 锁定模块编译
JDK，避免依赖 shell 的 `JAVA_HOME`。

## 约定

- 依赖统一走私服，版本对齐父 pom / BOM，禁止随手引不同版本。
- `-DskipTests` 仅限本地快速验证；提交/CI 必须跑测试。
- 构建前确认 `java -version` 与项目要求一致（见 `jdk-multiversion.md`）。
