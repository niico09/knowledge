---
title: "Direct Preference Optimization"
date: 2026-04-13
tags: [rl, preference-optimization, post-training, alignment]
---

# DPO (Direct Preference Optimization)

## Definición

Técnica de alignment que aprende directo de preference pairs sin entrenar un reward model separado.

## Comparación

| Aspecto | RLHF | DPO |
|---------|------|-----|
| Reward model | Separate network | No needed |
| Complejidad | Alta (two-network setup) | Baja |
| Stability | Mayor | Menor en algunos casos |
| Sample efficiency | Media | Mayor |

## Cómo funciona

1. Recolectar preference pairs: (preferred_response, rejected_response)
2. Entrenar directamente en esos pares
3. La policy aprende a preferir sin estimador de reward intermedio

## linked_from

- [[llm-training-post-training-pipeline]]
