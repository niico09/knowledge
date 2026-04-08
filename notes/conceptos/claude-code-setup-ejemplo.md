---
title: Ejemplo: Setup completo de .claude/ para un proyecto nuevo
created: 2026-04-04
updated: 2026-04-04
tags: [ClaudeCode, Setup, Ejemplo, Rules, Hooks, Skills, Agents]
sources:
  - "Proceso de Desarrollo con IA — Guía Práctica"
status: synthesized
last_lint: 2026-04-07
---

# Ejemplo: Setup completo de `.claude/` para un proyecto nuevo

Proyecto: **API REST con Node.js, TypeScript, Prisma y PostgreSQL**.

## Setup mínimo

### 1. Generar starter CLAUDE.md con `/init`

```bash
claude
/init
```

### 2. .claude/settings.json

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(npx *)",
      "Bash(git status)",
      "Bash(git diff)",
      "Bash(prisma *)",
      "Read", "Write", "Edit", "Glob", "Grep"
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

### 3. Commands para workflows recurrentes

`.claude/commands/review.md` — Code review:
```markdown
# Code Review

1. Run `git diff --staged`
2. Read changed files
3. Check for bugs, missing error handling, edge cases
4. Report with file:line references and suggested fixes
```

## Hooks funcionales

### bash-firewall.sh (PreToolUse)
```bash
#!/bin/bash
read -r cmd
dangerous_patterns=("rm -rf /" "git push --force main" "DROP TABLE")
for pattern in "${dangerous_patterns[@]}"; do
  if echo "$cmd" | grep -q "$pattern"; then
    echo "Blocked: $pattern" >&2
    exit 2
  fi
done
exit 0
```

### enforce-tests.sh (Stop)
```bash
#!/bin/bash
if [ "$stop_hook_active" != "true" ]; then exit 0; fi
npm test
exit $?
```

## Skills ejemplo

`.claude/skills/security-review/SKILL.md`:
```markdown
---
name: security-review
description: Security audit. Use when reviewing for vulnerabilities.
allowed-tools: Read, Grep, Glob
---

Analyze for SQL injection, XSS, exposed credentials, auth gaps.
Report with severity and remediation.
```

## Agents ejemplo

`.claude/agents/code-reviewer.md`:
```markdown
---
name: code-reviewer
description: Expert code reviewer. Use for PRs and bug validation.
model: sonnet
tools: Read, Grep, Glob, Bash
---

Flag bugs, suggest specific fixes, check edge cases.
```

## Relacionado

- [[claude-code-configuracion]] — Guía completa
- [[setup-claude]] — Guía de setup
