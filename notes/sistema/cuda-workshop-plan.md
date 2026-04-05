---
title: Workshop Plan — cuda-programming (4 sesiones x 90 min)
created: 2026-03-22
updated: 2026-03-22
tags: [CUDA, Workshop, LearningPath, NotebookLM]
sources:
  - "cuda-programming notebook (69 fuentes)"
---

# Workshop Plan — cuda-programming (4 sesiones x 90 min)

4 sesiones completas generadas (Beginner a Expert). Cobertura: Execution Model, Memory, Streams, Tensor Cores + Python interop.

## Sesion 1 — Beginner — Fundamentos y Execution Model

- **Objetivo:** primer kernel con Grid-Stride Loop
- **Hands-on:** Vector Addition
- **Gotcha:** silent kernel failures, usar CUDA_CHECK

## Sesion 2 — Intermediate — Memory Hierarchy

- **Objetivo:** shared memory vs global memory
- **Hands-on:** Tiled Matrix Multiplication
- **Gotcha:** Bank Conflicts (degradacion hasta 32x)

## Sesion 3 — Advanced — Streams y Sincronizacion

- **Objetivo:** overlap de transfers y compute
- **Hands-on:** multi-stream async pipeline con cudaMemcpyAsync
- **Gotcha:** Default Stream = barrera global serializing

## Sesion 4 — Expert — Arquitecturas Modernas, Python y Profiling

- **Objetivo:** Nsight + Tensor Cores + Python interop
- **Hands-on:** CuPy-PyTorch via ExternalStream zero-copy
- **Gotcha:** mito del 100% occupancy (20-40% es suficiente)

## Notebook

https://notebooklm.google.com/notebook/f4b389e4-e26a-4646-a41c-ad7125a755b7

## Relacionado

- [[workflow-7-pasos]] — Los 7 pasos originales
- [[paso-8-learning-path-personal]] — Paso 8 para derivar learning path personal
