---
title: "Your harness, your memory"
url: "https://x.com/hwchase17/status/2042978500567609738
date: 2026-04-12
type: article
status: synthesized
source: "@hwchase17 — Harrison Chase (LangChain/LangGraph), 1.2M views, Apr 11 2026"
tags: [agent-harness, memory, langchain, llm-agents, open-source]
---

## Resumen

Harrison Chase (Creador de LangChain/LangGraph) argumenta que los agent harnesses son la forma dominante de construir agentes y que memory está íntimamente ligada al harness. Si usás un harness cerrado (especialmente detrás de una API proprietaria), estás cediendo control de la memoria del agente a un tercero. Memory es lo que crea lock-in y diferenciación. Aboga por harnesses abiertos y ownership de la memoria.

## Contenido

### Agent Harnesses son cómo se construyen agentes

- 2022-2023: Simple RAG chains (LangChain)
- Luego: Flows más complejos (LangGraph)
- Ahora: Agent harnesses (Claude Code, Deep Agents, Pi/OpenClaw, OpenCode, Codex, Letta Code)

Los modelos no absorben el scaffolding — lo reemplazan por otro tipo. El evidence: cuando se leakó el source de Claude Code había 512k líneas de código.

### Harnesses están atados a memory

Memory no es un plugin — es el harness. Sarah Wooders (CTO de Letta) lo dijo: "preguntar cómo pluggear memory a un agent harness es como preguntar cómo pluggear driving a un car."

El harness maneja:
- Cómo se carga AGENTS.md/CLAUDE.md en contexto
- Cómo se muestra skill metadata al agente
- Si el agente puede modificar sus propias system instructions
- Qué sobrevive a compaction
- Si las interacciones se almacenan y se hacen queryables
- Cómo se representa el filesystem

### Si no ownés tu harness, no ownés tu memory

Tres niveles de lock-in:
1. **Mildly bad**: Stateful APIs (OpenAI Responses, Anthropic server-side compaction) — state en servidores de terceros
2. **Bad**: Closed harnesses (Claude Agent SDK) — harness interactúa con memory de forma desconocida
3. **Worst**: Todo (incluyendo long-term memory) detrás de una API — zero ownership

Los model providers tienen incentivo fuerte para hacer esto. Anthropic lanzó Claude Managed Agents. OpenAI tiene encrypted compaction summaries no usable fuera de su ecosistema.

### Memory es importante y crea lock-in

Sin memory, los agentes son fácilmente replicables. Con memory, construís un dataset propietario de interacciones y preferencias. Esto hace que sea mucho más difícil switching de model provider.

### Open Memory, Open Harnesses

Deep Agents (LangChain):
- Open source
- Model agnostic
- Usa estándares abiertos: agents.md y skills
- Plugins para Mongo, Postgres, Redis
- Deployable en cualquier cloud o hosting

## Conceptos extraídos

- [x] Agent harnesses como dominant pattern
- [x] Memory como responsabilidad del harness
- [x] Lock-in via memory
- [x] Open harnesses > closed harnesses
- [x] Deep Agents como ejemplo open

## Relacionado

- [[../notes/conceptos/agent-harness-engineering]] — Framework de harness engineering
- [[../notes/conceptos/devin-harness-integration]] — Devin como black box
- [[../notes/herramientas/langchain-agents]] — LangChain agents framework
- [[../notes/sistema/skills-en-produccion-lecciones-anthropic]] — Lecciones de Anthropic sobre skills
