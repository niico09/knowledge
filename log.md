## 2026-04-07 03:32 — LINT: 15 issues detectados
# Knowledge Wiki — Operation Log

Registro append-only de todas las operaciones sobre el wiki.
Formato: `## YYYY-MM-DD HH:MM — OPERACION: descripcion`

## Operaciones

## 2026-04-07 09:00 — BOOTSTRAP: Implementación del patrón LLM Wiki
- Creado CLAUDE.md.local con schema y workflows
- Creado index.md con catálogo inicial
- Creado scripts/ (ingest.sh, query.sh, lint.sh)
- Migrada estructura existente a status: synthesized
- Fuente bootstrap: [[sources/articulos/2026-04-07-llm-wiki-karpathy]]

<!-- Nuevas operaciones se agregan arriba -->

---

## Formato de entradas

- **INGEST:** Nueva fuente integrada. Formato: `INGEST: <type> <title> → notes/<destino>`
- **QUERY:** Consulta respondida. Formato: `QUERY: <topic> → [[pages consulted]]`
- **LINT:** Verificación de salud. Formato: `LINT: <resultado>`
- **SYNTHESIS:** Síntesis de múltiples fuentes. Formato: `SYNTHESIS: <sources> → [[output page]]`
- **CONTRADICTION:** Contradicción detectada. Formato: `CONTRADICTION: [[page-a]] vs [[page-b]] — <resolution>`
