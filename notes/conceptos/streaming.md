# Streaming en Agents

## Definición

**Streaming** es la capacidad de un sistema para transmitir datos incrementalmente conforme se generan, en lugar de esperar a que toda la respuesta esté completa para entregarla. En el contexto de LLM, significa que el modelo emite tokens uno por uno a través de un stream, y el agent puede procesar cada token (o cada grupo de tokens) casi inmediatamente.

## La Diferencia Fundamental

### Request-Response Tradicional (No Streaming)

```
Client: "Responde a mi mensaje"
Client: [espera... 15 segundos... espera...]
Server: "Aquí está tu respuesta completa de una vez"
Client: [recibe todo, lo muestra]
```

El usuario ve:
```
[blank screen por 15 segundos]
[respuesta completa aparece de golpe]
```

### Streaming (Token-by-Token)

```
Client: "Responde a mi mensaje"
Server: [inicia stream]
Server: "Hola" (token 1)
Server: " mundo" (token 2)
Server: " cómo" (token 3)
...
Server: [done]
Client: [va mostrando cada token conforme llegan]
```

El usuario ve:
```
H o l a   m u n d o   c ó m o   e s t á s ...
```

## Streaming en el Contexto de Claude Code

Claude Code usa streaming a dos niveles:

### Nivel 1: Model Streaming

El modelo de lenguaje genera tokens que llegan a través de HTTP chunked transfer encoding:

```typescript
async function* callModelStream(
  messages: Message[],
  options: ModelOptions
): AsyncGenerator<ModelEvent> {
  const response = await fetch('/v1/chat/completions', {
    method: 'POST',
    body: JSON.stringify({
      model: options.model,
      messages: serializeMessages(messages),
      stream: true, // ← Chunked response
      max_tokens: options.maxTokens,
    }),
  });

  // response.body es un ReadableStream
  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    const event = parseSSEMessage(chunk); // SSE format: data: {...}
    yield event;
  }
}

// Tipos de eventos en el stream:
type ModelEvent =
  | { type: 'content-delta', content: string }
  | { type: 'tool-call-start', tool: string }
  | { type: 'tool-call-delta', tool: string, delta: string }
  | { type: 'tool-call-complete', tool: string, input: object }
  | { type: 'stop-reason', reason: string };
```

### Nivel 2: Tool Streaming (Mid-Stream Execution)

Aún más interesante: Claude Code empieza a ejecutar tools antes de que el modelo termine de generar. Esto es **tool streaming** o **mid-stream execution**.

```typescript
async function* agentLoop(deps: AgentDeps) {
  for await (const event of deps.callModelStream(messages)) {
    yield { type: 'model-event', event };

    // MID-STREAM TOOL EXECUTION
    // Si el tool call JSON está completo, ejecutamos INMEDIATAMENTE
    if (isCompleteToolCall(event)) {
      // No esperamos a que el stream de modelo termine
      // Empezamos a ejecutar mientras el modelo sigue generando
      const toolResult = await deps.executeTool(event.toolCall);
      yield { type: 'tool-result', result: toolResult };
    }
  }
}
```

## Por Qué el Streaming Importa

### 1. Responsiveness Percibida

El usuario no mira una pantalla en blanco. Ve al agent "trabajando" — caracteres apareciendo, herramientas ejecutándose.

```
Sin streaming:
[User espera 20 segundos]
[Ve "I analyzed the codebase and found 3 issues"]

Con streaming:
[User ve "I" aparecer]
[Ve "I ana" gradualmente]
[Ve "I analyzed the cod" — sabe que está pensando]
[Respuesta completa en ~20 segundos pero no hubo espera]
```

### 2. Trust y Autonomy

> *"Users who can see what an agent is doing trust it more. Users who trust it give it more autonomy."*

Si看不到el agent trabajando, el usuario tiende a:
- Supervisionar más de cerca (interfiriendo con el trabajo)
- Desconfiar y no darle autonomía
- Cancelar prematuramente

Con streaming visible, el usuario entiende que el agent está procesando, no colgado.

### 3. Tool Execution Mid-Stream (Latency Hiding)

Esta es la ventaja más técnica y menos obvious:

```
ESCENARIO: Turn con 3 tool calls

SIN MID-STREAM:
[Modelo genera...............] → [Tool 1 exec] → [Tool 2 exec] → [Tool 3 exec]
Total: ~10s + 2s + 2s + 2s = 16 segundos

CON MID-STREAM:
[Modelo genera Tool 1 input...........] [Tool 1 exec]
[Modelo genera Tool 2 input...] [Tool 2 exec]
[Modelo genera Tool 3 input...] [Tool 3 exec]
Total: ~10s generación overlapped con ~6s tools = ~12 segundos

AHORRO: 4 segundos por turno con 3 tools
```

### 4. Backpressure Natural

Si el consumer (terminal) no puede procesar tan rápido como el producer genera, el generator pausa. En HTTP streaming tradicional, el servidor seguiría enviando aunque el cliente esté abrumado.

```typescript
// Con async generators:
for await (const token of modelStream()) {
  render(token); // Si render es lento, .next() se llama menos
  // El fetch dentro del generator PAUSA cuando el buffer local se llena
  // Memory se mantiene bounded
}

// Sin generators (buffer manual):
const buffer = [];
for await (const token of modelStream()) {
  buffer.push(token); // Acumula aunque render sea lento
}
// Después de 1 hora: buffer de millones de tokens
```

## Cómo Funciona Técnicamente: Server-Sent Events (SSE)

La mayoria de APIs de LLM usan Server-Sent Events para streaming:

```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

data: {"type": "content-delta", "content": "Hello"}

data: {"type": "content-delta", "content": " world"}

data: {"type": "tool-call-start", "tool": "Read"}

data: {"type": "content-delta", "content": "\nReading file"}

...
```

El cliente parsea cada `data:` line y yield el evento.

## El StreamingToolExecutor en Detalle

Este componente de Claude Code parsea el stream y detecta cuando un tool call JSON está completo:

```typescript
class StreamingToolExecutor {
  private buffer: string = '';
  private currentToolCall: ToolCall | null = null;
  private pendingResults: Map<string, Promise<ToolResult>> = new Map();

  async *execute(
    stream: AsyncGenerator<ModelEvent>,
    deps: ToolDeps
  ): AsyncGenerator<ExecutorEvent> {
    for await (const event of stream) {
      yield { type: 'model-event', event };

      if (event.type === 'tool-call-delta') {
        this.buffer += event.delta;

        // Try parsear JSON
        if (this.isValidJSON(this.buffer)) {
          this.currentToolCall = this.parseToolCall(this.buffer);

          // JSON COMPLETO — START EXECUTION INMEDIATELY
          // No esperamos a que el stream termine
          if (this.isCompleteToolCall(this.currentToolCall)) {
            const toolId = this.currentToolCall.id;

            // Guardar promise para mantener orden
            this.pendingResults.set(
              toolId,
              deps.executeTool(this.currentToolCall)
            );
          }
        }
      }

      if (event.type === 'content-delta') {
        // Output de texto normal — yield inmediatamente
        yield { type: 'text-delta', content: event.content };
      }
    }

    // Cuando el stream termina, yield tool results en orden
    for (const [toolId, resultPromise] of this.pendingResults) {
      const result = await resultPromise;
      yield { type: 'tool-result', toolId, result };
    }
  }
}
```

## Casos Edge y Cómo Se Manejan

### 1. Tool Fails in Parallel Batch

```typescript
// Si tool 2 falla, siblingAbortController mata siblings
const siblingAbort = new AbortController();

try {
  const results = await Promise.all([
    executeTool(tool1, { signal: siblingAbort.signal }),
    executeTool(tool2, { signal: siblingAbort.signal }), // Falla
    executeTool(tool3, { signal: siblingAbort.signal }),
  ].map(p => p.catch(e => {
    if (isFatalError(e)) {
      siblingAbort.abort(); // Mata tool1 y tool3
      throw e;
    }
    return e; // Non-fatal, continúa
  })));
} catch (e) {
  // Parent query alive, conversation continues
  // El modelo recibe el error y puede recover
}
```

### 2. Stream Fails, Fallback to Non-Streaming

```typescript
try {
  for await (const event of streamingCall()) {
    yield event;
  }
} catch (streamError) {
  // Descartar queued tools
  pendingTools.clear();

  // Generar errores sintéticos para lo que estaba en flight
  for (const tool of inFlightTools) {
    yield {
      type: 'tool-error',
      tool: tool.name,
      error: 'Stream interrupted, falling back'
    };
  }

  // Fallback a non-streaming para preservar retry logic
  yield* nonStreamingCall();
}
```

### 3. Results en Original Order

Aunque tool 2 termine antes que tool 1, los resultados se yield en el orden original para mantener coherencia narrativa:

```typescript
// pendingResults es un Map que mantiene orden de insertion
const pendingResults = new Map([
  ['tool-1', executeTool(tool1)], // Empezó primero
  ['tool-2', executeTool(tool2)], // Terminó primero
  ['tool-3', executeTool(tool3)], // Empezó tercero
]);

// Cuando resolved, yield en orden de tool call, no de completion
for (const [toolId, resultPromise] of pendingResults) {
  const result = await resultPromise;
  yield { type: 'tool-result', toolId, result };
}
```

## Streaming y la UI

La UI de Claude Code está construida sobre una fork de Ink (React para terminals). Muestra:

```
┌─────────────────────────────────────────────────────────────┐
│  > Writing function to process user data                    │
│    ↳ Read(file.ts)                                          │
│    ↳ Grep(function) in file.ts                              │
│    ↳ Edit(file.ts, ...)                      [running...]   │
│                                                             │
│  Context: 45% │ Cost: $0.002 │ Model: claude-opus-4-5       │
└─────────────────────────────────────────────────────────────┘
```

El streaming permite mostrar cada acción conforme ocurre, no al final.

## Contrast: Full Buffering vs Streaming

```typescript
// ❌ Full buffering: todo al final
async function bufferedAgent(messages) {
  const response = await fetch('/api/chat', {
    body: JSON.stringify({ messages, stream: false })
  });

  const fullResponse = await response.json();
  // El usuario esperó 20 segundos para ver NADA
  // Ahora muestra todo de golpe

  return fullResponse;
}

// ✅ Streaming: Yield incrementally
async function* streamingAgent(messages) {
  const stream = await fetch('/api/chat', {
    body: JSON.stringify({ messages, stream: true })
  });

  for await (const chunk of stream) {
    yield parseChunk(chunk); // Usuario ve cada pedazo
  }
}
```

## Impacto en Performance

| Métrica | No Streaming | Streaming |
|---------|-------------|-----------|
| Time to first token | 10-30s | <1s típicamente |
| Perceived latency | Alta | Baja |
| Memory (largo session) | Crece con buffer | Bounded |
| User trust | Baja | Mayor |
| Cancelability | Difícil | Natural |

## Referencias

- **[[async-generators]]**: El tipo que hace streaming posible
- **[[backpressure]]**: El beneficio colateral de generators + streaming
- **[[mid-stream-execution]]**: Ejecutar tools antes de que el stream termine
- **[[cancellation]]**: Cómo el streaming permite cancelación limpia
- **[[tool-execution]]**: Los tools que se ejecutan concurrentemente
