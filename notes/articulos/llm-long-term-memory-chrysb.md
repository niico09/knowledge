---
title: "Why long-term memory for LLMs remains unsolved"
author: Chrys Bader (@chrysb)
source: https://x.com/chrysb/status/2043020014035570784
date: 2026-04-11
tags: [llm, memory, ai-systems, architecture]
type: article
---

# Why long-term memory for LLMs remains unsolved

## Tesis Central

La memoria a largo plazo para LLMs conversacionales sigue siendo un **problema no resuelto**.

El sueño —un modelo que recuerda lo que dijiste y extrae significado a lo largo del tiempo— requiere resolver simultáneamente:
- **Preservación perfecta** (raw)
- **Interpretación perfecta** (derived)

Todo sistema actual sacrifica uno por el otro.

## El Trade-off Fundamental

| raw | derived |
|-----|---------|
| Sin pérdida pero inerte | Compacto y usable pero degrada |
| Pile de transcripts ≠ entendimiento | "Photocopy of a photocopy" |

> *"Raw is lossless but inert. A pile of transcripts isn't understanding."*

## ¿Por qué infinite context no resuelve esto?

1. **Costo:** Procesar todo en cada turno escala linealmente — economics prohibitivos
2. **Degradación:** El modelo empeora cuando el contexto se llena; atención en info del medio cae

## La Paradoja de la Evaluación

No puedes probar que un sistema de memoria funciona porque cualquier juez tiene las mismas limitaciones de contexto que el sistema que evalúa.

> *"Memory is what happens when facts change, when old context gets superseded, when the significance of a conversation only becomes clear weeks later. The right answer depends on the full arc of the relationship, and the arc is always in motion."*

## Framework: Los 9 ejes de un sistema de memoria

1. **What gets stored** — raw vs derived
2. **When derivation happens** — timing
3. **What triggers a write** — write triggers
4. **Where it gets stored** — storage backend
5. **How it gets retrieved** — retrieval strategy (semantic search, full-text, graph traversal)
6. **Post-retrieval processing** — re-ranking
7. **When retrieval happens** — always-injected vs hook-driven vs tool-driven
8. **Who is doing the curating** — main model vs cheap models vs user
9. **Forgetting policy** — qué, cómo, cuándo

## Failure Modes Comunes

| Failure Mode | Descripción |
|-------------|-------------|
| Session amnesia | Cada sesión empieza en cero |
| Entity confusion | El modelo fusiona entidades distintas |
| Over-inference | Salva gaps con fabricaciones plausibles |
| Derivation drift | Resúmenes encadenados degradan (photocopy of a photocopy) |
| Retrieval misfire | Embeddings semanticamnete cercanos pero meaning diferente |
| Stale context dominance | Memoria vieja satura la reciente |
| Selective retrieval bias | Solo encuentra lo que matchea el query actual |
| Confidence without provenance | Alta confianza sin poder rastrear fuente |

## Takeaway

> *"Memory for LLMs remains unsolved not because nobody's tried hard enough, but because the problem is very, very hard to solve."*

## Images del Deep Dive

El post incluye 9 diagramas (uno por eje). URLs de las imágenes:

| Eje | URL |
|----|-----|
| 1. What gets stored (raw) | https://pbs.twimg.com/media/HFo5bZ6acAAoAdC?format=jpg&name=small |
| 1. What gets stored (derived) | https://pbs.twimg.com/media/HFo5iVFaMAAdcTO?format=jpg&name=small |
| 2. When derivation happens | https://pbs.twimg.com/media/HFo5yK8bgAAZIde?format=jpg&name=small |
| 3. What triggers a write | https://pbs.twimg.com/media/HFo56x8akA4iVwk?format=jpg&name=small |
| 4. Where it gets stored | https://pbs.twimg.com/media/HFo6Qw3akAIxgKj?format=jpg&name=small |
| 5. How it gets retrieved | https://pbs.twimg.com/media/HFo6b8xakAQ61ZT?format=jpg&name=small |
| 6. Post-retrieval processing | https://pbs.twimg.com/media/HFo6mJlaEAAMXxY?format=jpg&name=small |
| 7. When retrieval happens | https://pbs.twimg.com/media/HFo6xQEbEAAhZBL?format=jpg&name=small |
| 8. Who is doing the curating | https://pbs.twimg.com/media/HFo64cuakAUaQeq?format=jpg&name=small |
| 9. Forgetting policy (what) | https://pbs.twimg.com/media/HFo7IJMakAAV-H2?format=jpg&name=small |
| 9. Forgetting policy (when) | https://pbs.twimg.com/media/HFo7W0_akAMPOUF?format=jpg&name=small |

## Relacionado

- [[memoria-ltm-llm]] — Conceptos sobre memoria
- [[ai-agent-architecture]] — Arquitectura de agentes
