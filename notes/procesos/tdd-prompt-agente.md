---
title: Prompt para Agente — Implementación TDD completa
created: 2026-03-24
updated: 2026-03-24
tags: [TDD, SDD, Agent, Prompt, presupuesto-generator]
sources:
  - "SDD — presupuesto-generator"
status: synthesized
last_lint: 2026-04-07
---

# Prompt para Agente — Implementación TDD completa

Prompt completo para ejecutar un plan TDD de 5 tasks sobre el proyecto presupuesto-generator.

## Uso

Copiar el bloque y pegarlo como primer mensaje al agente (Claude Code, Cursor, Windsurf, etc.).

## El prompt

```
Eres un agente de desarrollo trabajando sobre el proyecto presupuesto-generator.
Ruta del proyecto: E:\desarrollos\consultora\tonk-tools\presupuesto-generator

Tu misión es ejecutar las 5 tasks del plan TDD definido para este proyecto.

---

## ANTES DE EMPEZAR — LEÉ EL HARNESS

El proyecto tiene rules y skills en `.agents/`. Leélas antes de tocar cualquier archivo:

# Rules
cat .agents/rules/react19-modern-conventions/react19-modern-conventions.md
cat .agents/rules/rsc-client-boundaries/rsc-client-boundaries.md
# Skills
cat .agents/skills/rsc-and-client-architecture/SKILL.md
cat .agents/skills/nextjs-error-boundaries/SKILL.md
cat .agents/skills/server-actions-security/server-actions-security.md

Resumen de las restricciones más importantes:
- No usar `forwardRef` ni `Context.Provider` — React 19 los depreca
- `"use client"` solo en leaf nodes interactivos, nunca en layouts
- Archivos con lógica pura no necesitan `"use client"`
- Si creás un archivo con lógica de servidor, agregá `import 'server-only'`

---

## CONTEXTO DEL PROYECTO

Stack: Next.js 15 (App Router) + React 19 + TypeScript + Zustand + Zod v4 + Vitest

Archivos clave:
- src/lib/utils/calculos.ts — funciones puras de cálculo financiero
- src/lib/utils/parse-presupuesto-md.ts — parser MD → PresupuestoMD
- src/lib/stores/presupuestoStore.ts — store Zustand con generateId() interno
- src/types/presupuesto.ts — tipos base

Bugs conocidos:
- calcularInversionHito(20, 0, 50) devuelve NaN — no hay guard para capacidadSprint=0 ni tarifaHoraUSD negativa
- generateId() usa Date.now() + Math.random() → colisiones posibles

## RESTRICCIONES — no tocar salvo que la task lo indique

- src/components/ — ningún componente de UI
- src/app/ — ninguna ruta ni layout
- src/lib/stores/presupuestoStore.ts — solo la línea de generateId (Task 2)
- No instalar @testing-library ni jsdom
- No mockear Date.now() — la solución es crypto.randomUUID()

---

## TASK 1 — Setup del entorno de testing

Crear vitest.config.ts con environment node, globals true, include en src/**/*.test.{ts,tsx}.

Agregar scripts al package.json:
- "test": "vitest run"
- "test:watch": "vitest"
- "test:coverage": "vitest run --coverage"

Instalar: npm install -D vitest @vitest/coverage-v8

Verificación: npx vitest run corre sin errores.

---

## TASK 2 — Extraer generateId() y cubrir con tests

Crear src/lib/utils/id.ts con crypto.randomUUID().

Modificar presupuestoStore.ts para importar generateId desde @/lib/utils/id.

Crear src/__tests__/lib/utils/id.test.ts con:
- IDs únicos en 10.000 llamadas consecutivas
- String de al menos 12 caracteres
- Sin duplicados en llamadas sincrónicas

Verificación: npx vitest run → 3 tests en verde.

---

## TASK 3 — Tests RED para calculos.ts

Crear src/__tests__/lib/utils/calculos.test.ts cubriendo:
- calcularInversionHito con valores válidos
- redondeo hacia arriba de sprints (ceil)
- storyPoints=0 → ceros, no NaN
- capacidadSprint=0 → ceros, no NaN ni Infinity
- tarifaHoraUSD negativa → ceros (valor defensivo)
- defaults de 80 horas y 4 devs

Verificación: exactamente 2 tests en ROJO (capacidadSprint=0 y tarifaUSD negativa).

---

## TASK 4 — Fix de calculos.ts (GREEN)

Modificar el guard de calcularInversionHito de:
```
if (capacidadSprint <= 0 || storyPoints <= 0)
```
a:
```
if (capacidadSprint <= 0 || storyPoints <= 0 || tarifaHoraUSD <= 0)
```

Verificación: npx vitest run → 0 failures en calculos.test.ts.

---

## TASK 5 — Fixtures y tests para parse-presupuesto-md.ts

Paso A: Crear fixture presupuesto-simple.md
Paso B: Crear fixture presupuesto-incompleto.md
Paso C: Crear src/__tests__/lib/utils/parse-presupuesto-md.test.ts

Verificación: npx vitest run → todos los tests en verde.

---

## VERIFICACIÓN FINAL

npx vitest run → 0 failures:
- id.test.ts → 3 passed
- calculos.test.ts → 10 passed
- parse-presupuesto-md.test.ts → 10 passed

---

## LO QUE NO FORMA PARTE DE ESTE PLAN

- E1: export-pdf.ts sin guard SSR
- E5: falta import 'server-only'
- E6: posibles forwardRef / Context.Provider en componentes UI
- E7: falta error.tsx en /builder y /from-md
```

## Relacionado

- [[sdd-presupuesto-generator]] — SDD TDD para este proyecto
- [[sdd]] — Spec Driven Development
