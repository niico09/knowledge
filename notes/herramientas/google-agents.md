---
tags:
  - google
  - agents
  - framework
  - adk
  - a2a
created: 2026-04-09
---

# Google Agents

## Agent Development Kit (ADK)

**Qué es:** Toolkit open-source en Python para construir, evaluar y desplegar agentes de IA sofisticados.

**Repo:** https://github.com/google/adk-python
**Docs:** https://github.com/google/adk-docs

```python
# Código mínimo de un agent con ADK
# (del repo oficial)
```

## Productos en Google Cloud

| Producto | Descripción |
|----------|-------------|
| **Vertex AI Agent Builder** | Crear agents en Google Cloud |
| **Vertex AI Search** | Búsqueda empresarial con IA |
| **Dialogflow** | Agentes conversacionales |
| **Gemini en Vertex AI** | Modelos para agents |

## A2A Protocol (Agent to Agent)

**Qué es:** Protocolo abierto para comunicación entre agents de diferentes frameworks. Liderado por Google + Linux Foundation.

**Repos:** https://github.com/a2aproject/A2A
**Specs:** https://a2a-protocol.org
**Stars:** 23.1k

### Características

- **Comunicación:** JSON-RPC 2.0 sobre HTTP(S)
- **Descubrimiento:** Agent Cards (cada agent declara capacidades)
- **Interacciones:** síncrona, streaming (SSE), notificaciones push
- **Seguridad:** autenticación + observabilidad enterprise

### Agents que lo soportan

El documento A2A menciona:
- Google ADK
- CrewAI
- LangChain
- AutoGen
- Microsoft Agent Framework
- IBM Research

## Stack Google Agents

```
┌─────────────────────────────────────┐
│  Tu Código / App                    │
├─────────────────────────────────────┤
│  Google ADK                        │
│  (build, evaluate, deploy agents)  │
├─────────────────────────────────────┤
│  A2A Protocol                      │
│  (interoperabilidad entre agents)  │
├─────────────────────────────────────┤
│  Vertex AI                         │
│  (Gemini models, hosting)          │
├─────────────────────────────────────┤
│  Google Cloud                      │
│  (deploy, scale, monitor)          │
└─────────────────────────────────────┘
```

## ADK: Detalle Técnico

### Instalación
```bash
# Stable
pip install google-adk

# Dev (bi-weekly releases)
pip install git+https://github.com/google/adk-python.git@main
```

### Agente Simple
```python
from google.adk.agents import Agent
from google.adk.tools import google_search

root_agent = Agent(
    name="search_assistant",
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant...",
    tools=[google_search]
)
```

### Sistema Multi-Agent
```python
greeter = LlmAgent(name="greeter", model="gemini-2.5-flash", ...)
task_executor = LlmAgent(name="task_executor", model="gemini-2.5-flash", ...)
coordinator = LlmAgent(
    name="Coordinator",
    sub_agents=[greeter, task_executor]
)
```

### Componentes
- **Rich Tool Ecosystem** — tools preconstruidas, MCP tools, OpenAPI specs
- **Tool Confirmation** — human-in-the-loop antes de ejecutar tools
- **CodeExecutor** — ejecución de código generado via Vertex AI sandbox
- **Agent Config** — construcción sin código
- **Development UI** — interfaz para test/debug

### Evaluación
```bash
adk eval <agent_dir> <eval_set.json>
```

### Deployment
- **Cloud Run** — contenedor estándar
- **Vertex AI Agent Engine** — escalamiento automático

## Comparación

| Aspecto | Google ADK | LangChain | AutoGen |
|---------|-----------|-----------|---------|
| **Lenguaje** | Python | Multi | Python |
| **Estado** | Activo (bi-weekly) | Activo | Mantenimiento |
| **Interoperabilidad** | A2A nativo | A2A support | A2A support |
| **Vendor lock-in** | Google Cloud | None | Microsoft |
| **Setup complexity** | Media | Media-alta | Baja |
| **Multi-agent** | Sub-agents jerárquicos | LangGraph | Nativo |
| **Eval built-in** | Sí (CLI) | No (LangSmith) | No |

## Links

- ADK Repo: https://github.com/google/adk-python
- ADK Docs: https://github.com/google/adk-docs
- A2A Protocol: https://a2a-protocol.org
