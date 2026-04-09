---
title: Learning Path — ML + AI Engineering
created: 2026-04-05
updated: 2026-04-05
tags: [LearningPath, ML, AIEngineering, DeepLearning, LLM]
sources:
  - "Ruta de lectura basada en biblioteca personal"
status: synthesized
last_lint: 2026-04-07
---

# Learning Path — ML + AI Engineering

## Overview

Ruta de lectura para convertirse en ML/AI Engineer. Timeline: 10-12 meses de estudio serio.

**Principio**: No esperar a terminar todos los libros. Aplicar aunque sea verde.

## Fases

### FASE 1 — Fundamentos (Mes 1-2)

| Orden | Libro | Tema | Prioridad |
|-------|-------|------|-----------|
| 1 | Mathematics of Machine Learning | Álgebra lineal, cálculo, probabilidad | 🔴 Esencial |
| 2 | Artificial Intelligence: A Modern Approach (4th Ed) | Teoría IA completa | 🔴 Esencial |

**Skip si** ya tenés base de matemática universitaria.

### FASE 2 — ML Práctico (Mes 3-4)

| Orden | Libro | Tema | Prioridad |
|-------|-------|------|-----------|
| 3 | Hands-On Machine Learning (Scikit-Learn + PyTorch) | Implementación práctica | 🔴 Esencial |
| 4 | Machine Learning Systems | Diseño de sistemas ML reales | 🟠 Importante |

### FASE 3 — Deep Learning + GenAI (Mes 5-6)

| Orden | Libro | Tema | Prioridad | Recurso Complementario |
|-------|-------|------|-----------|------------------------|
| 5 | Generative AI with Python and PyTorch | CNNs, GANs, VAEs, Stable Diffusion | 🟠 Importante | |
| 6 | Build a Large Language Model (From Scratch) | Transformers, LLMs por dentro | 🔴 Esencial | [[transformer-architecture]] |

**Complemento**: La nota de Transformer cubre todo el fundamento teórico con código PyTorch, diagramas y preguntas de verificación.

### FASE 4 — AI Engineering / Producción (Mes 7-8)

| Orden | Libro | Tema | Prioridad |
|-------|-------|------|-----------|
| 7 | AI Engineering — Chip Huyen | MLOps, deployment, fine-tuning, RAG | 🔴 Esencial |
| 8 | LLM Engineer's Handbook | Fine-tuning, RLHF, RAG production | 🟠 Importante |
| 9 | Interpretable AI | XAI, SHAP, LIME | 🟡 Bueno |

### FASE 5 — Arquitectura de Software (Mes 9-12, en paralelo)

| Orden | Libro | Tema | Prioridad |
|-------|-------|------|-----------|
| 10 | Clean Architecture — Robert C. Martin | Estructurar proyectos grandes | 🟠 Importante |
| 11 | Software Architecture in Practice (4th Ed) | Arquitectura empresarial | 🟡 Bueno |
| 12 | Modern Software Engineering — David Farley | Software de calidad | 🟡 Bueno |

## Timeline Visual

```
Mes 1-2:   Mathematics → AIMA (capítulos selectos)
Mes 3-4:   Hands-On ML (capítulos 1-10)
Mes 5-6:   Hands-On ML (capítulos 11-19) + Machine Learning Systems
Mes 7-8:   Generative AI + Build LLM from Scratch
Mes 9-10:  AI Engineering + LLM Engineer's Handbook
Mes 11-12: Interpretable AI + Clean Architecture
```

## Employability Checklist

| Habilidad | Cómo Demostrar | Mínimo |
|-----------|---------------|--------|
| ML fundamentals | Entrevistas técnicas (AIMA-style) | Overfitting, regularization, gradient descent, backprop, CNNs/RNNs/Transformers |
| ML Implementation | Portfolio en GitHub | 1-2 proyectos completos |
| ML Systems Design | System design interviews | Diseñar sistema de recomendaciones / detección de fraude / API de ML |
| Producción/DevOps | Deployment real | Haber deployado un modelo en producción |

### Cuando Estás Empleable

| Nivel | Timing | Requisitos |
|-------|--------|------------|
| 🟢 Empleable | ~6-8 meses | Hands-On ML + 1 proyecto + fundamentos deep learning |
| 🟡 Más empleable | ~10-12 meses | +AI Engineering + 1 proyecto RAG/fine-tuning + deploy real |
| 🔴 Altamente empleable | ~12+ meses | +LLM Engineer's Handbook + 2-3 proyectos + MLOps tooling |

## Relacionado

- [[learning-path-architect]] — Learning path para Claude Architect
- [[guia-maestra-estudio]] — Sistema de estudio general
- [[transformer-architecture]] — Guía completa de Arquitectura Transformer (complemento a Fase 3)
