---
title: AI Second Brain — Claude Code + Obsidian
description: Sistema de knowledge base estilo Karpathy con Obsidian + Claude Code
created: 2026-04-09
updated: 2026-04-12
tags: [obsidian, knowledge-base, llm, second-brain, workflow]
sources:
  - "Post de @aiedge_ — 2026-04-09"
  - "Post de @KanikaBK — 2026-04-11"
  - "Gist de @karpathy — 2026-04-07"
status: synthesized
last_lint: 2026-04-12
---

# AI Second Brain — Claude Code + Obsidian

Sistema de base de conocimiento personal basado en el patrón LLM Wiki de Andrej Karpathy, implementado sobre Obsidian.

## Las 3 Capas

```
┌─────────────────────────────────────────────────────────┐
│  01 - Raw Sources  │  Material sin procesary            │
├─────────────────────────────────────────────────────────┤
│  02 - Wiki         │  Páginas generadas por IA         │
│                     │  (síntesis, conceptos, entities)  │
├─────────────────────────────────────────────────────────┤
│  index.md + log.md │  Catálogo y registro de cambios    │
└─────────────────────────────────────────────────────────┘
```

## Estructura de Carpetas

```
vault/
├── 00 - Inbox/          # Captura rápida, sin procesar
├── 01 - Raw Sources/    # Fuentes: PDFs, notas, artículos, transcripciones
├── 02 - Wiki/           # Conocimiento generado por IA
│   ├── index.md         # Catálogo de todas las páginas
│   └── log.md           # Registro append-only de actividad
└── CLAUDE.md            # Schema + convenciones del wiki
```

## Operaciones

### Ingest
1. Nuevo material entra en `01 - Raw Sources`
2. Claude (via Claude Code) ejecuta prompt de síntesis
3. Wiki pages se actualizan o crean en `02 - Wiki`
4. Se registra en `log.md`

### Query
1. Pregunta contra el wiki
2. Respuesta se filía de vuelta como nueva página si es valioso

### Lint
- Contradicciones detectadas
- Claims obsoletos
- Páginas huérfanas
- Links faltantes

## Workflow según Kanika

Prompt para la capa AI:
```
Read the note in my Raw Sources folder and turn it into a clean wiki page.
Summarize the key ideas, define important terms, list related concepts,
and suggest links to other pages I should create.
```

## Qué tenemos vs. qué falta

| Componente | Estado | Gap |
|-----------|--------|-----|
| `sources/articulos/*.md` raw | ✅ Existe | |
| `notes/sistema/*.md` synthesized | ⚠️ Parcial | Síntesis incompletez, sin flujo activo |
| `index.md` | ✅ Existe | Desactualizado |
| `log.md` | ✅ Existe | No se está usando activamente |
| `ingest.sh` (script) | ❌ No existe | No hay automatización |
| Carpeta `00 - Inbox` | ❌ No existe | Falta zona de captura |
| Carpeta `02 - Wiki` explícita | ❌ No existe | `notes/sistema/` hace de wiki |

## Relación con otros sistemas

- **[[notion-kb-overview]]** — KB de NotebookLM. Ya declara usar patrón Karpathy, pero desconectado de Obsidian
- **[[notebooklm-workflow]]** — Workflow de 7 pasos. Puede alimentar el ingest de este sistema
- **[[procesos/learning-path-architect]]** — Learning paths que deberían consumir de este wiki
- **[[../../../sources/articulos/2026-04-07-llm-wiki-karpathy]]** — Fuente original del patrón

## Siguiente paso sugerido

Crear `ingest.sh` que:
1. Lea archivos nuevos en `sources/articulos/`
2. Para cada uno en estado `raw`, ejecute prompt de síntesis
3. Genere o actualice página en `notes/sistema/`
4. Actualice `index.md` y `log.md`
5. Cambie estado a `synthesized`

## Ver también

- [[sistema/ai-second-brain-claude-obsidian]]
- [[sistema/notion-kb-overview]]
- [[../../../sources/articulos/2026-04-07-llm-wiki-karpathy]]
