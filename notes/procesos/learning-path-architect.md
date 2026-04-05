---
title: Learning Path — Claude Certified Architect (Foundations)
created: 2026-04-04
updated: 2026-04-04
tags: [LearningPath, ClaudeArchitect, Certificacion, ClaudeCode]
sources:
  - "Based on Claude Architect: Domain Map & Anti-Patterns"
  - "Passing score: 720/1000 · Fecha: Marzo 2026"
---

# Learning Path — Claude Certified Architect (Foundations)

## Secuencia de Aprendizaje

| Fase | Dominio | Peso | Enfoque |
|------|---------|------|---------|
| 1 | D3: Claude Code Config | 20% | Entorno y configuración |
| 2 | D4: Prompt Eng & Output | 20% | Craft fundamental |
| 3 | D2: Tool Design & MCP | 18% | Extensión de capacidades |
| 4 | D5: Context & Reliability | 15% | Confiabilidad producción |
| 5 | D1: Agentic Architecture | 27% | Síntesis arquitectónica |

**Total estimado: 3-4 semanas de estudio intensivo**

## Dominio 1: Agentic Architecture & Orchestration (27%)

El dominio más pesado. Integra todo lo anterior. Conceptos clave:

- Agentic loop correcto: inspeccionar `stop_reason` → `"tool_use"` vs `"end_turn"`
- Aislamiento de subagentes: NO heredan historial del coordinador
- Hub-and-spoke: toda comunicación fluye a través del coordinador
- Enforcement spectrum: system prompt (probabilístico) vs hooks (determinístico)

## Dominio 2: Tool Design & MCP Integration (18%)

- Tool descriptions: qué hace, qué inputs, edge cases, cuándo usar ESTA vs otras
- Óptimo: 4-5 tools por agente scoped a su rol
- Structured error responses: `transient | validation | business | permission`

## Dominio 3: Claude Code Configuration & Workflows (20%)

- Jerarquía CLAUDE.md: User → Project → Directory
- Skills vs CLAUDE.md: on-demand vs siempre cargado
- Plan mode vs Direct execution: cuándo usar cada uno

## Dominio 4: Prompt Engineering & Structured Output (20%)

- Criterios explícitos vs instrucciones vagas
- Few-shot examples: cuándo desplegarlo
- Validation-retry loops: efectivos para format errors, NO para info ausente

## Dominio 5: Context Management & Reliability (15%)

- "Lost in the middle" effect: colocar findings clave al principio
- Access failure vs valid empty result: solo el failure es retryable
- Information provenance: claim + source URL + excerpt + fecha

## Relacionado

- [[claude-code-configuracion]] — Dominio 3 en detalle
- [[sdd]] — Dominio 1 aplicado a SDD
