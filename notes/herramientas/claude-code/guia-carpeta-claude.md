---
title: "Anatomía de la carpeta .claude/ — Guía Completa"
created: 2026-04-02
updated: 2026-04-04
tags: [ClaudeCode, CLAUDE.md, Hooks, Skills, Agents, Permissions, Configuracion]
sources:
  - "@akshay_pachaar"
  - "Notion → migrado 2026-04-04"
status: synthesized
last_lint: 2026-04-07
---

# Anatomía de la carpeta .claude/ — Guía Completa

Guía completa sobre CLAUDE.md, custom commands, skills, agents, permissions, y cómo configurarlos correctamente.

> Inspirado en @akshay_pachaar, mejorado y expandido.

---

## Two folders, not one

Existen dos carpetas `.claude/`, no una:

- **`.claude/` a nivel de proyecto** → configuración del equipo. Se committea a git. Todos en el equipo reciben las mismas reglas.
- **`~/.claude/` a nivel global** → preferencias personales y estado local de la máquina (historial de sesiones, auto-memory).

---

## CLAUDE.md: El manual de instrucciones de Claude

Es el archivo más importante del sistema. Cuando inicias una sesión de Claude Code, lo primero que lee es CLAUDE.md. Se carga directamente en el system prompt y permanece durante toda la conversación.

### Donde colocar CLAUDE.md

- Proyecto root → reglas para el proyecto completo
- `~/.claude/CLAUDE.md` → preferencias globales que aplican a todos los proyectos
- Subdirectorios → reglas específicas por carpeta

Claude lee todos y los combina.

### Qué SÍ pertenece en CLAUDE.md

- **Contexto de negocio** — qué hace el proyecto, a quién sirve, dominio (2-5 líneas máximo)
- Comandos de build, test y lint (`npm run test`, `make build`, etc.)
- Decisiones arquitectónicas clave ("monorepo con Turborepo")
- Gotchas no obvias ("Strict TypeScript mode, variables no usadas son errores")
- Convenciones de imports, patrones de naming, estilos de error handling
- Estructura de archivos y carpetas para módulos principales

### Qué NO pertenece en CLAUDE.md

- Cualquier cosa que ya pertenezca a un linter o formatter config
- Documentación completa que puedas linkear
- Párrafos largos explicando teoría

### Recomendación práctica

**Mantener CLAUDE.md bajo 200 líneas.** Archivos más largos empiezan a comer contexto y la adherencia de Claude a las instrucciones realmente baja.

```markdown
# Project: Acme API

## Context
API REST para un sistema de gestión de inventarios B2B.
Clientes: warehouses medianos en LATAM.
Modelo de suscripción con tiers: Free, Pro, Enterprise.

## Commands
npm run dev          # Start dev server
npm run test         # Run tests (Jest)
npm run lint         # ESLint + Prettier check
npm run build        # Production build

## Architecture
- Express REST API, Node 20
- PostgreSQL via Prisma ORM
- All handlers live in src/handlers/
- Shared types in src/types/

## Conventions
- Use zod for request validation in every handler
- Return shape is always { data, error }
- Never expose stack traces to the client
- Use the logger module, not console.log

## Watch out for
- Tests use a real local DB, not mocks. Run `npm run db:test:reset` first
- Strict TypeScript: no unused imports, ever
```

~20 líneas. Da todo lo que Claude necesita para trabajar productivamente.

### CLAUDE.local.md para overrides personales

Si tienes una preferencia que es solo tuya, creá `CLAUDE.local.md` en la raíz del proyecto. Se lee junto con el CLAUDE.md principal y está automáticamente gitigneado.

---

## La carpeta rules/: instrucciones modulares que escalan

CLAUDE.md funciona bien para un proyecto individual. Pero cuando el equipo crece, terminás con un CLAUDE.md de 300 líneas que nadie mantiene.

**`rules/` solve eso.**

Cada archivo markdown dentro de `.claude/rules/` se carga automáticamente junto con tu CLAUDE.md:

```
.claude/rules/
├── code-style.md
├── testing.md
├── api-conventions.md
└── security.md
```

### El poder real: path-scoped rules

Agregá un bloque YAML frontmatter a un archivo de rules y **solo se activa cuando Claude trabaja con archivos específicos**:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/handlers/**/*.ts"
---
# API Design Rules

- All handlers return { data, error } shape
- Use zod for request body validation
- Never expose internal error details to clients
```

Claude no va a cargar este archivo cuando edite un componente React. Solo lo carga cuando trabaja dentro de `src/api/` o `src/handlers/`.

---

## El sistema de hooks: control determinista sobre el comportamiento de Claude

CLAUDE.md es bueno, pero son **sugerencias**. Claude las sigue la mayoría de las veces, no siempre.

**Hooks hacen estos comportamientos deterministas.** Son event handlers que se disparan automáticamente en puntos específicos del workflow de Claude.

### Estructura

```
.claude/
├── settings.json              # hooks config lives here
└── hooks/                     # hook scripts (convention, not required)
    ├── bash-firewall.sh       # PreToolUse: blocks dangerous commands
    ├── auto-format.sh         # PostToolUse: runs formatter on edited files
    └── enforce-tests.sh       # Stop: ensures tests pass before finishing
```

### Eventos principales

| Evento | Cuándo dispara |
|--------|---------------|
| `PreToolUse` | Antes de que cualquier tool corre (tu security gate) |
| `PostToolUse` | Después de que un tool corre (formatters, linters) |
| `Stop` | Cuando Claude termina (quality gates) |
| `UserPromptSubmit` | Cuando presionás enter (prompt validation) |
| `Notification` | Desktop alerts |
| `SessionStart/SessionEnd` | Context injection y cleanup |

### Códigos de salida — CRÍTICO

- **Exit 0** → Success, continuar
- **Exit 1** → Error pero no bloqueante (el tool ya corrió)
- **Exit 2** → **Bloquear todo** y enviar stderr a Claude para self-correction

> **Error común:** Usar exit 1 para security hooks. No bloquea nada. Usá exit 2.

### Ejemplo práctico: auto-format + bash firewall

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/bash-firewall.sh" }
        ]
      }
    ]
  }
}
```

### El script bash-firewall

```bash
#!/bin/bash
read -r command

dangerous_patterns=(
  "rm -rf /"
  "git push --force main"
  "DROP TABLE"
  "curl.*--data"
)
for pattern in "${dangerous_patterns[@]}"; do
  if echo "$command" | grep -q "$pattern"; then
    echo "Blocked dangerous command: $command" >&2
    exit 2
  fi
done

exit 0
```

### Stop hooks — trap para tests

```bash
#!/bin/bash
npm test
if [ $? -ne 0 ]; then
  echo "Tests failed, blocking completion" >&2
  exit 2
fi
exit 0
```

> **Gotcha crítica:** Siempre checkeá el flag `stop_hook_active` en el JSON payload. Sin esto, el hook bloquea a Claude, Claude reintenta, el hook bloquea de nuevo → **infinite loop**.

### Otras advertencias importantes

- Hooks **no** hacen hot-reload mid-session. Reiniciá la sesión para cambios.
- PostToolUse **no puede** deshacer nada — el tool ya corrió. Usá PreToolUse si necesitás prevenir.
- Hooks disparan recursivamente para acciones de subagents también.
- Hooks se ejecutan con tus permisos de usuario completos y **sin sandboxing**.

---

## La carpeta skills/: workflows reutilizables on-demand

Skills son workflows que **Claude puede invocar automáticamente** basado en el contexto, cuando la tarea matchea con la descripción del skill.

### Estructura

```
.claude/skills/
├── security-review/
│   ├── SKILL.md
│   └── DETAILED_GUIDE.md
└── deploy/
    ├── SKILL.md
    └── templates/
        └── release-notes.md
```

### Skills vs Commands

| Característica | Commands | Skills |
|----------------|----------|--------|
| Archivos múltiples | ❌ Solo un archivo | ✅ Paquetes completos |
| Auto-invocación | ❌ Manual explícito | ✅ Automática por contexto |
| Herramientas incluidas | ❌ No | ✅ pueden definir `allowed-tools` |
| Templates/recursos | ❌ No | ✅ Puede bundlear archivos |

**Regla simple:** Si es un workflow complejo que necesita múltiples archivos, documentación de soporte, o querés que se active automáticamente → **Skills**. Si es un solo comando simple y manual → **Commands**.

---

## La carpeta agents/: personalidades de subagents especializadas

Cuando una tarea es lo suficientemente compleja para beneficiarse de un especialista dedicado, definí una subagent persona en `.claude/agents/`.

### Ejemplo: code-reviewer.md

```markdown
---
name: code-reviewer
description: Expert code reviewer. Use PROACTIVELY when reviewing PRs,
  checking for bugs, or validating implementations before merging.
model: sonnet
tools: Read, Grep, Glob
---

You are a senior code reviewer with a focus on correctness and maintainability.

When reviewing code:
- Flag bugs, not just style issues
- Suggest specific fixes, not vague improvements
- Check for edge cases and error handling gaps
- Note performance concerns only when they matter at scale
```

### Agents personales

Van en `~/.claude/agents/` y están disponibles en todos los proyectos.

---

## settings.json: permissions y config del proyecto

`settings.json` controla qué Claude **puede y no puede** hacer. También es donde viven los hooks.

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Read",
      "Write",
      "Edit"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)"
    ]
  }
}
```

### El schema URI

La línea `$schema` habilita autocomplete e inline validation en VS Code o Cursor. **Siempre incluyanla.**

### Patrones de permissions

**Allow list** → comandos que corren sin confirmación:
- `Bash(npm run *)` o `Bash(make *)` — tus scripts
- `Bash(git *)` — comandos git de solo lectura
- `Read`, `Write`, `Edit`, `Glob`, `Grep` — operaciones de archivo

**Deny list** → comandos bloqueados entirely:
- Shell commands destructivos como `rm -rf`
- Network commands directos como `curl`
- Archivos sensibles como `.env` y cualquier cosa en `secrets/`

### settings.local.json para overrides personales

Creá `.claude/settings.local.json` para cambios de permissions que no querés commitear. Está auto-gitigneado.

---

## La carpeta global ~/.claude/

| Archivo/Carpeta | Qué hace |
|-----------------|---------|
| `~/.claude/CLAUDE.md` | Instrucciones globales para todas las sesiones |
| `~/.claude/settings.json` | Settings y hooks globales |
| `~/.claude/projects/` | Historial de sesiones + auto-memory por proyecto |
| `~/.claude/commands/` | Commands personales (disponibles en todos los proyectos) |
| `~/.claude/skills/` | Skills personales (disponibles en todos los proyectos) |
| `~/.claude/agents/` | Agents personales (disponibles en todos los proyectos) |

### Auto-memory

Claude Code guarda notas automáticamente mientras trabaja: comandos que descubre, patrones que observa, insights de arquitectura. Estos **persisten entre sesiones**. Podés browsearlos y editarlos con `/memory`.

---

## Setup práctico paso a paso

```
Paso 1.  Run /init dentro de Claude Code.
         Genera un CLAUDE.md starter leyendo tu proyecto.
         Editalo hacia abajo, dejalo en lo esencial.

Paso 2.  Creá .claude/settings.json con rules de allow/deny
         apropiadas para tu stack.
         Mínimo: allow tus run commands, deny .env reads.

Paso 3.  Creá uno o dos commands para los workflows
         que hacés más. Code review y issue fixing
         son buenos puntos de partida.

Paso 4.  A medida que el proyecto crece y CLAUDE.md se
         llena, empezá a dividir instrucciones en
         archivos .claude/rules/. Escopelos por path
         donde tenga sentido.

Paso 5.  Agregá ~/.claude/CLAUDE.md con tus preferencias
         personales. Algo como "always write types before
         implementations" o "prefer functional patterns
         over class-based."
```

**Esto es todo lo que necesitás para el 95% de los proyectos.** Skills y agents vienen después, cuando tenés workflows complejos recurrentes que valen la pena packagear.

---

## Errores comunes a evitar

| Error | Por qué es un problema | Solución |
|-------|----------------------|---------|
| Usar exit 1 en security hooks | No bloquea nada | Usar exit 2 |
| Olvidar `stop_hook_active` en Stop hooks | Loop infinito | Incluir el flag en el payload |
| CLAUDE.md de 300+ líneas | Come contexto, baja adherencia | Dividir en `rules/` |
| Hooks sin paths absolutos | Falla en contextos diferentes | Usar `$CLAUDE_PROJECT_DIR` |
| No usar `$schema` en settings.json | Sin autocomplete, errores no detectados | Siempre incluirlo |
| Skills que hacen de todo | Pierden el propósito | Skills específicos y auto-invocables |

---

## El insight clave

> **La carpeta .claude/ es fundamentalmente un protocolo para decirle a Claude quién sos, qué hace tu proyecto, y qué reglas debe seguir.**
>
> Cuanto más claro lo definís, menos tiempo gastás corrigiendo a Claude y más tiempo hace trabajo útil.

**CLAUDE.md es tu archivo de mayor leverage. Arrancá bien con eso. Todo lo demás es optimización.**

Empezá chico, refinanás sobre la marcha.

---

## Relacionado

- [[claude-architect-domain-map]] — Domain 3 del examen Claude Certified Architect
- [[skill-anatomia]] — Anatomía de un SKILL.md bien diseñado
- [[rules-idoenas]] — Rules Idóneas en Claude Code
