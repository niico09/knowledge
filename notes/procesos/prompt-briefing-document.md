---
title: Prompt — NotebookLM Briefing Document (Resumen de Capítulo)
created: 2026-04-02
updated: 2026-04-02
tags: [NotebookLM, Prompt, BriefingDocument, StudySystem]
sources:
  - "AI Engineering by Chip Huyen"
status: synthesized
last_lint: 2026-04-07
---

# Prompt — NotebookLM Briefing Document (Resumen de Capítulo)

Reemplaza el prompt default de NotebookLM en **"Resumen → Haz tu propia creación"**. Diseñado para generar un informe técnico estructurado a partir de cualquier capítulo de un libro.

## Instrucciones de uso

1. Abrí NotebookLM y cargá el capítulo como fuente
2. **Crear informe → Resumen → Haz tu propia creación**
3. Reemplazá `[NUMBER]` con el número del capítulo
4. Reemplazá `[CHAPTER TITLE]` con el título del capítulo
5. Pegá el prompt y generá

## Prompt

```javascript
You are a senior AI systems analyst and technical writer.

Context: The sources in this notebook contain material from "AI Engineering" by Chip Huyen.

Scope: Analyze ONLY Chapter [NUMBER] — "[CHAPTER TITLE]". Ignore all other sources in this notebook.

Your task is to produce a structured technical briefing document that synthesizes the content of this chapter exclusively. Every claim MUST be grounded in the chapter source. If a section cannot be grounded in the source, write [INSUFFICIENT SOURCE DATA] instead of generating content. Do not extrapolate or use general knowledge.

---

# [Descriptive title]

[One paragraph: state what this document analyzes, which chapter it covers, and the central transition or shift the chapter argues for. 50–80 words.]

--

## 1. Executive Summary

[One paragraph, 100–150 words. State the paradigm shift the chapter presents. Name the core problem it addresses and the strategic implication. Prose only — no bullet points.]

--

## 2. Detailed Analysis

[Derive ALL subsection titles from the actual content of the chapter. Minimum 3 subsections, maximum 5.]

### 2.1 [First major topic]
[3–5 bullet points. 80–120 words total.]

### 2.2 [Second major topic]
[Table if comparable methods, else bullet points. 80–150 words total.]

### 2.3 [Third major topic]
[Numbered list if sequential strategies. 80–150 words total.]

### 2.4 [Fourth — include only if present]
[60–100 words total.]

### 2.5 [Fifth — include only if present]
[60–100 words total.]

--

## 3. Conclusions and Engineering Trade-offs

[One sentence stating what decisions this section addresses.]

| Decision Axis | Engineering Trade-off |
|---|---|
| [Axis 1] | [Trade-off 1] |
| [Axis 2] | [Trade-off 2] |
| [Axis 3] | [Trade-off 3] |
| [Axis 4] | [Trade-off 4] |

**Final Vision:** [2–3 sentences on the chapter's overarching conclusion.]

--

## 4. Open Questions

[2–3 questions this chapter raises but does not fully resolve. Numbered list.]

Completion criteria: all 4 top-level sections present, every subsection in Section 2 contains at least one table or structured list, Open Questions ≥ 2 entries.
```

## Flujo de recuperación activa

1. **Leé** el Briefing generado en pantalla, con atención. Una sola vez.
2. **Cerrá la pantalla** — sin mirar el documento.
3. En papel, **reconstruí de memoria**:
   - El diagrama o flujo central del capítulo (Sección 2.3)
   - Los 3 trade-offs que recordás (Sección 3)
   - Una pregunta que te quedó abierta
4. **Abrí el Briefing y compará** — solo para identificar gaps
5. *(Opcional)* Transcribí únicamente la **tabla de trade-offs** de la Sección 3

> **Tiempo estimado:** los mismos ~10 minutos que transcribir, con retención significativamente mayor.

## Notas

- Compatible con cualquier libro técnico — solo cambiá la referencia en `Context:`
- Agnóstico al capítulo — los únicos placeholders son `[NUMBER]` y `[CHAPTER TITLE]`
- Si NotebookLM corta el output, pedile que continúe desde donde se detuvo

## Relacionado

- [[guia-reconstruccion]] — Guía de Reconstrucción
- [[workflow-7-pasos]] — Los 7 pasos originales
- [[prompts-ejemplo-learning-engine]] — Prompts de ejemplo
