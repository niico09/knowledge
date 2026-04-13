---
title: Whisper — Voice Input para Claude Code
created: 2026-04-13
tags: [ClaudeCode, Productivity, Voice, Whisper, Workflow]
sources:
  - "@zostaff — Complete Claude Code Guide, Apr 11 2026"
status: new
related:
  - guia-carpeta-claude
  - proceso-desarrollo-ia
---

# Whisper — Voice Input para Claude Code

## El Claim

> "Speaking is faster than typing. If you're still typing prompts by hand — you're losing 40% of your speed."

Voice input con Whisper permite dictar prompts directamente a Claude Code, eliminando la fricción del typing.

## Herramientas Mentionadas

- **Whisper Flow** — integración con flow states
- **Aqua Voice** — alternativa mencionada

(Nota: Verificar cuál está más activa al momento de implementar.)

## Por Qué Importa

- **40% de velocidad** en input de prompts
- Pensar en voz alta = más contexto natural
- No interrumpe el flujo de código
- Especialmente útil para:
  - Specs y descripciones largas
  - Modificaciones iterativas
  - Documentation
  -研究与 brainstorming

## Setup Típico

```bash
# Install Whisper (verificar docs actuales)
# Configurar como input method para Claude Code

# En terminal con voice enabled:
❯ claude
⚠️ Voice input enabled
```

## Limitaciones

- Ruido ambiental afecta accuracy
- No siempre funciona para código técnico con símbolos
-还得review lo que se dictó
- Puede ser incómodo en espacios abiertos

## Cuándo Preferir Typing

- Código con símbolos especiales
- Entornos compartidos (oficina open plan)
- Contexto que requiere precisión exact
- Passwords o datos sensibles

## Relacionado

- [[guia-carpeta-claude]] — Setup de Claude Code
- [[proceso-desarrollo-ia]] — SDD workflow donde voice puede ayudar
