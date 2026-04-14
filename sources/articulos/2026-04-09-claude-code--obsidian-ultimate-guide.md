---
title: "Claude Code + Obsidian Ultimate Guide"
url: "https://x.com/aiedge_/status/2041908011078447222"
date: 2026-04-09
type: article
status: synthesized
synthesized_date: 2026-04-12
sources:
  - "@aiedge_ — AI Edge, 843K views, Apr 8 2026"
tags: [claude-code, obsidian, second-brain, llm, workflow]
related:
  - sources/articulos/2026-04-07-llm-wiki-karpathy
  - notes/sistema/ai-second-brain-claude-obsidian
---

## Resumen

Guía práctica para construir un AI Second Brain combinando Claude Code + Obsidian, basada en el patrón LLM Wiki de Karpathy. El sistema tiene 4 componentes: datos, organización (a cargo de Claude Code), prompting instantáneo, y memoria que evoluciona. Setup en 5 minutos, mejora con el uso.

## Sistema — 4 Componentes

| Componente | Rol |
|-----------|-----|
| **Datos** | Artículos, notas, transcripciones, ideas |
| **Organización** | Claude Code mantiene el wiki en Obsidian |
| **Prompting instantáneo** | Consultar la base en cualquier momento |
| **Memoria evolutiva** | El sistema se vuelve más inteligente con el tiempo |

## Setup en 5 Pasos

1. **Download Obsidian** — obsidian.md
2. **Crear Vault** — carpeta donde Claude Code tiene acceso
3. **Vincular Claude Code** — Select Folder → Obsidian Vault
4. **System Prompt** — Pegar el prompt de Karpathy en el chat
5. **Input inicial** — Alimentar con datos: notas, CSVs, artículos, etc.

## Flujo de Trabajo

```
Artículo/web → Obsidian Web Clipper → raw folder
                                         ↓
                              Claude Code ingest
                                         ↓
                              Wiki actualiza links
                                         ↓
                              Preguntar a la base
```

## Tips Pro

- **Obsidian Chrome Extension** — "add to Obsidian" en cualquier página
- **Vaults separados** — uno para trabajo, otro para personal
- **Prompts más accurate** — con acceso a contexto vital, los prompts son más poderoso
- **Orphans** — nodes sin conexiones muestran gaps en el conocimiento

## Contra

1. No sos visual → el graph view no aporta valor
2. No querés mantener → sin input el sistema es inútil
3. Storage — archivos MD ocupan espacio local

## Relación con Karpathy

Este artículo es la **implementación práctica** del gist de Karpathy. Explica el setup paso a paso que el gist solo esboza conceptualmente. Juntos: Karpathy = teoría, aiedge_ = práctica.

## Relacionado

- [[../notes/sistema/ai-second-brain-claude-obsidian]] — Síntesis del sistema completo
- [[2026-04-07-llm-wiki-karpathy]] — Fuente conceptual / teórica
