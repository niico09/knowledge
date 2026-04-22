---
name: memory-caching
description: Memory Caching — extiende RNNs con memoria creciente via cached checkpoints
tags: [ai, ml, nlp, rnn, memory, long-context, titans]
created: 2026-04-22
sources: ["https://arxiv.org/abs/2602.24281"]
---

# Memory Caching: RNNs with Growing Memory

**Paper:** Behrouz et al. (2026) — Google, Cornell, USC

## Problema que resuelve

| Arquitectura | Memoria | Complejidad |
|-------------|---------|-------------|
| RNN | Fija O(L) | Rápido pero recall pobre |
| Transformer | Crece O(L²) | Recall perfecto pero lento |
| **MC** | Crece O(N·L) | Trade-off flexible |

## Idea Central

1. Dividir secuencia en segmentos S^(1),...,S^(N)
2. Cachear el último estado de memoria de cada segmento: {ℳ_{L(i)}^{(i)}}
3. En retrieval, consultar tanto memoria online como cached memories

```
Segment 1: [I love learning] → cache M_L(1)
Segment 2: [because it's fun] → cache M_L(2)
Segment 3: [and useful] → online memory

Query attention → consulta online + M_L(1) + M_L(2)
```

## 4 Variantes

| Variante | Descripción | Mejor para |
|----------|-------------|------------|
| **Residual Memory** | Suma directa sin weighting | Baseline simple |
| **GRM** (Gated Residual Memory) | Gate input-dependent por query-segment similarity | Mejor performance |
| **Memory Soup** | Promedia parámetros de módulos cacheados | Recall-intensive |
| **SSC** (Sparse Selective Caching) | MoE router selecciona top-k memorias | Ultra-long sequences |

### GRM (Gated Residual Memory)

```
g_i = σ(W_g · [q, M_L(i)])  # query-to-segment gate
output = Σ_i g_i · M_L(i)   # weighted sum
```

## Resultados

| Tarea | Modelo | Resultado |
|-------|--------|-----------|
| WikiText LM (1.3B) | Titans + GRM | 15.37 ppl (vs 15.60 baseline) |
| S-NIAH-1 16K | Titans + GRM | 100% (vs 100% baseline) |
| TriviaQA | Titans + GRM | 49.7 (vs 26.2 baseline) |

## Complejidad

```
Standard RNN:     O(L)
MC con N segs:   O(N·L)    donde 1 ≤ N ≤ L
Transformers:     O(L²)
```

## Relación con Titans

El paper extiende **Titans** (Behrouz et al., 2025), que ya introducía memoria de largo plazo en RNNs. MC añade caching explícito de estados ocultos.

## Implicaciones

- RNNs pueden ahora escalar memoria con contexto sin volver a O(L²)
- Trade-off efficiency/recall es configurable via N (número de segmentos cache)
- Arquitectura agnóstica — puede aplicarse a diferentes RNNs

## Referencias

- [Memory Caching: RNNs with Growing Memory](https://arxiv.org/abs/2602.24281)
- [Titans: Learning to Memorize at Scale](https://arxiv.org/abs/2501.00663)
