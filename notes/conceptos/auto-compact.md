# Auto Compact

## Definición

**Auto Compact** es la tercera estrategia en la jerarquía de compaction. Se activa cuando token usage cruza un threshold Y snip no fue suficiente.

Usa un **model call separado** para resumir la conversación anterior, preservando la mayor cantidad de información en el menor número de tokens.

## Diferencia Crítica con Snip

| Aspecto | Snip Compact | Auto Compact |
|---------|-------------|--------------|
| Mechanism | Remove messages | Summarize + replace |
| Model call | No | Sí |
| Information loss | Total (gone forever) | Parcial (preserved as summary) |
| Recovery | No | Sí (puedes recover el summary text) |
| Costo | ~5ms | ~500ms + tokens de summarization |

Snip es como arrancar páginas de un libro. Auto Compact es como reemplazar 10 páginas con 1 página de resumen.

## Cuándo Se Activa

```typescript
function shouldAutoCompact(
  messages: Message[],
  state: CompactionState
): AutoCompactDecision {
  const totalTokens = countTokens(messages);

  // 1. Debe haber pasado el threshold de snip
  if (totalTokens < CONTEXT_LIMIT * 0.85) {
    return { shouldCompact: false, reason: 'below-threshold' };
  }

  // 2. Snip ya se intentó y no fue suficiente
  if (state.lastCompaction === 'snip' && totalTokens > CONTEXT_LIMIT * 0.85) {
    // Snip didn't help enough
  }

  // 3. No debemos exceed el counter de summarizations
  if (state.summaryCount >= MAX_SUMMARIES) {
    return { shouldCompact: false, reason: 'max-summaries-reached' };
  }

  // 4. Si el último compaction fue un summary, no resumir de nuevo
  if (state.lastCompaction === 'summary' && state.summaryCount > 2) {
    return { shouldCompact: false, reason: 'no-summarize-summaries' };
  }

  return { shouldCompact: true };
}
```

## Cómo Funciona

### Paso 1: Separar Protected Tail vs Historical Messages

```typescript
function partitionMessages(
  messages: Message[],
  protectedTailCount: number
): { historical: Message[], protectedTail: Message[] } {
  return {
    historical: messages.slice(0, -protectedTailCount),
    protectedTail: messages.slice(-protectedTailCount)
  };
}
```

### Paso 2: Construir Prompt de Summarization

```typescript
function buildSummaryPrompt(historicalMessages: Message[]): string {
  return `You are a precise summarizer. Summarize the following conversation concisely while preserving:

1. Key decisions made and their rationale
2. Important context needed to continue the current work
3. Any unresolved issues or pending tasks
4. Specific values, names, or identifiers that were mentioned
5. The overall goal or objective being pursued

CONVERSATION TO SUMMARIZE:

${formatMessagesAsDialogue(historicalMessages)}

SUMMARY (preserve specific details, not generic descriptions):`;
}
```

### Paso 3: Llamar al Modelo de Summarization

```typescript
async function generateSummary(
  historicalMessages: Message[],
  options: SummaryOptions
): Promise<SummaryResult> {
  const prompt = buildSummaryPrompt(historicalMessages);

  // Usar modelo más barato si está disponible
  // Summarization no necesita Opus — Haiku o Sonnet basta
  const model = options.fallbackModel || 'claude-haiku';

  const response = await callModel({
    model,
    messages: [{ role: 'user', content: prompt }],
    maxTokens: options.targetSummaryTokens || 2000
  });

  return {
    summary: extractContent(response),
    originalTokenCount: countTokens(historicalMessages),
    summaryTokenCount: countTokens(response)
  };
}
```

### Paso 4: Reconstruir Mensajes

```typescript
function applyAutoCompact(
  messages: Message[],
  summary: SummaryResult,
  protectedTail: Message[],
  state: CompactionState
): Message[] {
  // Crear mensaje de resumen
  const summaryMessage: Message = {
    role: 'system',
    content: `[Prior conversation summarized: ${summary.summary}]`,
    metadata: {
      compactionType: 'auto',
      originalTokens: summary.originalTokenCount,
      summaryTokens: summary.summaryTokenCount
    }
  };

  // Persistir historial original en disco por si se necesita después
  const archivePath = persistHistoryToDisk(messages);

  // Update state
  state.lastCompaction = 'summary';
  state.summaryCount++;
  state.historyArchive = archivePath;

  return [summaryMessage, ...protectedTail];
}
```

## Compaction State Tracking

Auto Compact mantiene estado para **prevenir loops**:

```typescript
interface CompactionState {
  summaryCount: number;         // Cuántas veces se ha resumido
  lastCompaction: CompactionType;
  historyArchive: string | null;  // Path al archivo con histórico
  lastSummaryWasOfSummary: boolean;
  summaryTokensUsed: number;
}

const MAX_SUMMARY_COUNT = 3;
const MAX_SUMMARY_TOKENS = 10000; // No gastar más de 10K en summaries

function shouldAutoCompact(state: CompactionState): boolean {
  // No resumir si ya resumimos demasiado
  if (state.summaryCount >= MAX_SUMMARY_COUNT) {
    return false;
  }

  // No resumir summaries (previene recursion)
  if (state.lastSummaryWasOfSummary) {
    return false;
  }

  return true;
}
```

## El Problema de Summarize Summaries

```
Turn 10: Summarize (100 msgs → 1 summary)
Turn 20: Summarize (100 more msgs → 1 summary)
Turn 30: Summarize (SUMMARY + 100 msgs → summary of summaries?)

Si dejas que el modelo resuma summaries:
  → La información se degrada rápidamente
  → Detalles específicos se pierden
  → El modelo empieza a perder track de qué es qué
```

Claude Code previene esto trackeando si el último compaction fue un summary y evitando resumir summaries.

## Qué Se Persiste en Disco

```typescript
// Para cada summarization,archivar el histórico
async function persistHistoryToDisk(
  messages: Message[],
  sessionId: string
): Promise<string> {
  const path = `${CLAUDE_TEMP_DIR}/${sessionId}/history-${Date.now()}.json`;

  await fs.writeFile(path, JSON.stringify({
    messages,
    metadata: {
      persistedAt: new Date().toISOString(),
      tokenCount: countTokens(messages)
    }
  }, null, 2));

  return path;
}

// Posibilidad de recover si el usuario lo pide
async function recoverHistoricalMessages(archivePath: string): Promise<Message[]> {
  const data = await fs.readFile(archivePath, 'utf-8');
  return JSON.parse(data).messages;
}
```

## Impacto y Savings

### Antes

```
100 mensajes históricos: ~120,000 tokens
Protected tail: ~15,000 tokens
Total: ~135,000 tokens (sobre 200K limit)
```

### Después

```
Summary: ~2,000 tokens (preserve key info)
Protected tail: ~15,000 tokens
Total: ~17,000 tokens (bien bajo limit)

Ahorro: ~118,000 tokens
```

### Costo Real

```
Tokens usados para summary: ~2,000 tokens
Costo API (Haiku): ~$0.0001 por summary
Tokens guardados: ~118,000 tokens
Costo de guardar esos tokens en contexto: ~$0.35 (con Opus)
Net savings: ~$0.35 - $0.0001 = $0.35 por compaction
```

## Elección del Modelo de Summarization

```typescript
interface ModelStrategy {
  // Para sessions cortas: usar modelo barato
  if (totalTurns < 50) {
    return 'haiku'; // $0.0001/1K tokens
  }

  // Para sessions medias: usar modelo del agent
  if (totalTurns < 200) {
    return agentModel; // Lo que sea que esté usando
  }

  // Para sessions largas: fallback a haiku (ya tenemos contexto extenso)
  return 'haiku';
}
```

## Qué Hace un Good Summary

```typescript
// ✅ BUEN summary (preserva specifics)
"[Prior conversation: Implemented JWT authentication in auth/jwt.ts.
Set up bcrypt password hashing with 12 rounds.
Created /api/auth/login and /api/auth/register endpoints.
User mentioned they prefer TypeScript strict mode.
Outstanding: Need to add refresh token rotation.
Goal: Complete auth flow before starting billing module.]"

// ❌ MAL summary (generic, perdi o specifics)
"[The user discussed implementing authentication. Various files were created.
We talked about security. More work is needed on this feature.]"
```

La diferencia es que el buen summary preserva:
- Specific file paths y nombres
- Specific decisiones técnicas (no solo "we decided X" sino "why we decided X")
- Pending work identificable
- User preferences mentioned

## Interaction con Other Strategies

```
Setup Phase:
  1. Microcompact → ~10-20% savings, 0 cost
  2. Snip → ~30-50% savings, 0 cost, lossy
  3. Auto Compact → ~70-90% savings, 1 model call, preserves info
```

Auto Compact es significativamente más efectivo que Snip en términos de savings, pero tiene costo.

## Limitaciones

1. **Latencia**: ~500ms extra por summarization
2. **Token cost**: ~2K tokens por summary
3. **Information loss**: Incluso con buen summary, se pierden detalles
4. **Model capability**: La calidad del summary depende de la capacidad del modelo

## Referencias

- **[[compaction-hierarchy]]**: Dónde auto-compact encaja
- **[[context-collapse]]**: La siguiente opción si esto no alcanza
- **[[snip-compact]]**: La opción anterior en el hierarchy
- **[[protected-tail]]**: Cómo se preserva el trabajo reciente
