---
name: agent-harness
description: Concepto de Agent Harness — capa que envuelve modelos de IA para crear agentes funcionales
tags: [ai-agents, architecture, harness-engineering]
created: 2026-04-13
source: https://x.com/zuchka_/status/2042666023405699113
review: content marketing bias (Builder.io), complementar con notas más profundas
---

# Agent Harness — Concepto Base

> **Nota:** Esta es la definición básica del concepto. Las notas [[agent-harness-engineering]] y [[agent-harness-memory-hwchase17-2026]] tienen análisis más profundos y menos biased.

## Definición

Un **agent harness** es el código, configuración y lógica de ejecución que envuelve un modelo de IA para convertirlo en un agente funcional.

```
Agent = Model + Harness
```

El modelo provee la inteligencia. El harness provee:
- State management
- Tool execution
- Memory
- Orchestration
- Enforceable constraints

## Relevancia

> *"The model is a constant. The harness is the variable."*

Un mismo modelo puede pasar de outside top-30 a top-5 en benchmarks cambiando solo el harness (Terminal Bench 2.0).

## Componentes del Harness

| Componente | Función |
|------------|---------|
| **System prompts** | Instrucciones que moldean comportamiento antes de cualquier mensaje |
| **Tools + MCPs** | Schemas, descripciones y lógica de ejecución para actuar |
| **Bundled infrastructure** | Filesystem, browser, bash, sandboxes |
| **Orchestration logic** | Subagent spawning, model routing, handoffs |
| **Hooks + middleware** | Compaction triggers, confirmation gates, deterministic enforcement |
| **Sandboxes** | Aislar ejecución de código generado por el agente |

## Framework vs Runtime vs Harness

| Capa | Ejemplo | Descripción |
|------|---------|-------------|
| **Framework** | LangChain, CrewAI, AutoGPT | Abstracciones para *construir* agentes |
| **Runtime** | LangGraph | Gestión de estado y flujos de tareas durables |
| **Harness** | Claude Code, Codex, Cursor | Capa opinada y batteries-included para un caso de uso |

Analogía: **Node.js** = runtime, **Express** = framework, **Next.js** = harness.

## Capabilities Fundamentales

1. **Durable storage** — filesystem + git para persistencia entre sesiones
2. **Code execution** — bash para tooling dinamico
3. **Memory + context injection** — memoria que outlasts context window
4. **Orchestration** — subagent spawning y handoffs
5. **Context management** — compaction para combatir context rot
6. **Hooks** — comportamiento determinístico exigible

## 7 Behaviors a Nivel Harness

Según experiencia de comunidad en producción:

1. **Tool output protocol** — one output, multiple renderings (UI vs model context)
2. **Conversation state** — queryable views: failure counts, what's been tried, loop detection
3. **System reminders** — 3 niveles (seed in system message, attach to user messages, bind to specific tools)
4. **Stop conditions** — integradas con conversation state, no isolated flags
5. **Tool enforcement** — sequencing rules, confirmation gates, rate limits, auto-actions
6. **Injection queue** — priority, batching, deduplication para context injections
7. **Hooks** — customize execution at every stage

## Producción Failure Modes (son harness failures)

- `maxSteps` existe pero está disconnected de conversation state → agent loops
- Context rot after 30 min on complex task → harness didn't prevent it
- Large file read floods context window → harness didn't filter output

## Diseño de Harness para Producción

6 decisiones críticas:

1. **Execution environment** — local vs Docker vs cloud sandbox
2. **Tool surface area** — start small + bash como general escape hatch
3. **State/memory strategy** — filesystem como source of truth; AGENTS.md para memoria persistente; git para version/rollback
4. **Long-horizon continuity** — Ralph Loop pattern: agent treats every task as repeating loop con planning file que sobrevive a context resets
5. **Verification loops** — self-checking con test runners, log inspection, browser state observation
6. **Team access** — collaboration layer (vs solo-engineer harness)

## Referencias

- [LangChain: The Anatomy of an Agent Harness](https://blog.langchain.com/the-anatomy-of-an-agent-harness/)
- [Context Rot research](https://research.trychroma.com/context-rot)
- [Ralph Loop — Geoffrey Huntley](https://ghuntley.com/loop/)

## Relacionado

- [[agent-harness-engineering]] — Pipeline de better-harness loop con evals
- [[agent-harness-memory-hwchase17-2026]] — Análisis de Harrison Chase sobre memory=harness y lock-in via memoria

## Tags

#ai-agents #harness-engineering #agent-architecture