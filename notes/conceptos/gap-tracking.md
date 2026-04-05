---
title: Gap tracking
created: 2026-04-04
updated: 2026-04-04
tags: [GapTracking, Workflow, AssetGenerator]
sources:
  - "Glosario SDD"
---

# Gap tracking

Mecanismo del Asset Generator v3 que registra brechas detectadas durante el uso de un asset (SKILL.md, rule, subagent) en una base de datos Notion dedicada.

## Campos

- Elemento: qué falta
- Tecnología: ej: Chakra UI v3
- Notebook de origen
- Apariciones: contador
- Estado: Sin resolver
- Asset donde apareció
- Fecha primer registro

## Señal

Si Apariciones ≥ 3 → hueco estructural en las fuentes.

## Relacionado

- [[asset-generator-v3]] — Sistema que lo usa
- [[sdd]] — SDD como metodología
