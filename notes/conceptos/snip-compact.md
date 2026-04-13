# Snip Compact

## Definición

**Snip Compact** es la segunda estrategia en la jerarquía de compaction. Se activa cuando el conversation se acerca a los token limits y snip es insuficiente.

Remueve mensajes del **inicio de la conversación** mientras preserva un "protected tail" de mensajes recientes. No requiere model call.

## Diferencia Fundamental con Microcompact

| Aspecto | Microcompact | Snip Compact |
|---------|-------------|--------------|
| Trigger | Cada turn, siempre | Solo cuando token count > threshold |
| Mechanism | Cached references | Remove messages |
| Model call | No | No |
| Lossiness | No (cached = guaranteed identical) | Sí (mensajes se van para siempre) |
| Token savings | Moderate (~10-20%) | High (~30-50%) |

## Protected Tail: El Concepto Clave

El "protected tail" son los últimos N mensajes que **nunca** se resumen ni se eliminan. La hipótesis es que el trabajo reciente es más relevante que el histórico.

```typescript
interface SnipConfig {
  protectedTailMessages: number;  // ej: 10 mensajes
  protectedTailTokens: number;    // ej: 4000 tokens
}

function applySnipCompact(
  messages: Message[],
  config: SnipConfig
): Message[] {
  // 1. Encontrar el punto de corte
  // 2. Remover todo antes del protected tail
  // 3. Agregar marker de truncamiento
}
```

## Cómo Funciona Paso a Paso

### Paso 1: Calcular Tokens Totales

```typescript
async function calculateSnipNeeded(
  messages: Message[],
  config: SnipConfig
): Promise<SnipDecision> {
  const totalTokens = await countTokens(messages);
  const targetTokens = CONTEXT_LIMIT * 0.75; // Trigger at 75%

  if (totalTokens < targetTokens) {
    return { shouldSnip: false };
  }

  // Cuántos tokens necesitamos remover?
  const tokensToRemove = totalTokens - targetTokens;

  return {
    shouldSnip: true,
    tokensToRemove,
    protectedTail: getProtectedTail(messages, config.protectedTailMessages)
  };
}
```

### Paso 2: Encontrar el Punto de Corte

```typescript
function findCutPoint(
  messages: Message[],
  tokensToRemove: number,
  protectedTailCount: number
): number {
  // Empezar desde el inicio, ir hacia adelante
  // until we've removed enough tokens
  let tokensRemoved = 0;
  let cutIndex = messages.length - protectedTailCount; // Start of protected

  for (let i = 0; i < cutIndex; i++) {
    const msgTokens = estimateTokens(messages[i]);

    // ¿Remover este mensaje nos pone bajo el target?
    if (tokensRemoved + msgTokens > tokensToRemove) {
      // Stop here — no removemos más
      break;
    }

    tokensRemoved += msgTokens;
    cutIndex = i + 1; // Cut after this message
  }

  return cutIndex;
}

function getProtectedTail(messages: Message[], count: number): Message[] {
  // Siempre proteger los últimos N mensajes
  return messages.slice(-count);
}
```

### Paso 3: Aplicar el Snip

```typescript
function applySnip(
  messages: Message[],
  cutIndex: number,
  protectedTail: Message[]
): Message[] {
  const removedCount = cutIndex;
  const removedMessages = messages.slice(0, cutIndex);
  const removedTokens = estimateTokens(removedMessages);

  // Crear marker de truncamiento
  const truncationMarker: Message = {
    role: 'system',
    content: `[Conversation truncated: ${removedCount} messages (${removedTokens} tokens) removed. Preserved last ${protectedTail.length} messages for context.]`
  };

  // Retornar marker + protected tail
  return [truncationMarker, ...protectedTail];
}
```

## Ejemplo Visual

```
ANTES (100 mensajes, 180K tokens):
[Msg 1] [Msg 2] [Msg 3] ... [Msg 90] [Msg 91] ... [Msg 100]
  ↑                                         ↑
Start                                    Protected tail (últimos 10)

DESPUÉS DE SNIP (10 mensajes, 12K tokens):
[System: Truncated 90 messages] [Msg 91] [Msg 92] ... [Msg 100]
```

## El Protected Tail en Detalle

### Qué Protegemos

```typescript
interface ProtectedTailPolicy {
  // Siempre proteger los últimos N mensajes
  minMessagesProtected: 10;

  // Proteger hasta X tokens
  maxTokensProtected: 4000;

  // Proteger ciertos tipos de mensajes SIEMPRE
  protectedRoles: ['user', 'assistant']; // Nunca干掉system de contexto
  protectedToolResults: boolean; // Resultados de tools no se snipean?
}

function shouldProtect(message: Message, policy: ProtectedTailPolicy): boolean {
  // Messages con ciertas properties son always protected
  if (message.isCheckpoint) return true;
  if (message.role === 'system') return true;
  if (message.isUserInput) return true;

  return false;
}
```

### Qué NO Protegemos (y Por Qué)

```typescript
// Estos mensajes SON elegibles para snip:

// Viejo intercambio de debugging que ya se resolvió
{ role: 'assistant', content: "Intentando leer el archivo..." }
{ role: 'tool', toolResult: "File not found" }
{ role: 'assistant', content: "El archivo no existe, voy a crearlo" }
{ role: 'user', content: "Sí, créalo" }

// Estos pueden snipearse porque:
1. Son old (fueron reemplazados por acciones concrete)
2. El resultado ya está incorporated en state
3. Mantenerlos vs no mantenerlos no cambia el outcome actual
```

## Cuándo Aplica Snip

```typescript
function shouldUseSnip(messages: Message[], config: SnipConfig): boolean {
  // 1. Snip solo si excedemos threshold
  const totalTokens = countTokens(messages);
  if (totalTokens < CONTEXT_LIMIT * 0.8) {
    return false; // No es necesario aún
  }

  // 2. Microcompact ya se intentó (en setup phase)
  // Si aún estamos sobre budget, snip

  // 3. Pero solo si hay suficiente "old" content para snipear
  const nonProtectedCount = messages.length - config.protectedTailMessages;
  if (nonProtectedCount < 20) {
    return false; // No hay suficiente histórico para méritar snip
  }

  return true;
}
```

## Límites y Trade-offs

### Lo Que Se Pierde

```
[Msg 1] → [Msg 10]: "Vamos a refactorizar el auth system"
[Msg 11] → [Msg 30]: Implementación detallada (SNIPEADO)
[Msg 31] → [Msg 40]: "OK, el auth está listo, ahora el billing"
```

Después del snip, el modelo ya no sabe *cómo* se implementó el auth system. Si necesita hacer cambios en esa área, no tiene el contexto.

### Señales de Que Snip Está Dañando

```typescript
// El modelo empieza a "olvidar" decisiones recientes
// O empieza a repetir trabajo que ya hizo
// O hace preguntas cuyas respuestas estaban en mensajes snipeados

const warningSigns = [
  "We're going to refactor the auth system", // Nuevo contexto, inesperado
  "Let me read that file again", // Pregunta repetitiva
  "As I mentioned earlier", // El modelo assume historical context
];
```

## Por Qué No Empezar con Auto Compact

> *"Most harnesses that implement compaction at all jump straight to summarization."*

La diferencia de costo:

| Estrategia | Model Calls | Latency Agregada | Tokens de Costo |
|-----------|-------------|-------------------|-----------------|
| Microcompact | 0 | ~0ms | ~0 |
| Snip | 0 | ~5ms (hash calc) | ~0 |
| Auto Compact | 1 (summarization) | ~500ms | ~500-2000 |
| Context Collapse | Múltiples | ~2000ms | ~3000+ |

Snip handles 30-50% de casos de growth a costo near-zero. Auto Compact es para cuando eso falla.

## Interaction con Other Phases

```
Setup Phase:
  1. Microcompact (por tool, near-zero cost)
  2. Si aún > 80% tokens: Snip (near-zero cost, lossy)
  3. Si aún > 80% tokens: Auto Compact (1 model call)
```

## Referencias

- **[[compaction-hierarchy]]**: Dónde snip encaja en el hierarchy
- **[[auto-compact]]**: La siguiente opción si snip no alcanza
- **[[protected-tail]]**: El concepto de qué se preserva
- **[[context-flooding]]**: Qué estamos previniendo
