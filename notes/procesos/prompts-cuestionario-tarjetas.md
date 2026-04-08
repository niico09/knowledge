---
title: Prompts — Cuestionario y Tarjetas Didácticas (Libros)
created: 2026-03-29
updated: 2026-03-29
tags: [NotebookLM, Prompts, Quiz, Flashcards, StudySystem]
sources:
  - "NotebookLM Studio"
status: synthesized
last_lint: 2026-04-07
---

# Prompts — Cuestionario y Tarjetas Didácticas (Libros)

Para usar en NotebookLM Studio junto con el Briefing Document. Reemplazá `[NUMBER]` y `[CHAPTER TITLE]`.

## Cuestionario

**Cuándo:** Justo después de leer el Briefing Document, antes de cerrar la pantalla.

**Configuración:** Más preguntas / Difícil

```javascript
Scope: Analyze ONLY Chapter [NUMBER] — "[CHAPTER TITLE]". Ignore all other sources.

Generate a quiz to test deep understanding of this chapter. Every question must require reasoning about trade-offs, mechanisms, or implications — not just recall definitions.

Question distribution:
- 40% on engineering trade-offs and decision criteria
- 40% on technical mechanisms and how/why each technique works
- 20% on edge cases, failure modes, or limitations

For each question:
- 4 options (A–D), one correct, three plausible distractors
- After each answer, one-sentence explanation grounded in the chapter source

If a question cannot be grounded in the chapter source, skip it. Do not invent content.
```

## Tarjetas Didácticas

**Cuándo:** Después de la sesión de papel (revisiones espaciadas cada 2-3 días).

**Configuración:** Más tarjetas / Difícil

```javascript
Scope: Analyze ONLY Chapter [NUMBER] — "[CHAPTER TITLE]". Ignore all other sources.

Generate flashcards for spaced repetition. Every card must test understanding of a concept, trade-off, or mechanism — not surface-level recall.

Card distribution:
- 40% trade-offs: front = decision axis, back = trade-off and when each option is preferred
- 40% mechanisms: front = technique name, back = how it works + key advantage or limitation
- 20% comparative distinctions: front = "What is the difference between X and Y?", back = precise technical distinction

Card format:
- Front: 1–5 words maximum
- Back: 2–4 sentences, grounded in chapter source
- No cards for concepts mentioned only once in passing
```

## Flujo completo

| Fase | Herramienta | Momento |
|------|------------|---------|
| Fase 1 | Briefing Document | Al terminar de leer el capítulo |
| Fase 2a | **Cuestionario** | Antes de cerrar la pantalla |
| Fase 2b | Papel (Guía de Reconstrucción) | Después del cuestionario |
| Fase 3 | Learning Engine PASO -1 | Con gaps como base |
| Días siguientes | **Tarjetas Didácticas** | Revisiones espaciadas cada 2-3 días |

## Relacionado

- [[prompt-briefing-document]] — Briefing Document
- [[guia-reconstruccion]] — Guía de Reconstrucción
- [[workflow-7-pasos]] — Los 7 pasos originales
