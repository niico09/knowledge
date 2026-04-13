# Backpressure

## Definición

**Backpressure** es el mecanismo por el cual un consumer lento indica a un producer rápido que reduzca o pause su ritmo de envío, evitando que se acumulen datos no procesados en memoria hasta el punto de causar OOM (out of memory).

En sistemas de streaming asíncronos, cuando el producer genera datos más rápido de lo que el consumer puede procesar, hay dos opciones:
1. **Buffering** — guardar todo en memoria (puede causar memory explosion)
2. **Backpressure** — el producer pausa hasta que el consumer esté listo (memory bounded)

## El Problema: Memory Explosion Without Backpressure

### Escenario Sin Backpressure

```
Producer: Genera tokens a 1000/segundo
Consumer: Renderiza a 100/segundo

Buffer en el medio:
Segundo 0: 0 tokens
Segundo 1: 900 tokens en buffer (generó 1000, consumió 100)
Segundo 10: 9,000 tokens en buffer
Segundo 60: 54,000 tokens en buffer
Segundo 3600 (1 hora): 3,240,000 tokens en buffer

Result: OOM crash después de unas horas
```

### Por Qué Ocurre

En Node.js streams tradicionales o promesas plain, cuando el producer genera más rápido de lo que el consumer consume, los datos se bufferizan en algún queue interno. Si no hay límite, el queue crece indefinidamente.

```typescript
// ❌ Promesa que bufferiza todo
async function badStream() {
  const chunks: string[] = [];

  // Producer rápido
  producer.on('data', (chunk) => chunks.push(chunk));

  // Consumer lento
  await new Promise(resolve => {
    consumer.on('data', (chunk) => {
      processSlowly(chunk); // 100/segundo
    });
  });

  // chunks creció a millones de elementos
}
```

## Cómo Async Generators Resuelven Backpressure

Los async generators tienen backpressure **natural**:

```typescript
async function* modelStream(): AsyncGenerator<string> {
  let token = 0;
  while (true) {
    // PAUSA hasta que el consumer llame .next()
    const next = yield `token-${token++}`;

    // Si el consumer no llama .next(), este yield no se ejecuta de nuevo
    // El producer NO genera más datos
  }
}

// Consumer
const stream = modelStream();
const gen = stream.next(); // Inicia, pero el generator PUEDE pausar aquí

// Consumer lento
for (let i = 0; i < 10; i++) {
  const { value } = await stream.next(); // Consume 1 por vez
  processSlowly(value); // 100ms por token
  // Between .next() calls, el generator PAUSA
  // No hay buffer growth
}
```

### Visualización del Flow

```
Producer (1000 tokens/segundo)
         │
         │  yield token
         ▼
[Generator State: PAUSED] ◀── El modelo NO genera más
         │                    hasta que .next() se llama
         │  .next() llamado
         ▼
Consumer (procesa 1 token, 100ms)
         │
         │  .next() llamado de nuevo
         ▼
[Generator State: PAUSED]
         │
         ...repite...
```

## Backpressure en la Práctica

### Caso Real: Terminal UI

```typescript
// Producer: modelo generando tokens
async function* streamModel(): AsyncGenerator<Token> {
  const stream = await fetch('/api/chat/stream');

  for await (const chunk of stream) {
    yield parseToken(chunk); // Yield por cada token
  }
}

// Consumer: terminal renderizando
async function renderTokens() {
  for await (const token of streamModel()) {
    process.stdout.write(token.content);

    if (isSlowTerminal) {
      // Terminal lento — el loop se pausa naturalmente
      // porque .next() no se llama hasta que process.stdout.write termine
      await new Promise(r => setTimeout(r, 10));
    }
  }
}
```

### Caso Real: HTTP Response

```typescript
// Producer: leyendo archivo grande
async function* readFileStream(path: string): AsyncGenerator<Chunk> {
  const file = await openFile(path);
  while (true) {
    const chunk = await file.read(1024); // 1KB por vez
    if (!chunk) break;
    yield chunk; // Pausa si el consumer no puede procesar
  }
}

// Consumer: escrebindo a la red
async function sendFile(destination: WritableStream) {
  const writer = destination.getWriter();

  for await (const chunk of readFileStream('large-file.zip')) {
    await writer.ready; // Espera si el buffer de red está lleno
    await writer.write(chunk);
    // Si la red está congestionada, writer.ready nunca se resuelve
    // entonces el .next() del generator no se llama
    // el generator PAUSA en yield chunk
  }
}
```

## Backpressure en Claude Code

### Model → Agent Loop → UI

```
Model (generates fast)
    │
    │ tokens via HTTP/ SSE stream
    ▼
Agent Loop (async generator)
    │
    │ yields StreamEvent por cada token/herramienta
    ▼
UI (render depends on terminal speed)
    │
    │ Si UI no llama .next(), el loop PAUSA
    │ El fetch interno PAUSA cuando su buffer se llena
    ▼
No hay memory explosion en largas sesiones
```

### Tool Execution → Results Queue

```
Tools executing in parallel
    │
    │ results
    ▼
Queue (bounded by pendingResults Map)
    │
    │ Si el consumer no llama .next() para obtener results
    ▼
El generator paús en yield, tools pueden seguir ejecutando?
    │
    │ Depende de implementación:
    │ - Si tool execution está disconnection del generator,
    │   puede continuar en background
    │ - Pero los results se bufferizan en pendingResults Map
```

## La Diferencia Entre Generators y Streams Tradicionales

### Node.js Readable Streams

```typescript
// Readable stream tiene highWaterMark — buffer con límite
const readable = createReadableStream({
  highWaterMark: 16 // Solo 16 objects en buffer
});

// Si el buffer está lleno, readable.read() retorna null
// Consumer debe esperar hasta que haya espacio
```

### Async Generators

```typescript
// Async generator es naturalmente bounded por la velocidad del consumer
async function* generator() {
  for (let i = 0; i < Infinity; i++) {
    yield i;
    // PAUSA hasta que .next() se llame de nuevo
  }
}

// Consumer controla el ritmo
const gen = generator();
for await (const item of gen) {
  process(item);
  // Si process() es lento, el generator no produce más
  // hasta que process() termine y llame .next()
}
```

## Memory Boundedness

El objetivo: que sin importar cuánto tiempo corra el agent, la memoria se mantenga bounded.

```typescript
// Sin backpressure: O(n) donde n = tiempo de sesión
class BadAgent {
  private buffer: Event[] = [];

  async process() {
    for (;;) {
      const event = await this.getNextEvent();
      this.buffer.push(event); // Acumula todo
    }
  }
}

// Con backpressure: O(1) — solo el evento actual
class GoodAgent {
  async *process() {
    for (;;) {
      const event = await this.getNextEvent();
      yield event; // No se acumula, se yield ydone
    }
  }
}
```

## Backpressure en Paralelismo

Cuando tienes múltiples producers/consumers:

```
Producer A ─┐
Producer B ─┼──▶ [Channel] ──▶ Consumer X
Producer C ─┘
               │
               │ Si channel está lleno, producers pausan
               ▼
```

```typescript
// Channel con backpressure
async function* channel<T>(capacity: number): AsyncGenerator<T> {
  const queue: T[] = [];
  let waitingPushers: [(T) => void, () => void][] = [];
  let waitingPullers: [(T) => void][] = [];

  // Push with backpressure
  this.push = (item: T) => new Promise(resolve => {
    if (waitingPullers.length > 0) {
      const resolver = waitingPullers.shift()!;
      resolver(item);
      resolve();
    } else if (queue.length < capacity) {
      queue.push(item);
      resolve();
    } else {
      waitingPushers.push([item, resolve]);
    }
  });

  // Pull with backpressure
  this.pull = (): Promise<T> => new Promise(resolve => {
    if (queue.length > 0) {
      resolve(queue.shift()!);
    } else if (waitingPushers.length > 0) {
      const [item, resolver] = waitingPushers.shift()!;
      resolver();
      resolve(item);
    } else {
      waitingPullers.push(resolve);
    }
  });
}
```

## Trade-offs de Backpressure

### Ventajas
1. **Memory bounded** — no hay OOM en sesiones largas
2. **Natural pacing** — el consumer controla el ritmo
3. **No buffering explode** — no hay queue infinita

### Desventajas
1. **Producer idle** — el modelo puede estar esperando al consumer
2. **Latency** — si el producer pausa, hay delay
3. **Complexity** — entender cuándo pausar no siempre es obvio

## Cuándo El Backpressure No Es Suficiente

### Caso: Producer Sin Control Sobre Producción

```typescript
// El modelo genera a su propio ritmo — no puedes pedirle que pare
// Pero puedes dejar de LEER del stream
async function* modelStream() {
  const response = await fetch('/api/chat/stream');

  for await (const chunk of response.body) {
    // No hay forma de decirle al servidor "deja de generar"
    // Solo puedes dejar de leer del stream
    yield parseChunk(chunk);
  }
}
```

### Solución: AbortSignal + Backpressure Combinados

```typescript
async function* controlledStream(signal: AbortSignal) {
  const response = await fetch('/api/chat/stream', { signal });

  for await (const chunk of response.body) {
    if (signal.aborted) {
      // Además de backpressure, tenemos abort signal
      // que puede cerrar el stream completamente
      break;
    }
    yield parseChunk(chunk);
  }
}
```

## Backpressure en la UI

En una terminal o UI, el backpressure se manifiesta como:

```typescript
// Si la UI está overwhelmed, puede pausar el rendering
class TerminalUI {
  private paused = false;

  async write(token: string) {
    if (this.paused) {
      // Espera a que el buffer de pantalla se vacíe
      await this.waitForDrain();
    }
    this.output.write(token);
  }

  pause() {
    this.paused = true;
  }

  resume() {
    this.paused = false;
  }
}

// El agent loop detecta y usa este signal
async function* agentLoop(ui: TerminalUI) {
  for await (const event of modelStream()) {
    if (ui.isOverloaded()) {
      // Pausar el loop hasta que la UI esté lista
      await ui.waitForDrain();
    }
    yield event;
  }
}
```

## Métricas de Backpressure

```typescript
interface BackpressureMetrics {
  producerPausedCount: number;      // Veces que el producer pausó
  averagePauseDuration: number;     // Duración promedio de pausas
  bufferSize: number;              // Tamaño actual del buffer
  consumerLaggingMs: number;       // Cuánto está lagged el consumer
}
```

## Referencias

- **[[async-generators]]**: El mecanismo que hace backpressure natural
- **[[streaming]]**: El contexto donde backpressure ocurre
- **[[agent-loop]]**: Cómo el loop maneja backpressure
- **[[memory-management]]**: Por qué bounded memory importa
