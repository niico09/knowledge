# Streaming Tool Executor (Mid-Stream Execution)

## Definición

El **StreamingToolExecutor** es el componente que permite iniciar la ejecución de tools antes de que el modelo termine de generar su respuesta completa. Mientras el modelo aún está emitiendo tokens, el sistema parsea el stream y cuando detecta un tool call JSON completo, comienza su ejecución en paralelo.

## El Problema del Modelo Secuencial

### Sin Mid-Stream Execution

```
T=0:    Modelo empieza a generar respuesta
T=0-10: Modelo genera tokens lentamente (10 segundos total)
T=10:   Modelo termina, todos los tool calls conocidos
T=10-12: Tool 1 ejecuta (Read file.ts)
T=12-14: Tool 2 ejecuta (Grep in file.ts)
T=14-16: Tool 3 ejecuta (Bash git status)
T=16:    Todos los resultados disponibles

Total: 16 segundos
```

### Con Mid-Stream Execution

```
T=0:    Modelo empieza a generar respuesta
T=0-2:  Modelo genera tool call 1 (input completo en stream)
T=2:     StreamingToolExecutor detecta JSON completo → inicia Tool 1
T=2-4:  Tool 1 ejecuta EN PARALELO con generación de modelo
T=4-6:  Modelo genera tool call 2 → inicia Tool 2
T=6-8:  Modelo genera tool call 3 → inicia Tool 3
T=6-8:  Tool 1 ya terminó, Tool 2 empieza
T=8-10: Tool 2 termina, Tool 3 sigue corriendo
T=10:    Modelo termina, Tool 3 termina
T=10:    Todos los resultados disponibles

Total: 10 segundos (6 segundos de tool execution ocultos por generación)
Ahorro: 6 segundos por turno
```

## Arquitectura del StreamingToolExecutor

```typescript
class StreamingToolExecutor {
  private buffer: string = '';
  private currentToolCall: ParsedToolCall | null = null;
  private pendingTools: Map<string, ToolExecution> = new Map();
  private resultsOrder: string[] = []; // Maintain insertion order
  private abortController: AbortController;

  constructor(private deps: ToolExecutorDeps) {
    this.abortController = new AbortController();
  }

  // El executor recibe el stream de eventos del modelo
  async *execute(
    modelStream: AsyncGenerator<ModelEvent>
  ): AsyncGenerator<ExecutorEvent> {
    for await (const event of modelStream) {
      yield { type: 'model-event', event };

      // Parsear tool calls del stream
      const toolCalls = this.parseFromEvent(event);

      for (const toolCall of toolCalls) {
        if (toolCall.isComplete) {
          // JSON COMPLETO — INICIAR EJECUCIÓN INMEDIATAMENTE
          const execution = this.startExecution(toolCall);
          this.pendingTools.set(toolCall.id, execution);
          this.resultsOrder.push(toolCall.id);
        }
      }
    }

    // Cuando el stream del modelo termina, wait for pending tools
    yield* this.waitForPendingResults();
  }

  private startExecution(toolCall: ToolCall): ToolExecution {
    // Crear un AbortController específico para este tool
    const toolAbort = new AbortController();

    // Iniciar ejecución ASINCRONA
    const promise = this.deps.executeTool(toolCall, {
      signal: toolAbort.signal,
      // Link al abort del parent query
      parentAbort: this.abortController.signal
    });

    return {
      toolCall,
      promise,
      abort: toolAbort,
      startedAt: Date.now()
    };
  }
}
```

## Cómo Detecta tool Calls Completos

### Parser de JSON Incremental

```typescript
class ToolCallParser {
  private buffer = '';

  // El stream llega como tokens/strings parciales
  parse(chunk: string): ParsedToolCall | null {
    this.buffer += chunk;

    // Intentar parsear JSON del buffer
    // Esto funciona porque el tool call viene como JSON válido

    try {
      // Primer paso: verificar si empieza con marker de tool call
      if (!this.buffer.includes('"tool_call"') && !this.buffer.includes('"name"')) {
        return null; // No es un tool call todavía
      }

      // Segundo paso: intentar parsear
      const parsed = JSON.parse(this.buffer);

      // Tercer paso: verificar que esté completo
      if (this.isComplete(parsed)) {
        this.buffer = ''; // Reset para siguiente tool call
        return parsed;
      }

    } catch (e) {
      // JSON incompleto todavía, continuar buffering
    }

    return null;
  }

  private isComplete(parsed: any): boolean {
    // Verificar que el tool call tenga todos los campos necesarios
    return (
      parsed.name &&
      parsed.arguments &&
      typeof parsed.arguments === 'object'
    );
  }
}
```

## Manejo de Errores

### Cuando Un Tool Falla Fatalmente

```typescript
async function handleToolFailure(
  toolId: string,
  error: Error,
  execution: ToolExecution
): Promise<void> {
  // 1. Marcar el tool como fallido
  execution.reject(error);

  // 2. Si es error fatal, abortar siblings
  if (isFatalError(error)) {
    // Abortar todos los tools siblings que estén corriendo
    for (const [id, sibling] of this.pendingTools) {
      if (id !== toolId && !sibling.isDone) {
        sibling.abort.abort();
      }
    }

    // 3. También abortar el parent query
    this.abortController.abort();

    // 4. El modelo recibirá el error y podrá recover
  }
}
```

### siblingAbortController en Acción

```typescript
async function executeToolBatch(
  tools: ToolCall[],
  deps: ToolDeps
): Promise<ToolResult[]> {
  const batchAbort = new AbortController();
  const results: ToolResult[] = [];

  // Map para mantener orden
  const resultMap = new Map<string, ToolResult>();

  const promises = tools.map((tool, index) =>
    deps.executeTool(tool, { signal: batchAbort.signal })
      .then(result => {
        resultMap.set(tool.id, result);
        return result;
      })
      .catch(error => {
        if (isFatalError(error)) {
          // Error fatal — abortar siblings
          batchAbort.abort();
          resultMap.set(tool.id, { error, fatal: true });
        }
        throw error; // Para que Promise.all también rejeite
      })
  );

  // Esperar todos
  try {
    await Promise.all(promises);
  } catch (e) {
    // Algunos fallaron
  }

  // Retornar en orden original
  return tools.map(tool => resultMap.get(tool.id));
}
```

## Múltiples Tool Calls Simultáneos

### Scenario: 5 Read Calls en Paralelo

```typescript
// El modelo quiere leer 5 archivos
// ToolCall 1: Read("src/a.ts")
// ToolCall 2: Read("src/b.ts")
// ToolCall 3: Read("src/c.ts")
// ToolCall 4: Read("src/d.ts")
// ToolCall 5: Read("src/e.ts")

async function* handleReadBatch(
  modelStream: AsyncGenerator<ModelEvent>
): AsyncGenerator<ExecutorEvent> {
  const reads: ToolCall[] = [];
  const readPromises: Map<string, Promise<ToolResult>> = new Map();

  for await (const event of modelStream) {
    if (event.type === 'tool-call-complete') {
      if (event.tool === 'Read') {
        reads.push(event.toolCall);

        // INICIAR EJECUCIÓN INMEDIATAMENTE
        // 5 reads en paralelo
        readPromises.set(
          event.toolCall.id,
          executeTool(event.toolCall) // No esperar a los demás
        );
      }
    }

    yield event; // Re-yield al consumer
  }

  // Esperar resultados y yield en orden
  for (const tool of reads) {
    const result = await readPromises.get(tool.id);
    yield { type: 'tool-result', toolId: tool.id, result };
  }
}
```

## Ordering de Resultados

### Problema: Race Condition

```
Tool 1: Read("large-file.ts") → termina en T=100ms
Tool 2: Read("small-file.ts") → termina en T=5ms
Tool 3: Read("medium-file.ts") → termina en T=30ms

Orden de terminación: 2, 3, 1
Pero el modelo espera resultados en orden: 1, 2, 3
```

### Solución: Promise FIFO Queue

```typescript
class ResultOrderer {
  private pending: Map<string, Promise<ToolResult>> = new Map();
  private order: string[] = [];

  add(id: string, promise: Promise<ToolResult>): void {
    this.order.push(id);
    this.pending.set(id, promise);
  }

  async *waitInOrder(): AsyncGenerator<{ id: string; result: ToolResult }> {
    for (const id of this.order) {
      const result = await this.pending.get(id);
      this.pending.delete(id);
      yield { id, result };
    }
  }
}
```

## Fallback a Non-Streaming

### Cuándo Ocurre

Si el stream del modelo falla (network error, server error), el executor hace fallback a non-streaming:

```typescript
async function executeWithFallback(
  messages: Message[],
  deps: ToolDeps
): AsyncGenerator<ExecutorEvent> {
  let events: ModelEvent[] = [];
  let streamFailed = false;

  try {
    // Intentar streaming
    const stream = deps.callModel(messages, { stream: true });

    for await (const event of stream) {
      if (isCompleteToolCall(event)) {
        const result = await deps.executeTool(event.toolCall);
        yield { type: 'tool-result', result };
      }
      events.push(event);
    }
  } catch (streamError) {
    streamFailed = true;
    deps.logger.warn('Stream failed, falling back to non-streaming');

    // Discard pending tools
    this.pendingTools.clear();

    // Generate synthetic errors para tools en flight
    for (const [id, execution] of this.pendingTools) {
      yield {
        type: 'tool-error',
        toolId: id,
        error: 'Stream interrupted, falling back'
      };
    }

    // Retry sin streaming
    const response = await deps.callModel(messages, { stream: false });

    // Ejecutar tools del response completo
    for (const toolCall of response.toolCalls) {
      const result = await deps.executeTool(toolCall);
      yield { type: 'tool-result', result };
    }
  }
}
```

## Beneficios Cuantificados

### Sesión Típica de Coding

```
Sesión de 1 hora
50 turns totales
2-3 tool calls por turn promedio

CON MID-STREAM:
  Ahorro: 2-5 segundos por turn × 50 turns = 100-250 segundos
  = 2-4 minutos de espera de usuario REDUCIDOS

SIN MID-STREAM:
  El usuario ve el agent "pensando" por más tiempo
  Percepción de agent más lento
```

### Multi-Tool Turns

```
Turn con 5 tool calls:
  Sin mid-stream: 10s generación + 5s tools = 15s total
  Con mid-stream: 10s generación + 3s tools overlapped = 11s total
  Ahorro: 4 segundos

Turn con 10 tool calls:
  Sin: 10s + 10s = 20s
  Con: 10s + 5s overlapped = 12s
  Ahorro: 8 segundos
```

## Limitaciones

1. **No funciona para todos los tools**: Algunos tools dependen del resultado de otros
2. **Memory pressure**: Los tool results se guardan pending hasta que el stream termina
3. **Error propagation**: Si el stream falla, hay overhead de fallback
4. **Complex tool dependencies**: Si Tool B necesita output de Tool A, no se pueden paralelizar

## Referencias

- **[[streaming]]**: El contexto de streaming del modelo
- **[[tool-execution]]**: La ejecución de tools en general
- **[[concurrency-classification]]**: Read-only vs write tools
- **[[async-generators]]**: El patrón que hace esto posible
