# Microcompact

## Definición

**Microcompact** es la estrategia de compaction más ligera del hierarchy. Se ejecuta **cada turn**, antes de la API call, con costo computacional ~cero. Su objetivo es eliminar redundancia trivially detectada: resultados de tools que fueron llamadas con exactamente los mismos parámetros.

Es la primera línea de defensa contra el crecimiento del contexto, no la última.

## La Observación Central

En una sesión de coding típica, el agent lee el mismo archivo múltiples veces mientras navega por un codebase:

```
Turn 1: Read("src/app.ts") → 500 líneas
Turn 2: Read("src/app.ts") → 500 líneas (identicas)
Turn 3: Read("src/app.ts") → 500 líneas (identicas)
Turn 4: Grep("function", "src/app.ts") → 20 matches
Turn 5: Read("src/app.ts") → 500 líneas (identicas)
```

Sin microcompact, cada una de esas 500 líneas se acumula en el context. Con microcompact, después del primer Turn, las llamadas subsiguientes con inputs idénticos se reemplazan con cached references.

## Mecanismo: Cached References

### Hash-Based Deduplication

```typescript
interface CacheEntry {
  inputHash: string;
  outputHash: string;
  cachedReference: string;
  accessCount: number;
  lastAccess: number;
}

class MicrocompactCache {
  private cache = new Map<string, CacheEntry>();

  // Genera hash único para el tool call
  private hashToolCall(toolCall: ToolCall): string {
    return sha256(`${toolCall.name}:${JSON.stringify(toolCall.input)}`);
  }

  // Check si tenemos un cache hit
  get(toolCall: ToolCall): CacheEntry | null {
    const key = this.hashToolCall(toolCall);
    const entry = this.cache.get(key);

    if (entry) {
      entry.accessCount++;
      entry.lastAccess = Date.now();
    }

    return entry || null;
  }

  // Guardar resultado
  set(toolCall: ToolCall, output: string): void {
    const key = this.hashToolCall(toolCall);
    this.cache.set(key, {
      inputHash: key,
      outputHash: sha256(output),
      cachedReference: `[Cached: ${toolCall.name}(...)]`,
      accessCount: 1,
      lastAccess: Date.now()
    });
  }
}
```

### Aplicación en el Loop

```typescript
async function applyMicrocompact(
  messages: Message[],
  cache: MicrocompactCache
): Message[] {
  const result: Message[] = [];

  for (const msg of messages) {
    // Solo tools pueden ser cached
    if (msg.role !== 'tool') {
      result.push(msg);
      continue;
    }

    // Check cache
    const cacheEntry = cache.get(msg.toolCall);

    if (cacheEntry && isUnchanged(msg.content, cacheEntry.outputHash)) {
      // Reemplazar con cached reference
      result.push({
        role: 'tool',
        toolCallId: msg.toolCallId,
        toolCall: msg.toolCall,
        content: cacheEntry.cachedReference, // ~30 chars vs 500+ líneas
        cached: true // Metadata para debugging
      });
    } else {
      result.push(msg);
      // Update cache con el contenido real
      cache.set(msg.toolCall, msg.content);
    }
  }

  return result;
}
```

## Qué Se Cacha y Qué No

### Se Cachan (Cache Hits)

```typescript
// Mismo archivo, mismo contenido
Read({ file: "src/app.ts" })           // Turn 1: cache miss, store
Read({ file: "src/app.ts" })           // Turn 2: cache HIT

// Mismo glob pattern
Glob({ pattern: "src/**/*.ts" })       // Turn 1: miss
Glob({ pattern: "src/**/*.ts" })       // Turn 2: HIT si no changed

// Mismo grep query
Grep({ pattern: "function", file: "src/app.ts" })  // Turn 1: miss
Grep({ pattern: "function", file: "src/app.ts" })  // Turn 2: HIT
```

### NO Se Cachan (Always Run)

```typescript
// Contenido diferente
Read({ file: "src/app.ts" })           // Turn 1
Read({ file: "src/utils.ts" })        // Different file

// Bash commands son NON-DETERMINISTIC por default
Bash({ command: "ls -la" })            // Turn 1: run (output puede cambiar)
Bash({ command: "ls -la" })           // Turn 2: run (ls output puede cambiar)

// Tool con timestamp
Bash({ command: "date" })             // Never cache (time always different)
```

## Invalidación de Cache

El cache se invalida cuando:

```typescript
interface InvalidationRule {
  tool: string;
  invalidationCondition: (input: ToolInput, currentOutput: string) => boolean;
}

const invalidationRules: InvalidationRule[] = [
  // Read se invalida si el archivo cambió en disco
  {
    tool: 'Read',
    invalidationCondition: (input, output) => {
      const currentMtime = getFileMtime(input.file);
      return currentMtime > cachedTimestamp;
    }
  },

  // Glob se invalida si cualquier file matching cambió
  {
    tool: 'Glob',
    invalidationCondition: (input, output) => {
      return hasFileSystemChangesSince(cachedTimestamp);
    }
  },

  // Bash NUNCA se cacha por default (excepto con flag explícito)
  {
    tool: 'Bash',
    invalidationCondition: () => true // Always re-run
  }
];
```

## Impacto Cuantificado

### Escenario Típico de Coding Session

```
Session: 1 hora de debugging
- 150 turns
- 30 unique files leídos
- Cada file leído ~5 veces promedio
- Cada Read output: ~800 tokens

SIN microcompact:
  150 × 800 = 120,000 tokens solo en reads redundantes

CON microcompact:
  Primer Read de cada file: 30 × 800 = 24,000 tokens
  Reads subsecuentes: 120 × ~0.05 tokens (cached reference) = 6 tokens
  Total: ~24,006 tokens

Ahorro: ~96,000 tokens = ~$0.05 en costs (a $0.003/1K tokens con Opus)
```

## Límites y False Positives

### Edge Case: Archivo Cambió En Disco

```typescript
// El archivo se leyó hace 10 turns
Read({ file: "src/app.ts" })  // Cached

// User edita el archivo externamente
Edit({ file: "src/app.ts", ... })  // En otro lugar, no a través del agent

// Agent lee el archivo otra vez
Read({ file: "src/app.ts" })  // Cache miss! Archivo cambió desde el cache
```

El cache no sabe que el archivo cambió externamente. El invalidation basado en mtime resuelve esto.

### Edge Case: Timestamp in Output

```bash
# Este comando SIEMPRE da output diferente
$ date
Sat Apr 12 10:23:45 UTC 2026

$ date
Sat Apr 12 10:23:46 UTC 2026
```

```typescript
// Bash commands nunca se cachan por default
// A menos que el usuario marque explicitly como idempotent
Bash({
  command: "git status",
  cacheable: true  // Git status es deterministic
})
```

## Costo Real

| Aspect | Costo |
|--------|-------|
| Hash computation (SHA-256) | ~1-5 microsegundos |
| Map lookup | ~1 microsegundo |
| Memory (cache entry) | ~200 bytes por unique tool call |
| Model API calls | 0 |
| Token cost | Near zero |

Para una sesión con 1000 tool calls únicos, el cache usa ~200KB de memoria. Trivial.

## Por Qué Existe

Microcompact es la manifestación de un principio: **no pagues el costo de operations costosas si puedes detectarin which they're redundant**.

La alternativa es "no caching" y dejar que el modelo maneje redundancia — pero eso consume context que podría usarse para trabajo real.

## Referencias

- **[[compaction-hierarchy]]**: Dónde microcompact encaja en el hierarchy
- **[[tool-budgets]]**: Cómo se relaciona con tool result budgeting
- **[[context-management]]**: El contexto más amplio de management de contexto
