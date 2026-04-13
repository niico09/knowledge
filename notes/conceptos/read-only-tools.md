# Read-Only Tools

## Definición

**Read-only tools** son herramientas que consultan estado existente sin modificar nada del sistema. En contraste, **write tools** (o **mutating tools**) sí alteran estado: archivos, procesos, git branches, etc.

La clasificación es fundamental para la paralelización segura: read-only tools pueden ejecutarse en paralelo sin risk de race conditions.

## Clasificación Estándar

### Read-Only Tools

```typescript
const READ_ONLY_TOOLS = {
  // File system reads
  Read: {
    description: 'Read file contents',
    mutations: [],  // No side effects
  },
  Glob: {
    description: 'Find files by pattern',
    mutations: [],
  },
  Grep: {
    description: 'Search file contents',
    mutations: [],
  },

  // Web content
  WebFetch: {
    description: 'Fetch URL content',
    mutations: [],
  },
  WebSearch: {
    description: 'Search the web',
    mutations: [],
  },

  // Information gathering
  Bash: {
    description: 'Read-only bash commands',
    allowedCommands: ['ls', 'cat', 'head', 'tail', 'git log', 'git show', 'ps', 'df'],
    mutations: [],
  },
};
```

### Write/Mutating Tools

```typescript
const WRITE_TOOLS = {
  Write: {
    description: 'Create or overwrite file',
    mutations: ['file-system'],
  },
  Edit: {
    description: 'Modify file contents',
    mutations: ['file-system'],
  },
  Bash: {
    description: 'Mutating bash commands',
    deniedCommands: ['rm', 'mv', 'cp', 'git commit', 'npm publish'],
    mutations: ['file-system', 'git', 'processes'],
  },
  Delete: {
    description: 'Delete files or directories',
    mutations: ['file-system'],
  },
};
```

## El Problema de Paralelizar Escrituras

### Race Condition en Archivos

```
Hilo A: Read(file.txt)          → contenido "Version A"
Hilo B: Read(file.txt)          → contenido "Version A"

Hilo A: Write(file.txt, "X")    → escribe "X"
Hilo B: Write(file.txt, "Y")    → escribe "Y"

Resultado: Depende de cuál terminó último
         Probablemente contenido mixto o corrupto
```

### Read-Modify-Write Race

```
Hilo A: Read(counter.txt) → "5"
Hilo B: Read(counter.txt) → "5"

Hilo A: Write(counter.txt, "6") → counter = 6
Hilo B: Write(counter.txt, "6") → counter = 6

Counter final: 6 (debería ser 7!)
Lost update problem
```

## Concurrency Classification en la Práctica

### Configuración del Tool Registry

```typescript
interface ToolDefinition {
  name: string;
  concurrency: 'read-only' | 'serial';
  maxParallel?: number;  // Solo para read-only
  retryable: boolean;
  idempotent: boolean;
}

const TOOL_REGISTRY: Record<string, ToolDefinition> = {
  Read: {
    name: 'Read',
    concurrency: 'read-only',
    maxParallel: 10,  // Hasta 10 reads simultáneos
    retryable: true,
    idempotent: true,
  },
  Glob: {
    name: 'Glob',
    concurrency: 'read-only',
    maxParallel: 10,
    retryable: true,
    idempotent: true,
  },
  Grep: {
    name: 'Grep',
    concurrency: 'read-only',
    maxParallel: 10,
    retryable: true,
    idempotent: true,
  },
  Edit: {
    name: 'Edit',
    concurrency: 'serial',
    retryable: false,  // Edit no es idempotent
    idempotent: false,
  },
  Write: {
    name: 'Write',
    concurrency: 'serial',
    retryable: false,
    idempotent: false,
  },
  Bash: {
    name: 'Bash',
    concurrency: 'read-only', // o 'serial' dependiendo del comando
    retryable: true,
    idempotent: false,
  },
};
```

### Orchestration Layer

```typescript
class ToolOrchestrator {
  private running: Map<string, Promise<ToolResult>> = new Map();

  async executeBatch(
    toolCalls: ToolCall[]
  ): Promise<ToolResult[]> {
    // 1. Clasificar por concurrency behavior
    const { readOnly, serial } = this.partitionByConcurrency(toolCalls);

    // 2. Ejecutar read-only en paralelo (hasta maxParallel)
    const readOnlyResults = await this.executeReadOnlyParallel(readOnly);

    // 3. Ejecutar serial en orden (uno por uno)
    const serialResults = await this.executeSerial(serial);

    // 4. Merge resultados en orden original
    return this.mergeInOriginalOrder(toolCalls, readOnlyResults, serialResults);
  }

  private async executeReadOnlyParallel(
    tools: ToolCall[]
  ): Promise<Map<string, ToolResult>> {
    const results = new Map<string, ToolResult>();

    // Ejecutar en batches de maxParallel
    for (const batch of this.chunk(tools, 10)) {
      const promises = batch.map(tool =>
        this.executeTool(tool).then(r => [tool.id, r])
      );

      const batchResults = await Promise.all(promises);
      batchResults.forEach(([id, result]) => results.set(id, result));
    }

    return results;
  }

  private async executeSerial(
    tools: ToolCall[]
  ): Promise<Map<string, ToolResult>> {
    const results = new Map<string, ToolResult>();

    for (const tool of tools) {
      // Esperar a que el anterior termine
      await this.waitForSerialSlot();
      const result = await this.executeTool(tool);
      results.set(tool.id, result);
    }

    return results;
  }
}
```

## ¿Por Qué até 10?

### Benchmarking Results

```
1 parallel read:  100ms
2 parallel read:  52ms  (1.9x speedup)
5 parallel read:  25ms  (4x speedup)
10 parallel read:  15ms  (6.7x speedup)
20 parallel read:  12ms  (8.3x speedup)

Conclusión: diminishing returns después de 10
           más threads = más overhead de context switching
```

## Ejemplo Real: Búsqueda en Código

### Sin Clasificación (Todo Serial)

```
Agent necesita buscar en 20 archivos:
  Glob("**/*.ts") → 50ms
  For each file:
    Grep(function, file) → 20 × 30ms = 600ms
Total: 650ms
```

### Con Clasificación (Paralelo para Reads)

```
Glob("**/*.ts") → 50ms

Greps en paralelo (10 a la vez):
  Batch 1: file1-10 → 30ms
  Batch 2: file11-20 → 30ms
Total: 50ms + 60ms = 110ms
Speedup: 6x
```

## Limitaciones de la Clasificación

### 1. No Es Infalible

```typescript
// Bash se marca como "read-only" para ciertos comandos
Bash({ command: 'ls' })  // Safe, read-only

// Pero el usuario puede injectar comandos destructivos
Bash({ command: 'ls; rm -rf /' })  // No es realmente read-only!

// La clasificación es por TOOL, no por COMMAND
// El permission system debe detectar commandsdangerous
```

### 2. Glob es Read-Only Pero Depende del Estado

```typescript
Glob({ pattern: '**/*.ts' })  // Read-only en teoría

// Pero si otro proceso está creando archivos:
Process A: Creates new file
Process B: Glob right after

Si Glob corre antes/después de A,得到不同的结果
```

### 3. Algunos Read-Only Son Lentos

```typescript
// Este glob puede tomar 10+ segundos en proyectos grandes
Glob({ pattern: '**/*' })  // Too broad

// El sistema debería poder abortar glob operations
// que están tardando demasiado
```

## Integration con Permission System

La clasificación de read-only vs serial es independente del permission system:

```
Permission System: ¿PUEDE este user/tool ejecutar este command?
Concurrency System: ¿CÓMO ejecutamos múltiples calls simultáneamente?
```

Un tool puede ser:
- Allowed + read-only → parallel
- Allowed + write → serial
- Denied → no execute

## Referencias

- **[[concurrency-classification]]**: El sistema de clasificación más amplio
- **[[tool-execution]]**: Cómo se ejecutan los tools
- **[[permission-system]]**: Permissions que coexisten con clasificación
