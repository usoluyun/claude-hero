---
name: apollo-config
description: Apollo 配置中心接入与使用约定。当涉及 Apollo、配置中心、apollo namespace、灰度配置、配置热更新、@ApolloConfig、@ApolloConfigChangeListener、bootstrap 配置时触发，用于在 Spring Boot 项目里正确接入与读取 Apollo 配置。
---

# Apollo 配置中心（apollo-config）

团队配置中心统一用 Apollo。本 skill 给出接入、读取、热更新、命名与排障约定。

## 何时使用

- 新服务接入 Apollo / 配置 meta server
- 用 `@Value` / `@ConfigurationProperties` / `@ApolloConfig` 读配置
- 需要配置热更新（监听变更）
- 灰度发布配置、多 namespace 组织
- 排查"配置不生效 / 启动读不到配置"

## 依赖与版本

```xml
<dependency>
  <groupId>com.ctrip.framework.apollo</groupId>
  <artifactId>apollo-client</artifactId>
  <version>${apollo-client.version}</version>
</dependency>
```

Spring Boot 启动类或 `application.yml` 开启：

```yaml
apollo:
  bootstrap:
    enabled: true
    namespaces: application,common.redis,common.mq   # 多 namespace 逗号分隔
    eagerLoad:
      enabled: true   # 让 Apollo 在 logging system 初始化前加载（日志相关配置需要）
app:
  id: ${spring.application.name}   # appId 与服务名一致
```

环境 meta server 通过 `apollo.meta` 或 `ENV` + `apollo-env.properties` 指定，**不要硬编码到
代码里**。本地缓存目录默认 `/opt/data/{appId}/config-cache`（容器内注意挂载/权限）。

## 读取配置

```java
// 1) 静态绑定：@Value（配合 @ConfigurationProperties 实现热更新见下）
@Value("${order.timeout:3000}")
private int orderTimeout;

// 2) 类型安全：@ConfigurationProperties
@Component
@ConfigurationProperties(prefix = "order")
public class OrderProps {
    private int timeout = 3000;
    // getter/setter
}

// 3) 直接拿 Config 对象
@ApolloConfig
private Config config;        // application namespace
@ApolloConfig("common.redis")
private Config redisConfig;   // 指定 namespace
```

## 热更新

`@Value` 注入的字段默认**不会**随 Apollo 变更刷新。两种做法：

```java
// A) 监听变更，手动刷新/做动作
@ApolloConfigChangeListener({"application", "common.mq"})
private void onChange(ConfigChangeEvent event) {
    for (String key : event.changedKeys()) {
        log.info("apollo changed: {} = {}", key, event.getChange(key).getNewValue());
    }
}

// B) @ConfigurationProperties + Spring Cloud Context 的 @RefreshScope（配合监听触发 refresh）
@RefreshScope
@RestController
class XxxController { ... }
```

## 团队约定

- **appId = `spring.application.name`**，与 Eureka 注册名保持一致。
- namespace 命名：私有用 `application`；公共配置拆 `common.<域>`（如 `common.redis`、
  `common.mq`、`common.datasource`），多服务共享。
- 敏感配置（密码/密钥）放 Apollo 并设权限，**不要进 git**；代码里只留 key。
- 灰度发布：先建灰度规则按实例 IP/标签下发，验证无误再全量。

## 常见坑

- 日志框架相关配置（如 logging.level）必须开 `eagerLoad`，否则 Apollo 加载晚于日志初始化。
- 容器化时 `config-cache` 目录无写权限 → 启动 warning / 降级；给目录或改 `apollo.cacheDir`。
- `@Value` 不刷新别误以为是 Apollo 没下发，按上面热更新方案处理。
- 多 namespace 漏配 `apollo.bootstrap.namespaces` → 公共配置读不到。
