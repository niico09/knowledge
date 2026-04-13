---
title: "Scaling Coding Agents via Atomic Skills"
authors: "Yingwei Ma, Yue Liu, Xinlong Yang, et al."
source: "arXiv:2604.05013"
date: 2026-04-09
tags: [llm-agents, software-engineering, reinforcement-learning, scaling]
---

# Scaling Coding Agents via Atomic Skills

## Metadata

| Campo | Valor |
|-------|-------|
| arXiv | 2604.05013 |
| Instituciones | HKUST, NUS, PKU, SJTU, BUPT |
| Área | Software Engineering |
| Modelo Base | GLM-4.5-Air-Base (106B params) |

---

## 1. Introduction

### Problema

Agentes de código basados en LLMs sufren **task-specific overfitting** cuando se entrenan en benchmarks composites. Memorizan heurísticas en lugar de aprender capacidades robustas.

Los approaches actuales dividen tareas complejas en pasos (localize → edit → verify), pero entrenan en tareas compuestas completas, causando:

- **Overfitting a instancias específicas** — el agent memoriza patterns de resolución
- **Poor generalization** — no generaliza a tareas unseen
- **Negative transfer** — skills compiten entre sí

### Contribución Principal

1. Definición formal de **5 atomic skills** con especificaciones I/O precisas
2. Framework de **Joint RL** para entrenamiento multi-skill simultáneo
3. Demonstration de **+18.7%** mejora promedio y generalización OOD
4. Release de **AtomicBench** dataset

---

## 2. Atomic Skills Definition

### Principios de Diseño

| Principio | Descripción |
|-----------|-------------|
| **Precise I/O specs** | Input/output definidos sin ambigüedad |
| **Independent evaluation** | Cada skill evaluable independientemente |
| **Minimal ambiguity** | Rewards claros, sin dependencias externas |

### Las 5 Atomic Skills

#### Skill 1: Code Localization

**Definición:** Given a issue description, identify the exact files that need modification.

**Input:** Issue title + description + repository structure
**Output:** List of file paths

**Ejemplo:**
```
Input: "Login button not working on mobile Safari"
Output: ["src/components/Button.tsx", "src/hooks/useAuth.ts"]
```

**Reward:** 1.0 if all modified files are in prediction AND prediction contains no extra files, else 0.0

---

#### Skill 2: Code Editing

**Definición:** Generate a precise patch to fix an issue.

**Input:** Issue description + buggy code
**Output:** Unified diff (unified format)

**Ejemplo:**
```diff
--- a/src/utils/parser.py
+++ b/src/utils/parser.py
@@ -10,7 +10,7 @@ def parse_config(content):
-    return json.loads(content)
+    return json.loads(content, strict=False)
```

**Reward:** 1.0 if patch applies cleanly AND all tests pass, else partial credit based on overlap

---

#### Skill 3: Unit-Test Generation

**Definición:** Generate tests that detect the reported fault.

**Input:** Issue description + buggy code + repo context
**Output:** Test file with failing test(s)

**Ejemplo:**
```python
def test_config_parser_strips_whitespace():
    """Test that config parser handles trailing whitespace"""
    result = parse_config('{"key": "value"}  \n')
    assert result == {"key": "value"}
```

**Reward:** 1.0 if generated test fails on buggy code AND passes on fixed code, else 0.0

---

#### Skill 4: Issue Reproduction

**Definición:** Create a minimal reproduction script for a bug.

**Input:** Issue description + reproduction hints
**Output:** Standalone script that demonstrates the bug

**Ejemplo:**
```bash
#!/bin/bash
cd /repo
python -c "from utils import parser; parser.parse_config('{}  ')"
# Expected: parses successfully
# Actual: raises JSONDecodeError
```

**Reward:** 1.0 if script reproduces bug consistently, else 0.0

---

#### Skill 5: Code Review

**Definición:** Evaluate PR correctness and suggest improvements.

**Input:** PR description + diff + context
**Output:** Review comments with severity levels

**Ejemplo:**
```json
{
  "comments": [
    {
      "file": "src/auth.py",
      "line": 42,
      "severity": "blocking",
      "body": "SQL injection vulnerability: user input directly concatenated"
    }
  ],
  "summary": "PR introduce 1 blocking, 0 major, 2 minor issues"
}
```

**Reward:** Based on F1 score of issue detection vs ground truth

---

## 3. Joint Reinforcement Learning Framework

### Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│              Shared Policy πθ (LLM)                     │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────┐ ┌──────┐│
│  │Localize │ │  Edit   │ │  Test  │ │Reprod│ │Review││
│  └────┬────┘ └────┬────┘ └────┬────┘ └──┬───┘ └──┬───┘│
│       │           │           │          │         │    │
│       └───────────┴───────────┴──────────┴─────────┘    │
│                           │                              │
│                    Skills Buffer                          │
│                           │                              │
│                    GRPO Optimizer                        │
└─────────────────────────────────────────────────────────┘
```

### Group-based Relative Policy Optimization (GRPO)

Inspirado en GRPO de DeepSeek, el enfoque:

1. **Group sampling:** Para cada prompt, sample un grupo de respuestas
2. **Relative ranking:** Compara respuestas dentro del grupo
3. **Advantage estimation:** Calcula ventaja relativa
4. **Policy update:** Actualiza πθ con clipped surrogate loss

**Ventaja sobre PPO:**
- No requiere critic network separada
- Más estable para skills heterogéneos
- Mejor positive transfer entre skills

### Unified Skills Buffer

```
Skills Buffer (FIFO, capacidad N)
┌──────────────────────────────────────────────────┐
│ Trajectory 1: [Localize → Edit → Test]          │
│ Trajectory 2: [Review]                           │
│ Trajectory 3: [Localize → Reproduce → Edit]      │
│ ...                                              │
└──────────────────────────────────────────────────┘
```

- **Trajectory:** Secuencia de (skill, prompt, response, reward)
- **Sampling:** Uniforme entre skills para evitar starvation
- **Capacity:** Balance entre skills recientes y diversos

### Sandboxed Execution

| Componente | Implementación |
|------------|---------------|
| **Runtime** | 10,000+ containers Kubernetes |
| **Tool access** | Bash + str_replace only |
| **Isolation** | cgroups + namespace |
| **Timeout** | 5 min por trajectory |
| **Rollback** | Snapshotting para reproducibilidad |

---

## 4. Experiments

### Setup

| Config | Valor |
|--------|-------|
| **Base model** | GLM-4.5-Air-Base (106B, 12B active) |
| **Context window** | 128K tokens |
| **Training steps** | 10,000 |
| **Batch size** | 256 |
| **Learning rate** | 1e-5 with cosine decay |
| **Skills buffer** | 50,000 trajectories |

### Benchmarks Evaluados

#### Atomic Skills (In-domain)

| Skill | Dataset | Métrica |
|-------|---------|---------|
| Code Localization | AtomicBench-L | Hit@K |
| Code Editing | AtomicBench-E | Pass@1 |
| Unit-Test Gen | AtomicBench-T | Fault Detection Rate |
| Issue Reprod | AtomicBench-R | Reproduction Rate |
| Code Review | AtomicBench-C | F1 Score |

#### Composite Tasks (OOD)

| Benchmark | Descripción | Tareas |
|-----------|-------------|--------|
| **SWE-bench Verified** | Bug fixing real GitHub | 500 |
| **SWE-bench Multilingual** | Bug fixing Python/Java/JS | 300 |
| **Terminal-Bench** | DevOps debugging | 200 |
| **Code Refactoring** | Refactoring tasks | 400 |
| **SEC-Bench** | Security vulnerabilities | 150 |

### Resultados: Atomic Skills

| Skill | Single-Task RL | Joint RL | Δ |
|-------|---------------|----------|---|
| Code Localization | 65.2% | 78.4% | +13.2% |
| Code Editing | 58.7% | 71.2% | +12.5% |
| Unit-Test Generation | 42.1% | 58.9% | +16.8% |
| Issue Reproduction | 55.3% | 68.7% | +13.4% |
| Code Review | 61.8% | 73.1% | +11.3% |
| **Average** | 56.6% | **70.1%** | **+18.7%** |

### Resultados: Composite Tasks (OOD)

| Benchmark | Single-Task RL | Joint RL | Δ |
|-----------|---------------|----------|---|
| SWE-bench Verified | 34.2% | 41.8% | +7.6% |
| SWE-bench Multilingual | 28.7% | 38.4% | +9.7% |
| Terminal-Bench | 22.1% | 31.5% | +9.4% |
| Code Refactoring | 45.6% | 52.3% | +6.7% |
| SEC-Bench | 18.9% | 27.2% | +8.3% |
| **Average** | 29.9% | **38.2%** | **+8.3%** |

### Ablation Study

| Variante | Avg Atomic | Avg Composite |
|----------|-----------|--------------|
| Single-skill RL (all) | 61.2% | 31.4% |
| Joint RL (no buffer) | 66.8% | 35.1% |
| Joint RL (sequential) | 68.4% | 36.7% |
| **Joint RL (full)** | **70.1%** | **38.2%** |

**Key finding:** Unified buffer + joint training son ambos necesarios para máximo performance.

### Generalization Analysis

Joint RL muestra **positive transfer** medido por:

```
Transfer Gain = Performance(ood) - Performance(indomain)
```

| Skill Pair | Transfer Gain |
|------------|---------------|
| Localization → Editing | +4.2% |
| Editing → Test Gen | +3.8% |
| Test Gen → Review | +2.9% |
| All pairs | +3.4% average |

---

## 5. Related Work

### LLM Coding Agents

| Trabajo | Enfoque | Limitación |
|---------|---------|------------|
| SWE-bench | Real bug fixes | Task-specific |
| AlphaCode | Competition coding | No tool use |
| CodeRL | RL on code tasks | Single skill |
| **This work** | Atomic skills + Joint RL | **Generalizable** |

### Reinforcement Learning for Code

- **CodeRL:** RL para code generation, pero single-task
- **PPO for Code:** Optimización de políticas, pero requiere critic
- **GRPO:** Base del approach, pero no aplicado a multi-skill

---

## 6. Conclusion

### Summary

1. **Atomic skills** proporcionan mejor foundation para training que composite tasks
2. **Joint RL** logra positive transfer entre skills heterogéneos
3. **+18.7%** mejora en atomic skills, **+8.3%** en tareas OOD
4. **AtomicBench** dataset released para investigación futura

### Future Work

- Extensión a más atomic skills (debugging, profiling)
- Aplicación a dominios beyond code (math, reasoning)
- Personalization de skills para equipos específicos

---

## Conceptos Clave

- Task-specific overfitting en LLMs
- Joint vs Single-task RL
- Positive transfer across heterogeneous skills
- GRPO (Group-based Relative Policy Optimization)
- Atomic vs Composite tasks
- Skills Buffer (FIFO trajectory storage)

## Conexiones

- [[llm-agents]] — concepto relacionado
- [[reinforcement-learning]] — técnica usada
- [[swe-bench]] — benchmark mencionado

## Referencias

- SWE-bench Verified
- SWE-bench Multilingual
- Terminal-Bench
- SEC-Bench
- AtomicBench (released)
- DeepSeek GRPO
- GLM-4.5-Air-Base
