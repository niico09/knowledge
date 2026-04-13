# Context Flooding

## Definición

**Context flooding** ocurre cuando el context window se llena con datos irrelevantes, redundantes o excesivos (logs, outputs masivos, histórico innecesario), dejando poco espacio para que el modelo piense y mantenga coherencia.

Es el equivalente a tratar de tener una conversación inteligente mientras alguien te grita datos aleatorios en el oído — la señal se pierde en el ruido.

## Síntomas en Producción

### Síntomas Comportamentales

```typescript
// El agent empieza a "olvidar"
agent: "As I mentioned earlier..."
user: "You never mentioned that"

→ Contexto histórico se llenó de ruido, relevante no tiene espacio

// Agent repite trabajo
agent: "Let me read that file again"
agent: "Let me read that file again"
agent: "Let me read that file again"

→ Agent no recuerda que ya leyó el archivo

// Agent pierde el hilo
agent: "I'll fix the bug in auth.ts"
[30 seconds later]
agent: "Now let me check the user model"
→ Perdió track de qué estaba haciendo

// Agent da respuestas degradadas
agent: "I need more context about the codebase"
→ El contexto está dominado por tool outputs, no por instrucciones
```

### Síntomas Técnicos

```typescript
// Tokens exceed threshold
contextTokens > CONTEXT_LIMIT * 0.95

// Compaction triggers frecuentemente
compactionCount++ every few turns

// Tool result budgets apply
truncatedResults = true

// Protected tail shrinks
protectedMessages < 5
```

## Causas Principales

### Causa 1: Tool Outputs Masivos

```bash
# El usuario corre sin saber las consecuencias:
kubectl logs -n production --all-containers > /tmp/all.txt
cat /tmp/all.txt
# Output: 500MB de logs, 10M tokens

# Otro ejemplo:
find / -type f -name "*.log" 2>/dev/null | xargs wc -l
# Output: miles de líneas de output de sistema de archivos
```

**Por qué pasa:**
- El usuario no sabe cuánto output produce su comando
- `cat` o `ls` parecen inofensivos pero pueden ser masivos
- El agent no sabe el tamaño antes de ejecutar

### Causa 2: Acumulación de Histórico

```
Sesión de debugging típica:
Turn 1-10:   User hace preguntas, agent lee archivos
Turn 11-50:  Agent investiga, muchos reads, greps
Turn 51-100: Agent propone fixes, edita archivos
Turn 100+:   Sesión sigue...

Sin compaction:
  → Cada turn añade mensajes al history
  → History crece linearmente
  → Eventually dominan el context
```

### Causa 3: Logs de Comandos Secuenciales

```typescript
// Agent ejecuta muchos comandos pequeños con output
Bash({ cmd: 'ls -la' })              // 50 líneas
Bash({ cmd: 'git status' })          // 20 líneas
Bash({ cmd: 'git log --oneline -20' }) // 20 líneas
Bash({ cmd: 'ps aux | grep node' })  // 10 líneas
// Cada uno pequeño, pero acumulando...
// 10 comandos × 20 líneas = 200 líneas = ~1K tokens por turn
// × 100 turns = 100K tokens solo de outputs menores
```

### Causa 4: Media Pesada en Mensajes

```
El agent procesa imágenes:
- Screenshots de error
- Diagramas
- UI mockups

Cada imagen → embedding de ~10K tokens
10 imágenes = 100K tokens de media

Queda poco espacio para el conversation real
```

## El Ciclo Vicioso

```
1. Contexto crece un poco
2. Más tools se invocan
3. Más outputs se acumulan
4. Compaction se trigger
5. Pero compaction también consume tokens
6. Agent tiene menos espacio disponible
7. Agent trabaja menos eficientemente
8. Necesita más turns para completar tarea
9. → goto 1
```

## Soluciones: Defense in Depth

### Layer 1: Tool Result Budgeting

```typescript
// Prevenir que tool outputs dominen
const BUDGET = {
  Read: { maxChars: 100_000 },      // 100KB max
  Bash: { maxChars: 50_000 },       // 50KB max
  Grep: { maxChars: 10_000 },       // 10KB max
};

function applyBudget(result: ToolResult, config: ToolBudget): ToolResult {
  if (result.content.length > config.maxChars) {
    return {
      type: 'file-reference',
      path: persistToFile(result.content),
      preview: result.content.substring(0, 500),
    };
  }
  return result;
}
```

Ver: **[[tool-budgets]]**

### Layer 2: Compaction Hierarchy

```typescript
// Cuando budgeting no es suficiente, compact
const COMPACTION_STRATEGY = {
  // Microcompact: cada turn, ~0 costo
  microcompact: true,

  // Snip: cuando > 80% tokens, ~0 costo
  snipThreshold: 0.8,

  // Auto Compact: cuando snip falla, 1 model call
  autoCompactThreshold: 0.9,

  // Context Collapse: feature flag, último recurso
  enableContextCollapse: false,
};
```

Ver: **[[compaction-hierarchy]]**

### Layer 3: Protected Tail

```typescript
// Nunca resumir los últimos N mensajes
const PROTECTED_TAIL = {
  minMessages: 10,
  minTokens: 4000,
};

function compact(messages: Message[]): Message[] {
  // ... apply compaction strategies ...

  // Asegurar que protected tail está intacto
  const protectedTail = messages.slice(-PROTECTED_TAIL.minMessages);
  const compacted = applyCompaction(messages);

  return [...compacted, ...protectedTail];
}
```

### Layer 4: Token Validation Pre-API

```typescript
async function validateBeforeAPI(messages: Message[]): Promise<void> {
  const totalTokens = await countTokens(messages);

  if (totalTokens > CONTEXT_LIMIT) {
    throw new Error('Context overflow - cannot proceed');
  }

  if (totalTokens > CONTEXT_LIMIT * 0.95) {
    // Warning pero no blocking
    logger.warn('Context at 95%', {
      tokens: totalTokens,
      compactionRecommended: true
    });
  }

  const toolResultTokens = countToolResultTokens(messages);
  if (toolResultTokens > totalTokens * 0.5) {
    // Tool results dominan más del 50%!
    logger.warn('Context flooded with tool results', {
      toolResultTokens,
      totalTokens,
      percentage: (toolResultTokens / totalTokens) * 100
    });
  }
}
```

## Señales de Warning Temprano

```typescript
interface FloodIndicators {
  // Métricas técnicas
  tokenRatio: number;           // tool-result-tokens / total-tokens
  compactionFrequency: number;   // compactions por minuto
  avgTurnLength: number;        // tokens promedio por turn
  truncationRate: number;       // % de resultados truncados

  // Métricas comportamentales
  repetitionRate: number;        // Veces que agent repite actions
  contextLossRate: number;     // Veces que agent "olvida" contexto
  suggestionQuality: number;    // Calidad de sugerencias empeorando
}

function detectFlooding(indicators: FloodIndicators): FloodingLevel {
  if (indicators.tokenRatio > 0.7) return 'critical';
  if (indicators.compactionFrequency > 2) return 'high';
  if (indicators.repetitionRate > 0.1) return 'medium';
  return 'low';
}
```

## Intervención Proactiva

```typescript
async function proactiveContextManagement(
  messages: Message[],
  indicators: FloodIndicators
): Promise<ManagementAction> {
  const level = detectFlooding(indicators);

  switch (level) {
    case 'critical':
      // Forzar compaction ahora
      return { action: 'compact-now', strategy: 'auto' };

    case 'high':
      // Sugerir al usuario que considere hacer checkpoint
      return {
        action: 'user-prompt',
        message: 'Session is getting long. Consider saving progress and starting fresh?'
      };

    case 'medium':
      // Aplicar microcompact aggressive
      return { action: 'compact-now', strategy: 'micro' };

    case 'low':
      // No hacer nada,monitorear
      return { action: 'monitor' };
  }
}
```

## Casos de Estudio

### Caso 1: El Log Sprawl

```
User: "Debug the production issue"
Agent: kubectl logs -n prod... → 500K tokens de logs
Agent reads logs → context dominated
Agent ignores actual problem → poor response
```

**Solución**: Budget los logs antes de pasarlos al modelo

### Caso 2: The Accumulating Session

```
Turn 1-50: Normal debugging session
Turn 51: Agent starts repeating reads
Turn 52: Agent "forgets" what it was doing
Turn 53: Agent asks user to repeat instructions
```

**Solución**: Compaction hierarchy que se activa antes de que sea crítico

### Caso 3: The Verbose Output

```
Agent runs: git diff HEAD~50..HEAD
Output: 10MB de diff, 200K tokens
Context flooded
Agent has no room to analyze the diff
```

**Solución**: Budget con truncation + file reference

## Cultura de Prevención

```
El flooding no es solo un problema técnico — es un problema de UX:

1. User debería ver cuando el contexto está creciendo
2. User debería poder decir "enough context, compact"
3. User debería poder ver qué está consumiendo el contexto
4. User debería poder discardtool outputs específicos

类似 a Memory profiler en un IDE:
- Ver qué está usando memoria
- Poder limpiar cuando sea necesario
```

## Referencias

- **[[tool-budgets]]**: Prevenir overflow de tool outputs
- **[[compaction-hierarchy]]**: Reducir contexto cuando ya creció
- **[[protected-tail]]**: Preservar lo más reciente
- **[[token-validation]]**: Detección temprana
