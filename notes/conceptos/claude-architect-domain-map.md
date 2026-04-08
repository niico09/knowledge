---
title: "Claude Architect: Domain Map & Anti-Patterns"
created: 2026-03-25
updated: 2026-04-04
tags: [ClaudeArchitect, Exam, AntiPatterns, AgenticAI, MCPTools, PromptEngineering]
sources:
  - "@hooeem en X"
  - "Notion → migrado 2026-04-04"
status: synthesized
last_lint: 2026-04-07
---

# Claude Architect — Domain Map & Anti-Patterns

Mapa de los 5 dominios del examen **Claude Certified Architect (Foundations)** con pesos, anti-patrones críticos que el examen testa, y prompts de estudio listos para usar.

> **Fuente base:** [@hooeem en X](https://x.com/hooeem/status/2033198345045336559) — desarmó el exam guide completo en un curriculum accionable.

## Resumen de Dominios

| Dominio | Peso | Escenarios de examen principales |
|---------|------|----------------------------------|
| **1. Agentic Architecture & Orchestration** | 27% | Customer Support Agent, Multi-Agent Research System, Developer Productivity Tools |
| **2. Tool Design & MCP Integration** | 18% | Customer Support Agent, Multi-Agent Research System, Developer Productivity Tools |
| **3. Claude Code Configuration & Workflows** | 20% | Code Generation, Developer Productivity Tools, CI/CD |
| **4. Prompt Engineering & Structured Output** | 20% | CI/CD, Structured Data Extraction |
| **5. Context Management & Reliability** | 15% | Customer Support Agent, Multi-Agent Research, Structured Data Extraction |

**Passing score:** 720/1000. El examen favorece soluciones determinísticas sobre probabilísticas cuando el contexto es de alto riesgo, fixes proporcionales al problema, y rastreo de root cause.

---

# Domain 1: Agentic Architecture & Orchestration (27%)

## Anti-patrones que el examen rechaza en primer vistazo

- **Parsing natural language para determinar terminación de loop** — ej: detectar si el asistente dijo "I'm done". Incorrecto porque el lenguaje natural es ambiguo. El campo `stop_reason` existe exactamente para esto.
- **Iteration caps arbitrarios como mecanismo principal de parada** — ej: "detener después de 10 loops". Incorrecto porque corta trabajo útil o corre iteraciones innecesarias. El modelo señala completitud vía `stop_reason`.
- **Chequear `response.content[0].type == "text"` como indicador de completitud** — incorrecto porque el modelo puede retornar texto junto con bloques `tool_use`.

## Principios críticos

**El agentic loop correcto:**
1. Enviar request a Claude vía Messages API
2. Inspeccionar `stop_reason` en la respuesta
3. Si `stop_reason == "tool_use"` → ejecutar tool(s), appendear resultados al historial, reenviar a Claude
4. Si `stop_reason == "end_turn"` → el agente terminó, presentar respuesta final

**Aislamiento de subagentes** — el concepto más malentendido: los subagentes NO heredan automáticamente el historial del coordinador. NO comparten memoria entre invocaciones. Cada pieza de información que un subagente necesita debe incluirse explícitamente en su prompt.

**Enforcement spectrum:**
- Instrucciones en system prompt → guías probabilísticas. Tasa de falla no-cero.
- Hooks o prerequisite gates → garantías determinísticas. Cuando el contexto es financiero, de seguridad o compliance: usar enforcement programático, no instrucciones.

**Hub-and-spoke:** El coordinador está en el centro. Los subagentes son radios. Toda comunicación fluye a través del coordinador — los subagentes nunca se comunican directamente entre sí.

**Narrow decomposition failure:** Si el coordinador descompone "impacto de IA en industrias creativas" solo en subtópicos de artes visuales, la falla está en la descomposición del coordinador, no en ningún agente downstream.

## Conceptos clave a dominar

- `stop_reason` vs. señales de texto natural
- Task tool para spawning de subagentes; `allowedTools` debe incluir `"Task"`
- `fork_session` para explorar enfoques divergentes desde un baseline compartido
- `PostToolUse` hooks para normalizar datos heterogéneos antes de que el modelo los procese
- Tool call interception hooks para bloquear operaciones policy-violating
- Session management: `--resume`, `fork_session`, fresh start con summary injection

### Prompt de estudio — Domain 1

```javascript
You are an expert instructor teaching Domain 1 (Agentic Architecture & Orchestration) of the Claude Certified Architect (Foundations) certification exam. This domain is worth 27% of the total exam score.

Teach like a senior architect at a whiteboard: direct, specific, grounded in production scenarios. British English spelling throughout.

EXAM CONTEXT: Scenario-based multiple choice. Passing score: 720/1000. Rewards deterministic solutions over probabilistic ones when stakes are high.

When I begin, ask me to rate my familiarity (none / built a simple agent / built multi-agent systems). Then work through these 7 task statements in order: 1.1 Agentic Loops, 1.2 Multi-Agent Orchestration, 1.3 Subagent Invocation & Context Passing, 1.4 Workflow Enforcement & Handoff, 1.5 Agent SDK Hooks, 1.6 Task Decomposition Strategies, 1.7 Session State & Resumption.

For each: explain with a production example, highlight exam traps, ask 1-2 check questions, connect to next statement. After all 7, run a 10-question practice exam.
```

---

# Domain 2: Tool Design & MCP Integration (18%)

## Anti-patrones críticos

- **Descripciones de herramientas vagas o superpuestas** — si `get_customer` y `lookup_order` tienen descripciones casi idénticas, la selección se vuelve poco confiable. El fix correcto es mejores descripciones, NO: ejemplos few-shot, routing classifiers, ni consolidación de herramientas.
- **18 herramientas por agente** — degrada la confiabilidad de selección. Óptimo: 4-5 tools por agente, scoped a su rol.
- **Confundir access failure con valid empty result** — un resultado vacío válido (la query funcionó, no hay matches) NO debe generar reintentos. Solo los failures de acceso (timeout, auth) son retryables.

## Principios críticos

**Tool descriptions son el mecanismo primario** que Claude usa para selección de herramientas. Una buena descripción incluye: qué hace, qué inputs espera, ejemplos de queries que maneja bien, edge cases y limitaciones, y cuándo usar ESTA tool vs. tools similares.

**`tool_choice` config — memorizar de memoria:**
- `"auto"` → default, el modelo puede retornar texto (no garantiza tool call)
- `"any"` → DEBE llamar una tool, elige cuál. Usar para output estructurado garantizado
- `{"type": "tool", "name": "..."}` → DEBE llamar esta tool específica. Forzar pasos obligatorios

**MCP scoping jerarquía:**
- `.mcp.json` en el repo → project-level, version-controlled, compartido con el equipo
- `~/.claude.json` → user-level, personal, NO version-controlled
- Soporta `${GITHUB_TOKEN}` para credentials fuera del control de versiones

**Evaluar community servers antes de construir custom** — Jira, GitHub, Slack tienen servidores MCP existentes. Solo construir custom para workflows del equipo que los community servers no pueden manejar.

**Structured error responses:**
```javascript
errorCategory: transient | validation | business | permission
isRetryable: true/false
```
- Business errors (refund excede límite): NO retryable, necesita workflow alternativo
- Transient (timeout): retryable

### Prompt de estudio — Domain 2

```javascript
You are an expert instructor teaching Domain 2 (Tool Design & MCP Integration) of the Claude Certified Architect (Foundations) certification exam. This domain is worth 18%.

Direct, practical teaching. British English spelling throughout. The exam favours low-effort, high-leverage fixes as first steps: better tool descriptions before routing classifiers, scoped access before full access, community servers before custom builds.

Ask about my MCP and tool design experience, then work through: 2.1 Tool Interface Design, 2.2 Structured Error Responses, 2.3 Tool Distribution & tool_choice, 2.4 MCP Server Integration, 2.5 Built-in Tools (Grep vs Glob). After all 5, run a 7-question practice exam.
```

---

# Domain 3: Claude Code Configuration & Workflows (20%)

## Anti-patrones críticos

- **Instrucciones del equipo en user-level config** — un nuevo miembro del equipo no recibe las instrucciones porque están en `~/.claude/CLAUDE.md` (no version-controlled, no compartido). Project-level (`.claude/CLAUDE.md` o `CLAUDE.md` raíz) es lo que se versiona.
- **Directory-level CLAUDE.md para convenciones cross-codebase** — si los test files están distribuidos en 50+ directorios, un CLAUDE.md por directorio es inmantenible. `.claude/rules/` con glob patterns (`**/*.test.tsx`) resuelve esto.
- **Plan mode para un bug fix de un archivo** — plan mode es para restructuraciones masivas, migraciones multi-archivo, decisiones arquitectónicas. Direct execution para cambios bien entendidos con scope claro.
- **Pipeline CI/CD sin `-p` flag** — sin `-p`, el job cuelga esperando input interactivo. Memorizar: `claude -p "prompt"` para non-interactive mode.

## Principios críticos

**CLAUDE.md hierarchy:**

| Nivel | Path | Alcance |
|-------|------|---------|
| User | `~/.claude/CLAUDE.md` | Solo vos, no compartido |
| Project | `.claude/CLAUDE.md` o `CLAUDE.md` raíz | Toda la team, version-controlled |
| Directory | `subdirectory/CLAUDE.md` | Solo ese directorio |

**Skill frontmatter de producción:**
- `context: fork` — aísla output verboso en un sub-agente. La conversación principal queda limpia.
- `allowed-tools` — restringe tools que el skill puede usar. Previene acciones destructivas.
- `argument-hint` — solicita parámetros requeridos al invocar sin argumentos.

**Skills vs CLAUDE.md:**
- Skills = on-demand, task-specific (invocados cuando se necesitan)
- CLAUDE.md = siempre cargado, estándares universales (aplicados automáticamente)

**Plan mode vs Direct execution:**
- Plan mode: restructuración de monolito, migración multi-archivo (45+ archivos), decisiones arquitectónicas
- Direct execution: bug fix en un archivo con stack trace claro, cambio de scope limitado bien entendido

**CI/CD output estructurado:** `--output-format json --json-schema` produce findings machine-parseable para comentarios inline en PRs.

**Independent review instance:** La misma sesión que generó código es MENOS efectiva revisando sus propios cambios — usar una instancia independiente para code review.

### Prompt de estudio — Domain 3

```javascript
You are an expert instructor teaching Domain 3 (Claude Code Configuration & Workflows) of the Claude Certified Architect exam. This domain is worth 20%.

This is the most configuration-heavy domain. Reasoning alone won't save you — hands-on experience is critical. Ask about my Claude Code experience (never used / use daily / configured for a team). Work through: 3.1 CLAUDE.md Hierarchy, 3.2 Custom Slash Commands & Skills, 3.3 Path-Specific Rules, 3.4 Plan Mode vs Direct Execution, 3.5 Iterative Refinement, 3.6 CI/CD Integration. After all 6, run an 8-question practice exam.
```

---

# Domain 4: Prompt Engineering & Structured Output (20%)

## Anti-patrones críticos

- **"Be conservative" o "only report high-confidence findings"** — NO mejoran la precisión. Lo que funciona: definir exactamente qué issues reportar vs. saltear, con ejemplos de código concretos por nivel de severidad.
- **Asumir que `tool_use` con JSON schema elimina errores semánticos** — elimina errores de sintaxis (malformed JSON). Pero NO previene: line items que no suman al total declarado, valores en campos incorrectos, ni fabricación de valores.
- **Batch API para todo** — no soporta multi-turn tool calling dentro de un request, tiene hasta 24h de processing window, sin latency SLA.

## Principios críticos

**Criterios explícitos sobre instrucciones vagas:**
- ❌ "Be conservative"
- ✅ "Flag comments only when claimed behaviour contradicts actual code behaviour. Report bugs and security vulnerabilities. Skip minor style preferences and local patterns."

**Few-shot examples** son la técnica de mayor apalancamiento para consistencia. Cuándo desplegar: instrucciones detalladas producen formatting inconsistente, el modelo hace judgment calls inconsistentes en casos ambiguos, campos de extracción salen null para información que sí existe.

**Schema design para prevenir fabricación:**
- Campos `nullable` cuando el source puede no contener esa información → previene valores fabricados
- Valor enum `"unclear"` para casos ambiguos
- String `"other"` + detail field para categorización extensible

**Message Batches API:**
- 50% de ahorro en costos
- Hasta 24h de processing
- Sin latency SLA garantizado
- NO soporta multi-turn tool calling
- `custom_id` para correlacionar request/response pairs
- Usar para: reportes overnight, audits semanales, generación de tests nocturnos

**Validation-retry loops:**
- Efectivos para: format mismatches, structural output errors, valores mal ubicados
- NO efectivos para: información genuinamente ausente del documento fuente

### Prompt de estudio — Domain 4

```javascript
You are an expert instructor teaching Domain 4 (Prompt Engineering & Structured Output) of the Claude Certified Architect exam. This domain is worth 20%.

This domain is where the exam gets sneaky. Wrong answers sound like good engineering. Right answers require knowing which technique applies to which specific problem. Ask about my prompt engineering experience, then work through: 4.1 Explicit Criteria, 4.2 Few-Shot Prompting, 4.3 Structured Output with tool_use, 4.4 Validation-Retry Loops, 4.5 Batch Processing, 4.6 Multi-Instance Review. After all 6, run an 8-question practice exam.
```

---

# Domain 5: Context Management & Reliability (15%)

## Anti-patrones críticos

- **Progressive summarisation de datos transaccionales** — condensar historial convierte "el cliente quiere un reembolso de $247.83 para la orden #8891" en "el cliente quiere un reembolso por un pedido reciente". Fix: bloque "case facts" persistente con montos, fechas y números de orden exactos.
- **Escalation triggers no confiables** — el examen tentará con: análisis de sentimiento del cliente y self-reported confidence scores del modelo. Ambos son poco confiables. Los 3 triggers válidos: cliente solicita explícitamente un humano (honrar inmediatamente), policy gaps, incapacidad de hacer progreso.
- **Silently suppressing errors** — retornar resultados vacíos marcados como éxito previene cualquier recovery.
- **Terminar el workflow entero en un single failure** — descarta resultados parciales.

## Principios críticos

**"Lost in the middle" effect:** Los modelos procesan confiablemente el inicio y el final de inputs largos. Findings enterrados en el medio pueden perderse. Fix: colocar resúmenes de hallazgos clave al principio, headers de sección explícitos.

**Access failure vs valid empty result:**
- Access failure: la tool no pudo llegar al data source (timeout, auth). Considerar retry.
- Valid empty result: la tool consultó exitosamente, no encontró matches. NO retry.

**Escalation inmediata:** Si el cliente dice explícitamente "quiero hablar con un humano" → escalar inmediatamente, sin investigar primero.

**Structured error context para propagación:**
```javascript
- failure_type: transient | validation | business | permission
- what_was_attempted: query específica y parámetros usados
- partial_results: lo que se recopiló antes del failure
- alternative_approaches: posibles próximos pasos
```

**Information provenance:** Cada finding debe incluir claim + source URL + nombre del documento + excerpt relevante + fecha de publicación.

**Context degradation mitigation:**
- Scratchpad files: escribir hallazgos clave a un archivo, referenciar para preguntas subsecuentes
- Subagent delegation: spawnear subagentes para investigaciones específicas
- `/compact` cuando el contexto se llena de output verboso

### Prompt de estudio — Domain 5

```javascript
You are an expert instructor teaching Domain 5 (Context Management & Reliability) of the Claude Certified Architect exam. This domain is worth 15%, but its concepts cascade into Domains 1, 2, and 4. Getting this wrong breaks your multi-agent systems and extraction pipelines.

Ask about my experience with long-context applications. Work through: 5.1 Context Preservation, 5.2 Escalation & Ambiguity Resolution, 5.3 Error Propagation, 5.4 Codebase Exploration, 5.5 Human Review & Confidence Calibration, 5.6 Information Provenance. After all 6, run a 6-question practice exam.
```

---

# Gaps vs. base de conocimiento existente

Esta nota cubre conceptos que **no existen en otras páginas** de la base:

- `stop_reason` handling — agentic loop completo
- `tool_choice` (auto / any / forced) — cuándo usar cada uno
- Programmatic enforcement vs. prompt guidance para stakes altas
- `fork_session` mecánica
- Message Batches API — tradeoffs de latencia, costo, multi-turn support
- Validation-retry loops — efectivos vs. inefectivos según el tipo de error
- Progressive summarisation trap + persistent case facts block
- "Lost in the middle" effect + mitigaciones
- Escalation triggers válidos vs. no confiables
- Information provenance en sistemas multi-agente

---

## Recursos de aprendizaje recomendados por Anthropic

1. Building with the Claude API
2. Introduction to Model Context Protocol
3. Claude Code in Action
4. Claude 101
5. Agent SDK Python repo + examples (hooks, custom tools, fork_session)
6. Claude Code CLI docs (CLAUDE.md hierarchy, rules directory, slash commands)

---

## Relacionado

- [[learning-path-architect]] — Learning path para el examen
- [[guia-carpeta-claude]] — Domain 3 en profundidad (CLAUDE.md, hooks, path-specific rules)
- [[skill-anatomia]] — Domain 3: skills frontmatter, `context: fork`
- [[skills-auto-mejoran]] — Domain 1: hooks programáticos para self-improvement loops
