---
title: "Meta-Harness"
date: 2026-04-13
tags: [agent-harness, optimization, benchmark, llm-training]
source: https://yoonholee.com/meta-harness/
---

# Meta-Harness

## Definición

Framework que optimiza el **harness code mismo**, no los weights del modelo. El programa que rodea el modelo es una capa de optimización propia.

## Resultado clave

> "With the same base model, only changing the harness, you can see a **6x performance gap** on the same benchmark."

## Qué optimiza

- Prompt construction
- Retrieval
- Memory
- State update programs

## Cómo funciona

1. Escribe todo (código, scores, execution traces) a filesystem
2. Proposer hace grep/cat/diff comparisons
3. Trace failed paths para revisar harness
4. **No es un optimizer textual genérico** — harnesses son long-running, stateful programs

## Resultados documentados

| Benchmark | Mejora |
|-----------|--------|
| Online text classification | +7.7 points, 1/4 context tokens |
| Retrieval-augmented math reasoning | +4.7 points avg across 5 models |
| TerminalBench-2 | Superó baseline hand-engineered |

## Descubrimiento automático

TerminalBench-2: Meta-Harness descubrió **environment bootstrap** — corre shell command antes del agent loop para snapshot working directory, available languages, package manager, memory state.

## Implicación

> "The program surrounding the model is no longer just a deployment detail. It's a layer that shapes capability."

## linked_from

- [[llm-training-tw93-2026]]
- [[agent-harness]]
