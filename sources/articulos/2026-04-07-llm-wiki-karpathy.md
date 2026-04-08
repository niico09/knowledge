---
title: "LLM Wiki — A Pattern for Building Personal Knowledge Bases"
url: "https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f"
date: 2026-04-07
type: article
status: raw
---

## Resumen

Patrón para construir bases de conocimiento personales usando LLMs. En vez de RAG clásico, el LLM mantiene un wiki persistente de markdown files que sintetiza fuentes. Tres capas: raw sources, wiki generado, schema de configuración.

## Conceptos extraídos

- [ ] Raw sources como capa inmutable
- [ ] Wiki con síntesis, cross-references y contradicciones flaggeadas
- [ ] Operations: ingest, query, lint
- [ ] index.md como catálogo
- [ ] log.md como registro append-only

## Fuentes relacionadas

- (pendiente)
