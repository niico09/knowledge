---
title: "Your harness, your memory"
date: 2026-04-12
type: article
status: synthesized
source: [[../../../sources/articulos/2026-04-12-harrison-chase-agent-harness-memory]]
tags: [agent-harness, memory, langchain, llm-agents, open-source]
---

## Resumen

Harrison Chase (creador de LangChain/LangGraph) argumenta que los agent harnesses son la forma dominante de construir agentes y que la memoria está íntimamente ligada al harness. Si usás un harness cerrado (especialmente detrás de una API proprietaria), estás cediendo control de la memoria del agente a un tercero. Memory es lo que crea lock-in y diferenciación. Aboga por harnesses abiertos y ownership de la memoria.

## Conceptos Clave

### Agent Harnesses son la forma dominante de construir agentes

- 2022-2023: Simple RAG chains (LangChain)
- Luego: Flows más complejos (LangGraph)
- Ahora: Agent harnesses (Claude Code, Deep Agents, Pi/OpenClaw, OpenCode, Codex, Letta Code)
- Los modelos no absorben el scaffolding — lo reemplazan por otro tipo. Evidence: Claude Code leak = 512k líneas de código.

### Memory es responsabilidad del harness

Sarah Wooders (CTO de Letta): "preguntar cómo pluggear memory a un agent harness es como preguntar cómo pluggear driving a un car."

El harness maneja: cómo se carga AGENTS.md/CLAUDE.md, skill metadata, system instructions modificables, compaction, interacciones queryables.

### Lock-in via memory en 3 niveles

1. **Mildly bad**: Stateful APIs (OpenAI Responses, Anthropic server-side compaction) — state en servidores de terceros
2. **Bad**: Closed harnesses (Claude Agent SDK) — harness interactúa con memory de forma desconocida
3. **Worst**: Todo (incluyendo long-term memory) detrás de una API — zero ownership

### Open Harnesses > Closed Harnesses

Sin memory, los agentes son replicables. Con memory, construís un dataset propietario de interacciones y preferencias. Modelo providers tienen incentivo fuerte para hacer lock-in via memory.

Deep Agents (LangChain): open source, model agnostic, usa agents.md y skills, plugins para Mongo/Postgres/Redis, deployable en cualquier cloud.

## Conexiones

- [[../../../sources/articulos/2026-04-07-llm-wiki-karpathy]] — LLM Wiki pattern (memoria como wiki)
- [[../sistema/2026-04-12-claude-code--obsidian-ultimate-guide]] — Setup práctico de AI second brain con Obsidian + Claude Code
- [[../conceptos/agent-harness-engineering]] — Framework de harness engineering
- [[../conceptos/devin-harness-integration]] — Devin como black box harness
- [[../herramientas/langchain-agents]] — LangChain agents framework

## Notas Personales

El argumento de "tu harness, tu memoria" es directamente aplicable a cómo estructuramos el KB: así como Chase aboga por harnesses abiertos para no ceder memory a terceros, nuestro second brain en Obsidian/Claude Code nos da ownership completo del conocimiento. La tensión closed vs open atraviesa tanto agents como knowledge bases. El enfoque de Deep Agents (estándares abiertos, model agnostic, deployable) es el mismo espíritu que el patrón LLM Wiki de Karpathy: ownership del material que alimenta el sistema.

## Fuentes

- [[../../../sources/articulos/2026-04-12-harrison-chase-agent-harness-memory]]
- Tweet original: https://x.com/hwchase17/status/2042978500567609738
- Autor: @hwchase17 — Harrison Chase (LangChain/LangGraph), 1.2M views, Apr 11 2026
