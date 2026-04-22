---
title: Synthesize Prompt — Wiki Article Synthesis
description: Prompt template para sintetizar articles crudos en páginas wiki
type: template
version: 1.0
---

# Synthesis Prompt

Usa este prompt cuandoClaude Code te pida sintetizar un article crudo del wiki.

## Prompt a usar

```
Eres un wiki maintainer disciplinado. Tu tarea es convertir un article raw en una página wiki
dentro del sistema LLM Wiki de Karpathy.

## Archivo source
Lee: {SOURCE_FILE}

## Tu tarea

1. **Resumen** — 3-5 oraciones del contenido central
2. **Conceptos clave** — Extrae 3-5 conceptos con descripción de 1-2 oraciones cada uno
3. **Conexiones** — Identifica:
   - Páginas wiki existentes relacionadas (usa wiki-links [[]])
   - Contradicciones con páginas existentes (marca ⚠️ CONTRADICTION)
   - Gaps que podrían填充 con nuevas páginas
4. **Notas personales** — Reflexiones sobre uso práctico, opiniones, preguntas abiertas
5. **Fuentes** — Referencia al archivo source original

## Formato de salida

Usa este template exacto:

---
title: "<título>"
date: {DATE}
type: synthesis
source: [[{SOURCE_FILE}]]
category: {CATEGORIA}
tags: [tag1, tag2, tag3]
---

## Resumen

(3-5 oraciones)

## Conceptos Clave

### Concepto 1
Descripción.

### Concepto 2
Descripción.

## Conexiones

- Relacionado con: [[página existente]]
- Contradice: [[página existente]] ⚠️ CONTRADICTION

## Notas Personales

(reflexiones/uso práctico)

## Fuentes

- [[{SOURCE_FILE}]]
```

## Variables a reemplazar

| Variable | Valor |
|----------|-------|
| `{SOURCE_FILE}` | Path al archivo en sources/ |
| `{DATE}` | Fecha actual YYYY-MM-DD |
| `{CATEGORIA}` | sistema, conceptos, procesos, herramientas |

## Después de generar

1. Guardar el output en `knowledge/notes/{categoria}/`
2. Ejecutar `./scripts/update-index.sh {categoria} "<título>" "<tags>" "<fuentes>" notes/{categoria}/`
3. Ejecutar `./scripts/lint.sh`
4. Registrar en log.md:
   ```
   ## YYYY-MM-DD HH:MM — SYNTHESIS: <título> → notes/{categoria}/<archivo>.md
   ```
5. Marcar source como `status: synthesized` cambiando el frontmatter
