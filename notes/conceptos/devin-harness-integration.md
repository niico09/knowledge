---
tags:
  - devin
  - agent-architecture
  - llm-ops
created: 2026-04-09
---

# Devin + Harness Engineering Integration

## El Problema

Devin es un black-box SaaS. No tenés acceso directo a su "harness" interno.

**Lo que podés controlar:**
- Contexto que le pasás
- Prompts/instrucciones externas
- Filtrado y curiación de outputs

**Lo que NO podés controlar:**
- El model internals de Devin
- Su prompt system
- Sus tool definitions

## Arquitectura Posible

```
┌─────────────────────────────────────┐
│         External Harness Layer       │
│  (el que vos controlás)             │
│                                     │
│  • Context Engineering              │
│  • Eval-triggered prompts           │
│  • Output validation                │
│  • Retry logic                      │
└─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│            Devin (black box)         │
└─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│         Trace Collection             │
│  ( outputs, decisiones, errores )    │
└─────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────┐
│         Eval Loop                   │
│  • Identificar patterns de error    │
│  • Crear evals específicos         │
│  • Mejorar context/prompts          │
└─────────────────────────────────────┘
```

## Qué Podés Hacer Prácticamente

### 1. Context Engineering para Devin

Crear "harnesses externos" que mejoren las inputs de Devin:

```markdown
# Tu codebase context
- Arquitectura: Monolito Python + FastAPI
- Stack: PostgreSQL, Redis, Celery
- Patrones: Transaction wrapping en DB
- Code style: Black formatter, type hints obligatorios

# Instrucciones específicas para este codebase
- Antes de modify un archivo, revisar imports existentes
- No hardcodear credenciales
- Tests en ./tests/
```

### 2. Trace Collection

Capturar outputs de Devin sistemáticamente:
- Guardar los prompts que mandás
- Guardar las respuestas
- Clasificar errores recurrentes

### 3. Evals Específicos del Codebase

Crear evals que midan:
- ¿Devin sigue los coding standards del proyecto?
- ¿Hace tests correctos?
- ¿Maneja edge cases del dominio?

### 4. Loop de Mejora

```
Devin produce output
    ↓
Identificás error/pattern
    ↓
Creás/modificás eval
    ↓
Ajustás context template
    ↓
La próxima vez Devin recibe mejor contexto
```

## Herramientas Recomendadas

| Herramienta | Uso | Relación con Devin |
|-------------|-----|-------------------|
| [LangSmith](https://smith.langchain.com/) | Tracing de traces | Compatible si usás LangChain, pero podés usarla para logging genérico |
| [Braintrust](https://www.braintrust.dev/) | Evals + Traces | Alternativa más open, buena para eval-first |
| [Helicone](https://www.helicone.ai/) | Logging de LLMs | Si Devin expone logs de API, lo conectás ahí |
| [PromptLayer](https://promptlayer.com/) | Prompt versioning | versionar los templates de contexto |

## Alternativas a Devin (para considerar)

Si en el futuro quieren un agent más controlable:

- **Cody** (Sourcegraph) — código-aware, self-hosted option
- **GitHub Copilot** — más controlable, menos autonomous
- **AutoGPT / AgentGPT** — open, control total del harness
- **LangChain agents** — máximo control, requires más setup

## Trade-off

| Enfoque | Control | Effort |
|---------|---------|--------|
| Devin + External Harness | Medio | Bajo |
| Agent controlable (LangChain) | Alto | Alto |
| Hybrid (Devin + evals) | Medio-alto | Medio |

## Ver También

- [[agent-harness-engineering]]
- <!-- ai-team-setup: pendiente de definir -->

## Links

- Repo Better Harness: https://github.com/langchain-ai/deepagents/tree/main/examples/better-harness
