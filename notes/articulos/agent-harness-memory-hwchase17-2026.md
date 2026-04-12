---
title: "Agent Harnesses & Memory - Harrison Chase"
source: https://x.com/hwchase17/status/2042978500567609738
date: 2026-04-11
author: @hwchase17
tags: [agentes, memory, harness, langchain, deep-agents]
Vínculos: [[memory-as-harness]], [[agent-architecture]], [[soberania-de-datos]]
---

# Agent Harnesses & Memory

## Thesis

Los **agent harnesses** son el patrón dominante para construir agentes AI y están íntimamente ligados a la **memoria**. Si usas un harness cerrado (especialmente tras una API propietaria), estás cediendo el control de la memoria a un tercero.

> *"Memory is incredibly important to creating good and sticky agentic experiences. This creates incredible lock in. Memory - and therefor harnesses - should be open, so that you own your own memory"*

---

## Evolución del Stack de Agentes

```
2022-2023: RAG chains simples (LangChain)
   ↓ modelos mejoran → LangGraph (flujos complejos, estado)
   ↓ modelos mucho mejores → Agent Harnesses (scaffolding nuevo tipo)
```

### Qué es un Agent Harness

Un agent harness es el sistema que rodea al LLM para facilitar la interacción con tools y otras fuentes de datos. Es todo el código de "pegamento" que hace falta alrededor del modelo.

**No va a desaparecer.** Aunque hay sentimiento de que "los modelos absorberán más scaffolding", lo que realmente pasa es que scaffolding de 2023 ya no es necesario — pero se reemplaza por otro tipo de scaffolding.

### Ejemplos de Agent Harnesses

- Claude Code
- Deep Agents (LangChain)
- Pi (potencia OpenClaw)
- OpenCode
- Codex
- Letta Code

**Evidencia de peso:** Cuando se filtró el código de Claude Code → **512k líneas** de código. Ese código ES el harness. Incluso los creadores del mejor modelo del mundo invierten fuertemente en harnesses.

### Nota sobre APIs de modelos

Cuando OpenAI o Anthropic ofrecen "web search integrado" en sus APIs, eso **no es parte del modelo**. Es un lightweight harness que orquesta el modelo con APIs de web search via tool calling.

---

## Memory is the Harness

Referencia central: [Sarah Wooders](https://x.com/sarahwooders) (CTO de Letta, ex-MemGPT)

> *"Asking to plug memory into an agent harness is like asking to plug driving into a car. Managing context, and therefore memory, is a core capability and responsibility of the agent harness."*

### Por qué memoria NO es un plugin

Hay quienes preguntan: *"cómo conecto mi memory system a mi agent?"* — Esta pregunta no tiene sentido. La memoria es parte del harness, no un add-on.

### Memory = Context

| Tipo | Qué es | Cómo lo maneja el harness |
|------|--------|--------------------------|
| **Short-term** | Mensajes en conversación, resultados grandes de tool calls | Lo maneja el harness directamente |
| **Long-term** | Memoria cross-session | El harness la actualiza y lee |

### El harness gestiona (清单 completo)

1. **Cómo se carga `AGENTS.md` / `CLAUDE.md`** al contexto
2. **Cómo se muestra metadata de skills** al agente (en system prompt? en system messages?)
3. **Si el agente puede modificar sus propias instrucciones** del sistema
4. **Qué sobrevive a la compactación** — y qué se pierde en el proceso
5. **Si las interacciones se almacenan y son queryables**
6. **Cómo se presenta metadata de memoria** al agente
7. **Cómo se representa el directorio de trabajo actual** — cuánta info del filesystem está expuesta

### Estado actual de memory

> *"Memory as a concept is in it's infancy."*

Aún no hay abstracciones comunes o well-known para memoria. long-term memory frecuentemente **no es parte del MVP** — primero hacés funcionar el agente, después la personalización. Esto significa que la industria todavía está figuring out memory.

Eventualmente, si memory se estandariza con best practices, memory systems separados podrían tener sentido. **Pero no ahora.**

---

## Si no controlás tu harness, no controlás tu memoria

Hay tres niveles de lock-in:

### Nivel 1: APIs Stateful (Mildly Bad)

Proveedores almacenan estado en sus servidores:

- OpenAI Responses API
- Anthropic's server-side compaction

**Problema:** Si querés hacer swap de modelo y continuar threads previos → no podés.

### Nivel 2: Harnesses Cerrados (Bad)

Ejemplo: **Claude Agent SDK** — usa Claude Code bajo el hood, que no es open source.

El harness interactúa con memoria de forma unknown. Puede crear artifacts client-side, pero:

- ¿Cuál es la forma de esos artifacts?
- ¿Cómo debería un harness usar esos?
- Eso es desconocido → **non-transferible** de un harness a otro

### Nivel 3: Todo tras API (Worst)

Cuando el harness completo + memoria larga está detrás de una API:

- **Cero ownership** sobre memoria
- **Cero visibilidad** sobre cómo funciona
- No sabés el harness → no sabés usar la memoria
- Peor aún: **ni siquiera荷你的 memoria**
- Algunas partes pueden estar expuestas via API, otras no — **sin control**

> *"When people say that 'models will absorb more and more of the harness' - this is what they really mean. They mean that these memory related parts will go behind the APIs that model providers offer."*

---

## Memory es importante y crea lock-in

### Sin memoria

Agentes fácilmente replicables por cualquiera con acceso a las mismas tools.

### Con memoria

Dataset propietario de interacciones y preferencias → experiencia diferenciada y cada vez más inteligente.

### El problema de switchear modelos

Hasta ahora fue fácil cambiar de modelo proveedor:

- APIs similares o idénticas
- Solo cambiás prompts un poco
- **Pero todo eso porque son stateless**

Cuando hay estado involucrado (memoria), es mucho más difícil cambiar. Si switchteás, perdés acceso a la memoria.

### La historia de Chase

Tiene un email assistant interno en **Fleet** (no-code platform de LangChain para OpenClaws). El platform tiene memoria built-in.

Hace unas semanas, su agent fue borrado por accidente. Trató de crear un agent del mismo template — la experiencia fue **mucho peor**. Tuvo que re-enseñar todas sus preferencias, su tono, todo.

**El lado positivo:** Le hizo realized cuán poderosa y sticky puede ser la memoria.

---

## La amenaza: Model Providers

Los proveedores de modelos tienen **incentivos enormes** para crear lock-in vía memoria. Y ya están empezando:

### Claude Managed Agents (Anthropic)

Ponen literalmente todo detrás de una API, locked into su platform.

### Codex (OpenAI)

Aunque es open source, genera **encrypted compaction summaries** que no son usables fuera del ecosistema OpenAI.

> *"Why are they doing this? Because memory is important, and it creates lock in that they don't get from just the model."*

---

## Solución: Deep Agents

[Deep Agents](https://docs.langchain.com/oss/python/deepagents/overview) es la respuesta de LangChain al problema:

| Feature | Descripción |
|---------|-------------|
| Open source | Código abierto, auditable |
| Model agnostic | No te ata a un provider |
| Open standards | Usa `agents.md` y `skills` |
| Storage plugins | Mongo, Postgres, Redis para memoria |
| Deployment | LangSmith Deployment (self-hostable, cualquier cloud) o cualquier web hosting framework |

### Por qué importan los open standards

- `agents.md` — estándar para definición de agentes
- `skills` — estándar para skills de agentes

Esto permite portabilidad real entre harnesses.

---

## Agenda de deep agents en LangChain

```
Sydney Runkle → Deep Agents + memory work
Viv Trivedy → Leading voice en agent harnesses
Nuno Campos → Context engineering para finance agents
Sarah Wooders → CTO Letta, stateful agents
```

---

## takeaway

1. **Harness = architecture pattern dominante** — no va a desaparecer
2. **Memory is the harness** — no es un plugin separado
3. **Lock-in via memoria es la verdadera amenaza** — más que lock-in por API de modelo
4. **Proveedores tienen incentivos** para cerrar memoria
5. **Open harnesses + open standards = única defensa**

La memoria (datos de usuario, interacciones, preferencias) es lo que realmente importa. Es más difícil de replicar que el modelo porque representa tu **data flywheel propietario**.

---

## Referencias

- [The Anatomy of an Agent Harness (LangChain Blog)](https://blog.langchain.com/the-anatomy-of-an-agent-harness/)
- [Deep Agents](https://github.com/langchain-ai/deepagents)
- [Sarah Wooders - Why memory isn't a plugin](https://x.com/sarahwooders/status/2040121230473457921)
- [Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview)

---

Relacionado: [[memory-as-harness]], [[agent-architecture]], [[soberania-de-datos]]
