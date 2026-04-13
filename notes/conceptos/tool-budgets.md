# Tool Result Budgeting

## Definición

**Tool result budgeting** es el sistema que limita cuánto output de tool se pasa al modelo, previniendo que resultados masivos (logs de 1MB, outputs de commands) inunden el context window con ruido irrelevante.

Cada tool puede producir desde unos bytes hasta gigabytes. Sin budgeting, un solo `cat` en un archivo grande puede destruir una sesión.

## El Problema: Context Flooding

### Sin Budgeting

```
User command: cat /var/log/nginx/access.log
Tool output: 50,000 líneas, 2.4MB de texto
  ↓
Context window: 200K tokens disponible
  ↓
Logs consumen: ~60K tokens
  ↓
Disponible para trabajo real: 140K tokens
  ↓
Sesión larga → logs acumulan → context cada vez más dominado por noise
  ↓
Agent hace garbage porque no tiene espacio para pensar
```

### Síntomas en Producción

1. **Agent pierde coherencia** después de commands que producen output grande
2. **Agent empieza a repetir** porque no tiene contexto suficiente
3. **Respuestas degradas** progresivamente en sesiones largas
4. **Agent ignora instrucciones** porque el contexto está saturado

## Sistema de Budgeting en Tres Capas

Claude Code implementa budgeting en tres niveles:

### Layer 1: Per-Tool maxResultSizeChars

Cada tool define cuánto puede retornar:

```typescript
interface ToolDefinition {
  name: string;
  maxResultSizeChars: number;  // Límite hard de este tool
  maxResultTokens?: number;     // Alternativa en tokens
  category: 'read' | 'write' | 'execute';
}

// Ejemplos de configuración
const ToolConfigs: Record<string, ToolDefinition> = {
  Read: {
    name: 'Read',
    maxResultSizeChars: 100_000,  // 100KB por archivo
    category: 'read'
  },
  Grep: {
    name: 'Grep',
    maxResultSizeChars: 10_000,   // 10KB para resultados de grep
    category: 'read'
  },
  Bash: {
    name: 'Bash',
    maxResultSizeChars: 50_000,   // 50KB para output de comandos
    category: 'execute'
  },
  WebFetch: {
    name: 'WebFetch',
    maxResultSizeChars: 20_000,   // 20KB para contenido web
    category: 'read'
  },
  Glob: {
    name: 'Glob',
    maxResultSizeChars: 5_000,    // 5KB para resultados de glob
    category: 'read'
  },
  Edit: {
    name: 'Edit',
    maxResultSizeChars: 0,        // No produce output
    category: 'write'
  },
};
```

### Layer 2: Total Tool Result Budget

Limita todos los tool results combinados:

```typescript
interface ToolBudgetConfig {
  maxTotalChars: number;          // ej: 200KB total
  maxTotalTokens: number;        // ej: 8K tokens total
  truncationSuffix?: string;      // ej: "... (truncated)"
}

class ToolResultBudgetEnforcer {
  private config: ToolBudgetConfig;

  apply(message: Message): Message {
    const toolResults = message.toolResults || [];
    const overBudget = this.calculateOverhead(toolResults);

    if (overBudget === 0) return message;

    // Truncar del más nuevo al más viejo
    // ( protected tail concept)
    return this.truncate(toolResults, overBudget);
  }

  private truncate(results: ToolResult[], bytesOver: number): ToolResult[] {
    let remaining = bytesOver;
    const truncated = [...results];

    // Empezar desde el principio (más viejo)
    for (let i = 0; i < truncated.length && remaining > 0; i++) {
      const result = truncated[i];
      if (result.content.length <= remaining) {
        remaining -= result.content.length;
        truncated[i] = this.toReference(result);
      } else {
        truncated[i] = this.truncateResult(result, remaining);
        remaining = 0;
      }
    }

    return truncated;
  }

  private toReference(result: ToolResult): ToolResult {
    return {
      type: 'file-reference',
      path: this.persistToTempFile(result.content),
      preview: result.content.substring(0, 500),
      originalSize: result.content.length
    };
  }
}
```

### Layer 3: applyToolBudget Antes de Cada API Call

```typescript
async function prepareMessagesForModel(
  messages: Message[],
  budgetEnforcer: ToolResultBudgetEnforcer
): Promise<Message[]> {
  const result: Message[] = [];

  for (const msg of messages) {
    if (msg.role === 'tool' && msg.toolResults) {
      // Aplicar budgeting a cada tool result
      msg.toolResults = msg.toolResults.map(r =>
        budgetEnforcer.enforce(r)
      );
    }
    result.push(msg);
  }

  // También enforcing el total de tool results en el mensaje
  const totalToolResultTokens = countToolResultTokens(result);

  if (totalToolResultTokens > MAX_TOOL_RESULT_TOKENS) {
    // Truncar o reemplazar con summaries
    return this.compactToolResults(result);
  }

  return result;
}
```

## Qué Ocurre Con Resultados Que Exceden El Límite

### Paso 1: Detectar Overflow

```typescript
function needsBudgeting(result: ToolResult, config: ToolConfig): boolean {
  return result.content.length > config.maxResultSizeChars;
}
```

### Paso 2: Persistir a Archivo

```typescript
async function budgetResult(
  result: ToolResult,
  config: ToolConfig
): Promise<ToolResult> {
  if (result.content.length <= config.maxResultSizeChars) {
    return result; // No necesita budgeting
  }

  // Persistir contenido completo a archivo temporal
  const tempPath = path.join(
    os.tmpdir(),
    `claude-tool-${Date.now()}-${Math.random().toString(36).slice(2)}.txt`
  );

  await fs.writeFile(tempPath, result.content);

  // Retornar referencia + preview
  return {
    type: 'file-reference',
    path: tempPath,
    preview: result.content.substring(0, config.maxResultSizeChars / 10),
    originalSize: result.content.length,
    toolCall: result.toolCall,
    timestamp: Date.now()
  };
}
```

### Paso 3: El Modelo Recibe Path + Preview

El modelo no recibe el output completo — recibe un placeholder:

```xml
<tool_result>
<tool_name>Bash</tool_name>
<output>
File: /tmp/claude-tool-1712901234-abc123.txt (48.2KB)
Preview (first 500 chars):
Apr 12 10:23:45 server nginx: 200 OK /api/users
Apr 12 10:23:46 server nginx: 200 OK /api/products
Apr 12 10:23:47 server nginx: 200 OK /api/orders
...

[Full output available at: /tmp/claude-tool-1712901234-abc123.txt]
</output>
</tool_result>
```

El modelo puede decidir:
1. Continuar con la preview (si le parece suficiente)
2. Invocar una herramienta para leer el archivo completo si lo necesita

## Por Qué Es Crítico

> *"Users will run cat on enormous files. They will pipe commands that produce megabytes of output. Without budgeting, the context fills with noise and the agent loses coherence."*

### Ejemplos de Desastres Sin Budgeting

```bash
# 1. Logs masivos
kubectl logs -n production --all-containers > /tmp/all-logs.txt
# Output: 500MB de logs

# 2. Dump de base de datos
psql -c "SELECT * FROM transactions" > dump.csv
# Output: 2GB de CSV

# 3. Build output
npm run build 2>&1 | tee build.log
# Output: 50MB de output de build

# 4. git diff en proyecto grande
git diff HEAD~50..HEAD
# Output: 10MB de diff
```

Sin budgeting, cualquiera de estos destruiría el context.

## Casos de Edge Cases

### 1. Tool Produce Output Inesperadamente Grande

```typescript
// Read típicamente pequeño, pero alguien corre Read en un ISO
async function handleReadTool(params: { file: string }) {
  const stats = await fs.stat(params.file);

  if (stats.size > TOOL_MAX_RESULT_CHARS) {
    // even BEFORE execution, check size
    return {
      type: 'file-reference-needed',
      path: params.file,
      preview: `[File too large: ${formatBytes(stats.size)}]`,
      message: 'File exceeds size limit. Use Bash with head/tail instead.'
    };
  }
}
```

### 2. Binary Output

```typescript
// Un comando produce binary que no debería ir al modelo
const result = await exec('cat /dev/urandom | head -c 1000');

if (isBinary(result.content)) {
  return {
    type: 'binary-output',
    preview: '[Binary data suppressed]',
    size: result.content.length
  };
}
```

### 3. Streaming Output Con Budget

```typescript
// Para commands que producen output gradualmente
async function* streamBashWithBudget(
  cmd: string,
  maxChars: number
): AsyncGenerator<string> {
  let collected = '';
  const process = spawn('bash', ['-c', cmd]);

  for await (const chunk of process.stdout) {
    collected += chunk;

    if (collected.length > maxChars) {
      yield `[Output truncated at ${maxChars} chars]`;
      process.kill();
      break;
    }

    yield chunk;
  }
}
```

## Interacción Con Compaction

Tool budgeting y compaction son complementarios:

```
Tool Budgeting: Previene overflow ANTES de que ocurra
  ↓ (si budgeting no es suficiente)
Compaction: Reduce el contexto EXISTENTE cuando ya creció
```

```typescript
async function ensureContextFits(messages: Message[]): Promise<Message[]> {
  // Step 1: Budget los tool results que acaban de llegar
  let msgs = applyToolBudgets(messages);

  // Step 2: Si aún así exceedemos limit, compact
  if (countTokens(msgs) > TOKEN_LIMIT * 0.9) {
    msgs = await compactContext(msgs);
  }

  return msgs;
}
```

## UI Feedback

El usuario debe saber cuándo algo fue truncado:

```typescript
// En la UI mostrar indicators claros
function renderToolResult(result: ToolResult) {
  if (result.type === 'file-reference') {
    return `
      <div class="tool-result truncated">
        <span class="tool-name">${result.toolName}</span>
        <span class="preview">${escapeHtml(result.preview)}</span>
        <span class="file-path">${result.path}</span>
        <span class="size">${formatBytes(result.originalSize)}</span>
        <button onclick="expandResult('${result.path}')">View Full</button>
      </div>
    `;
  }
}
```

## Configuración Recomendada

```typescript
const DEFAULT_BUDGET_CONFIG = {
  // Read files: hasta 100KB
  Read: { maxChars: 100_000, maxTokens: 25_000 },

  // Grep results: hasta 10KB
  Grep: { maxChars: 10_000, maxTokens: 2_500 },

  // Bash output: hasta 50KB
  Bash: { maxChars: 50_000, maxTokens: 12_500 },

  // Web content: hasta 20KB
  WebFetch: { maxChars: 20_000, maxTokens: 5_000 },

  // Glob results: hasta 5KB
  Glob: { maxChars: 5_000, maxTokens: 1_250 },

  // Total budget: no más de 100KB de tool results por mensaje
  totalMaxChars: 100_000,
  totalMaxTokens: 25_000,
};
```

## Referencias

- **[[context-flooding]]**: El problema que budgeting previene
- **[[compaction-hierarchy]]**: Qué pasa si budgeting no es suficiente
- **[[token-validation]]**: Validación de tokens antes de enviar al modelo
- **[[context-management]]**: Vista de conjunto del manejo de contexto
