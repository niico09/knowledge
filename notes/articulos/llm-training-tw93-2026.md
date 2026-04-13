---
title: "You Don't Know LLM Training: Principles, Pipelines, and New Practices"
author: Tw93 (@HiTw93)
url: https://x.com/HiTw93/status/2042240337352274199
date: 2026-04-09
tags: [llm-training, post-training, rlhf, reward-modeling, agent-harness, distillation]
type: article-summary
---

# Resumen

Post técnico profundo sobre cómo funciona el entrenamiento de LLMs en 2026, desmintiendo la idea de que solo importa el pretraining.

## Temas Centrales

### 1. Pretraining es solo la base
- Balance compute/parameters/tokens (Chinchilla optimal point)
- Tokenizer vocabulary size impacta eficiencia e inferencia
- 8B model debería entrenar en ~200B tokens (vs Llama 3 8B que usó 15T)
- Single-GPU deployability, long context, multimodality son constraints fijados antes del entrenamiento

### 2. La recipe de datos determina las capacidades
- Deduplicación y control de contaminación subestimados
- Datos sintéticos son parte formal del pipeline
- Modelos grandes desarrollan capacidades primero → se comprimen en modelos pequeños (distillation)
- "Bigger-before-smaller es partly about capability decoupling, not just cost strategy"

### 3. Post-Training: Pipeline de 4 Etapas (DeepSeek-R1)
1. **Cold-start SFT** — pequeño set de high-quality CoT data
2. **RL con GRPO** — verifiable domains (math, code, logic), sin value network separado
3. **Rejection Sampling FT** — filtrar trayectorias exitosas de RL → nuevo SFT data
4. **Alignment RL** — helpfulness + safety preference feedback

**GRPO vs PPO**: GRPO usa within-group ranking en vez de absolute value estimation, significativamente más simple de operar.

### 4. Eval, Grader, Reward
- **ORM**: sparse signal, bajo costo, propenso a shortcut reasoning
- **PRM**: dense signal, mejor para math/code, pero 几张 más caro
- **Reward hacking / alignment faking**: modelos explotan el scoring system
- Visible CoT no es ground truth — modelos usan hints sin承认 en chain of thought visible

### 5. Agent Harness es una capa de optimización propia
El **harness** (prompt construction, memory, retrieval, context editing, tool orchestration) no es deployment detail — **es una capa que shapes capability**.

- **Meta-Harness**: optimiza el harness code mismo (no weights). Mismo modelo base + different harness = 6x performance gap en mismo benchmark.
- **Kimi K2.5 PARL**: solo entrenar orquestador, credit assignment en orchestration layer
- **Cursor Composer 2**: real-time RL via production traffic
- **Chroma Context-1**: prune_chunks como policy

> "The program surrounding the model is no longer just a deployment detail. It's a layer that shapes capability."

### 6. Después del shipping, el pipeline sigue
- Modelo shipped es un **snapshot**
- El pipeline y harness program son lo que siguen corriendo
- Continuous optimization via production traffic acorta el feedback loop entre training y deployment

## Tres Preguntas para Diagnosticar "Modelo de repente mejoró"
1. **Where** — pretraining vs post-training
2. **Which layer** — weights vs reward/eval/grader vs harness
3. **What** — ceiling vs cost/latency vs specialization

## Referencias
- Chinchilla, InstructGPT, DeepSeekMath (GRPO), DeepSeek-R1/V3, Llama 3
- Constitutional AI, Deliberative Alignment
- Anthropic reward tampering research
- Meta-Harness, Kimi K2.5, Cursor Composer 2, Chroma Context-1

## linked_to
- [[llm-training-post-training-pipeline]]
- [[agent-harness]]
- [[cold-start-sft]]
- [[rejection-sampling-ft]]
- [[orm-prm]]
- [[reward-hacking]]
- [[meta-harness]]
- [[parl]]
- [[distillation]]
- [[chinchilla-optimal]]
- [[mup]]
- [[wsd-schedule]]
