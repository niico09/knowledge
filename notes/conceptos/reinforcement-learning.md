---
title: "Reinforcement Learning"
date: 2026-04-09
tags: [machine-learning, reinforcement-learning, optimization]
---

# Reinforcement Learning

## Conceptos Fundamentales

- **Policy** — función que mapea estados a acciones
- **Reward** — señal de feedback
- **Value function** — ожидание будущих rewards

## RL en LLMs

- **RLHF** — Reinforcement Learning from Human Feedback
- **GRPO** — Group-based Relative Policy Optimization
- **Joint RL** — entrenamiento multi-skill simultáneo

## GRPO (Group-based Relative Policy Optimization)

Usado en [[scaling-coding-agents-atomic-skills]] para entrenamiento estable de múltiples atomic skills.

### Algoritmo

1. **Group sampling:** Para cada prompt, sample un grupo de respuestas
2. **Relative ranking:** Compara respuestas dentro del grupo
3. **Advantage estimation:** Calcula ventaja relativa
4. **Policy update:** Actualiza πθ con clipped surrogate loss

### Ventajas sobre PPO

- No requiere critic network separada
- Más estable para skills heterogéneos
- Mejor positive transfer entre skills

## Joint vs Single-Task RL

| Metric | Single-Task | Joint RL | Δ |
|--------|-------------|----------|---|
| Atomic Skills | 56.6% | 70.1% | +13.5% |
| OOD Composite | 29.9% | 38.2% | +8.3% |

Joint RL logra mejor generalización OOD porque:
- Skills se complementan (positive transfer)
- Shared policy captura abstract representations
- Skills buffer evita starvation

## Skills Buffer

FIFO buffer que almacena trajectories de todos los skills:

```
Skills Buffer (N=50,000)
┌──────────────────────────────────────────────────┐
│ Trajectory: [Skill, Prompt, Response, Reward]    │
│ Trajectory: [Skill, Prompt, Response, Reward]    │
│ ...                                              │
└──────────────────────────────────────────────────┘
```

Sampling uniforme entre skills para evitar que algunos sean ignorados.

## Aplicaciones en Software

- Training de coding agents ([[scaling-coding-agents-atomic-skills]])
- Optimización de código
- Bug fixing

## Referencias

- [[scaling-coding-agents-atomic-skills]] — usa GRPO para atomic skills
- DeepSeek GRPO paper
