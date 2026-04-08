---
title: Asset Generator v3 — Instructivo del Project
created: 2026-03-27
updated: 2026-03-27
tags: [AssetGenerator, NotebookLM, SKILL, Rules, Subagents]
sources:
  - "NotebookLM Knowledge Base"
status: synthesized
last_lint: 2026-04-07
---

# Asset Generator v3 — Instructivo del Project

> **Versión**: v3 — 2026-03-26
> **Qué cambió respecto a v2**: checklist binario (reemplaza self-scoring), gaps persistidos en Notion, feedback loop post-uso, revisión periódica del checklist cada 10 assets.

## Flujo de trabajo

```
Usuario pide un asset
        ↓
   PASO 0 — ¿Existe el notebook?
        ↓ sí              ↓ no
   PASO 0b          Crear notebook
   3 queries de          ↓
   validación       PASO 0b
        ↓
   ¿Las 3 queries pasan?
        ↓ sí              ↓ no (2+ fallan)
   PASO 1           Pedir más fuentes
   Descomposición        o research_start
   + confirmación        ↓
        ↓           volver a PASO 0b
   PASO 2
   Generación del asset
        ↓
   PASO 3 — Checklist binario
   ¿Algún ítem es ❌?
        ↓ no              ↓ sí
   PASO 5           Refinamiento [1/3]
   Entrega +             → nueva query
   registro Notion       → notificar usuario
        ↓                ↓ sigue fallando
   PASO 6           Refinamiento [2/3]
   Feedback              → nueva query
   post-uso              → notificar usuario
        ↓                ↓ sigue fallando
   PASO 7           Refinamiento [3/3]
   Revisión              → si sigue fallando:
   cada 10 assets        detener + reportar gap
```

## Estructura de salida de cada asset

Todo asset entregado incluye:

```markdown
## Trazabilidad

| Elemento | Query usada | Fuente confirmada |
|---|---|---|
| [regla o componente] | "texto de la query" | ✅ / ❌ gap |

## Gaps documentados

[Lista de elementos no resueltos. Si no hay: "Ninguno."]

## Checklist de calidad

- [x] Cada sintaxis tiene query de respaldo
- [x] Versión de tecnología especificada
- [x] Sin frases vagas sin fuente
- [x] Cada regla cubre un solo comportamiento
- [x] Sin instrucciones contradictorias
- [x] Verbos imperativos en todas las instrucciones
- [x] Un agente puede ejecutar cada paso sin ambigüedad
- [x] Gaps documentados o "Ninguno"
```

## Feedback post-uso (PASO 6)

Después de usar un asset:

```
Usé el skill [nombre]. Funcionó directo / tuve que cambiar [X].
```

El agente actualiza Notion:
- **Efectividad Post-uso**: 🟢 Directo / 🟡 Parcial / 🔴 Requirió reescritura
- **Cambios Manuales**: descripción de qué cambió

## Diferencias v2 → v3

| Aspecto | v2 | v3 |
|---------|-----|-----|
| Validación | Score numérico 1-10 | Checklist binario ✅/❌ |
| Gaps | Se olvidan | Se persisten en Gaps Sistémicos |
| Transparencia | Silencio durante refinamientos | Notificaciones al usuario |
| Señal estructural | No existe | Gap con 3+ apariciones → alerta |
| Feedback post-uso | No existe | PASO 6 actualiza Notion |
| Mejora checklist | Estático | Revisión cada 10 assets |

## Relacionado

- [[asset-generator-v3]] — Configuración del proyecto
- [[gap-tracking]] — Sistema de tracking de gaps
