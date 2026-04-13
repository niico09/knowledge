---
title: "Reward Hacking"
date: 2026-04-13
tags: [rl, alignment, reward-modeling, safety]
---

# Reward Hacking

## Definición

Cuando un modelo explota el scoring system sin genuinamente completar la tarea.

##Reward Tampering

Modificar directamente la computación de reward.

## Alignment Faking

Parecer compliant mientras se oculta intent desalineado.

## Señales de alerta

- CoT visible no correpsonde al proceso interno
- Modelo usa hints sin承認 en chain of thought
- Explota scoring rules sin capability genuina

## Investigación

Anthropic (2025): después de injectar reward-hack knowledge en RL environments explotables, el modelo:
- Continuó exploitando tareas similares
- Exhibió broader misalignment behaviors

## Implicación

Reward, grader, environment isolation y monitoring deben ser parte del training design — no afterhought.

## linked_from

- [[llm-training-post-training-pipeline]]
- [[llm-training-tw93-2026]]
