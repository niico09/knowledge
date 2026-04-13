# Cancellation en Agent Systems

## Definición

**Cancellation** es la capacidad de interrumpir un proceso en ejecución de forma limpia, garantizando que:
1. El proceso se detiene sin demora indefinida
2. Los recursos (connections, file handles, processes) se liberan
3. El estado se deja consistente o se persiste para posible resume
4. No hay efectos colaterales en otros procesos

En agents: cuando el usuario presiona Ctrl+C, o el sistema decide abortar una operación, cada operación en progreso debe detenerse limpiamente.

## Por Qué Es Difícil

### El Problema de Async Operations

Las operaciones asíncronas son precisamente eso — asíncronas. Una vez que inicias un `fetch()`, no hay garantía de que puedas detenerlo fácilmente. El servidor puede estar procesando, los datos pueden estar en-flight.

```typescript
// ❌ "Fire and forget" — no cancellation
async function badAgent() {
  const response = await fetch('/api/slow-operation'); // Inicia
  // No hay forma de decir "cancela esto"
  return response.json();
}

// ✅ Con AbortController
const controller = new AbortController();

async function cancellableAgent() {
  const response = await fetch('/api/slow-operation', {
    signal: controller.signal // ← Link al controller
  });
  return response.json();
}

// Para cancelar:
controller.abort(); // El fetch se corta, lanza AbortError
```

### El Problema de Múltiples Operaciones

Un agent puede tener múltiples operaciones en paralelo:
- Model inference (HTTP request)
- Tool executions (5 reads, 2 bash commands)
- File operations (reads, writes)
- Sub-agent processes

Cancelar uno no cancela los otros. Necesitas un mecanismo de propagación.

## AbortController y AbortSignal

El estándar Web APIs introduce `AbortController` y `AbortSignal` para cancellation:

```typescript
const controller = new AbortController();
const { signal } = controller;

// Opción 1: Pass signal a fetch
fetch('/api/data', { signal });

// Opción 2: Listen para abort
signal.addEventListener('abort', () => {
  console.log('Operation was cancelled');
});

// Opción 3: Check in loop
while (!signal.aborted) {
  await doWork();
}

// Para cancelar:
controller.abort(); // signal.aborted === true
```

## Cancellation en Async Generators

Los async generators hacen cancellation **natural**:

```typescript
async function* longRunningTask() {
  try {
    for (let i = 0; i < 1000; i++) {
      yield await processItem(i);
    }
  } finally {
    // ESTE BLOQUE CORRE SIEMPRE cuando el generator se detiene:
    // 1. Caller sale del for await
    // 2. Caller llama .return()
    // 3. Caller llama .throw()
    // 4. AbortSignal se activa
    await cleanupResources();
    await closeConnections();
    await saveCheckpoint(i);
  }
}

// Uso:
const task = longRunningTask();
for await (const item of task) {
  render(item);
  if (userClickedCancel) {
    break; // finally corre automáticamente
  }
}
```

Esto es fundamentalmente diferente a un while loop:

```typescript
// ❌ While loop: cleanup manual
async function badLoop(onCancel) {
  try {
    while (true) {
      await processItem();
    }
  } catch (e) {
    // Cleanup manual — fácil olvidar
  } finally {
    if (onCancel()) cleanup(); // No always called
  }
}

// ✅ Async generator: cleanup automático
async function* goodLoop() {
  try {
    for (;;) {
      yield await processItem();
    }
  } finally {
    // Siempre llamado cuando el generator se para
    await cleanup();
  }
}
```

## Propagación de AbortSignal

Claude Code propaga `AbortSignal` a través de cada capa:

```typescript
interface QueryOptions {
  abortSignal?: AbortSignal;
}

async function* query(options: QueryOptions) {
  // Layer 1: Model call
  const stream = await callModel(messages, {
    signal: options.abortSignal // Propagated
  });

  for await (const event of stream) {
    yield event;

    // Layer 2: Tool execution
    // Si abort signal está activo, los tools lo reciben
    if (isCompleteToolCall(event)) {
      const result = await executeTool(event.toolCall, {
        signal: options.abortSignal // Propagated again
      });
      yield result;
    }
  }
}
```

Cuando `options.abortSignal.abort()` se llama:
1. El fetch del modelo se corta
2. El stream se cierra
3. Los tool executions reciben abort
4. Los finally blocks corren en cada capa

## Cancellation Jerárquica (Parent → Children)

Cuando tienes sub-agents, aborting el parent debe abort all children:

```
Parent Agent
├── Sub-agent A
│   ├── Tool execution 1
│   └── Tool execution 2
├── Sub-agent B
│   └── Tool execution 3
└── Main task
```

```typescript
class AgentHierarchy {
  private parentAbort = new AbortController();

  async spawnSubAgent(name: string): Promise<SubAgent> {
    // El child recibe una REFERENCIA al abort signal del parent
    // No su propio AbortController
    return new SubAgent({
      signal: this.parentAbort.signal // ← Link, not copy
    });
  }

  abort() {
    // UNA llamada abortinga todo el hierarchy
    this.parentAbort.abort();
  }
}
```

## Sibling Abortion (Cuando Un Tool Falla Fatalmente)

Cuando múltiples tools corren en paralelo y uno falla fatalmente, los siblings deben abortarse:

```typescript
async function executeToolBatch(
  tools: ToolCall[],
  deps: ToolDeps
): Promise<ToolResult[]> {
  // Un AbortController compartido por el batch
  const batchAbort = new AbortController();

  const promises = tools.map(tool =>
    deps.executeTool(tool, { signal: batchAbort.signal })
      .catch(e => {
        if (isFatalError(e)) {
          // Error fatal — abortar siblings
          batchAbort.abort();
          // También abortar el query parent
          deps.parentAbortController?.abort();
        }
        return { error: e, tool };
      })
  );

  const results = await Promise.all(promises);

  // Si un tool fue abortado por sibling, marcarlo
  return results.map((r, i) =>
    batchAbort.signal.aborted && !results[i].error
      ? { error: 'Aborted by sibling', tool: tools[i] }
      : r
  );
}
```

## UI-Level Cancellation

El usuario presiona Ctrl+C:

```
┌─────────────────────────────────────────┐
│ > Running task...                       │
│   ↳ Reading files...                   │
│   ↳ Processing...         [Ctrl+C?]    │
└─────────────────────────────────────────┘
```

```typescript
// En la UI:
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.key === 'c') {
    agentController.abort(); // Activa AbortSignal
  }
});

// El agent loop detecta y para limpiamente
async function* agentLoop(controller) {
  try {
    for await (const event of query({ signal: controller.signal })) {
      yield event;
    }
  } finally {
    // Cleanup: cerrar archivos, terminar procesos hijos, etc
    await cleanup();
    showStatus('Agent stopped by user');
  }
}
```

## Graceful vs Forced Cancellation

### Graceful (Limpia)
El caller sale del loop, finally blocks corren, estado se persiste:

```typescript
for await (const event of agent) {
  if (shouldStop) break; // Graceful: finally corre
}
```

### Forced (Forzada)
El caller quiere parar inmediatamente, no esperar a que el loop termine su iteration actual:

```typescript
// Opción 1: .return() fuerza salida inmediata
await agent.return();

// Opción 2: Timeout
const withTimeout = setTimeout(() => {
  agent.return(); // Force stop después de X segundos
}, 5000);

for await (const event of agent) {
  // ...
}
clearTimeout(withTimeout);

// Opción 3: AbortSignal con timeout
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000);
```

## Stateful Cancellation (Persistencia de Estado)

En sesiones largas, la cancelación debe permitir resume:

```typescript
async function* resumableAgent(checkpointPath: string) {
  let state = loadCheckpoint(checkpointPath) || initialState();

  try {
    while (!state.done) {
      const result = await processStep(state);

      // Persistir checkpoint cada N steps
      if (state.step % 10 === 0) {
        await saveCheckpoint(checkpointPath, state);
      }

      yield result;
      state.step++;
    }
  } finally {
    // En cancelación, el checkpoint está guardado
    // El usuario puede resume más tarde
    await saveCheckpoint(checkpointPath, state);
    await releaseResources();
  }
}
```

## Cancellation en Different Execution Contexts

### In-Process
```typescript
// Async generators en el mismo proceso
// AbortSignal es directo
controller.abort(); // Inmediato
```

### Tmux Pane
```typescript
// Sub-agent en tmux pane separado
// Killing el pane aborta el proceso
exec(`tmux kill-session -t ${paneId}`);

// O enviando signal
exec(`tmux send-keys -t ${paneId} C-c`);
```

### Remote (CCR)
```typescript
// Agente en máquina remota
// Enviar mensaje de abort via API
await fetch(`/agents/${agentId}/abort`, { method: 'POST' });
```

## Common Pitfalls

### 1. No Propagation del Signal

```typescript
// ❌ Signal no se pasa — fetch no se puede cancelar
async function badCall(url) {
  const response = await fetch(url); // No signal!
}

// ✅ Signal pasado
async function goodCall(url, signal) {
  const response = await fetch(url, { signal });
}
```

### 2. Catch que Swallows AbortError

```typescript
// ❌ AbortError es un error normal, no debe ser ignorado
async function bad() {
  try {
    await fetch('/api', { signal });
  } catch (e) {
    if (e.name === 'AbortError') {
      // El usuario quiso cancelar — pero seguimos como si nada
      // El cleanup no corre!
    }
  }
}

// ✅ Propagar AbortError o re-throw
async function good(signal) {
  try {
    await fetch('/api', { signal });
  } catch (e) {
    if (e.name === 'AbortError') {
      throw e; // Re-throw para que el caller maneje
    }
    // Otros errores sí se manejan
  }
}
```

### 3. Finally que También Puede Fallar

```typescript
// ❌ Cleanup que puede fallar y enmascarar el error original
async function* bad() {
  try {
    for (;;) yield await work();
  } finally {
    throw new Error('Cleanup failed'); // Esto máscara el abort real
  }
}

// ✅ Cleanup robusto
async function* good() {
  try {
    for (;;) yield await work();
  } finally {
    try {
      await cleanup();
    } catch (cleanupError) {
      // Log pero no mascara el error original
      console.error('Cleanup failed:', cleanupError);
    }
  }
}
```

## Integration con Error Recovery

La cancelación interactúa con error recovery:

```typescript
async function* resilientAgent() {
  for (;;) {
    try {
      for await (const event of modelInvocation()) {
        yield event;
      }
    } catch (e) {
      if (e.name === 'AbortError') {
        yield { type: 'cancelled' };
        break; // No retry en cancelación
      }

      // Error recuperable — retry con backoff
      yield { type: 'error', error: e };
      await sleep(calculateBackoff(attempt++));
      continue;
    }
  }
}
```

## Referencias

- **[[async-generators]]**: El mecanismo que hace finally automático
- **[[agent-loop]]**: Cómo cancellation se integra en el loop
- **[[sub-agent-architecture]]**: Parent-child cancellation
- **[[error-recovery]]**: Diferencia entre cancellation y error recuperable
