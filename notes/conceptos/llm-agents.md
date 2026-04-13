---
title: "LLM Agents"
date: 2026-04-09
tags: [llm, agents, software-engineering]
---

# LLM Agents

## Definición

Agentes basados en Large Language Models capaces de ejecutar tareas de software engineering mediante herramientas (bash, edición de código, etc.).

## Componentes

- **Policy** — modelo que decide acciones
- **Tools** — operaciones disponibles (bash, str_replace, etc.)
- **Memory** — contexto y historial
- **Planning** — descomposición de tareas

## Tipos de Agents

- Coding agents (SWE-bench, Devin, Claude Code)
- Research agents
- Multi-modal agents

## Atomic Skills para Coding Agents

Paper [[scaling-coding-agents-atomic-skills]] define 5 atomic skills:

1. **Code Localization** — identificar archivos relevantes
2. **Code Editing** — generar patches
3. **Unit-Test Generation** — crear tests que detecten fallos
4. **Issue Reproduction** — reproducir bugs
5. **Code Review** — evaluar PRs

### Joint RL Training

Entrenar skills simultáneamente vs. individual:

| Approach | Atomic Skills | OOD Generalization |
|----------|-------------|-------------------|
| Single-task RL | 56.6% | 29.9% |
| **Joint RL** | **70.1%** | **38.2%** |

Joint RL logra **+18.7%** mejora promedio y positive transfer entre skills.

## Skills Relacionadas

- [[swe-bench]] — benchmark para coding agents
- [[reinforcement-learning]] — training approach

## Papers Clave

- [[scaling-coding-agents-atomic-skills]] — scaling via atomic skills (+18.7%)
