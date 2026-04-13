---
title: Context como Presupuesto — Zonas y Status Line
created: 2026-04-13
tags: [ClaudeCode, Context, Performance, TokenManagement]
sources:
  - "@zostaff — Complete Claude Code Guide, Apr 11 2026"
status: new
related:
  - conceptos/context-flooding
  - conceptos/context-collapse
  - guia-carpeta-claude
---

# Context como Presupuesto — Zonas y Status Line

## Concepto Central

La ventana de context es tu presupuesto. Todo entra ahí: tools, CLAUDE.md, MCPs, skills, y la conversación. Cuanto más lleno está, más lento y caro se vuelve cada operación.

## Zonas de Utilización

```
Context: ██████████████████████░░░░░░░░░  67%

 0%━━━━━━50%━━━━━━70%━━━━━━85%━━━100%
```

| Zona | Rango | Comportamiento |
|------|-------|----------------|
| **Verde** | 0-50% | Trabajo efectivo. Sin problemas. |
| **Amarillo** | 50-70% | Precaución. Empezar a considerar compactación. |
| **Naranja** | 70-85% | Problemas adelante. Auto-compact se acerca. |
| **Rojo** | 85%+ | **Auto-compact activa.** Claude compacta contexto automáticamente — pérdida de información. |

## Status Line en Tiempo Real

El status line muestra el porcentaje en vivo. Sin esto, estás conduciendo vendado.

```bash
# Tu status line se ve algo así:
❯ ~/my-project · opus-4 · 1M ctx · 67% ■■■■■■░░
```

**Configuración típica** (en settings.json o terminal prompt):
- Modelo activo
- Límite de contexto
- Porcentaje actual
- Indicador visual

## Reglas para Mantener Context Bajo

1. **CLAUDE.md < 500 líneas** — si es más largo, estás haciendo algo mal
2. **1 task = 1 sesión → /clear** — no encadenar tareas sin limpiar
3. **Tools por proyecto, no global** — global = solo lo que necesitás en todos lados

## Auto-Compact (85%+)

Cuando el context supera 85%, Claude activa auto-compact:
- Resume contexto importante
- Descarta información redundante
- Puede perder decisiones de diseño o contexto de tareas anteriores

**Prevención:** Monitorear el status line y hacer `/compact` manualmente antes de llegar a 85%.

## Por Qué Importa

- 0-50%: Cada mensaje cuesta lo mismo
- 50-70%: Empieza a latir más lento
- 70-85%: Latencia notable, costos suben
- 85%+: Auto-compact = comportamiento impredecible

**Benchmark:** Con CLAUDE.md optimizado: ~1.2K tokens por sesión. Sin CLAUDE.md: ~33K tokens solo para entender el proyecto. **27x más barato con CLAUDE.md.**

## Relacionado

- [[context-flooding]] — Qué es cuando el context se llena de ruido
- [[context-collapse]] — El evento de pérdida masiva de contexto
- [[guia-carpeta-claude]] — Setup de CLAUDE.md y estructura .claude/
