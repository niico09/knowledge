# Claude Code Harness — Lecciones de Arquitectura

## Metadata
- **Fuente**: [Post Twitter/X @rohit4verse](https://x.com/rohit4verse/status/2041548810804211936)
- **Fecha**: 2026-04-07
- **Autor**: Rohit (@rohit4verse)
- **Título original**: "How I built harness for my agent using Claude Code leaks"
- **Métricas**: 473K views, 950 likes, 3099 bookmarks, 115 reposts
- **Tags**: #agent-architecture #claude-code #harness #infrastructure

## Thesis Central

La industria habla de 3 capas: **Weights → Context → Harness**.

Claude Code revela una **4ª capa: Infrastructure** — multi-tenancy, RBAC, resource isolation, state persistence, distributed coordination.

> *"Most teams talk about the first three because they are interesting to think about. The fourth is where products die."*

## Principios Clave

### 1. Async Generators para Agent Loop
- `query.ts` (1,729 líneas) usa `async function*` en vez de `while loop`
- Beneficios inherentes: streaming, cancellation, composability, backpressure

### 2. Five Phases por Iteración
1. **Setup** — budgets, compaction, token validation
2. **Model Invocation** — streaming + retry sobre 10 clases de error
3. **Error Recovery & Compaction** — estados de primera clase, no try-catch externo
4. **Tool Execution** — StreamingToolExecutor ejecuta mid-stream
5. **Continuation Decision** — stop_reason + turn counter + abort signals

### 3. Concurrency Classification para Tools
- Read-only (Glob, Grep, Read) → paralelo hasta 10
- Write tools → serial
- **Resultado**: 2-5x speedup sin race conditions

### 4. Streaming Tool Executor
- Ejecución comienza antes de que el modelo termine de generar
- Oculta 2-5 segundos de latencia por turno multi-tool

### 5. Tool Result Budgeting
- Resultados grandes → persist a disco, modelo recibe path + preview
- Previene context flooding

### 6. System Prompt como Cache Problem
- `SYSTEM_PROMPT_DYNAMIC_BOUNDARY` separa contenido estático (~80%) del dinámico
- 80% del prompt → cacheable globalmente en la API

### 7. Four-Level CLAUDE.md Hierarchy
```
Enterprise (MDM) → Project (.claude/) → User (~/.claude/) → Local (CLAUDE.local.md)
```
Multi-tenancy para comportamiento de agentes.

### 8. Compaction Hierarchy (cheapest → most expensive)
1. **Microcompact** — cada turn, costo ~0 (cached references para herramientas llamadas repetidamente)
2. **Snip Compact** — lossy, sin call al modelo, preserva "protected tail"
3. **Auto Compact** — summarization con modelo separado
4. **Context Collapse** — multi-fase staged compression, feature flag

**Protected tail**: mensajes recientes nunca se resumen. El modelo mantiene fidelity en las últimas N exchanges.

### 9. Permission System — 7 Stages
- Pipeline de deny rules: enterprise → project → user → session
- Hooks como escape hatch: shell commands, HTTP endpoints, TypeScript callbacks

### 10. Error Recovery — 823 líneas en `withRetry.ts`
Cada error class tiene su propia recovery strategy:
- **429 (rate limit)**: Retry-After header → <20s retry keep-alive, >20s 30-min cooldown
- **529 (overloaded)**: 3 en fila + fallback model → switch model
- **400 (context overflow)**: recalculate available = limit - input - 1000 buffer
- **401/403 (auth)**: clear API key cache, force-refresh OAuth
- **Network errors**: disable keep-alive, new connection

Backoff formula: `delay = min(500ms × 2^attempt, 32s) + random(0, 0.25 × baseDelay)`

### 11. Sub-Agent Architecture
- Git worktree isolation → cada agente en su propia branch
- `node_modules` symlinked para evitar disk bloat
- `siblingAbortController` contiene fallos para que no cascaden
- Task coordination: file-based locking con exponential backoff (30 retries, 5-100ms)

### 12. Extension Points — Zero Source Modifications
- **Skills**: markdown files con YAML frontmatter, 5 sources (bundled, project, user, plugin, MCP)
- **Hooks**: 6 tipos — shell, LLM eval, agentic verification, HTTP, TypeScript, in-memory
- **MCP**: 5 transport types (stdio, SSE, HTTP streaming, WebSocket, in-process)
- **Plugins**: directorios compuestos

## Quote Final

> *"Build the harness. Then build the infrastructure around it."*

> *"The model is commodity. The environment determines outcomes."*

## Implicaciones para Build

| Patrón | Aplicación |
|--------|------------|
| Async generators | Agent loop con streaming + cancellation nativo |
| Concurrency classification | Marcar tools en definición, orchestration layer maneja batching |
| Tool execution mid-stream | Parse incremental, start execution cuando JSON está completo |
| System prompt cache boundary | Static content first, dynamic content last, boundary explícito |
| Compaction hierarchy | Cheap first (microcompact, snip), expensive last (summarization) |
| Error recovery inside loop | Cada error type = su propia recovery strategy como estado de primera clase |
| Layer 4 desde day one | State across sessions, permissions scaling, coordination parallelism |
| Extension points | Si users fork para customize → gap arquitectónica |

## Referencias
- [[agent-architecture-patterns]]
- [[claude-code-internals]]
-SWE-agent paper (Princeton NLP): mismo modelo, mejor environment → 64% mejora en SWE-bench
