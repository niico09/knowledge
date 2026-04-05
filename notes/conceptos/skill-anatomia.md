---
title: Anatomía de un SKILL.md bien diseñado
created: 2026-03-29
updated: 2026-04-04
tags: [Skills, SKILL.md, ProgressiveDisclosure, ClaudeCode]
sources:
  - "Notion → migrado 2026-04-04"
---

# Anatomía de un SKILL.md bien diseñado

## Estructura de un skill — 3 niveles de Progressive Disclosure

El principio fundamental: el agente solo carga lo que necesita, cuando lo necesita. El contexto es finito y costoso.

> **Principio central:** Progressive Disclosure — mostrar justo suficiente para que el agente decida qué hacer, y revelar más detalles a medida que los necesita.

### Nivel 1 — Trigger (~100 tokens)

Solo el **frontmatter**. Nombre y descripción. Es lo único que el agente ve al inicio de cada sesión.

- Se carga en el system prompt automáticamente al arrancar
- Define si el skill se activa o no
- **El trigger real es la `description`, no las instrucciones**

### Nivel 2 — Runbook (< 5.000 tokens recomendado)

El cuerpo del `SKILL.md`. Instrucciones core, flujo de trabajo, ejemplos.

- Se carga solo cuando el skill se activa
- Mantener en **< 500 líneas**
- Solo instrucciones procedurales — nada que Claude ya sepa

### Nivel 3 — Recursos (on-demand)

Archivos en `references/`, `scripts/`, `assets/`. Se leen solo cuando la tarea los necesita.

- El agente los lee con comandos explícitos del SKILL.md (ej: "Ver `references/schema.md`")
- Nunca se cargan automáticamente
- Tamaño efectivamente ilimitado

---

## Estructura de directorios

```
skill-name/
├── SKILL.md          ← Obligatorio: frontmatter + instrucciones core
├── scripts/          ← Código ejecutable (Python/Bash) como CLIs pequeños
├── references/       ← Contexto suplementario (schemas, cheatsheets, políticas)
└── assets/           ← Templates o archivos estáticos usados en el output
```

> **Regla de profundidad:** Solo 1 nivel de subdirectorios. `references/schema.md` ✅ — `references/db/v1/schema.md` ❌

---

## Frontmatter: campos clave

### `name` (Obligatorio)

- Formato: `minúsculas-con-guiones`
- Debe coincidir **exactamente** con el nombre del directorio padre
- Se convierte en el slash-command: `/nombre-del-skill`
- Solo letras minúsculas, números y guiones (sin guiones consecutivos)

### `description` (Obligatorio — el campo más importante)

Es el único campo que el agente ve **antes** de decidir activar el skill. Si la descripción no es precisa, el skill nunca se dispara.

| Mala | Buena |
|------|-------|
| "Helps with Excel files" | "Processes Excel files and generates formatted reports with charts" |
| "For writing" | "Generates internal communications using company tone guidelines" |
| "Code stuff" | "Refactors Java 21 + Spring Boot 3.5 classes applying SOLID principles" |

**Reglas para la description:**

- Escribir en **tercera persona**
- Incluir **qué hace** + **cuándo usarlo**
- Ser específico sobre tecnologías y formatos
- Inconsistencia de punto de vista causa problemas de discovery

### `allowed-tools` (Opcional)

Define qué herramientas puede usar el skill sin aprobación del usuario.

```yaml
allowed-tools: "Bash, Read, Write"
```

Solo declarar los necesarios. Principio de mínimo privilegio.

### Frontmatter completo de ejemplo

```yaml
---
name: chakra-ui-component
description: Generates Chakra UI v3 components with TypeScript, proper theming tokens, and accessibility patterns. Use when creating or refactoring React components with Chakra UI.
allowed-tools: "Read, Write, Bash"
version: 1.0.0
---
```

---

## Buenas prácticas

### Hacer

- ✅ `description` en tercera persona, específica y orientada a la acción
- ✅ Mantener SKILL.md en < 500 líneas — solo instrucciones procedurales
- ✅ Mover referencias densas a `references/` y vincularlas explícitamente
- ✅ Usar paths relativos con `/` (independiente del OS)
- ✅ Scripts para lógica determinista o frágil — no code inline en el skill
- ✅ Vincular archivos con frases como "Ver `references/auth-flow.md` para códigos de error"
- ✅ Probar en sesión nueva (Claude B) — no en la misma sesión donde se creó
- ✅ Ciclo de iteración: **observar → refinar → probar** con tareas reales
- ✅ Adaptar verbosidad al modelo objetivo (Opus vs Haiku necesitan distinto nivel de detalle)
- ✅ Una responsabilidad por skill — scope acotado y bien definido

### Evitar

- ❌ Explicar conceptos que Claude ya conoce
- ❌ Incluir README.md, CHANGELOG.md o documentación para humanos
- ❌ Duplicar información en SKILL.md y en `references/`
- ❌ Subdirectorios profundos (solo 1 nivel)
- ❌ Skills con permisos demasiado amplios
- ❌ Asumir comportamiento sin probar con tareas reales
- ❌ Mezclar contexto de creación del skill con instrucciones de uso
- ❌ Skills que hacen llamadas de red externas sin declarar explícitamente
- ❌ Mismo nombre de skill en dos directorios distintos
- ❌ Scope demasiado amplio — mejor dividir en múltiples skills enfocados

---

## Ciclo de desarrollo recomendado

1. **Definir** el caso de uso concreto y ejemplos de inputs/outputs esperados
2. **Generar** el SKILL.md con Claude (entiende el formato nativamente)
3. **Revisar** concisión — quitar todo lo que Claude ya sabe
4. **Probar** en sesión nueva con tareas reales (no escenarios de prueba artificiales)
5. **Observar** dónde el agente se desvía del comportamiento esperado
6. **Refinar** basado en comportamiento observado, no en suposiciones
7. Repetir desde el paso 4

> El skill-creator de Anthropic usa exactamente este ciclo: Claude A (experto en crear skills) + Claude B (agente que lo usa en producción).

---

## Seguridad en skills de comunidad

> ⚠️ Instalar un skill es equivalente a instalar software. Auditarlo antes.

- Revisar **todos** los archivos: `SKILL.md`, `scripts/`, recursos
- Desconfiar de skills con llamadas de red no declaradas explícitamente en el propósito
- Usar sandboxing para skills con scripts ejecutables
- Preferir skills con provenance claro (autor conocido, control de versiones, mantenimiento activo)
- Cuidado con typosquatting — nombres que imitan skills populares

---

## Ecosistema y recursos

### Repositorios oficiales

- [anthropics/skills](https://github.com/anthropics/skills) — Skills oficiales de Anthropic
- [Documentación oficial](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Best practices de Anthropic
- [The Complete Guide to Building Skill for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) — PDF de Anthropic

### Comunidad

- [skillmatic-ai/awesome-agent-skills](https://github.com/skillmatic-ai/awesome-agent-skills) — Repositorio definitivo de la comunidad
- [mgechev/skills-best-practices](https://github.com/mgechev/skills-best-practices) — Guía técnica profunda
- [agentskill.sh](http://agentskill.sh) — Directorio de 44k+ skills con security scanning
- [SkillsMP](https://skillsmp.io) — Marketplace para descubrir y compartir skills

### Compatibilidad cross-tool

El formato SKILL.md es un **estándar abierto** compatible con:
Claude Code · Claude.ai · OpenAI Codex · GitHub Copilot · Cursor · VS Code · Antigravity IDE · Gemini CLI

---

## Loop de mejora continua

El ciclo "observar → refinar → probar" documentado arriba es el punto de partida **manual**. Para el loop automatizado — cómo los skills detectan sus propios fallos y se auto-enmiendan a lo largo del tiempo — ver:

→ [[skills-auto-mejoran]]

---

## Template base

```markdown
---
name: mi-skill
description: [Tercera persona. Qué hace + cuándo usarlo. Tecnologías específicas.]
allowed-tools: "Read, Write"
version: 1.0.0
---

# Mi Skill

## Cuándo usar este skill
[Casos de uso específicos]

## Instrucciones
1. Paso uno
2. Paso dos
3. Ver `references/detalle.md` para casos especiales

## Ejemplos
- Input: ...
- Output esperado: ...

## Restricciones
- [Lo que NO debe hacer]
```

---

## Relacionado

- [[claude-architect-domain-map]] — Domain 3 del examen: skills frontmatter, `context: fork`, distinción skills vs CLAUDE.md
- [[skills-auto-mejoran]] — Loop automatizado de self-improvement para skills
- [[skills-generadas-registry]] — Registry de skills generadas por Asset Generator v3
