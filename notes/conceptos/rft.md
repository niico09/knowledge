---
title: "RFT (Reinforcement Fine-Tuning)"
date: 2026-04-13
tags: [rl, post-training, alignment]
---

# RFT (Reinforcement Fine-Tuning)

## Definición

Interface de producción que empaqueta task definition + grader design + reward signal en pipeline desplegable.

## Comparación con otras técnicas

| Técnica | Característica |
|---------|----------------|
| **SFT** | Supervised, aprende de labeled pairs |
| **RLHF** | pairwise preferences + reinforcement |
| **DPO** | Direct desde preference pairs, sin reward model |
| **RFT** | Pipeline completo listo para deploy |

## Caso de uso

Cuando necesitas que el proceso de RL sea reproducible y operationally simpler que PPO completo.

## linked_from

- [[llm-training-post-training-pipeline]]
