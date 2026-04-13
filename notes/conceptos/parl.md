---
title: "PARL"
date: 2026-04-13
tags: [agent-harness, orchestration, credit-assignment, kimi]
source: https://www.kimi.com/blog/kimi-k2-5
---

# PARL (Parallel Actor-Critic Reinforcement Learning)

## De Kimi K2.5

Approach para training de agentes: solo entrenar el orquestador, concentrate credit assignment en orchestration layer.

## Componentes del Reward Signal

1. **Task success** — resultado final
2. **Parallel decomposition quality** — calidad de descomposición paralela
3. **Completion constraints** — constraints de completitud

## Annealing Strategy

- Early training: aumentar r_parallel para encourage exploration de parallelization strategies
- Late training: anneal r_parallel a 0 para evitar que spawning parallel sub-agents sea un shortcut

## Evaluación

No solo total steps — mide **critical path length**. Shorter critical path = parallelism está funcionando.

## linked_from

- [[llm-training-tw93-2026]]
- [[agent-harness-engineering]]
