---
title: Setup completo de .claude/ para un proyecto nuevo
created: 2026-04-04
updated: 2026-04-04
tags: [ClaudeCode, Setup, CLAUDEMd, Rules, Skills, Agents, Hooks]
sources:
  - "Proceso de Desarrollo con IA — Guía Práctica"
status: synthesized
last_lint: 2026-04-07
---

# Setup completo de .claude/ para un proyecto nuevo

## Progresión de 5 pasos

1. `/init` → genera CLAUDE.md starter
2. `.claude/settings.json` → permissions allow/deny
3. `.claude/commands/` → workflows recurrentes (/review, /fix-bug)
4. `.claude/rules/` → cuando CLAUDE.md > 200 líneas
5. `~/.claude/CLAUDE.md` → preferencias globales personales

## Estructura completa

```
proyecto/
├── CLAUDE.md
├── CLAUDE.local.md              # Overrides personales
└── .claude/
    ├── settings.json
    ├── settings.local.json
    ├── hooks/
    │   ├── bash-firewall.sh    # PreToolUse
    │   ├── auto-format.sh      # PostToolUse
    │   └── enforce-tests.sh     # Stop
    ├── commands/
    ├── rules/
    ├── skills/
    └── agents/

~/.claude/
├── CLAUDE.md                    # Global
├── skills/                      # Todos los proyectos
└── agents/                      # Todos los proyectos
```

## Relacionado

- [[claude-code-configuracion]] — Referencia completa de anatomía
- [[rules-idoneas]] — Guía de rules
