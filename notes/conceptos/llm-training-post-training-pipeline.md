---
type: concept
tags: [llm-training, post-training, rlhf, dpo, grpo, sft]
---

# LLM Training Post-Training Pipeline

## Pipeline Completo de Entrenamiento

```
Pretraining → Post-Training → Distillation → Specialization
```

## Post-Training: Etapas

### 1. Cold-Start SFT
- Pequeño set de high-quality chain-of-thought data
- Warm up antes de RL
- Estabiliza formato y consistencia de lenguaje
- DeepSeek-R1-Zero mostró que RL directo es viable pero produce modelos difíciles de leer

### 2. Reinforcement Learning (GRPO)
- Dominios verificables: math, code, logic
- **GRPO** (Group Relative Policy Optimization) vs PPO:
  - PPO requiere value network separado (engineering-heavy)
  - GRPO: within-group ranking en vez de absolute value estimation
  - No necesita segundo network
  - Usado por DeepSeek y Cursor Composer 2

### 3. Rejection Sampling Fine-Tuning
- Filtrar trayectorias exitosas de RL
- Convertir en nuevo SFT data para siguiente round
- Bridge entre RL y SFT

### 4. Alignment RL
- Helpfulness + safety preference feedback
- Lleva el modelo a release standards como assistant

## Técnicas de Preference Optimization

| Técnica | Descripción |
|---------|-------------|
| **RLHF** | Imitación + pairwise preference comparison + reinforcement |
| **DPO** | Direct Preference Optimization — aprende directo de preference pairs, sin reward model separado |
| **RFT** | Reinforcement Fine-Tuning — task definition + grader + reward en pipeline desplegable |

## SFT Aprende Más que Conocimiento

- Output length, formato, estilo
- Preference evaluation naturalmente favorece respuestas más largas
- Lo que parece diferencia de capability es muchas veces diferencia de **estilo**

## Reward Models

- **ORM** (Outcome Reward Model): solo scoring final, signal sparse, bajo costo
- **PRM** (Process Reward Model): scoring de steps intermedios, mejor para math/code, pero几张 más caro

## Reward Hacking y Alignment Faking

- Models exploitean el scoring system
- Alignment faking: parecen compliant pero ocultan misaligned intent
- Visible CoT no es ground truth completo

## linked_from
- [[llm-training-tw93-2026]]
- [[agent-harness]]

## Técnicas y Conceptos Relacionados

- [[dpo]] — Direct Preference Optimization
- [[rft]] — Reinforcement Fine-Tuning
- [[orm-prm]] — Outcome vs Process Reward Models
- [[reward-hacking]] — Reward hacking y alignment faking
- [[cold-start-sft]] — Warmup antes de RL
- [[rejection-sampling-ft]] — Bridge entre RL y SFT
- [[distillation]] — Capability decoupling bigger→smaller
