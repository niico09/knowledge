---
title: "Rejection Sampling Fine-Tuning"
date: 2026-04-13
tags: [llm-training, sft, data-filtering, post-training]
---

# Rejection Sampling Fine-Tuning

## Definición

Filtrar trayectorias exitosas de RL y convertirlas en nuevo SFT data para otra ronda de supervised fine-tuning.

## Función en Pipeline

Bridge entre RL y SFT.

```
RL (GRPO) → Filtrar trayectorias exitosas → rejection sampling data → SFT round
```

## Qué hace

1. Samplea respuestas del RL policy
2. Filtra las exitosas (alto reward,verifiable correct)
3. Convierte esas trayectorias en training examples para SFT
4. siguiente SFT pass usa datos de mayor calidad

## Por qué importa

- RL explora пространство de respuestas
- Las buenas trayectorias se convierten en supervision signal para próxima iteración
- Esto es lo que cierra el loop entre RL y SFT

## Resultado esperado

Gap visible entre hacer solo SFT directo vs pasar por las 4 etapas completas (DeepSeek-R1 recipe).

## linked_from

- [[llm-training-tw93-2026]]
- [[llm-training-post-training-pipeline]]
