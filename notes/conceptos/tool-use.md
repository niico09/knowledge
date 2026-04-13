---
tags: [tool-use, function-calling, agent primitives, tool-executor]
created: 2026-04-13
---

# Tool Use / Function Calling

## Concepto Central

Tool Use es el mecanismo por el cual LLMs interactúan con sistemas externos: ejecutan código, consultan APIs, manipulan archivos.

```
LLM → Tool Definition → Tool Execution → Result → LLM → Response
```

## Anatomy of a Tool

### 1. Tool Definition (schema)

```json
{
  "name": "read_file",
  "description": "Lee contenido de archivo, máximo 1000 líneas",
  "parameters": {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "Ruta absoluta al archivo"
      },
      "offset": {
        "type": "number",
        "description": "Línea inicial (default 0)"
      }
    },
    "required": ["path"]
  }
}
```

### 2. Tool Executor

Componente que recibe la llamada y ejecuta la operación:

```python
class ToolExecutor:
    def execute(self, tool_name: str, params: dict) -> ToolResult:
        tool = self.registry.get(tool_name)
        try:
            result = tool(**params)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))
```

### 3. Result Formatting

Respuesta estructurada para que el LLM pueda usarla:

```json
{
  "tool": "read_file",
  "success": true,
  "data": "file content here...",
  "meta": {
    "lines_read": 45,
    "truncated": false
  }
}
```

## Tool Categories

### Navigation Tools
- `ls`, `find`, `glob` — explorar filesystem
- `read_file`, `read_dir` — leer contenido
- `search` — grep en archivos

### Mutation Tools
- `write`, `edit`, `str_replace` — modificar archivos
- `create_file`, `delete` — operaciones de filesystem
- `bash` — ejecutar comandos

### Information Tools
- `grep` — buscar en archivos
- `web_search` — búsqueda web
- `read_mcp_resource` — acceder recursos MCP

### Meta Tools
- `invoke_skill` — ejecutar skills
- `task_create`, `task_update` — gestión de tasks
- `Agent` — spawn sub-agents

## Tool Calling Patterns

### 1. Single Tool Call
El LLM llama una herramienta, espera resultado, continúa.

```
User: "What is in package.json?"
→ LLM: call read_file("package.json")
→ Executor: returns content
→ LLM: generates answer
```

### 2. Parallel Tool Calls
El LLM llama múltiples herramientas independientes simultáneamente.

```python
# Executor receives
[
  {"name": "read_file", "params": {"path": "a.txt"}},
  {"name": "read_file", "params": {"path": "b.txt"}}
]
# Returns results in same order
```

### 3. Sequential Tool Calls (Chain)
Resultado de una tool es input de otra.

```
User: "Find the function that handles auth"
→ LLM: call grep("auth", {type: "function"})
→ Executor: returns [file1:45, file2:120]
→ LLM: call read_file(file1, offset=40, limit=10)
→ Executor: returns function code
→ LLM: summarizes
```

### 4. Tool + Human-in-the-Loop

某些操作 requieren confirmación antes de ejecutar:

```python
if tool.is_destructive:
    return ToolResult(
        success=False,
        error="Destructive operation requires confirmation",
        requires_approval=True
    )
```

## Tool Budgets

Concepto de [[tool-budgets]] — límite de llamadas por task para evitar loops infinitos.

```python
@dataclass
class ToolBudget:
    max_calls: int = 100
    max_depth: int = 10  # chained calls
    timeout_seconds: int = 300
```

## Error Handling

| Error Type | Retry Strategy | User Impact |
|------------|---------------|-------------|
| **Timeout** | 1 retry, then fail | "Operation timed out" |
| **Not Found** | No retry | "File does not exist" |
| **Permission** | No retry | "Access denied" |
| **Rate Limit** | Exponential backoff | "Rate limited, waiting..." |
| **Invalid Params** | Fail immediately | "Invalid parameter X" |

## Tool Definition Best Practices

1. **Description clarity** — LLM debe entender cuándo usar la tool
2. **Parameter types** — usar types específicos, no generic strings
3. **Required vs optional** — marcar required params claramente
4. **Examples in description** — cuando usar, cómo no usar
5. **Versioning** — track cambios para retrocompatibilidad

## Security Considerations

- **Destructive tools** — siempre requerir confirmación
- **Shell injection** — sanitizar parámetros en `bash` calls
- **File access** — considerarscope de acceso (sandbox vs full filesystem)
- **Rate limiting** — prevenir abuse

## Integration con Agent Loop

Tools son el primitive central en [[agent-loop]]:

```
while task_not_complete:
    state = get_current_state()
    action = policy.decide(state, available_tools)
    if action.is_tool_call:
        result = executor.execute(action.tool, action.params)
        state = state.update(result)
    else:
        # Human response or final answer
```

## References

- [[streaming-tool-executor]] — Execution model con streaming
- [[tool-budgets]] — Budget management para tool calls
- [[llm-agents]] — Context más amplio de agents
- [[agent-loop]] — Loop completo del agent