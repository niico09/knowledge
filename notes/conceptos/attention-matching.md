# Attention Matching (AM)

## Definición

Framework para KV cache compaction propuesto por Zweiger et al. (2026). Dado un KV cache de tamaño S, encuentra un cache compacto de tamaño t < S que produce outputs de atención casi idénticos al original.

## Formulación

Para cada attention head, se buscan (C1, β, C2) tales que:

```
softmax(Q · C1ᵀ + β) · C2 ≈ softmax(Q · Kᵀ) · V
```

Donde:
- **C1** (compacted keys): subset de keys originales con mayor atención
- **β** (bias corrections): ajustes escalares que compensan keys faltantes
- **C2** (compacted values): value vectors reconstruidos vía ridge regression

## Limitación original

El algoritmo procesa cada par (layer, head) independientemente → 320 solves serializados para Qwen3-14B → 30+ segundos en A100 (GPU subutilizada por sequential CUDA kernel launches).

## Extensión: Latent Briefing

Ramp Labs modificó AM con:
1. Task-guided query vectors (queries del task prompt vs. del contexto)
2. Shared token selection via global scoring (batched execution)
3. MAD normalization thresholding

Ver: [[latent-briefing]]

## Referencia

- Zweiger et al., 2026 — arXiv:2602.16284
