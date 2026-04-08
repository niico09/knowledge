---
title: Integraciones — NotebookLM MCP, Claude Desktop, Google Classroom
created: 2026-03-21
updated: 2026-03-21
tags: [NotebookLM, MCP, ClaudeDesktop, GoogleClassroom, Integraciones]
sources:
  - "Post de @ihtesham2005 en X — 20 marzo 2026"
status: synthesized
last_lint: 2026-04-07
---

# Integraciones

Cómo NotebookLM se conecta con el resto del stack de trabajo.

## MCP + notebooklm-mcp-cli

### Configuración en `claude_desktop_config.json`

```json
{
  "mcpServers": {
    "notebooklm": {
      "command": "uvx",
      "args": ["--from", "notebooklm-mcp-cli", "notebooklm-mcp"]
    }
  }
}
```

> **Nota:** Usar `uvx --from notebooklm-mcp-cli notebooklm-mcp` (no `notebooklm-mcp-cli` directamente).

### Herramientas disponibles via MCP

- `notebook_list` — listar todos los notebooks
- `notebook_query` — consultar un notebook existente
- `source_add` — agregar fuentes
- `studio_create` — generar Audio Overview y otros artefactos
- `research_start` — iniciar Deep Research

## Pipeline Antigravity + NotebookLM

### Patrón de queries óptimo (triangulación)

Para cada dominio del SKILL.md, hacer **3 queries secuenciales**:

1. Query con identificador de versión (ej: "Chakra UI v3")
2. Query con la librería subyacente (ej: "Ark UI headless")
3. Query con la API específica (ej: "useColorMode hook")

### Flujo completo

```
NotebookLM (chakra-ui notebook)
    ↓ MCP queries (triangulación)
Claude Code
    ↓ Genera SKILL.md
Antigravity
    ↓ Empaqueta skill
Claude (producción)
```

## Google Classroom (2026)

- Crear notebook directamente desde Google Classroom
- Asignar notebooks como "View Only" a estudiantes
- Feature disponible en 2026

## Claude Code + CLAUDE.md

Agregar en `CLAUDE.md`:

```markdown
## NotebookLM Queries
Al consultar notebooks via MCP, usar patrón de triangulación:
1. Query por versión
2. Query por librería subyacente
3. Query por API específica
```

## Relacionado

- [[notebooklm-workflow]] — Sistema de estudio completo
- [[asset-generator-v3]] — Asset Generator que usa este pipeline
