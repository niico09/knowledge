---
title: "Guía Completa: Rules Idóneas en Claude Code (2026)"
created: 2026-04-04
updated: 2026-04-04
tags: [Rules, CLAUDE.md, ClaudeCode, Hooks, BestPractices]
sources:
  - "Notion → migrado 2026-04-04"
---

# Guía Completa: Rules Idóneas en Claude Code (2026)

## Qué son las Rules en Claude Code

Las **rules** son instrucciones persistentes que guían el comportamiento del agente a lo largo de las sesiones. Se almacenan en archivos de texto que Claude lee automáticamente al inicio de cada conversación.

> `CLAUDE.md` es la memoria permanente del agente para tu proyecto. Sin él, Claude comienza cada sesión sabiendo absolutamente nada de tu codebase.

## Dónde viven las Rules

| Ubicación | Scope | Uso |
|-----------|-------|-----|
| `~/.claude/CLAUDE.md` | Global | Todas las sesiones, todos los proyectos |
| `./CLAUDE.md` | Por repo | Se versiona en git. Comandos, arquitectura, convenciones del equipo |
| `./.claude/rules/*.md` | Modular | Archivos separados por dominio, cargados automáticamente |

Los archivos pueden importar otros usando la sintaxis `@path/to/archivo.md`.

---

## Principio Fundamental: Menos es Más

El instinto natural cuando Claude ignora una regla es agregar más reglas. La evidencia muestra que eso **empeora** el problema.

> **Límite crítico (HumanLayer, Nov 2025):** Los LLMs frontier pueden seguir ~150-200 instrucciones con consistencia. El system prompt propio de Claude Code ya consume ~50 slots. Tu presupuesto real es **100-150 instrucciones**. Cuando lo superás, el modelo ignora **todas de forma uniforme**.

**Test de cada línea:** Si elimino esta línea, ¿cometerá Claude un error que no cometería de otra forma? Si la respuesta es **NO**, elimínala.

## Longitud objetivo

| Longitud | Estado |
|----------|--------|
| < 60 líneas | ✅ Óptimo. Máxima adherencia garantizada |
| < 200 líneas | ✅ Recomendado por la comunidad |
| < 300 líneas | ⚠️ Límite práctico máximo |
| > 300 líneas | ❌ Anti-patrón. Las reglas críticas se pierden |

---

## Anatomía de una Rule Bien Escrita

### Instrucciones Positivas vs. Negativas

Los LLMs procesan la negación de forma costosa. Las instrucciones positivas tienen mayor adherencia (~50% menos violaciones).

| Negativa (evitar) | Positiva (usar) |
|-------------------|-----------------|
| `Do NOT use default exports` | `Use named exports exclusively` |
| `Never use 'any' type` | `Use 'unknown' and narrow explicitly` |
| `Don't use relative imports from parent dirs` | `Use path aliases (@/) for all imports` |
| `Never put tests in a separate folder` | `Place tests in __tests__/ next to the source file` |

### Posicionamiento Estratégico (Primacy/Recency Bias)

Los LLMs prestan más atención al inicio y al final del contexto.

> **Técnica de duplicación estratégica:** Las reglas que Claude viola con mayor frecuencia merecen dos slots — uno al inicio (primacy bias) y uno al final (recency bias).

```javascript
# CRÍTICO — Leer primero
- [Regla más violada #1]
- [Regla más violada #2]

# Contexto del proyecto
...

# CRÍTICO — Recordatorio final
- [Regla más violada #1]
- [Regla más violada #2]
```

### Las 3 Dimensiones de Contexto (WHAT / WHY / HOW)

| Dimensión | Contenido esperado |
|-----------|-------------------|
| **WHAT** | Stack, estructura de carpetas, mapa del codebase |
| **WHY** | Propósito del proyecto y función de sus partes |
| **HOW** | Comandos de build/test, cómo verificar cambios, convenciones de entorno |

---

## Hooks: De Sugerencias a Enforcement Determinístico

- **Instrucciones en CLAUDE.md** → sugerencias probabilísticas
- **Hooks** → garantías determinísticas

> Si escribís en CLAUDE.md "no modificar archivos .env", Claude *probablemente* lo respetará. Si configurás un hook `PreToolUse` que bloquea writes a `.env`, *siempre* los bloqueará.

### Eventos disponibles

| Evento | Cuándo ejecuta | Uso principal |
|--------|---------------|---------------|
| `PreToolUse` | Antes de que Claude use una herramienta | Bloquear acciones peligrosas |
| `PostToolUse` | Después de completar una acción | Formatters automáticos |
| `UserPromptSubmit` | Al enviar cada prompt | Inyectar contexto adicional |
| `SessionStart` | Al iniciar la sesión | Setup automático |
| `Stop` | Cuando Claude termina | Notificaciones y validación final |
| `PermissionRequest` | Al solicitar permiso para una acción | Auto-aprobación/denegación programable |

### Códigos de salida — CRÍTICO

- **Exit 0** → Success, continuar
- **Exit 1** → Error pero no bloqueante (el tool ya corrió)
- **Exit 2** → **Bloquear todo** y enviar stderr a Claude para self-correction

> Usá `exit 2` (bloquea). `exit 1` solo registra una advertencia pero **NO bloquea**.

### Hook de seguridad

```bash
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

BLOCKED=("rm -rf /" "DROP DATABASE" "DROP TABLE" "mkfs")

for pattern in "${BLOCKED[@]}"; do
  if echo "$COMMAND" | grep -q "$pattern"; then
    echo "Blocked: $pattern is not allowed" >&2
    exit 2
  fi
done

exit 0
```

### Los 3 hooks de mayor impacto

| Hook | Evento | Valor |
|------|--------|-------|
| Auto-formatter | `PostToolUse` | Ejecuta tu formatter en cada archivo editado |
| Bloqueo de peligros | `PreToolUse` | Previene `rm -rf`, `DROP TABLE` y similares |
| Notificaciones | `Stop` | Avisa cuando Claude termina |

---

## Progressive Disclosure: El Patrón Avanzado

En proyectos grandes, meter todo en `CLAUDE.md` viola el principio de "menos es más". La solución: solo ver contexto específico de tarea cuando realmente lo necesita.

```
proyecto/
├── CLAUDE.md                    # Mínimo: contexto universal
├── .claude/
│   ├── settings.json            # Hooks y permisos
│   ├── rules/                   # Módulos por dominio
│   │   ├── code-style.md
│   │   ├── testing.md
│   │   └── security.md
│   ├── skills/                  # Conocimiento bajo demanda
│   └── commands/                # Slash commands personalizados
└── agent_docs/                  # Documentación referenciada desde CLAUDE.md
```

---

## Anti-patrones Comunes

| Anti-patrón | Por qué evitarlo |
|-------------|-----------------|
| **El CLAUDE.md sobredimensionado** | Superar 300 líneas hace que las reglas críticas se pierdan en el ruido |
| **Mezclar global con local** | Instrucciones de proyecto en el global generan ruido en cada sesión |
| **Claude como linter costoso** | Guías de estilo extensas en CLAUDE.md. Usá un linter + hook automático |
| **Auto-generar con /init sin revisar** | El output es un borrador. Editar manualmente siempre |
| **Instrucciones en negativo** | Reformular en positivo mejora la adherencia ~50% |
| **Reglas de edge cases** | Solo incluir lo que Claude no puede inferir del código |
| **Solo CLAUDE.md para seguridad** | Para reglas críticas, combinar con hooks `PreToolUse` determinísticos |

---

## Resumen Ejecutivo

| Principio | Recomendación |
|-----------|---------------|
| **Longitud objetivo** | < 60 líneas (ideal) / < 200 líneas (práctico) / < 300 líneas (máximo) |
| **Separación de capas** | Global para preferencias. Local para el repo |
| **Redacción** | Instrucciones positivas, imperativas, sin ambigüedad |
| **Estructura mínima** | WHAT + WHY + HOW |
| **Progressive Disclosure** | Archivos en `agent_docs/` o `.claude/rules/` con punteros |
| **Enforcement fuerte** | Usar hooks `PreToolUse/PostToolUse` para reglas no negociables |
| **Exit codes en hooks** | `exit 2` = bloquea. `exit 1` = solo avisa |
| **Anti-patrón #1** | El CLAUDE.md sobredimensionado. Más reglas ≠ mejor adherencia |
| **Anti-patrón #2** | No separar lo que debe ser hook de lo que puede ser instrucción |

---

## Relacionado

- [[claude-architect-domain-map]] — Domain 3 del examen: CLAUDE.md hierarchy, plan mode vs direct execution, CI/CD con `-p` flag
- [[guia-carpeta-claude]] — Anatomía completa de la carpeta .claude/ (hooks, agents, skills, settings)
- [[skill-anatomia]] — Anatomía de SKILL.md bien diseñado
