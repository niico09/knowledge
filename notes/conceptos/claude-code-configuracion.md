---
title: Anatomía de la carpeta .claude/
created: 2026-04-04
updated: 2026-04-04
tags: [ClaudeCode, Configuracion, Rules, Skills, Agents, Hooks]
sources:
  - "Inspirado en @akshay_pachaar, mejorado y expandido"
status: synthesized
last_lint: 2026-04-07
---

# Anatomía de la carpeta .claude/

Guía completa sobre CLAUDE.md, custom commands, skills, agents, permissions, y cómo configurarlos correctamente.

## Two folders, not one

**Existen dos carpetas .claude/**:

- **`.claude/` a nivel de proyecto** → configuración del equipo. Se committea a git.
- **`~/.claude/` a nivel global** → preferencias personales y estado local de la máquina.

## CLAUDE.md: El manual de instrucciones de Claude

Cuando inicias una sesión de Claude Code, lo primero que lee es CLAUDE.md. Se carga directamente en el system prompt y permanece durante toda la conversación.

### Donde colocar CLAUDE.md

- Proyecto root → reglas para el proyecto completo
- `~/.claude/CLAUDE.md` → preferencias globales
- Subdirectorios → reglas específicas por carpeta

Claude lee todos y los combina.

### Qué SÍ pertenece en CLAUDE.md

- **Contexto de negocio** — qué hace el proyecto, a quién sirve, dominio (2-5 líneas máximo)
- Comandos de build, test y lint
- Decisiones arquitectónicas clave
- Gotchas no obvias
- Convenciones de imports, patrones de naming, estilos de error handling
- Estructura de archivos y carpetas

### Qué NO pertenece en CLAUDE.md

- Cualquier cosa que ya pertenezca a un linter o formatter config
- Documentación completa que puedas linkear
- Párrafos largos explicando teoría

### Recomendación práctica

**Mantén CLAUDE.md bajo 200 líneas.** Archivos más largos empiezan a comer contexto y la adherencia baja.

## La carpeta rules/: instrucciones modulares

Cada archivo markdown dentro de `.claude/rules/` se carga automáticamente junto con tu CLAUDE.md.

### Path-scoped rules

Agregá un bloque YAML frontmatter para que el archivo solo se active en paths específicos:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/handlers/**/*.ts"
---
# API Design Rules
```

## El sistema de hooks: control determinista

Hooks son event handlers que se disparan automáticamente en puntos específicos del workflow.

### Eventos principales

| Evento | Cuándo dispara |
|--------|--------------|
| `PreToolUse` | Antes de que cualquier tool corra (security gate) |
| `PostToolUse` | Después de que un tool corre (formatters, linters) |
| `Stop` | Cuando Claude termina (quality gates) |
| `UserPromptSubmit` | Cuando presionás enter (prompt validation) |

### Códigos de salida

- **Exit 0** → Success, continuar
- **Exit 1** → Error pero no bloqueante
- **Exit 2** → **Bloquear todo** y enviar stderr a Claude

## La carpeta skills/: workflows reutilizables

Skills son workflows que Claude puede invocar automáticamente basado en el contexto.

### Skills vs Commands

| Característica | Commands | Skills |
|---------------|----------|--------|
| Archivos múltiples | ❌ Solo uno | ✅ Paquetes completos |
| Auto-invocación | ❌ Manual | ✅ Automática |
| allowed-tools | ❌ No | ✅ Sí |
| Templates | ❌ No | ✅ Sí |

## La carpeta agents/: personalidades especializadas

Definí subagents especializados en `.claude/agents/`:

```markdown
---
name: code-reviewer
description: Expert code reviewer. Use when reviewing PRs.
model: sonnet
tools: Read, Grep, Glob
---
```

## settings.json: permissions

```json
{
  "permissions": {
    "allow": ["Bash(npm run *)", "Bash(git status)", "Read", "Write", "Edit"],
    "deny": ["Bash(rm -rf *)", "Bash(curl *)", "Read(./.env)"]
  }
}
```

## Setup práctico paso a paso

1. Run `/init` dentro de Claude Code — genera un CLAUDE.md starter
2. Crear `.claude/settings.json` con rules de allow/deny
3. Crear uno o dos commands para workflows recurrentes
4. Dividir instrucciones en `.claude/rules/` cuando CLAUDE.md crezca
5. Agregar `~/.claude/CLAUDE.md` con preferencias personales

## Relacionado

- [[sdd]] — SDD usa el Agent Harness como base
- [[proceso-desarrollo-ia]] — Proceso que depende de la configuración del harness
