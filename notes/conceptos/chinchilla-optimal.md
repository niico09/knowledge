---
title: "Chinchilla Optimal Point"
date: 2026-04-13
tags: [llm-training, scaling-laws, compute-optimal]
source: arXiv:2203.15556
---

# Chinchilla Optimal Point

## paper: Hoffmann et al. 2022

"Training Compute-Optimal Large Language Models"

## Insight central

Balance entre parameter count y training token count dado un fixed compute budget.

## La Regla

Para un compute budget dado, un modelo optimally trained debería tener:

```
tokens ≈ 20 * parameters
```

## Ejemplo Concreto

- 8B parameter model → ~200B tokens (según Chinchilla)
- Llama 3 8B entrenó en 15T tokens (~75x más que el optimal point)
- Esto produce **mayor capability density per parameter**
- Resultado: modelo más pequeño y barato de servir

## Por qué importa

> "Many models aren't too small; they're undertrained."

La pregunta práctica: ¿agregar más parámetros o más datos? ¿El modelo es capacity-limited o solo undertrained?

## linked_from

- [[llm-training-tw93-2026]]
