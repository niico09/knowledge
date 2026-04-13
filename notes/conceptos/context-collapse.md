# Context Collapse

## Definición

**Context Collapse** es la estrategia de compaction más agressiva y costosa. Reserved para sesiones que han estado corriendo por horas y nada más funciona. Usa **multi-phase staged compression** para reducir el contexto cuando Microcompact, Snip, y Auto Compact todos fallaron.

## Cuándo Se Activa

```
Compaction State:
  - Microcompact: ✓ Applied (turn-by-turn)
  - Snip: ✓ Applied (multiple times)
  - Auto Compact: ✓ Applied (3+ times)
  - Token count: STILL > 85% of limit

→ Context Collapse (feature flag required)
```

No es automática — requiere que el usuario o admin habilite la feature flag:

```typescript
interface AgentConfig {
  enableContextCollapse: boolean; // Default: false
  contextCollapseMinSessionMinutes: number; // Default: 60
}
```

## Por Qué No Es Automática

Context Collapse es **destructivo**:
- Comprime multiple tool results en summaries
- Elimina detalles de thinking blocks
- Puede perder información importante

Está reservado para:
1. **Sesiones de debugging largas** (2+ horas) donde el usuario explícitamente quiere mantener la sesión viva
2. **Agentes desatendidos** (CI/CD, background tasks) que no pueden restart
3. **Casos donde el usuario choose explícitamente** aceptar la pérdida de fidelity por continuar

## Multi-Phase Staged Compression

### Concepto

```
Phase 1: Tool Results Compression
  - "Read 50 files" → "Read 50 files (details in /tmp/claude-compacted/)"
  - Tool outputs completos → archivos en disco

Phase 2: Thinking Blocks Compression
  - Claude 3.5+ thinking blocks → compressed versions
  - Elimina reasoning intermedio que ya no es relevante

Phase 3: Message Section Compression
  - Grupos de mensajes → compressed summaries
  - Ultra-agresivo, solo preserva decisions clave
```

Cada fase es opcional y puede detenerse si el contexto ya está bajo el target.

## Implementación Detallada

### Phase 1: Tool Results Compression

```typescript
async function compressToolResults(
  messages: Message[],
  options: CompressionOptions
): Promise<CompressionResult> {
  const compressedResults: Map<string, CompressedToolResult> = new Map();

  // Agrupar tool results por tipo
  const toolResults = messages.filter(m => m.role === 'tool');

  for (const result of toolResults) {
    if (result.content.length > options.maxToolResultSize) {
      // Persistir a archivo
      const compressedPath = await persistToCompressedFile(result.content);

      compressedResults.set(result.id, {
        type: 'compressed',
        originalSize: result.content.length,
        compressedPath,
        preview: result.content.substring(0, 500),
        summary: generateToolResultSummary(result)
      });
    }
  }

  // Reemplazar en mensajes
  const compressedMessages = replaceToolResults(messages, compressedResults);

  return {
    messages: compressedMessages,
    bytesSaved: calculateBytesSaved(compressedResults),
    phasesApplied: ['tool-results']
  };
}

function generateToolResultSummary(result: ToolResult): string {
  // Generar un summary de 1-2 líneas del tool result
  return `Tool ${result.tool} returned ${result.content.length} chars.
Key info: ${extractKeyInformation(result.content)}`;
}
```

### Phase 2: Thinking Blocks Compression

```typescript
async function compressThinkingBlocks(
  messages: Message[],
  options: CompressionOptions
): Promise<CompressionResult> {
  // Los thinking blocks de Claude pueden ser très largos
  // Comprimirlos preserva el fact de que hubo thinking
  // pero reduce el espacio

  for (const msg of messages) {
    if (msg.thinkingBlock) {
      const compressed = await compressThinking(
        msg.thinkingBlock,
        options.thinkingBlockBudget
      );
      msg.thinkingBlock = compressed;
    }
  }

  return { messages, bytesSaved: calculateSavings(), phasesApplied: ['thinking'] };
}

async function compressThinking(
  thinking: string,
  budget: number
): Promise<CompressedThinking> {
  // Si el thinking ya cabe en el budget, return as-is
  if (countTokens(thinking) <= budget) {
    return { type: 'original', content: thinking };
  }

  // Summarize el thinking
  const summary = await callModel({
    model: 'haiku',
    messages: [{
      role: 'user',
      content: `Compress this thinking to ~${budget} tokens, preserving key insights:\n\n${thinking}`
    }]
  });

  return {
    type: 'summarized',
    content: summary.content,
    originalTokenCount: countTokens(thinking),
    compressedTokenCount: countTokens(summary.content)
  };
}
```

### Phase 3: Section Compression

```typescript
async function compressSections(
  messages: Message[],
  options: CompressionOptions
): Promise<CompressionResult> {
  // Agrupar mensajes en "secciones" temáticas
  const sections = identifySections(messages);

  for (const section of sections) {
    if (section.tokenCount > options.sectionBudget) {
      // Compress esta sección
      const summary = await summarizeSection(section);
      section.compressTo(summary);
    }
  }

  return reconstructMessages(sections);
}

function identifySections(messages: Message[]): Section[] {
  // Detectar cambios de "tema" en la conversación
  // ej: de "implementing auth" a "adding tests" a "fixing bugs"

  const sections: Section[] = [];
  let currentSection: Section = { messages: [], topic: null };

  for (const msg of messages) {
    const topic = detectTopic(msg);

    if (topic !== currentSection.topic && currentSection.messages.length > 5) {
      // Nuevo tema, cerrar sección anterior
      sections.push(currentSection);
      currentSection = { messages: [msg], topic };
    } else {
      currentSection.messages.push(msg);
    }
  }

  sections.push(currentSection);
  return sections;
}
```

## Persistencia a Disco

```typescript
class ContextArchive {
  private archiveDir: string;

  async persist(
    messages: Message[],
    sessionId: string,
    phase: CollapsePhase
  ): Promise<ArchiveMetadata> {
    const archivePath = `${this.archiveDir}/${sessionId}/collapse-${phase}-${Date.now()}.json`;

    await fs.mkdirp(dirname(archivePath));
    await fs.writeFile(archivePath, JSON.stringify({
      messages,
      phase,
      persistedAt: new Date().toISOString()
    }));

    return {
      path: archivePath,
      tokenCount: countTokens(messages),
      phase
    };
  }

  async recover(archivePath: string): Promise<Message[]> {
    const data = await fs.readFile(archivePath, 'utf-8');
    return JSON.parse(data).messages;
  }
}
```

## Feature Flag y User Consent

```typescript
interface ContextCollapseConfig {
  // Habilitar feature
  enabled: boolean;

  // Minimum session length before enabling
  minSessionMinutes: number;

  // Cuántas fases aplicar como máximo
  maxPhases: CollapsePhase[];

  // Pedir confirmación al usuario?
  requireUserConsent: boolean;

  // Phases específicas a aplicar
  phases: {
    toolResults: boolean;
    thinkingBlocks: boolean;
    sections: boolean;
  };
}

// User-facing prompt cuando se activa
async function promptUserForCollapse(): Promise<boolean> {
  return confirm(
    `Session is very long (${sessionMinutes} minutes).
Context Collapse will compress older conversation to continue.
This may lose some detail. Continue?`
  );
}
```

## Trade-offs

### Lo Que Se Gana

```
Antes: Contexto sobre 200K tokens, agent fallando
Después: Contexto en 30K tokens, agent puede continuar

Capacidad de continuar sesiones de horas
No perder todo el trabajo acumulado
```

### Lo Que Se Pierde

```
Tool results: solo summaries en vez de contenido completo
Thinking blocks: compressed, reasoning detallado perdido
Sections: solo decisiones clave preservadas

El agent ya no puede hacer "vea el output completo de ese comando de hace 2 horas"
```

## Cuándo Usar en Vez de Restart

```
Context Collapse ←→ Restart Session

USE COLLAPSE:
- Session tiene estado que sería costoso perder (ej: largo debugging trail)
- Usuario explícitamente quiere continuar
- El agent está cerca de resolver algo

USE RESTART:
- Session estáConfused (modelo lost track)
- El trabajo acumulado es mayormente ruido
- Usuario prefiere fresh start
```

## Referencias

- **[[compaction-hierarchy]]**: Dónde context-collapse encaja
- **[[auto-compact]]**: La opción anterior antes de collapse
- **[[context-management]]**: El sistema más amplio de management de contexto
