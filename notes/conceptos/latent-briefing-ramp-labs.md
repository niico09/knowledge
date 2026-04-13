# Latent Briefing (Ramp Labs)

## Meta

- **Fuente:** [Post X @RampLabs](https://x.com/RampLabs/status/2042660310851449223) — 10 Abr 2026
- **Autor investigación:** Ben Geist (@b_geist)
- **Métricas:** 326.5K vistas, 1,341 likes, 175 reposts, 2,669 bookmarks
- **Tags:** #multi-agent-systems #kv-cache #inference-efficiency #LLM

## Problema

Sistemas multi-agente tipo RLM (orquestador → worker) son token-ineficientes:

- Orquestador acumula reasoning trajectory a través de múltiples llamadas
- Worker recibe solo (query + documento raw), pierde contexto valioso del orquestador
- Token usage compounds rápidamente en arquitecturas jerárquicas

**Tradeoffs de soluciones existentes:**
| Método | Problema |
|--------|----------|
| LLM Summarization | 20-60s latencia/step, información se pierde |
| RAG / Retrieval | Chunking rompe dependencias cross-chunk |
| Pass everything | Caro, lento, accuracy degrada con contexto irrelevante |

## Solución

**Latent Briefing:** Comprimir KV cache del orquestador a nivel de representación usando attention patterns del worker model como señal de relevancia.

### Base: Attention Matching (AM) Framework

De Zweiger et al., 2026 (arXiv:2602.16284). given KV cache de tamaño S, encontrar cache compacto de tamaño t < S que produzca outputs de atención casi idénticos.

Para cada attention head: seek (C1, β, C2) tales que:

```
softmax(Q · C1ᵀ + β) · C2 ≈ softmax(Q · Kᵀ) · V
```

Donde:
- **C1** (compacted keys): subset de keys originales con alta atención
- **β** (bias corrections): ajustes escalares que compensan keys faltantes
- **C2** (compacted values): vectors reconstruidos vía ridge regression

### 3 Modificaciones de Ramp Labs

1. **Task-guided query vectors**: Usan queries del task prompt del orquestador (no del contexto) para scoring de relevancia. Prioriza información relevante para la tarea específica del worker.

2. **Shared token selection via global scoring**: Agregan scores a través de todas las capas y heads en un solo per-position score con weight por head importance. Voting consenso vs 320 solves independientes → batched execution.

3. **Thresholding con MAD normalization**: `keep si position_score > median + threshold · MAD` — más robusto a outliers que top-k fijo.

### Optimización de Latency

- AM original: 30+ segundos en A100 (320 CUDA kernel launches secuenciales)
- Con shared mask: batched tensor operations → **~1.7s median overhead** (~20× speedup)
- KV prefix caching: 90%+ de tokens se reúsan entre calls

## Resultados

**Setup:** RLM con Claude Sonnet 4 (orquestador) + Qwen3-14B (worker), LongBench v2 (126 preguntas, docs 0-100k tokens).

| Métrica | Resultado |
|---------|-----------|
| Accuracy | Comparable o **+3pp** sobre baseline |
| Token savings (worker) | **42-57%** mediana |
| Token savings (total) | **21-31%** mediana |
| Reducción worker token consumption | **65%** |
| Overhead compaction | **~1.7s** mediana |

### Threshold óptimo varía por régimen

| Régimen | Threshold óptimo | Compactación | Por qué |
|---------|-----------------|--------------|---------|
| Docs largos (32k-100k) | t = -1.0 | 18% | Información dispersa; compactación ligera preserva cobertura |
| Preguntas difíciles | t = 2.0 | 79% | Reasoning especulativo diluye señal; filtración agresiva ayuda |
| Docs cortos + fáciles | t = 1.0 | 68% | Trayectoria corta y focused; moderada remueve redundancia |

Intuición: preguntas difíciles generan hipótesis y speculation noise → compactación agresiva actúa como filtro de relevancia.

## Limitaciones

1. **Orchestrator variance**: Claude Sonnet 4 es no-determinístico → estrategias de descomposición varían entre runs (n=42 por condición, resultados ruidosos pero tendencias consistentes)
2. **Single benchmark**: Solo LongBench v2 — code generation, math reasoning, multi-doc synthesis pueden comportarse diferente

## Relevancia

Es un ejemplo de **inference-time efficiency** para multi-agent systems. Opera directamente sobre KV cache en vez de pasar texto redundante. Esto se vuelve bottleneck conforme arquitecturas agent crecen en depth/width.

> "Beyond improving intelligence per token within individual agents, there is increasing value in how efficiently tokens are used across agents in the system as a whole, saving time and money."

## Papers relacionados

- **AM Compaction:** Zweiger et al., 2026 — arXiv:2602.16284
- **RLM (base):** Zhang et al., 2025 — arXiv:2512.24601
