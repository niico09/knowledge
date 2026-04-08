---
title: Spec Driven Development (SDD)
created: 2026-04-04
updated: 2026-04-04
tags: [SDD, SpecDrivenDevelopment, AIAgents, CodingAgents, ClaudeCode, Cursor, AgentHarness, SpecKit, ProductividadIA]
sources:
  - "Post de Julián de Angelis en X (Twitter) — 15 marzo 2026"
  - "https://x.com/juliandeangeiis/status/2033303156340240481"
status: synthesized
last_lint: 2026-04-07
---

# Spec Driven Development (SDD)

SDD es una **metodología** (no una herramienta) para trabajar con agentes de código IA. El cuello de botella real no es el modelo, el contexto ni el tooling — es **la ambigüedad en las instrucciones humanas**. SDD define qué construir antes de escribir código, y deja que el agente implemente desde especificaciones estructuradas.

## El Proceso SDD — 4 Pasos

1. **Spec** — Especificar qué construir (capa funcional, agnóstica a la tecnología)
2. **Plan** — Planificar cómo construirlo técnicamente (arquitectura, modelos de datos, testing)
3. **Tasks** — Dividir en tareas pequeñas, ordenadas y autocontenidas
4. **Implement** — Una tarea a la vez con el agente

## Los 3 Niveles de Madurez

### Nivel 1 — Spec-First
Spec antes de codificar, descartada al entregar. Elimina la ambigüedad para ese ciclo. La mayoría comienza aquí, y ya tiene valor real.

### Nivel 2 — Spec-Anchored
La spec vive en el repo y evoluciona junto al código. Se convierte en documentación viva para el equipo.

### Nivel 3 — Spec-as-Source
La spec es el artefacto primario. Se edita la spec y el código se regenera para coincidir. Es la frontera actual — la trayectoria apunta hacia allí.

## La Spec: Qué, No Cómo

Puramente funcional y agnóstica a la tecnología. Define propósito, casos de uso, requisitos, edge cases y criterios de éxito **en lenguaje no técnico**. Separar lo funcional de lo técnico reduce la incertidumbre del LLM.

### Criterios de Aceptación — Given/When/Then

- **Formato:** `Given [contexto], When [acción], Then [resultado esperado]`
- **Ejemplo:** Given un usuario nuevo, When hace clic en "Sign in with Google" y autoriza la app, Then es redirigido al dashboard con sesión válida.

## El Plan: Expertise del Developer

Capa técnica. El developer define: arquitectura y decisiones técnicas, modelos de datos y contratos, estrategia de testing, restricciones de performance. Aquí se referencian reglas custom, patrones existentes del codebase, los MCPs que el agente debe usar, y las convenciones internas.

## Tasks: Divide and Conquer

El plan se divide en tareas pequeñas y ordenadas. Cada una debe ser completable en una sesión del agente y producir un cambio verificable. Las tasks habilitan:

1. **Paralelismo** — tareas independientes pueden ejecutarse por múltiples agentes simultáneamente
2. **Agente-agnosticismo** — el contexto está embebido en la tarea, no en el agente. Se puede empezar con Claude Code, continuar con Cursor, terminar con Codex

## El Ecosistema Convergiendo

- **GitHub Spec Kit** (77k ⭐): estructura el ciclo spec-plan-task-implement, compatible con Claude Code, Cursor y otros
- **OpenAI Symphony**: monitorea el issue tracker, lanza agentes autónomos por issue, requiere `SPEC.md` como contrato
- **The Ralph Loop**: pone un PRD en un loop infinito de agentes; el progreso persiste en archivos y git
- **Plan mode en Claude Code y Cursor**: paso ligero de spec-and-plan nativo en los agentes

## Tradeoffs

SDD **no es gratis**. El ciclo spec-plan-task consume 2-3x más tokens que el prompting directo. No aplica para cambios pequeños, bug fixes o config updates.

Brilla cuando la feature es lo suficientemente compleja como para que la ambigüedad cause que el agente se desvíe: cambios multi-archivo, features que tocan múltiples dominios, repos legacy, o lógica de negocio no obvia.

## Caso Real — MercadoLibre a Escala

MercadoLibre está introduciendo SDD a **~20.000 developers**. Dos grandes desafíos:

**Desafío 1 — El cambio de hábito:** Pasar de "escribir código" a "describir comportamiento". Resuelto con workshops hands-on (+5.000 devs hasta ahora).

**Desafío 2 — El contexto interno:** SDD solo no alcanza. El agente también necesita el **agent harness**: reglas custom, skills y MCPs.

> "Vibe coding builds demos and MVPs. Spec Driven Development builds production systems."

## Glosario

- **Agent Harness:** conjunto de reglas custom + skills + MCPs que dan al agente el contexto interno de la organización
- **Ambiguity Problem:** el gap entre lo que el humano quiso decir y lo que el agente construyó
- **Spec Kit:** framework open source (77k stars en GitHub) que implementa SDD con comandos como `/plan`
- **Given/When/Then:** formato de criterios de aceptación inequívocos
- **Plan mode:** funcionalidad nativa en Claude Code y Cursor

## Relacionado

- [[proceso-desarrollo-ia]] — Proceso práctico implementando SDD
- [[claude-code-configuracion]] — Anatomía del .claude/ para configurar el agent harness
