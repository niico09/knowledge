# Agent Loop

## Definición

El **agent loop** es el ciclo de control central que gobierna un agent: observa el estado actual (mensajes, contexto, herramientas disponibles), decide una acción basándose en ese estado, la ejecuta, y repite hasta que la tarea se completa, se alcanza un límite, o ocurre un error irrecuperable.

Es el equivalente al "main loop" en sistemas embebidos o game engines, pero para agents de IA. Mientras el modelo de lenguaje es el "cerebro" que decide *qué hacer*, el agent loop es el "sistema nervioso" que gobierna *cómo* se ejecuta.

## Anatomía del Agent Loop

### Conceptual Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ┌───────────┐    ┌─────────────┐    ┌─────────────────────┐   │
│  │           │───▶│   Model     │───▶│  Tool Executor      │   │
│  │  Current  │    │  Inference  │    │  (Parallel/Serial) │   │
│  │  Context  │    └─────────────┘    └─────────────────────┘   │
│  │  (State)  │           │                    │                │
│  └───────────┘           │                    ▼                │
│       ▲                  │             ┌───────────┐           │
│       │                  │             │  Results  │           │
│       │                  ▼             └───────────┘           │
│       │         ┌─────────────────┐         │                   │
│       └─────────│   Decision:     │◀────────┘                   │
│                 │  Continue?      │                              │
│                 │  Stop? Retry?   │                              │
│                 └─────────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### El Loop como State Machine

En lugar de un loop imperativo simple, Claude Code implementa el agent loop como una **state machine** con fases explícitas. Cada fase tiene precondiciones, post-condiciones, y manejo de errores específico.

```typescript
enum LoopPhase {
  SETUP = 'setup',
  MODEL_INVOCATION = 'model_invocation',
  ERROR_RECOVERY = 'error_recovery',
  TOOL_EXECUTION = 'tool_execution',
  CONTINUATION = 'continuation',
}

interface LoopState {
  phase: LoopPhase;
  messages: Message[];
  turn: number;
  contextTokens: number;
  compactionState: CompactionState;
  abortSignal: AbortSignal;
}
```

## Las Cinco Fases Detalladas

### Phase 1: Setup (Preparación)

Esta fase corre **antes** de cada invocación al modelo. Es el "sanity check" que evita que el modelo trabaje con contexto inválido o excedido.

```typescript
async function setup(state: LoopState): Promise<SetupResult> {
  const issues: Issue[] = [];

  // 1. Verificar token budget
  const tokenCount = countTokens(state.messages);
  if (tokenCount > TOKEN_LIMIT * 0.9) {
    issues.push({ type: 'near-limit', tokens: tokenCount });
  }

  // 2. Evaluar estrategia de compaction
  if (tokenCount > TOKEN_LIMIT * 0.8) {
    const strategy = selectCompactionStrategy(state.compactionState);
    state.messages = await strategy.run(state.messages);
    state.compactionState.record(strategy.name);
  }

  // 3. Aplicar tool result budgets
  state.messages = applyToolBudgets(state.messages);

  // 4. Validar precondiciones del modelo
  if (!hasValidModelConfig(state)) {
    issues.push({ type: 'model-config-invalid' });
  }

  return { messages: state.messages, issues };
}
```

**Qué NO hace esta fase:**
- No llama al modelo
- No ejecuta herramientas
- No modifica el estado de manera substantiva

**Qué SÍ hace:**
- Garantiza que el input al modelo está dentro de bounds
- Trigger compaction si necesario
- Reporta issues a la UI para que el usuario esté informado

### Phase 2: Model Invocation (Invocación del Modelo)

Esta es la fase donde el modelo realmente genera. Pero en Claude Code no es una llamada bloqueante simple — es un stream de eventos.

```typescript
async function* modelInvocation(
  messages: Message[],
  deps: ModelDeps
): AsyncGenerator<ModelEvent> {
  const stream = deps.callModel(messages, {
    signal: deps.abortSignal,
    model: deps.model,
    maxTokens: deps.outputBudget,
  });

  for await (const event of stream) {
    yield event;

    // EARLY TOOL EXECUTION (mid-stream)
    // Si el tool call JSON está completo, empezamos antes de que el modelo termine
    if (isCompleteToolCall(event)) {
      // No esperamos a que el stream termine
      // Ejecutamos mientras el modelo sigue generando
      const toolResult = await deps.executeTool(event.toolCall);
      yield { type: 'tool-result', result: toolResult };
    }
  }
}
```

**Importancia del mid-stream execution:**
El modelo puede tardar 10 segundos en generar completamente. Sin mid-stream execution, sumarías 10s + tiempo de tools. Con mid-stream, las tools empiezan a ejecutarse mientras el modelo aún está generando — ocultando 2-5 segundos de latencia.

### Phase 3: Error Recovery & Compaction (Recuperación de Errores)

Esta es la fase más distintiva de Claude Code. Los errores no se manejan con un `try-catch` genérico alrededor del loop — cada tipo de error tiene un handler específico dentro de la state machine.

```typescript
type ErrorType =
  | 'rate-limited'        // 429
  | 'overloaded'          // 529
  | 'context-overflow'    // 400
  | 'auth-failure'        // 401/403
  | 'network-error'       // ECONNRESET, EPIPE, timeout
  | 'internal-error';     // 500

function handleErrors(
  state: LoopState,
  error: Error | null,
  response: ModelResponse | null
): ErrorRecoveryAction {
  // 1. Rate Limiting (429)
  if (error?.status === 429) {
    const retryAfter = error.headers?.['retry-after'];
    if (retryAfter && retryAfter < 20) {
      return { action: 'retry-fast', delay: retryAfter * 1000 };
    } else if (retryAfter > 20) {
      return { action: 'enter-cooldown', duration: 30 * 60 * 1000 };
    }
    return { action: 'retry-default' };
  }

  // 2. Server Overloaded (529)
  if (error?.status === 529) {
    const consecutive529 = state.metrics.consecutive529 || 0;
    if (consecutive529 >= 3 && deps.fallbackModel) {
      return { action: 'switch-model', model: deps.fallbackModel };
    }
    return { action: 'retry-with-backoff', backoff: calculateBackoff(consecutive529) };
  }

  // 3. Context Overflow (400)
  if (error?.status === 400 && error.message.includes('context')) {
    const match = error.message.match(/(\d+)\s*>\s*(\d+)/); // actual > limit
    if (match) {
      const [, actual, limit] = match;
      const available = parseInt(limit) - parseInt(actual) - 1000; // 1K buffer
      return {
        action: 'adjust-budget-and-retry',
        newMaxTokens: Math.max(available, 3000) // floor de 3K
      };
    }
    return { action: 'compact-and-retry' };
  }

  // 4. Auth Failure (401/403)
  if (error?.status === 401 || error?.status === 403) {
    return { action: 'refresh-credentials-and-retry' };
  }

  // 5. No error — check stop_reason del modelo
  if (!error && response?.stopReason === 'tool_use') {
    // El modelo quiere usar tools — normal, continuamos
    return { action: 'continue' };
  }

  if (!error && response?.stopReason === 'end_turn') {
    // El modelo considera la tarea completa
    return { action: 'stop' };
  }

  return { action: 'continue' }; // Default
}
```

**Por qué dentro del loop y no alrededor:**

```typescript
// ❌ ERROR: try-catch genérico fuera del loop
async function badAgentLoop() {
  while (true) {
    try {
      const response = await callModel(messages);
      const result = executeTools(response);
      messages.push(result);
    } catch (e) {
      if (e.status === 429) await sleep(1000); // too simple!
      else throw e; // todo o nada
    }
  }
}

// ✅ CORRECTO: errores como estados de primera clase dentro del loop
async function* goodAgentLoop() {
  let state = initialState();
  for (;;) {
    const prepared = await setup(state);

    for await (const event of modelInvocation(prepared.messages)) {
      yield event;
    }

    // Error handling es PARTE del loop, no un wrapper
    const recovery = handleErrors(state, error, response);
    if (recovery.action === 'retry-fast') {
      await sleep(recovery.delay);
      state = incrementTurn(state);
      continue;
    }
    if (recovery.action === 'compact-and-retry') {
      state.messages = await compact(state.messages);
      continue;
    }
    if (recovery.action === 'stop') break;
  }
}
```

### Phase 4: Tool Execution (Ejecución de Herramientas)

Esta fase solo contiene tools que NO fueron ejecutados durante el streaming (mid-stream). Los tools ejecutados durante Phase 2 ya tienen sus resultados.

```typescript
async function toolExecution(
  pendingTools: ToolCall[],
  executedTools: Map<string, ToolResult>,
  deps: ToolDeps
): Promise<ToolExecutionResult[]> {
  const results: ToolResult[] = [];

  // Clasificar por concurrency behavior
  const { readOnly, serial } = partitionByConcurrency(pendingTools);

  // Read-only: paralelo, hasta 10
  const readOnlyBatch = readOnly.slice(0, MAX_PARALLEL_READ);
  const readOnlyPromises = readOnlyBatch.map(tool =>
    deps.executeTool(tool)
  );
  const readOnlyResults = await Promise.all(readOnlyPromises);

  // Serial: uno por uno
  for (const tool of serial) {
    const result = await deps.executeTool(tool);
    results.push(result);
  }

  // Interleaving: results de read-only se insertan en posición original
  return mergeInOrder(readOnlyResults, results, pendingTools);
}
```

### Phase 5: Continuation Decision (Decisión de Continuación)

Esta fase determina si el loop debe continuar o terminar. Múltiples señales se evalúan:

```typescript
function shouldContinue(state: LoopState): ContinueDecision {
  // 1. Stop reason del modelo
  if (state.lastResponse.stopReason === 'end_turn') {
    return { should: false, reason: 'model-completed' };
  }
  if (state.lastResponse.stopReason === 'max_tokens') {
    return { should: true, reason: 'incomplete-response' };
  }

  // 2. Turn counter
  if (state.turn >= state.maxTurns) {
    return { should: false, reason: 'max-turns-reached' };
  }

  // 3. Abort signal del usuario
  if (state.abortSignal?.aborted) {
    return { should: false, reason: 'user-abort' };
  }

  // 4. Hooks pueden request stop
  if (state.hooks.shouldStop?.()) {
    return { should: false, reason: 'hook-stop' };
  }

  // 5. Error irrecuperable
  if (state.consecutiveErrors > MAX_CONSECUTIVE_ERRORS) {
    return { should: false, reason: 'too-many-errors' };
  }

  return { should: true, reason: 'normal-continue' };
}
```

## Dependency Injection (QueryDeps)

El loop recibe sus dependencias a través de una interfaz:

```typescript
interface QueryDeps {
  // Model
  callModel: (
    messages: Message[],
    options: ModelOptions
  ) => AsyncGenerator<ModelEvent>;
  fallbackModel?: Model;

  // Tools
  executeTool: (tool: ToolCall) => Promise<ToolResult>;
  toolRegistry: ToolRegistry;

  // Context management
  compactionStrategy: CompactionStrategy;
  toolBudgetEnforcer: ToolBudgetEnforcer;

  // Configuration
  maxTurns: number;
  outputBudget: number;

  // Cancellation
  abortSignal?: AbortSignal;

  // Observability
  onEvent?: (event: LoopEvent) => void;
}
```

**Por qué DI importa:**
Inject un mock `callModel` que yield eventos predeterminados → puedes verificar:
- Context overflow handling sin API real
- Tool failure recovery sin ambiente real
- Cancellation sin procesos reales

## El Async Generator como Contrato

La firma de `async function* query()` no es solo un detalle de implementación — es un **contrato**:

```typescript
// Este tipo dice: "puedes iterar sobre eventos de este agent"
// No dice: "este agent hace X y retorna Y"
async function* query(deps: QueryDeps): AsyncGenerator<LoopEvent>
```

Consumers (UI, tests, sub-agents) saben que pueden:
1. Iterar sobre eventos con `for await`
2. Hacer `.return()` para cleanup
3. Escuchar por `.throw()` para errores
4. Obtener valores incrementally

## Comparación: Agent Loop vs Other Loops

| Loop Type | Cancellable | Streaming | Recoverable | Composable |
|-----------|-------------|-----------|-------------|------------|
| While loop simple | ✗ (manual) | ✗ | ✗ | ✗ |
| Promise chain | ✗ | ✗ | Maybe | ✗ |
| Async Generator | ✓ (finally) | ✓ | ✓ (states) | ✓ |
| EventEmitter | ✓ (off) | Partial | ✗ | ✓ |
| Actor model | ✓ (death) | ✓ | ✓ | ✓ |

## Anti-Patrones

### 1. Loop que no es interruption-safe

```typescript
// ❌ Si este sleep es interrumpido, el finally no corre
async function badLoop() {
  try {
    while (true) {
      await sleep(1000); // Sin abort signal
    }
  } finally {
    cleanup(); // Puede que no corra si fue interrupted
  }
}

// ✅ Con AbortSignal, la cancelación es limpia
async function goodLoop(abortSignal) {
  try {
    while (true) {
      await sleep(1000, { signal: abortSignal });
    }
  } finally {
    cleanup(); // Siempre corre
  }
}
```

### 2. Estado global compartido

```typescript
// ❌ Estado en closures — difícil de testear
let globalMessages = [];
async function* badAgent() {
  globalMessages.push(yield);
}

// ✅ Estado explícito vía closure o clase
function createAgent(initialMessages) {
  let messages = [...initialMessages];
  return async function* agent() {
    messages.push(yield);
  };
}
```

## Métricas de un Agent Loop Saludable

```typescript
interface LoopMetrics {
  turnsCompleted: number;
  averageTurnDuration: number;
  totalTokensConsumed: number;
  toolCallsExecuted: number;
  compactionCount: number;
  errorRecoveryCount: number;
  averageContextTokens: number;
}
```

## Conexiones con Otros Conceptos

- **[[async-generators]]**: El loop DEBERÍA implementarse como async generator
- **[[streaming]]**: Phase 2 yield eventos de streaming
- **[[mid-stream-execution]]**: Tool execution durante Phase 2
- **[[error-recovery]]**: Phase 3 maneja errores como estados
- **[[compaction-hierarchy]]**: Phase 1 puede trigger compaction
- **[[tool-budgets]]**: Phase 1 aplica tool result budgets
- **[[permission-system]]**: Los tools que se ejecutan en Phase 4 pasan por permission checks
- **[[sub-agent-architecture]]**: Sub-agents son instancias del mismo loop
