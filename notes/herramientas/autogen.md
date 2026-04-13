---
tags:
  - autogen
  - agents
  - framework
  - microsoft
created: 2026-04-09
---

# AutoGen

## Qué es

Framework de Microsoft para crear aplicaciones de **IA multi-agente** que pueden actuar de forma autónoma o junto con humanos.

## ⚠️ Estado: Modo Mantenimiento

AutoGen **entrò en modo mantenimiento**. Microsoft recomienda:

> **Microsoft Agent Framework** para nuevos proyectos.

(Validar cuál es el reemplazo actual — puede haber cambiado.)

## Arquitectura

```
┌─────────────────────────────────┐
│  Extensions API                 │
│  (LLM clients, code execution) │
├─────────────────────────────────┤
│  AgentChat API                 │
│  (prototipado rápido)          │
├─────────────────────────────────┤
│  Core API                      │
│  (mensajes, eventos, runtime)  │
└─────────────────────────────────┘
```

## Tipos de Agentes

- **AssistantAgent** — Agente asistente general
- **Agentes expertos** — math_expert, chemistry_expert
- **Web browsing assistant** — Usa servidores MCP

## Características

- Soporte Python 3.10+ y .NET
- Integración con OpenAI y Azure OpenAI
- **MCP (Model Context Protocol)** servers
- **AutoGen Studio** — GUI sin código para prototipado
- AutoGen Bench para benchmarks

## Casos de Uso

- Orquestación multi-agente
- Navegación web automatizada
- Asistencia con herramientas MCP
- Prototipado rápido sin código

## Comparación con LangChain

| Aspecto | AutoGen | LangChain |
|---------|---------|-----------|
| Multi-agente | Nativo | Requiere LangGraph |
| Ease of use | AgentChat API simple | Más flexible pero más verbose |
| Estado | **Mantenimiento** | Activo |
| Microsoft | Estándar | Propio |
| Tool support | MCP | Propio + LangChain tools |

## Alternativa Recomendada

**Microsoft Agent Framework** — el reemplazo oficial para nuevos proyectos.

(Verificar docs actualizadas, el ecosystem Microsoft cambia rápido.)

## Links

- Repo: https://github.com/microsoft/autogen
- Docs: https://microsoft.github.io/autogen/
