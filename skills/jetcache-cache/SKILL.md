---
name: jetcache-cache
description: JetCache 缓存接入与使用约定（底层 Redis）。当涉及 JetCache、缓存、@Cached、@CreateCache、@CacheInvalidate、@CacheUpdate、两级缓存、本地缓存、Redis 缓存、缓存穿透/击穿、key 约定时触发，用于在 Spring Boot 项目里用 JetCache 注解式缓存。
---

# JetCache 缓存（jetcache-cache）

团队缓存统一用 JetCache（注解式，底层 Redis）。本 skill 给出接入、注解用法、两级缓存、
key 约定与防穿透/击穿约定。

## 何时使用

- 给方法/对象加缓存（注解 `@Cached` 或编程式 `@CreateCache`）
- 配两级缓存（本地 + Redis）
- 缓存更新/失效（`@CacheUpdate` / `@CacheInvalidate`）
- 处理缓存穿透/击穿/雪崩、key 设计

## 依赖与配置

```xml
<dependency>
  <groupId>com.alicp.jetcache</groupId>
  <artifactId>jetcache-starter-redis</artifactId>
  <version>${jetcache.version}</version>
</dependency>
```

```yaml
jetcache:
  statIntervalMinutes: 15
  areaInCacheName: false
  local:
    default:
      type: linkedhashmap        # 本地缓存
      keyConvertor: fastjson2
      limit: 1000
  remote:
    default:
      type: redis
      keyConvertor: fastjson2
      valueEncoder: java          # 或 kryo；跨服务共享缓存用 json 更稳
      valueDecoder: java
      poolConfig:
        maxTotal: 50
      host: ${redis.host}         # 放 Apollo common.redis
      port: ${redis.port}
```

启动类：`@EnableMethodCache(basePackages = "com.team")` + `@EnableCreateCacheAnnotation`。

## 注解式（@Cached）

```java
@Cached(name = "user:", key = "#userId", expire = 30, timeUnit = TimeUnit.MINUTES,
        cacheType = CacheType.BOTH)        // BOTH = 本地 + Redis 两级
@CacheRefresh(refresh = 10, timeUnit = TimeUnit.MINUTES)   // 自动刷新，防击穿
@CachePenetrationProtect                   // 多线程只放一个去加载，防击穿
public UserDTO getUser(Long userId) { ... }

@CacheUpdate(name = "user:", key = "#user.id", value = "#user")
public void updateUser(UserDTO user) { ... }

@CacheInvalidate(name = "user:", key = "#userId")
public void deleteUser(Long userId) { ... }
```

## 编程式（@CreateCache）

```java
@CreateCache(name = "stock:", expire = 5, timeUnit = TimeUnit.MINUTES, cacheType = CacheType.REMOTE)
private Cache<String, Integer> stockCache;

Integer v = stockCache.computeIfAbsent(sku, k -> loadFromDb(k));   // 自带防穿透
stockCache.put(sku, 100);
stockCache.remove(sku);
```

## 团队约定

- **key/name 命名**：`name` 用 `<域>:` 前缀（`user:`、`stock:`），`key` 用业务主键，最终
  Redis key 形如 `user:123`，便于扫描与排障。
- **cacheType**：读多写少、可容忍短暂不一致 → `BOTH`；强一致/跨实例共享 → `REMOTE`。
- 必设 `expire`，**禁止永不过期**；热点 key 配 `@CacheRefresh` + `@CachePenetrationProtect`。
- `keyConvertor` 统一 `fastjson2`；跨服务共享的缓存 `valueEncoder` 用 json，避免 Java 序列化
  版本不兼容。
- Redis 连接信息放 Apollo `common.redis`，不硬编码。

## 防穿透 / 击穿 / 雪崩

- **穿透**（查不存在的 key）：`computeIfAbsent` 缓存空值（短 TTL）或布隆过滤器。
- **击穿**（热点 key 失效瞬间打 DB）：`@CachePenetrationProtect` + `@CacheRefresh`。
- **雪崩**（大量 key 同时失效）：过期时间加随机抖动，别用统一 TTL。

## 常见坑

- `BOTH` 两级缓存下，本地缓存有 TTL 内的不一致窗口，强一致场景别用 BOTH。
- 改了 DTO 字段 + Java 序列化（kryo/java）→ 旧缓存反序列化失败，发布时考虑 key 版本或 json。
- 忘记 `@EnableMethodCache` 的 `basePackages` → 注解不生效。
- 本地缓存 `limit` 太小频繁淘汰，太大占内存，按热点量评估。
