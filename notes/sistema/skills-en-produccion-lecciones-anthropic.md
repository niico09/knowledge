---
title: Skills en Producción — Lecciones de Anthropic
created: 2026-03-26
updated: 2026-03-26
tags: [Skills, ClaudeCode, Anthropic, BestPractices]
sources:
  - "Thariq (@trq212) — Anthropic, 17 mar 2026"
status: synthesized
last_lint: 2026-04-07
---

# Skills en Producción — Lecciones de Anthropic

> Fuente: [Post de Thariq (@trq212) — Anthropic, 17 mar 2026](https://x.com/trq212/status/2033949937936085378) · 6.6M visualizaciones

# Taxonomía de 9 tipos de Skills

## 1. Library & API Reference
Explican cómo usar correctamente una librería, CLI o SDK interno. Suelen incluir snippets de código de referencia y una lista de gotchas.
**Ejemplos:** `billing-lib`, `internal-platform-cli`, `frontend-design`

## 2. Product Verification
Descriiben cómo testear o verificar que el código funciona. Se combinan con herramientas externas (Playwright, tmux).
**Técnicas avanzadas:** Grabar video del output del agente, assertions programáticos en cada paso.
**Ejemplos:** `signup-flow-driver`, `checkout-verifier`, `tmux-cli-driver`

## 3. Data Fetching & Analysis
Conectan al stack de datos y monitoreo. Incluyen credenciales, dashboard IDs, y workflows comunes.
**Ejemplos:** `funnel-query`, `cohort-compare`, `grafana`

## 4. Business Process & Team Automation
Automatizan workflows repetitivos en un solo comando.
**Ejemplos:** `standup-post`, `create-<ticket-system>-ticket`, `weekly-recap`

## 5. Code Scaffolding & Templates
Generan boilerplate de framework para funciones específicas del codebase.
**Ejemplos:** `new-<framework>-workflow`, `new-migration`, `create-app`

## 6. Code Quality & Review
Enforcan calidad de código y ayudan a revisar PRs. Pueden incluir scripts deterministas.
**Ejemplos:** `adversarial-review`, `code-style`, `testing-practices`

## 7. CI/CD & Deployment
Ayudan a fetchear, pushear y deployar código.
**Ejemplos:** `babysit-pr`, `deploy-<service>`, `cherry-pick-prod`

## 8. Runbooks
Toman un síntoma (Slack thread, alerta, error), hacen una investigación multi-tool, y producen un reporte estructurado.
**Ejemplos:** `<service>-debugging`, `oncall-runner`, `log-correlator`

## 9. Infrastructure Operations
Realizan mantenimiento rutinario y procedimientos operacionales.
**Ejemplos:** `<resource>-orphans`, `dependency-management`, `cost-investigation`

# Tips de Anthropic para escribir Skills

## No declarar lo obvio
Enfocarse en información que saca a Claude de su modo de pensar por defecto.

## Construir una sección de Gotchas
El contenido de mayor señal. Debe construirse a partir de fallos comunes reales.

## Usar el File System para Progressive Disclosure
Un skill es una carpeta, no solo un archivo.
- `references/api.md` — firmas y ejemplos
- `assets/` — templates
- Carpetas de referencias y scripts

## El campo `description` es para el modelo
El listing que Claude escanea al iniciar sesión. No es un resumen — es una descripción de cuándo triggerear.

## Memoria y Almacenamiento de Datos
- Append-only log file (`.log`) o JSON
- O una base de datos SQLite
- Usar `${CLAUDE_PLUGIN_DATA}` para persistir entre upgrades

## On-Demand Hooks
- `/careful` — bloquea acciones peligrosas via `PreToolUse`
- `/freeze` — bloquea Edit/Write fuera de un directorio específico

# Distribuir Skills

1. **Commitear al repo** (`.claude/skills`) — equipos pequeños
2. **Crear un plugin y subirlo a un marketplace interno** — escala mejor

## Gestionar un Marketplace Interno
- No hay equipo centralizado
- Subís a una carpeta sandbox y compartís por Slack
- Cuando tiene tracción → PR para moverlo al marketplace

# Componer Skills

Skills pueden depender de otros. La dependencia no está construida nativamente — se pueden **referenciar otros skills por nombre**.

# Relacionado

- [[skill-anatomia]] — Anatomía de un SKILL.md bien diseñado
- [[asset-generator-v3]] — Asset Generator que las genera
- [[skills-generadas-registry]] — Registry de skills generadas
