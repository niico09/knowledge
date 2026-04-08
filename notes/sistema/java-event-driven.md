---
title: Java Event-Driven — Rules
created: 2026-03-26
updated: 2026-03-26
tags: [Java, Kafka, SpringCloudStream, EventDriven, Rules]
sources:
  - "Java 17+ Notebook"
status: synthesized
last_lint: 2026-04-07
---

# Java Event-Driven — Rules

Guidelines para construir event-driven microservices con Java 21, Spring Boot 3.x, Spring Cloud Stream y Apache Kafka.

## Scope

- `*Config.java`
- `*Consumer.java`
- `*Producer.java`
- `*IntegrationTest.java`
- `application.yml` / `application.properties`

## Reglas

### 1. Functional Programming Model (REQUIRED)

Usar interfaces funcionales de Java como Spring `@Bean`s. **Nunca usar `@StreamListener`** (deprecated).

```java
@Configuration
public class KafkaEventConfig {
    @Bean
    public Supplier<OrderEvent> orderEventProducer() {
        return () -> new OrderEvent(UUID.randomUUID().toString(), "CREATED");
    }

    @Bean
    public Function<OrderEvent, ProcessedOrder> orderProcessor() {
        return order -> new ProcessedOrder(order.id(), "PROCESSED");
    }

    @Bean
    public Consumer<ProcessedOrder> orderConsumer(OrderService orderService) {
        return order -> orderService.handle(order);
    }
}
```

### 2. Avro + Schema Registry

```yaml
spring:
  cloud:
    stream:
      kafka:
        binder:
          producer-properties:
            schema.registry.url: http://localhost:8081
            value.serializer: io.confluent.kafka.serializers.KafkaAvroSerializer
          consumer-properties:
            schema.registry.url: http://localhost:8081
            value.deserializer: io.confluent.kafka.serializers.KafkaAvroDeserializer
            specific.avro.reader: true
```

### 3. Consumer Group (REQUIRED)

```yaml
spring:
  cloud:
    stream:
      bindings:
        orderConsumer-in-0:
          destination: processed-orders
          group: order-processing-group
```

### 4. Idempotent Consumers

```java
@Service
public class OrderService {
    @Transactional
    public void handle(ProcessedOrder order) {
        if (eventRepository.existsById(order.eventId())) {
            log.warn("Event {} already processed. Skipping.", order.eventId());
            return;
        }
        processBusinessRules(order);
        eventRepository.save(new ProcessedEventRecord(order.eventId()));
    }
}
```

### 5. Dead-Letter Topic + RetryTemplate

```yaml
spring:
  cloud:
    stream:
      kafka:
        bindings:
          orderConsumer-in-0:
            consumer:
              enableDlq: true
              dlqName: processed-orders-dlq
```

### 6. Testing con @EmbeddedKafka

```java
@SpringBootTest
@EmbeddedKafka(partitions = 1, brokerProperties = { "listeners=PLAINTEXT://localhost:9092" })
class OrderConsumerIntegrationTest {
    @Autowired private StreamBridge streamBridge;

    @Test
    void shouldConsumeOrderSuccessfully() {
        streamBridge.send("orderConsumer-in-0", new ProcessedOrder(UUID.randomUUID().toString(), "PROCESSED"));
        verify(orderService, timeout(3000).times(1)).handle(any());
    }
}
```

## Anti-Patterns

- **NO usar `@StreamListener`** — deprecated
- **NO omitir `group`** — causa reprocesamiento de mensajes
- **NO usar plain JSON para esquemas que evolucionan** — usar Avro + Schema Registry
- **NO usar `synchronized` en consumers** — causa Virtual Thread pinning
- **NO dejar poison-pill messages looping** — siempre configurar `enableDlq: true`

## Relacionado

- [[java-spring-ai]] — Spring AI integration
- [[skills-generadas-registry]] — Registry de skills generadas
