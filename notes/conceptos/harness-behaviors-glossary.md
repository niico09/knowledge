---
name: harness-behaviors-glossary
description: Términos fundamentales de Agent Harness — 7 behaviors y conceptos clave
tags: [ai-agents, harness, glossary]
created: 2026-04-13
source: https://x.com/zuchka_/status/2042666023405699113
---

# Harness Behaviors — Glossary

> Términos del artículo de Matt Abrams (@zuchka_). Ver [[agent-harness]] para contexto general.

---

## Tool Output Protocol

Un mismo tool output se renderiza de forma diferente según el consumidor:
- **UI** — formato legible para humanos
- **Model context** — formato estructurado/compacto para el modelo

Evita flooding al modelo con información innecesaria.

---

## Conversation State

Vistas queryables sobre el estado de la conversación:

- **Failure counts** — cuántas veces falló un tool/ paso
- **What's been tried** — historial de intentos
- **Loop detection** — detectar cuando el agent está en un ciclo

El harness mantiene esto como estructura de datos, no solo en messages.

---

## System Reminders (3 Niveles)

Tres lugares donde inyectar recordatorios persistente:

| Nivel |Ubicación | Uso |
|-------|----------|-----|
| **Seed** | System message (inicial) | Instrucciones base |
| **User messages** | Cada mensaje | Context fresco |
| **Tool binding** | Specific tools | Constraints por tool |

---

## Stop Conditions

Condiciones que determinan cuándo el agent debe detenerse.

**Crítico:** Deben estar integradas con conversation state, no como flags aislados.

```
❌aislado: maxSteps = 100 (flag)
✅integrado: failureCount > 3 AND no progress in last 5 steps → stop
```

---

## Tool Enforcement

Reglas que controlan cómo se ejecutan los tools:

- **Sequencing** — orden obligatorio entre tools
- **Confirmation gates** — pausa para approval humana
- **Rate limits** — throttle por tool o por tipo
- **Auto-actions** — qué hacer automáticamente vs preguntar

---

## Injection Queue

Sistema para manejar inyecciones de contexto:

- **Priority** — qué entra primero
- **Batching** — agrupar inyecciones relacionadas
- **Deduplication** — evitar información redundante

El harness decide qué, cuándo y cuánto se inyecta.

---

## Hooks

Puntos de personalización en cada stage del execution lifecycle:

```
pre-tool → post-tool → pre-message → post-message → on-error → on-complete
```

Permite cross-cutting concerns (logging, auth, monitoring) sin modificar lógica core.

---

## Relacionado

- [[agent-harness]] — concepto general
- [[agent-loop]] — execution loop donde operan estos behaviors
- [[tool-budgets]] — resource management para tools