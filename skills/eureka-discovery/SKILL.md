---
name: eureka-discovery
description: Eureka 服务发现接入与服务间调用约定。当涉及 Eureka、服务发现、服务注册、注册中心、Feign 调用、@LoadBalanced、Ribbon、服务下线慢、自我保护时触发，用于在 Spring Cloud 项目里正确注册服务并做服务间调用。
---

# Eureka 服务发现（eureka-discovery）

团队服务发现统一用 Eureka。本 skill 给出注册、调用、健康检查、命名与排障约定。

## 何时使用

- 新服务注册到 Eureka
- 服务间调用（Feign / RestTemplate + @LoadBalanced）
- 配置续约/拉取间隔、健康检查
- 排查"调不到下游 / 下线后还被调用 / 注册不上"

## 依赖与配置

```xml
<dependency>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

```yaml
spring:
  application:
    name: order-service          # 注册名，全大写在控制台显示；与 Apollo appId 一致
eureka:
  client:
    service-url:
      defaultZone: ${eureka.zone}/eureka/   # 多节点逗号分隔，地址放 Apollo
    registry-fetch-interval-seconds: 10      # 拉取注册表间隔
  instance:
    prefer-ip-address: true                  # 用 IP 注册，容器/多网卡更稳
    instance-id: ${spring.cloud.client.ip-address}:${server.port}
    lease-renewal-interval-in-seconds: 10    # 续约间隔
    lease-expiration-duration-in-seconds: 30 # 超时剔除
```

启动类加 `@EnableDiscoveryClient`（新版本可省略）。

## 服务间调用

```java
// 1) Feign（推荐）
@FeignClient(name = "inventory-service")   // name = 目标服务的 spring.application.name
public interface InventoryClient {
    @GetMapping("/api/stock/{sku}")
    StockDTO getStock(@PathVariable("sku") String sku);
}

// 2) RestTemplate + 负载均衡
@Bean
@LoadBalanced
RestTemplate restTemplate() { return new RestTemplate(); }
// 调用用服务名作 host：http://inventory-service/api/stock/{sku}
```

容错：Feign 配 `connectTimeout`/`readTimeout`，结合熔断/降级（Sentinel/Resilience4j），
**不要无超时的远程调用**。

## 团队约定

- `spring.application.name` 用小写中划线（`order-service`），与 Apollo appId 一致。
- 注册中心地址、zone 放 Apollo（`common.discovery`），不硬编码。
- 调用一律走服务名，不写死 IP/端口。
- 所有 Feign 接口必须设超时 + 降级。

## 常见坑

- **下线慢**：Eureka 多级缓存（client 30s 拉取 + ribbon 缓存）导致实例下线后仍被调用几十秒。
  发布期可缩短 `registry-fetch-interval-seconds`、主动 `/eureka/apps` 注销，或配合优雅停机
  （`/actuator/shutdown` 前先从注册表摘除）。
- **自我保护**：网络抖动时 Eureka Server 触发自我保护不再剔除实例 → 调到死节点。生产按需
  关闭或调阈值，并保证客户端有重试/降级。
- `prefer-ip-address` 不开，在容器里会注册成 hostname 调不通。
- 多网卡注册到内网不可达 IP → 用 `spring.cloud.inetutils.preferred-networks` 指定网段。
