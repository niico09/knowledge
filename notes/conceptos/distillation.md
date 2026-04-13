---
title: "Distillation (LLM)"
date: 2026-04-13
tags: [llm-training, model-compression, knowledge-transfer]
---

# Distillation in LLMs

## Definición

Comprimir capabilities de un modelo grande a uno pequeño.

## Patrón: Bigger-Before-Smaller

> "Models generally need to develop capabilities at larger scale first before those capabilities can be compressed into smaller ones."

No es solo estrategia de costo — es **capability decoupling**:

1. Knowledge memorization y reasoning capability están entrelazados en pretraining
2. Modelos grandes desarrollan ambos simultáneamente
3. Solo a suficiente escala pueden cargar ambas responsabilidades
4. Modelo grande genera pure reasoning demonstration data
5. Modelo pequeño entrenado en eso puede focus en reasoning sin memorización forzada

## Ejemplo: DeepSeek-R1-Distill

- Large model desarrolla reasoning via RL + verified rewards
- Trayectorias resultantes se transfieren a dense models (1.5B a 70B)
- Llama 3.1 405B usado para mejorar post-training quality de 8B y 70B

## Distillation ≠ MoE

- **Dense**: todos los parámetros corren para cada token
- **MoE**: solo subset de experts se activa por token

## linked_from

- [[llm-training-tw93-2026]]
