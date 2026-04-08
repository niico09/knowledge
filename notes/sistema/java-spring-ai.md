---
title: Java Spring AI — SKILL
created: 2026-03-26
updated: 2026-03-26
tags: [Java, SpringAI, RAG, FunctionCalling, Skill]
sources:
  - "Java 17+ Notebook"
status: synthesized
last_lint: 2026-04-07
---

# Java Spring AI — SKILL

Implementación de capacidades de IA generativa en Java usando Spring AI 1.0.

## Stack

- Java 21+, Spring Boot 3.x, Spring AI 1.0+

## Triggers

- "Implement RAG with Spring AI"
- "Add AI chat capabilities"
- "Integrate vector store"
- "Create an AI tool or function"
- "Use Claude/OpenAI with Spring Boot"

## Patrones Clave

### ChatClient y Advisors API

```java
@Configuration
public class AiConfig {
    @Bean
    public ChatClient chatClient(ChatClient.Builder builder, ChatMemory chatMemory) {
        return builder
            .defaultSystem("You are a helpful, concise assistant.")
            .defaultAdvisors(
                new PromptChatMemoryAdvisor(chatMemory),
                new SimpleLoggerAdvisor()
            )
            .build();
    }

    @Bean
    public ChatMemory chatMemory() {
        return new InMemoryChatMemory();
    }
}
```

**Anti-pattern:** No concatenar conversation history manualmente. Usar siempre `PromptChatMemoryAdvisor`.

### RAG Pipelines

```java
@Service
public class RagService {
    private final ChatClient chatClient;

    public RagService(ChatClient.Builder builder, VectorStore vectorStore) {
        this.chatClient = builder
            .defaultAdvisors(new QuestionAnswerAdvisor(
                vectorStore,
                SearchRequest.defaults()
                    .withTopK(6)
                    .withSimilarityThreshold(0.8)
            ))
            .build();
    }

    public String askWithContext(String question) {
        return chatClient.prompt()
            .user(question)
            .call()
            .content();
    }
}
```

### Function Calling con @Tool

```java
@Service
public class BookingTools {
    @Tool(description = "Book an appointment for a given date and time.")
    public String bookAppointment(String name, String isoDateTime) {
        return "Appointment successfully booked for " + name + " at " + isoDateTime;
    }
}
```

**Anti-pattern:** No omitir descripciones detalladas en métodos `@Tool`. El LLM depende del texto.

### Structured Output con Records

```java
public record DogAdoptionResponse(String dogName, String breed, boolean isAvailable) {}

public DogAdoptionResponse analyzeDog(String query) {
    return chatClient.prompt()
        .user(query)
        .call()
        .entity(DogAdoptionResponse.class);
}
```

**Anti-pattern:** No parsear JSON manualmente. Usar `.entity(Class)`.

## Best Practices

- **Token Usage:** Usar métrica `gen_ai.client.token.usage` via Micrometer/Actuator
- **Virtual Threads:** `spring.threads.virtual.enabled=true` para llamadas IO-bound
- **ETL Pipelines:** `TokenTextSplitter` + `DocumentReader` para PDFs, JSONs
- **Dynamic Filtering:** `FILTER_EXPRESSION` para filtrar búsquedas por usuario

## Relacionado

- [[java-event-driven]] — Event-driven microservices
- [[asset-generator-v3]] — Asset Generator que crea estas skills
