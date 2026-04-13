---
tags:
  - agent-architecture
  - evals
  - llm-ops
  - devin
created: 2026-04-09
---

# Agent Harness Engineering

## Concepto Central

```
model + training data + gradient descent → better model
harness + evals + harness engineering → better agent
```

El **harness** es el layer que controla el comportamiento del agent: prompts, tool definitions, contexto, instrucciones.

Los **evals** son los "datos de entrenamiento" del agent — codifican el comportamiento deseado en producción.

**Trace** = cada interacción del agent, genera feedback para mejorar los evals.

## Pipeline: Better-Harness Loop

```
data sourcing → experiment design → optimization → review & acceptance
```

### 6 Pasos

1. **Source & tag evals** — hand-curated, production traces, external datasets
2. **Split data** — Optimization set + Holdout set (evita overfitting)
3. **Run baseline**
4. **Optimize** — iteraciones autónomas con revisión humana opcional
5. **Validate** — check regresiones
6. **Human review** — sanity check final

## Fuentes de Evals

| Fuente | Pros | Contras |
|--------|------|---------|
| Hand-curated | Alto valor, preciso | No escala |
| Production traces | Leverage alto, flywheel | Requiere logging |
| External datasets | Rápido | Necesita curación |

## Tagging

Cada eval se taggea por categorías (tool selection, multi-step reasoning, etc.):
- Permite holdout sets significativos
- Corre subsets → ahorra costo
- Agrupa experimentos

## Overfitting en Agents

> "Agents are famous cheaters" — pueden overfitear a los evals que ven.

**Fix:**
- Holdout sets como proxy de generalización
- Human review como segunda señal
- Evals que miden comportamiento, no solo output

## Referencias

- [Better Harness - LangChain](https://x.com/Vtrivedy10/status/2041927488918413589) (fuente original)
- [Meta-Harness - Stanford](https://arxiv.org/abs/2603.28052)
- [Auto-Harness - DeepMind](https://arxiv.org/pdf/2603.03329)
- [How we build evals for Deep Agents](https://blog.langchain.com/how-we-build-evals-for-deep-agents/)
- [Harness Improvement Loop - LangChain](https://blog.langchain.com/improving-deep-agents-with-harness-engineering/)
- [[../sistema/2026-04-12-your-harness-your-memory]] — Harrison Chase sobre por qué memory = harness y la importancia de open harnesses

## Aplicación con Devin

Ver: [[devin-harness-integration]]
