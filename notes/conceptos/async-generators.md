# Async Generators

## Definición

Un **async generator** en TypeScript/JavaScript es una función declarada con `async function*` que puede pausar su ejecución en puntos de `yield`, emitiendo valores asíncronos a lo largo del tiempo en lugar de retornarlos todos de una vez.

A diferencia de una función `async` normal que retorna una `Promise<value>`, un async generator retorna un `AsyncGenerator` que produce valores a través del tiempo cuando se itera sobre él con `for await...of` o se llama `.next()` manualmente.

```typescript
// Función async normal: retorna todo de una vez
async function callModel(messages): Promise<LLMResponse> {
  const response = await fetch('/api/chat');
  return response.json(); // Todo o nada
}

// Async generator: emite valores incrementalmente
async function* streamModel(messages): AsyncGenerator<StreamEvent> {
  const response = await fetch('/api/chat/stream', {
    body: JSON.stringify(messages)
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    // Yield por cada chunk recibido — la ejecución PAUSA aquí
    // hasta que el consumer llame .next() nuevamente
    yield parseChunk(chunk);
  }
}
```

## El Patrón `function*` (Generator Semántico)

El asterisk después de `function` indica que es un generator. El método `.next()` permite:
- Obtener el siguiente valor: `{ value: T, done: boolean }`
- Enviar un valor al generator (para comunicación bidireccional)
- Lanzar una excepción dentro del generator

```typescript
function* numberGenerator() {
  let n = 0;
  while (true) {
    const increment = yield n; // Yield current, wait for input
    n += increment || 1;
  }
}

const gen = numberGenerator();
gen.next();      // { value: 0, done: false }
gen.next(5);     // { value: 5, done: false }
gen.next(10);    // { value: 15, done: false }
gen.throw(Error); // Lanza dentro del generator
```

## Contexto en Agent Architecture

Claude Code usa `async function* query()` en `query.ts` (1,729 líneas) como el corazón del agent loop. El author del post observó que esta decisión arquitectónica es una de las más importantes del codebase.

Un generator yield **valores en el tiempo**: caracteres de streaming, eventos de tool, resultados parciales, estados de error. El caller consume con `.next()` y puede romper en cualquier momento sin dejar recursos huérfanos.

## Las Cuatro Propiedades Habilitadas

### 1. Streaming

El generator yield `StreamEvent` objects conforme los tokens llegan. El usuario ve character-by-character, no una respuesta en blanco por 10-30 segundos.

```typescript
async function* chat(messages) {
  const stream = await fetchStream('/api/chat', messages);

  // El modelo está generando tokens en "background"
  // Nosotros yielding conforme llegan
  for await (const token of stream) {
    yield { type: 'token', content: token };
  }
}

// Consumer:
for await (const event of chat(initialMessages)) {
  if (event.type === 'token') {
    process.stdout.write(event.content); // Immediate feedback
  }
}
```

Sin generators, tendrías que bufferizar todo el stream en memoria antes de retornar. Con generators, cada token puede procesarse individualmente.

### 2. Cancellation

El caller deja de llamar `.next()`. Un `finally` block corre cleanup automáticamente. `AbortSignal` se propaga a través de cada capa sin necesidad de mecanismos externos.

```typescript
async function* longRunningTask(abortSignal: AbortSignal) {
  try {
    for (let i = 0; i < 1000; i++) {
      const result = await processItem(i, { signal: abortSignal });
      yield { progress: i / 10, result };
    }
  } finally {
    //Cleanup CORRE AUTOMATICAMENTE cuando:
    // 1. El caller sale del for await
    // 2. Se lanza una excepción
    // 3. abortSignal se activa y propagamos
    await releaseResources();
    await closeConnections();
    await persistCheckpoint(i); // Guardar estado para resume
  }
}

// Uso:
const task = longRunningTask(controller.signal);
for await (const event of task) {
  render(event);
  if (userClickedCancel) {
    break; // finally corre, cleanup se hace
  }
}
```

Comparado con while loop:

```typescript
// While loop: cleanup manual
async function badLongRunningTask(onCancel) {
  let i = 0;
  while (true) {
    if (onCancel()) {
      cleanup(); // Debes recordar llamar esto
      return;
    }
    await processItem(i++);
  }
}
```

### 3. Composability

Un generator es una **interfaz universal**. El mismo generator puede ser consumido por múltiples callers sin duplicación:

```typescript
// UN generator, TRES consumers

// 1. REPL UI consumer
async function runREPL() {
  for await (const event of agentLoop()) {
    if (event.type === 'token') renderToken(event.content);
    if (event.type === 'tool-start') showToolIndicator(event.tool);
    if (event.type === 'tool-end') hideToolIndicator();
  }
}

// 2. Sub-agent consumer (para observar sin interferir)
async function runSubAgent(agentLoop, monitor) {
  for await (const event of agentLoop()) {
    monitor.record(event); // Observa todo
    yield event; // Re-yields para consumer externo
  }
}

// 3. Test consumer (mocking trivial)
async function testAgent() {
  const events = [
    { type: 'token', content: 'Hello' },
    { type: 'tool-call', tool: 'Read', input: { file: 'test.js' } },
    { type: 'tool-result', result: 'file content' },
  ];

  async function* mockLoop() { yield* events; }
  // No hay API call, no hay estado global
  for await (const _ of mockLoop()) {}
  assert(mockLlm.receivedCorrectMessages());
}
```

> *"One query() function, three callers, zero duplication."*

### 4. Backpressure

Si el modelo genera más rápido de lo que el consumer puede procesar, el generator **pausa producción cuando el consumer deja de pull**. No hay buffer infinito.

```typescript
// Producer: modelo generando 1000 tokens/segundo
async function* modelStream() {
  while (true) {
    const token = await getNextToken(); // 1000/segundo
    yield token; // Pausa si el consumer no llama .next()
  }
}

// Consumer: terminal renderizando 100 tokens/segundo
for await (const token of modelStream()) {
  render(token); // 100/segundo
  // Si render es lento, .next() se llama menos frecuente
  // El generator PAUSA — no hay buffer growth
  // Memery se mantiene bounded
}
```

En while loops tradicionales, el buffer crece si el producer es más rápido que el consumer. Con generators, la presión hacia atrás es natural.

## Async Generators vs Iteradores Síncronos

| Aspecto | while/for loop | Async Generator |
|---------|----------------|-----------------|
| Retorno | Promise resolve una vez | Stream de valores |
| Cancelación | Manual, propensa a leaks | finally automático |
| Productor/Consumer | Buffer en memoria | Pausa natural |
| Error handling | try-catch global | try-catch por yield |
| Memory | Crece con buffer | Bounded |
| Composition | Difícil | Múltiples consumers |

## Implementación Detallada del Agent Loop de Claude Code

Según el análisis del post, el loop en `query.ts` sigue este patrón:

```typescript
interface QueryDeps {
  callModel: (
    messages: Message[],
    options: CallOptions
  ) => AsyncGenerator<ModelEvent>;
  executeTool: (tool: ToolCall) => Promise<ToolResult>;
  compactionStrategy: CompactionStrategy;
  maxTurns: number;
  abortSignal?: AbortSignal;
}

async function* query(deps: QueryDeps): AsyncGenerator<LoopEvent> {
  let messages: Message[] = [];
  let turn = 0;
  let state: LoopState = 'running';

  while (state === 'running') {
    // ===== PHASE 1: Setup =====
    // Aplicar budgets, validar tokens, evaluar compaction
    const budget = applyToolBudgets(messages);
    if (budget.exceedsLimit) {
      const compacted = await deps.compactionStrategy.run(messages);
      messages = compacted;
    }

    // ===== PHASE 2: Model Invocation (STREAMING) =====
    // Yield stream events mientras el modelo genera
    for await (const event of deps.callModel(messages, {
      signal: deps.abortSignal
    })) {
      yield { type: 'model-event', event };

      // ===== PHASE 4: Tool execution begins MID-STREAM =====
      // Si el tool call JSON está completo, empezamos ejecución
      if (event.type === 'tool-call-ready') {
        const result = await deps.executeTool(event.toolCall);
        yield { type: 'tool-result', result };
      }
    }

    // ===== PHASE 3: Error Recovery =====
    const errorState = handleModelErrors(messages);
    if (errorState.shouldRecover) {
      messages = errorState.recoveryMessages;
      continue; // Retry en siguiente iteration
    }

    // ===== PHASE 5: Continuation Decision =====
    const stopReason = getStopReason(messages);
    if (stopReason === 'stop' || turn >= deps.maxTurns) {
      state = 'done';
    }

    turn++;
    yield { type: 'turn-complete', turn };
  }
}
```

## Por Qué Async Generator > While Loop en Producción

La diferencia entre usar async generators y while loops parece sintáctica, pero tiene implicaciones profundas en producción:

### Escenario: Rate Limit + Long Session

```
Usuario inicia sesión de debugging largo (2 horas).
Sesión tiene 500 tool calls, contexto creciente.
API empieza a dar rate limits (429).
```

**While loop approach:**
```typescript
async function badAgentLoop() {
  while (true) {
    try {
      const response = await callModel(messages);
      const result = executeTools(response);
      messages.push(result);
    } catch (e) {
      if (e.status === 429) {
        // Qué pasa con messages parciales?
        // El stream se cortó a mitad
        // Cómo recovery sin perder contexto?
        await sleep(1000);
        continue;
      }
    }
  }
}
```

**Async generator approach:**
```typescript
async function* goodAgentLoop() {
  let retryCount = 0;

  for await (const event of callModelStreaming(messages)) {
    yield event;

    if (event.type === 'rate-limit') {
      // El finally block del generator puede cleanup
      // Podemos yield un evento de retry
      // El caller decide qué hacer (esperar, fallback a otro modelo, etc)
      yield { type: 'retry-scheduled', delay: calculateBackoff(retryCount++) };
    }
  }
}
```

### Escenario: Memory Leak en Sesión Larga

```
Sesión de 8 horas, 2000+ mensajes.
Sin backpressure, el buffer de while loop crece.
Con async generator, la pausa natural mantiene memory bounded.
```

## Conceptos Relacionados

Un async generator por sí solo no hace un agent. Necesita:

- **[[agent-loop]]**: El loop que lo usa como motor
- **[[streaming]]**: El tipo de evento que yields
- **[[cancellation]]**: El mecanismo deAbortSignal que lo hace cleanly stoppable
- **[[composability]]**: La propiedad que permite múltiples consumers
- **[[backpressure]]**: El efecto colateral positivo de la pausa natural
- **[[dependency-injection]]**: Cómo se inyectan las dependencias (callModel, executeTool)

## Errores Comunes Implementando Async Generators

### 1. No usar `yield*` para Delegation

```typescript
// ❌ Wrong: yield espera valores, no generators
async function* wrapper() {
  const inner = someAsyncGenerator();
  yield inner; // Esto yield el generator object, no sus valores!

  // ✅ Correcto: yield* delega a otro generator
  async function* wrapper() {
    const inner = someAsyncGenerator();
    yield* inner; // Delega completamente, valores van directamente
  }
}
```

### 2. Forget que async generators son lazy

```typescript
// ❌ Llamar una función async generator NO ejecuta nada
const gen = streamModel(messages);
gen; // Solo returns un AsyncGenerator object
// La ejecución empieza cuando iteras

// ✅ Necesitas consumirlo
for await (const event of gen) {
  process(event);
}
```

### 3. No handling errors en el generator mismo

```typescript
// ❌ Error no capturado — crash silencioso
async function* badStream() {
  const data = await fetchrisky(); // Si falla, el generator queda broken
  yield data;
}

// ✅ Try-catch dentro del generator
async function* goodStream() {
  try {
    const data = await fetchRisky();
    yield data;
  } catch (e) {
    yield { type: 'error', error: e }; // Notifica al consumer
  }
}
```

## Recursos

- [MDN: Async Iterators](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/AsyncIterator)
- [TC39: Async Generator Proposal](https://github.com/tc39/proposal-async-iteration)
- [[agent-loop]] — El patrón completo donde async generators se usan
