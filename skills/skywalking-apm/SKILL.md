---
name: skywalking-apm
description: SkyWalking APM 接入与链路追踪约定。当涉及 SkyWalking、APM、链路追踪、TraceId、调用链、javaagent、日志关联 traceId、@Trace、跨线程透传、性能埋点时触发，用于在 Java 服务里正确接入 SkyWalking 并打通日志与链路。
---

# SkyWalking APM（skywalking-apm）

团队 APM 统一用 SkyWalking。本 skill 给出 agent 接入、服务命名、日志关联、自定义埋点与
跨线程透传约定。

## 何时使用

- 服务接入 SkyWalking agent（`-javaagent`）
- 日志里打印 TraceId 以便和链路关联
- 自定义埋点（`@Trace` / Tag）
- 跨线程 / 线程池 / 异步导致链路断裂的排查

## agent 接入

SkyWalking 是无侵入 java agent，启动参数挂载：

```bash
java -javaagent:/opt/skywalking/agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=order-service \
     -Dskywalking.collector.backend_service=oap-host:11800 \
     -jar app.jar
```

或用环境变量（容器推荐）：

```bash
SW_AGENT_NAME=order-service
SW_AGENT_COLLECTOR_BACKEND_SERVICES=oap-host:11800
```

> agent 包、OAP 地址不进业务镜像/代码，由部署层注入（参考部署约定）。

## 日志关联 TraceId

加依赖 + logback pattern，把 TraceId 打进每行日志，方便从日志跳链路：

```xml
<dependency>
  <groupId>org.apache.skywalking</groupId>
  <artifactId>apm-toolkit-logback-1.x</artifactId>
  <version>${skywalking.toolkit.version}</version>
</dependency>
```

```xml
<!-- logback-spring.xml -->
<conversionRule conversionWord="tid"
    converterClass="org.apache.skywalking.apm.toolkit.log.logback.v1.x.LogbackPatternConverter"/>
<pattern>%d{HH:mm:ss.SSS} [%tid] [%thread] %-5level %logger{36} - %msg%n</pattern>
```

## 自定义埋点

```java
import org.apache.skywalking.apm.toolkit.trace.Trace;
import org.apache.skywalking.apm.toolkit.trace.Tag;
import org.apache.skywalking.apm.toolkit.trace.TraceContext;

@Trace                         // 让该方法成为独立 span
@Tag(key = "sku", value = "arg[0]")
public StockDTO query(String sku) { ... }

String traceId = TraceContext.traceId();   // 透传给前端/日志
```

## 跨线程透传

线程池/异步会丢失上下文，用 toolkit 包装：

```java
// apm-toolkit-trace 提供
executor.execute(RunnableWrapper.of(() -> { ... }));
Callable<T> c = CallableWrapper.of(() -> ...);
// @Async 场景用 apm-spring-annotation-plugin / 配置 cross-thread
```

## 团队约定

- **`SW_AGENT_NAME` = `spring.application.name`**，与 Eureka/Apollo 一致，链路里服务名统一。
- 日志 pattern 一律带 `[%tid]`，异常日志必须能反查链路。
- 业务关键方法（外部调用、慢操作）加 `@Trace` + 业务 Tag（订单号/SKU），便于过滤。
- agent 版本与 OAP 版本匹配，升级前查兼容矩阵。

## 常见坑

- 自定义线程池不包装 → 链路断、TraceId 变 `N/A`。
- agent 与 OAP 大版本不匹配 → 数据上报异常。
- `[%tid]` 在无链路上下文时显示 `TID:N/A` 属正常（非请求线程）。
- 高 QPS 下采样率过高影响性能，按需配 `agent.sample_n_per_3_secs`。
