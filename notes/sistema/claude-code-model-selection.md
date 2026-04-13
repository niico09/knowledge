---
title: Model Selection — Opus / Sonnet / Haiku
created: 2026-04-13
tags: [ClaudeCode, Models, Opus, Sonnet, Haiku, TokenOptimization]
sources:
  - "@zostaff — Complete Claude Code Guide, Apr 11 2026"
status: new
related:
  - proceso-desarrollo-ia
  - guia-carpeta-claude
---

# Model Selection — Opus / Sonnet / Haiku

## Mapeo Básico

| Modelo | Uso | Esfuerzo | Cuándo |
|--------|-----|----------|--------|
| **Opus** | Planificación, arquitectura, decisiones complejas | Alto | Sin límites de presupuesto |
| **Sonnet** | Escribir código (con un plan previo) | Medio | La mayoría del trabajo de código |
| **Haiku** | Búsqueda de documentación | Bajo | research rápido |

## La Regla de Oro

> **Opus sin plan = Ferrari en camino de tierra.**
> **Sonnet con buen plan = diana en el blanco.**

Opus tiene toda la potencia pero necesita dirección. Sin plan, desperdicia capacidad resolviendo ambigüedades que vos ya deberías haber contestado.

## SDD + Model Selection

En el flujo SDD (Spec → Plan → Tasks → Ejecución):

```
Opus  → Spec + Plan (decisiones arquitectura,Given/When/Then)
Sonnet → Tasks de código (implementación según plan)
Haiku → Búsqueda de documentación durante implementación
```

## Sin Límites de Contexto

Si no tenés problemas de límites de contexto, **quedate en Opus** para todo. La diferencia de costo no justifica la complejidad de cambiar entre modelos.

## Con Límites de Contexto

Si estás golpeando el límite de context frecuentemente:

1. **Opus** → Spec y Plan (decisiones estratégicas)
2. **Sonnet en subagents** → Código de cada task en paralelo
   - Aislado = no contamina el context principal
   - Paralelo = 3x más rápido, 6x más barato
3. **Haiku** → Research entre tareas (docs, ejemplos)

## Subagents y Model Selection

Los subagents pueden recibir modelo específico:

```markdown
# .claude/agents/landing-creator.md
---
name: landing-creator
model: sonnet
skills:
  - landing-page
  - frontend-design
---
```

```markdown
# .claude/agents/researcher.md
---
name: researcher
model: haiku
---
```

## Pricing Context

| Plan | Modelos | Límite |
|------|---------|--------|
| Pro ($20/mo) | Opus, Sonnet, Haiku | 5x más barato que API |
| Max 5x ($100/mo) | +Más capacidad | Suficiente para la mayoría |
| Max 20x ($200/mo) | +Agent Teams | Múltiples proyectos simultáneos |

**API directa:** Mismas tareas = ~$500/mo. Subscription = 5x ahorro.

## Errores Comunes

1. **Opus para todo sin plan** → Potencia desperdiciada, costos altos
2. **Sonnet sin dirección** → Código fuera de scope
3. **Cambiar modelos sin criterio** → Inconsistencia en calidad
4. **Ignorar el context** → Auto-compact rompe el flujo

## Relacionado

- [[proceso-desarrollo-ia]] — SDD completo con Spec/Plan/Tasks
- [[context-zonas-status-line]] — Monitoreo de context en tiempo real
- [[guia-carpeta-claude]] — Setup de agentes y skills
