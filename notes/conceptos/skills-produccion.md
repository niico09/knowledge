---
title: Skills en Producción — Lecciones de Anthropic
created: 2026-04-04
updated: 2026-04-04
tags: [Skills, Anthropic, Produccion, AIAgents]
sources:
  - "Post de Thariq (@trq212) — Anthropic, 17 mar 2026"
---

# Skills en Producción — Lecciones de Anthropic

## Taxonomía de 9 tipos de Skills

1. **Library & API Reference** — Cómo usar librerías, CLI o SDK interno
2. **Product Verification** — Cómo testear o verificar código (Playwright, tmux)
3. **Data Fetching & Analysis** — Conectan al stack de datos y monitoreo
4. **Business Process & Team Automation** — Automatizan workflows repetitivos
5. **Code Scaffolding & Templates** — Generan boilerplate de framework
6. **Code Quality & Review** — Enforcan calidad y ayudan a revisar PRs
7. **CI/CD & Deployment** — Ayudan a fetchear, pushear y deployar
8. **Runbooks** — Investigan síntomas y producen reportes estructurados
9. **Infrastructure Operations** — Mantenimiento rutinario y procedimientos

## Tips para escribir Skills

- **No declarar lo obvio** — Enfocarse en info que saca a Claude de su modo por defecto
- **Construir sección de Gotchas** — Construida a partir de fallos comunes reales
- **Usar el File System para Progressive Disclosure** — Dividir en `references/`, `scripts/`, `assets/`
- **El campo `description` es para el modelo** — Describe cuándo triggerear, no solo qué hace
- **Memoria y almacenamiento** — Append-only log files, `${CLAUDE_PLUGIN_DATA}` para persistir

## Relacionado

- [[skill-anatomia]] — Anatomía de un SKILL.md bien diseñado
- [[skills-auto-mejora]] — Skills que se auto-mejoran
- [[claude-code-configuracion]] — Context del sistema de skills
