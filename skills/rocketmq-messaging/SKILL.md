---
name: rocketmq-messaging
description: RocketMQ 消息队列生产消费与可靠性约定。当涉及 RocketMQ、消息队列、MQ、生产者、消费者、顺序消息、事务消息、延迟消息、消息幂等、死信队列、重试、topic/group 命名时触发，用于在 Spring Boot 项目里正确收发消息并保证可靠性。
---

# RocketMQ 消息队列（rocketmq-messaging）

团队消息队列统一用 RocketMQ。本 skill 给出生产/消费模板、消息类型、幂等与可靠性、命名与
排障约定。

## 何时使用

- 接入 RocketMQ 生产/消费
- 选择消息类型（普通/顺序/事务/延迟）
- 保证消费幂等、处理重试与死信
- topic / group 命名与排障

## 依赖与配置

```xml
<dependency>
  <groupId>org.apache.rocketmq</groupId>
  <artifactId>rocketmq-spring-boot-starter</artifactId>
  <version>${rocketmq-spring.version}</version>
</dependency>
```

```yaml
rocketmq:
  name-server: ${rocketmq.nameserver}      # 放 Apollo common.mq，不硬编码
  producer:
    group: order-service-producer
    send-message-timeout: 3000
    retry-times-when-send-failed: 2
```

## 生产者

```java
@Resource RocketMQTemplate rocketMQTemplate;

// 普通（异步/同步）
rocketMQTemplate.convertAndSend("ORDER_CREATED_TOPIC:tagA", orderDTO);
rocketMQTemplate.syncSend("ORDER_CREATED_TOPIC", MessageBuilder
        .withPayload(orderDTO).setHeader("KEYS", orderId).build());

// 顺序（按 hashKey 落同一队列，保证局部有序）
rocketMQTemplate.syncSendOrderly("ORDER_TOPIC", orderDTO, /*hashKey*/ orderId);

// 延迟（RocketMQ 4.x 用固定 18 级延迟；level 3 = 10s）
Message<?> msg = MessageBuilder.withPayload(orderDTO).build();
rocketMQTemplate.syncSend("DELAY_TOPIC", msg, 3000, /*delayLevel*/ 3);

// 事务消息（本地事务 + 半消息）
rocketMQTemplate.sendMessageInTransaction("TX_TOPIC", msg, arg);
```

## 消费者

```java
@Service
@RocketMQMessageListener(
    topic = "ORDER_CREATED_TOPIC",
    consumerGroup = "inventory-service-consumer",
    consumeMode = ConsumeMode.CONCURRENTLY,        // 顺序场景用 ORDERLY
    messageModel = MessageModel.CLUSTERING)
public class OrderCreatedConsumer implements RocketMQListener<OrderDTO> {
    @Override
    public void onMessage(OrderDTO order) {
        // 必须幂等！见下
        if (!idempotent.firstSeen(order.getId())) return;
        // 业务处理；抛异常 => 自动重试
    }
}
```

## 幂等（强制）

消息至少投递一次，**消费端必须幂等**。约定：用业务唯一键（订单号/`KEYS`）+ Redis/DB
去重表判断是否已处理：

```java
// 例：SETNX 占位，带过期
Boolean first = redis.opsForValue().setIfAbsent("mq:consumed:" + msgKey, "1", 24, HOURS);
if (Boolean.FALSE.equals(first)) return;   // 已消费，丢弃
```

## 重试与死信

- 消费抛异常 / 返回失败 → 按 16 次退避重试（CLUSTERING 模式）。
- 重试耗尽进死信队列 `%DLQ%<consumerGroup>`，需**订阅死信告警**并人工/补偿处理。
- 不可重试的业务错误（如参数非法）应捕获并落库告警，避免无意义重试。

## 团队约定

- **topic 命名**：`<业务域>_<事件>_TOPIC`，大写下划线（`ORDER_CREATED_TOPIC`）。
- **group 命名**：`<服务名>-<producer|consumer>`，消费组按"谁消费"命名，不复用。
- 发送必带 `KEYS`（业务唯一键），便于控制台按 key 查消息轨迹。
- nameserver 地址放 Apollo `common.mq`。
- 顺序消息发送用 `Orderly` + 消费 `ORDERLY`，二者要配套。

## 常见坑

- 只在生产端"重试"不能保证不丢，关键链路用**事务消息**或本地消息表。
- 消费幂等缺失 → 重试/重投导致重复扣减、重复下单。
- 顺序消费里单条卡住会阻塞整个队列，要有超时/跳过策略。
- 延迟消息 4.x 只有固定 18 级，任意延迟需 5.x 或自研。
- 死信队列没人管 = 静默丢消息，必须接告警。
