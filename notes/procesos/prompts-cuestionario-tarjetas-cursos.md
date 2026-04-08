---
title: Prompts — Cuestionario y Tarjetas Didácticas (Cursos)
created: 2026-03-29
updated: 2026-03-29
tags: [NotebookLM, Prompts, Quiz, Flashcards, Courses, StudySystem]
sources:
  - "NotebookLM Studio"
status: synthesized
last_lint: 2026-04-07
---

# Prompts — Cuestionario y Tarjetas Didácticas (Cursos)

Para usar cuando el material son **notas propias, transcripciones de video y apuntes de quiz** de cursos (Coursera, Udemy, etc.). El objetivo es ir más allá del nivel del curso.

> **Cómo cargar:** juntá en un solo notebook las notas del módulo + transcripción de videos + apuntes del quiz del curso.

## Cuestionario

**Configuración:** Más preguntas / Difícil

```javascript
The sources in this notebook contain my personal notes, video transcriptions, and quiz answers from the module "[MODULE NAME]" of the course "[COURSE NAME]".

The course already tested me on recall and definitions. Do NOT generate questions that ask "what is X" or "define Y".

Generate a quiz that forces application and synthesis. Every question must require:
- Apply a concept to a new scenario, OR
- Explain WHY a technique works, OR
- Identify what would break if a specific step were skipped/changed, OR
- Compare two approaches and justify when to use each

Question distribution:
- 35% application to new scenarios
- 35% failure modes and edge cases
- 30% comparative judgment

For each question:
- 4 options (A–D): one correct, three plausible but wrong for a specific reason
- After the answer, include WHY the correct answer is right AND why the most tempting wrong answer fails
```

## Tarjetas Didácticas

**Configuración:** Más tarjetas / Difícil

```javascript
The sources in this notebook contain my personal notes, video transcriptions, and quiz answers from the module "[MODULE NAME]" of the course "[COURSE NAME]".

Generate flashcards for spaced repetition. The course already covered basic definitions.

Every card must test:
- A mechanism (WHY something works)
- A failure mode (what breaks and under what condition)
- A decision rule (when to use X vs Y)
- A connection between concepts (how A affects B)

Card distribution:
- 30% mechanism cards: front = "How does [concept] actually work?", back = step-by-step + key insight
- 30% failure mode cards: front = "What breaks if [condition]?", back = specific failure + why
- 20% decision rule cards: front = "When do you use [A] instead of [B]?", back = criterion + consequence
- 20% connection cards: front = "How does [A] affect [B]?", back = causal explanation

Card format:
- Front: 1 clear question, maximum 10 words
- Back: 2–4 sentences, specific implication
- No cards for concepts mentioned only once in passing
```

## Libros vs Cursos

| | Prompts de libros | Prompts de cursos |
|--|-----------------|------------------|
| Fuente | Capítulo estructurado | Notas + transcripciones + quiz propios |
| Nivel base | Conceptual / teórico | Práctico / procedimental |
| Lo que el material ya cubre | Trade-offs y arquitectura | Definiciones y procedimientos |
| Lo que los prompts agregan | Recuperación de estructura | Aplicación, fallas y comparaciones |

## Placeholders

- `[MODULE NAME]` → ej: `"The PyTorch Workflow"`
- `[COURSE NAME]` → ej: `"PyTorch: Fundamentals — DeepLearning.AI"`

## Relacionado

- [[prompt-briefing-document]] — Briefing Document
- [[prompts-cuestionario-tarjetas]] — Versión para libros
