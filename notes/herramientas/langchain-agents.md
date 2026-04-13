---
tags:
  - langchain
  - agents
  - framework
  - devin
created: 2026-04-09
---

# LangChain Agents

## Qué es

Framework de código abierto para construir aplicaciones y agentes impulsados por LLMs. Se construye sobre **LangGraph**.

## Características

- Ejecución duradera
- Streaming
- Soporte human-in-the-loop
- Persistencia
- Menos de 10 líneas para crear un agente funcional

## Tipos de Agentes

| Tipo | Uso |
|------|-----|
| **LangChain Agents** | Uso general, fáciles de customizar |
| **Deep Agents** | Avanzados: compresión de conversaciones largas, filesystem virtual, subagentes |

## Herramientas

- Integraciones con múltiples providers (OpenAI, Anthropic, Google, etc.)
- Framework para crear tools custom
- **LangSmith** para tracing y debugging

## Stack

```
┌─────────────────────────────────┐
│  Your Code / Application        │
├─────────────────────────────────┤
│  LangChain Agents               │
│  (ReAct, OpenAI Tools, etc.)   │
├─────────────────────────────────┤
│  LangGraph                      │
│  (ejecución, persistencia)     │
├─────────────────────────────────┤
│  Model Providers               │
│  (OpenAI, Anthropic, etc.)     │
└─────────────────────────────────┘
```

## Integración con Devin

LangChain Agents pueden ser la **capa de control** sobre Devin si se usa como tool. Pero Devin es SaaS black-box — el control es limitado.

## Links

- Docs: https://docs.langchain.com/
- Repo: https://github.com/langchain-ai/langchain
