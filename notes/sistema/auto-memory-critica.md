---
title: Auto Memory — Perspectiva Crítica
created: 2026-04-13
tags: [ClaudeCode, Memory, AutoMemory, Critique]
sources:
  - "@zostaff — Complete Claude Code Guide, Apr 11 2026"
status: new
related:
  - guia-carpeta-claude
  - contexto-auto-compact
---

# Auto Memory — Perspectiva Crítica

## La Perspectiva del Post

> "Honestly? I don't love it. Too much magic. Stored at user/project level, can't share with team, hard to control."

El post cuestiona Auto Memory por ser opaco y no colaborativo.

## Qué Es Auto Memory

Claude Code guarda notas automáticamente mientras trabaja:
- Comandos que descubre en el proyecto
- Patrones de arquitectura que observa
- Insights sobre el codebase

Persiste entre sesiones. Se puede browswear y editar con `/memory`.

## Críticas Válidas

### 1. Too Much Magic
- No hay visibility clara de qué se guarda
- No se puede auditar qué sabe el agente de tu proyecto
- Puede generar context incorrecto sin que te des cuenta

### 2. No Compartible con Equipo
- Solo existe a nivel usuario o proyecto individual
- Un equipo no puede compartir el mismo Auto Memory
- Cada desarrollador tiene su propia "versión" del contexto

### 3. Difícil de Controlar
- No hay forma de limpiar o resetear selectivamente
- Puede acumular información obsoleta
- No hay manera de saber qué记住了 vs qué olvidó

## Alternativa Recomendada

**CLAUDE.md explícito:**
- Tenés control total de qué entra
- Se puede versionar en git
- Todo el equipo ve el mismo contexto
- Se puede auditar y corregir

```
Auto Memory     → Background, no confiable para decisiones
CLAUDE.md       → Fuente de verdad, versionable, auditabl
```

## Recomendación Práctica

1. Dejá Auto Memory correr en el background
2. **No confíes en ella** para decisiones importantes
3. Lo importante va siempre en CLAUDE.md explícitamente
4. Usá `/memory browse` periódicamente para ver qué grabó
5. Si algo es crítico → move it to CLAUDE.md

## El Principio Subyacente

> Magic is when you don't understand what's happening. And when you don't understand — you can't fix it.

Auto Memory puede ser útil como вспомогательный, pero nunca como fuente de verdad. Para eso está CLAUDE.md.

## Relacionado

- [[guia-carpeta-claude]] — CLAUDE.md y setup correcto
- [[context-zonas-status-line]] — Monitoreo de context
