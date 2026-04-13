# Composability

## Definición

**Composability** es la capacidad de diseñar componentes que pueden combinarse de formas predecibles y reutilizarse en múltiples contextos sin modificación. Un sistema composable permite que los mismos bloques básicos se ensamblen de maneras diferentes para resolver problemas distintos.

En agent architecture: un agent loop implementado como async generator puede ser consumido por diferentes callers — UI, tests, sub-agents — sin duplicar lógica ni conocimiento del loop interno.

## La Metáfora del Generador Eléctrico

Piensa en un generator de electricidad:
- Produce corriente eléctrica
- No le importa si está alimentando una casa, un hospital, o una fábrica
- El aparato que conecta define qué se hace con la electricidad

Un async generator de agent loop es similar:
- Produce eventos de agent (tokens, tool calls, resultados)
- No le importa si el consumer es una UI, un test, o un sub-agent
- El consumer define qué hacer con los eventos

## El Anti-Patrón: Monolito Informed

### Función Que Retorna Resultado Completo

```typescript
// ❌ Agent como función normal — retorna todo al final
async function monolithicAgent(messages: Message[]): Promise<AgentResult> {
  // Hace todo el trabajo internamente
  const response = await callModel(messages);
  const toolResults = executeTools(response);
  return {
    response,
    toolResults,
    finalMessage: combine(response, toolResults)
  };
}
```

**Problemas:**
1. No hay streaming — el caller no ve nada hasta el final
2. No hay cancelación — no puedes parar a mitad
3. No hay composición — no puedes intersectar el proceso
4. No hay testabilidad — necesitas mocking complejo

### Clase Con Métodos Privados

```typescript
// ❌ Agent como clase con estado interno
class MonolithicAgent {
  private messages: Message[] = [];
  private state: AgentState = 'idle';

  async run() {
    this.state = 'running';
    while (this.state === 'running') {
      const response = await this.callModel();
      await this.executeTools(response);
    }
  }

  // Consumers acceden a través de callbacks o polling
  onEvent(handler: (e: AgentEvent) => void) { ... }
}
```

**Problemas:**
- Estado privado que el consumer no puede inspeccionar fácilmente
- No hay iteración natural — tienes que usar callbacks o event emitters
- Difícil de testear porque necesitas una instancia completa

## El Patrón: Async Generator como Interfaz Universal

```typescript
// ✅ Agent como async generator — produce eventos en el tiempo
async function* createAgent(
  initialMessages: Message[],
  deps: AgentDeps
): AsyncGenerator<AgentEvent> {
  let messages = [...initialMessages];

  for (;;) {
    // Yield streaming events mientras trabajamos
    for await (const event of deps.callModel(messages)) {
      yield { type: 'model-event', event };

      if (event.type === 'tool-call-ready') {
        const result = await deps.executeTool(event.tool);
        yield { type: 'tool-result', result };
        messages.push(result);
      }
    }

    messages.push(yield { type: 'turn-complete' });
  }
}
```

### Consumer 1: REPL UI

```typescript
async function runREPL() {
  const agent = createAgent(initialMessages, deps);

  for await (const event of agent) {
    switch (event.type) {
      case 'model-event':
        if (event.event.type === 'content-delta') {
          process.stdout.write(event.event.content);
        }
        break;
      case 'tool-result':
        renderToolResult(event.result);
        break;
      case 'turn-complete':
        promptUser();
        break;
    }
  }
}
```

### Consumer 2: Sub-Agent Observer

```typescript
async function* createObserverAgent(
  parentAgent: AsyncGenerator<ParentEvent>,
  hooks: ObserverHooks
): AsyncGenerator<AgentEvent> {
  // Re-yield todos los eventos del parent, pero intersectar algunos
  for await (const event of parentAgent) {
    // Hook para cada evento
    hooks.onEvent?.(event);

    // Posiblemente transformar o filtrar
    if (shouldForward(event)) {
      yield transform(event);
    }
  }
}
```

### Consumer 3: Testing con Mocks

```typescript
async function testAgentBehavior() {
  // Crear eventos mock predeterminados
  const mockEvents: ModelEvent[] = [
    { type: 'content-delta', content: 'Hello' },
    { type: 'content-delta', content: ' world' },
    { type: 'tool-call-start', tool: 'Read' },
    { type: 'tool-call-complete', tool: 'Read', input: { file: 'test.js' } },
  ];

  // Mock del generator
  async function* mockCallModel() {
    yield* mockEvents;
  }

  // Crear agent con deps inyectadas
  const agent = createAgent([], {
    ...deps,
    callModel: mockCallModel // ← Mock injectable
  });

  // Coleccionar eventos
  const observed: AgentEvent[] = [];
  for await (const event of agent) {
    observed.push(event);
  }

  // Assertions
  assert(observed.some(e =>
    e.type === 'tool-result' && e.result.tool === 'Read'
  ));
}
```

## Zero Duplication

> *"One query() function, three callers, zero duplication."*

Lo mismo que hace el agent está disponible para:
- **UI en tiempo real** — renderiza cada evento
- **Testing determinístico** — mock completo sin API real
- **Sub-agents** — observan o interceptan eventos
- **Monitoring/logging** — sin modificar el agent

## Dependency Injection Hace Testing Trivial

En lugar de mockear una función concreta:

```typescript
// ❌ Hardcoded dependency — difícil de testear
class BadAgent {
  async callModel(messages) {
    return await openai.chat.completions.create({
      model: 'gpt-4',
      messages
    });
  }
}

// ✅ Dependency injection — trivial de testear
interface LLMClient {
  call(messages: Message[], options?: CallOptions): AsyncGenerator<ModelEvent>;
}

async function* createAgent(deps: {
  llm: LLMClient; // ← Injectable
}) {
  for await (const event of deps.llm.call(messages)) {
    yield event;
  }
}

// Test con mock:
const mockLlm = {
  async *call() {
    yield { type: 'content-delta', content: 'test' };
  }
};

const agent = createAgent({ llm: mockLlm });
```

### Dependency Injection en Profundidad

```typescript
interface AgentDependencies {
  // Model
  callModel: (
    messages: Message[],
    options: ModelOptions
  ) => AsyncGenerator<ModelEvent>;
  fallbackModel?: LLMClient;

  // Tools
  executeTool: (
    tool: ToolCall,
    options?: ToolOptions
  ) => Promise<ToolResult>;
  toolRegistry: Map<string, ToolDefinition>;

  // Context management
  compactionStrategy: CompactionStrategy;
  budgetEnforcer: BudgetEnforcer;

  // Configuration
  maxTurns: number;
  outputTokenBudget: number;

  // Cancellation
  signal?: AbortSignal;

  // Observability
  logger?: Logger;
  metrics?: MetricsCollector;
}

// Crear agent con TODAS las deps inyectadas
async function* createAgent(deps: AgentDependencies) {
  // El cuerpo del agent no sabe nada concret — solo usa las interfaces
}
```

## Composition de Múltiples Generators

Los generators pueden componerse:

```typescript
// Pipeline: preprocessor → agent → postprocessor
async function* pipeline(input: Message[]) {
  const preprocessed = preprocessor(input);
  const agentEvents = createAgent(preprocessed);
  const processed = postprocessor(agentEvents);

  for await (const event of processed) {
    yield event;
  }
}

// Fan-out: un agent alimenta múltiples consumers
async function fanOut(agent: AsyncGenerator<Event>) {
  const consumers = [
    createLogger(),
    createMetricsCollector(),
    createUIRenderer()
  ];

  for await (const event of agent) {
    // El evento va a todos los consumers
    await Promise.all(consumers.map(c => c.process(event)));
    yield event; // También re-yields para el consumer original
  }
}
```

## El Patrón Adapter

Si tienes un agent que no usa async generators, puedes envolverlo:

```typescript
// Wrapper que convierte un agent monolith en un generator
async function* wrapLegacyAgent(
  legacyAgent: LegacyAgent
): AsyncGenerator<AgentEvent> {
  // El legacy agent usa callbacks
  const events = await new Promise<AgentEvent[]>((resolve) => {
    legacyAgent.run({
      onModelEvent: (e) => resolve([...accumulatedEvents, e]),
      onComplete: () => resolve(accumulatedEvents)
    });
  });

  // Yield todos los eventos acumulados
  for (const event of events) {
    yield event;
  }
}
```

## Contrast: Composition vs Inheritance

### Con Inheritance (Anti-Patrón)

```typescript
// ❌ inheritance coupling
class BaseAgent {
  async *run() { ... }
}

class LoggingAgent extends BaseAgent {
  // Override completo para añadir logging
  async *run() {
    for await (const event of super.run()) {
      await log(event);
      yield event;
    }
  }
}

class MetricsAgent extends BaseAgent {
  async *run() {
    for await (const event of super.run()) {
      await recordMetrics(event);
      yield event;
    }
  }
}

// Si quieres logging + metrics... múltiples inheritance? Mixins?
```

### Con Composition (Patrón Recomendado)

```typescript
// ✅ Composition — apilar behaviors
function withLogging(agent) {
  return async function* (...args) {
    for await (const event of agent(...args)) {
      await log(event);
      yield event;
    }
  };
}

function withMetrics(agent) {
  return async function* (...args) {
    for await (const event of agent(...args)) {
      await recordMetrics(event);
      yield event;
    }
  };
}

// Uso:
const loggedAgent = withLogging(baseAgent);
const meteredAgent = withMetrics(loggedAgent);
const finalAgent = withLogging(withMetrics(baseAgent));
```

## Testabilidad

La composabilidad hace testing trivial:

```typescript
describe('Agent Loop', () => {
  it('should retry on rate limit', async () => {
    // Mock que falla 429 la primera vez, succeed después
    let callCount = 0;
    async function* mockModel() {
      callCount++;
      if (callCount === 1) {
        throw { status: 429 };
      }
      yield { type: 'stop', reason: 'complete' };
    }

    const agent = createAgent({
      ...deps,
      callModel: mockModel,
      maxRetries: 3
    });

    const events = [];
    for await (const event of agent) {
      events.push(event);
    }

    expect(callCount).toBe(2);
  });
});
```

## Cuándo NO Usar Este Patrón

- **Sesiones muy simples** donde un solo caller usa el agent
- **Performance crítica** donde el overhead del generator es problemático
- **Estado muy complejo** que no puede modelarse como stream de eventos

Para la mayoría de agent systems, especialmente los que necesitan cancellation, streaming, y testing, el async generator como interfaz es el mejor tradeoff.

## Referencias

- **[[async-generators]]**: El tipo que habilita composability
- **[[dependency-injection]]**: Cómo se inyectan las dependencias
- **[[agent-loop]]**: El loop que se envuelve en un generator
- **[[testing-strategies]]**: Cómo testear agents composables
