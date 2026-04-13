---
title: "Cold-Start SFT"
date: 2026-04-13
tags: [llm-training, sft, post-training, warmup]
---

# Cold-Start SFT

## Definición

Pequeño set de high-quality chain-of-thought data usado para warming up antes de RL.

## Problema que resuelve

DeepSeek-R1-Zero demostró que RL directo desde base model es viable, pero produce:
- Modelo que repeats itself
- Mixed languages
- Hard to read

## Función

- Estabiliza formato y consistencia de lenguaje antes de RL
- Da a RL un starting point más estable
- **No es step redundante** — es prerequisito para cold-start stability

## Posición en Pipeline

```
Pretraining → Cold-start SFT → RL (GRPO) → Rejection Sampling FT → Alignment RL
```

## linked_from

- [[llm-training-tw93-2026]]
- [[llm-training-post-training-pipeline]]
