---
title: "ORM vs PRM"
date: 2026-04-13
tags: [rl, reward-model, evaluation, post-training]
---

# ORM vs PRM

## ORM (Outcome Reward Model)

- Solo scorea el resultado final
- Signal sparse, bajo costo
- Bueno para empezar
- Más propenso a shortcut reasoning

## PRM (Process Reward Model)

- Scorea cada step intermedio
- Signal denso, mejor para math/code reasoning
- Más caro (varias veces más que ORM)
- Permite constrain process quality

## Cuándo usar cada uno

- **ORM**: dominios no verificables, baseline, producción a escala
- **PRM**: math, code, logic — dominios donde se pueden verificar pasos intermedios con programas

## OpenAI Math Reasoning Experiments

PRM no solo mejoró accuracy sino que hizo más fácil constraining process quality (cada step supervisado).

## linked_from

- [[llm-training-post-training-pipeline]]
- [[llm-training-tw93-2026]]
