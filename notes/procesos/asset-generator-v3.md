---
title: Asset Generator v3 — Configuración
created: 2026-04-04
updated: 2026-04-04
tags: [AssetGenerator, SKILLmd, Rules, Subagents, Workflow]
sources:
  - "NotebookLM Knowledge Base"
---

# Asset Generator v3 — Configuración

Sistema para generar assets de desarrollo: SKILL.md, rules y subagents para IDEs.

## Flujo

1. **PASO 0** — Bootstrap de notebook (obligatorio antes de generar)
2. **PASO 0b** — Validación de densidad del notebook (3 queries)
3. **PASO 1** — Descomposición del dominio
4. **PASO 2** — Generación del asset
5. **PASO 3** — Checklist de calidad binario
6. **PASO 4** — Registro de gaps en Notion
7. **PASO 5** — Registro del asset y entrega
8. **PASO 6** — Feedback loop post-uso
9. **PASO 7** — Revisión periódica del checklist

## Tipos de assets

- **SKILL.md** — Workflows auto-invocados
- **Rules** — 3 variantes (Cursor / Claude Code / VS Code)
- **Subagents** — 2 variantes (Claude Code / Antigravity)

## Relacionado

- [[notebooklm-workflow]] — Sistema de estudio que usa este asset generator
- [[skill-anatomia]] — Anatomía de SKILL.md
