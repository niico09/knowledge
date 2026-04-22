---
title: "LLM Wiki — A Pattern for Building Personal Knowledge Bases"
url: "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
date: 2026-04-07
type: article
status: synthesized
synthesized_date: 2026-04-12
sources:
  - "Andrej Karpathy @karpathy — Gist viral Apr 2026"
tags: [llm, knowledge-base, wiki, obsidian, rag]
---

## Resumen

Patrón donde un LLM construye y mantiene incrementalmente un wiki persistente de archivos markdown. A diferencia de RAG clásico que re-deriva conocimiento en cada pregunta, este enfoque compila conocimiento una vez y lo mantiene actualizado y cross-referenciado.

## Arquitectura — 3 Capas

| Capa | Función | Ejemplo en nuestro sistema |
|------|---------|---------------------------|
| **Raw Sources** | Documentos fuente inmutables que el LLM lee | `sources/articulos/*.md` |
| **Wiki** | Archivos markdown generados por LLM (summaries, entity pages, concept pages) | `notes/sistema/*.md` |
| **Schema** | Archivo de configuración (ej. CLAUDE.md) que define estructura y convenciones | `CLAUDE.md`, `index.md` |

## Operaciones

### Ingest
1. Se deposita una fuente nueva en raw
2. LLM la lee y extrae información clave
3. LLM actualiza wiki pages existentes o crea nuevas

### Query
1. Se hace una pregunta contra el wiki
2. Respuestas pueden volverse a archivar como nuevas pages

### Lint
- Check de contradicciones
- Claims obsoletos
- Páginas huérfanas
- Links faltantes

## Archivos especiales

- **index.md** — catálogo de páginas del wiki organizado por categoría
- **log.md** — registro cronológico append-only de ingests, queries y lint passes

## Por qué funciona

> "La parte tediosa de mantener una knowledge base no es la lectura ni el pensamiento — es el bookkeeping. Los LLMs no se aburren, no olvidan actualizar una cross-reference, y pueden tocar 15 archivos en un solo paso."

## Tips de implementación

- **Obsidian Web Clipper** para convertir artículos web a markdown
- **Descargar imágenes localmente** en `raw/assets/` para acceso offline
- **Graph view de Obsidian** para visualizar estructura del wiki
- **Marp** para slide decks, **Dataview** para queries dinámicas
- **qmd** como search engine local con hibrido BM25/vector

## Instanciación

El documento es intencionalmente abstracto — está diseñado para compartirlo con un LLM agent que instancie una versión personalizada.

## Relacionado

- [[../notes/sistema/ai-second-brain-claude-obsidian]] — Implementación en nuestro sistema
- [[../notes/sistema/notion-kb-overview]] — Sistema NotebookLM (declara usar este patrón)
- [[../notes/procesos/workflow-7-pasos]] — Workflow de estudio relacionado
