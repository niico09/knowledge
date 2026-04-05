---
title: Skills que se auto-mejoran
created: 2026-04-04
updated: 2026-04-04
tags: [Skills, AutoMejora, AIAgents, LLMJudge]
sources:
  - "Post de @tricalt sobre cognee-skills"
---

# Skills que se auto-mejoran: el problema real y cómo resolverlo

## El problema fundamental

Los skills son archivos estáticos en un entorno que cambia constantemente. Un skill que funcionaba hace tres semanas puede silenciosamente empezar a fallar cuando cambia el codebase, el modelo se comporta diferente, o el tipo de tarea evoluciona.

**El problema más fundamental que el post no menciona:** los skills no tienen contrato de éxito definido. Dicen *qué hacer*, pero no *cómo saber si lo hicieron bien*.

## El prerequisito: el contrato del skill

Antes de pensar en observación automática, cada skill necesita tres capas de verificación:

### Capa 1 — Corrección funcional
¿El resultado hace lo que se esperaba? Tests E2E.

### Capa 2 — Corrección de calidad
¿El resultado cumple las métricas del skill? Criterios chequeables programáticamente.

### Capa 3 — Corrección intencional
¿El agente siguió el approach que el skill propone? Requiere un LLM judge.

## El loop de auto-mejora

```
Proyecto cliente
  → skill corre con checklist de post-ejecución
  → Capa 1: E2E tests
  → Capa 2: quality-check.sh
  → Si hay fallo: escribe SKILL_FAILURE.md en tonk-tools/failures/
        ↓
tonk-tools
  → LLM judge subagente evalúa
  → Si confidence ≥ 0.7: skill-creator propone enmienda
  → PR con la enmienda para revisión humana
```

## Relacionado

- [[sdd]] — SDD como metodología base
- [[claude-code-configuracion]] — Anatomía de skills en .claude/
