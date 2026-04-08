---
title: SDD — presupuesto-generator: Cobertura de tests para lógica de negocio crítica
created: 2026-03-24
updated: 2026-03-24
tags: [SDD, TDD, Next.js, React19, Vitest, presupuesto-generator]
sources:
  - "Proceso de Desarrollo con IA — Guía Práctica"
status: synthesized
last_lint: 2026-04-07
---

# SDD — presupuesto-generator: Cobertura de tests para lógica de negocio crítica

> **Proyecto:** `presupuesto-generator` (Next.js 15 + React 19 + TypeScript)
> **Nivel SDD:** Nivel 1 — Spec-First
> **Harness activo:** `react19-modern-conventions`, `rsc-client-boundaries`, `rsc-and-client-architecture`, `nextjs-error-boundaries`, `nextjs15-data-fetching`, `server-actions-security`

## Spec: El QUÉ

El generador de presupuestos tiene lógica de negocio crítica sin cobertura de tests. Tres módulos centrales pueden producir resultados incorrectos silenciosamente: el motor de cálculo financiero, el generador de identificadores únicos, y el parser de documentos Markdown.

**Límites:**
- Dentro: `calculos.ts`, `generateId()`, `parse-presupuesto-md.ts`
- Fuera: componentes de UI, export PDF, rutas de Next.js, store de Zustand

## Plan: El CÓMO

- **Test runner:** Vitest
- **generateId()** debe extraerse del store a `src/lib/utils/id.ts`
- La corrección de `calculos.ts` se implementa DESPUÉS de escribir los tests en rojo (TDD estricto)
- Fixtures de MD van en `src/__tests__/fixtures/*.md`

## Tasks

### Task 1 — Setup del entorno de testing

Crear `vitest.config.ts` con `environment: "node"`, globals, include y alias `@/` → `./src`.

### Task 2 — Extraer y testear generateId()

Crear `src/lib/utils/id.ts` con `crypto.randomUUID()`. Modificar store para importar desde ahí.

### Task 3 — Tests RED para calculos.ts (sin tocar el módulo)

Escribir tests que documentan los bugs reales:
- `calcularInversionHito(20, 0, 50)` → NaN (divide por cero)
- `calcularInversionHito(20, 10, -50)` → sin guard defensivo

### Task 4 — Fix de calculos.ts (GREEN)

```typescript
if (capacidadSprint <= 0 || storyPoints <= 0 || tarifaHoraUSD <= 0) {
  return { sprints: 0, inversionUSD: 0 };
}
```

### Task 5 — Fixtures y tests para parse-presupuesto-md.ts

Crear fixtures y tests que documentan el comportamiento del parser.

## Criterio de done

`npx vitest run --coverage` con 100% de cobertura en `calculos.ts` e `id.ts`, y >80% en `parse-presupuesto-md.ts`.

## Relacionado

- [[sdd]] — Spec Driven Development
- [[proceso-desarrollo-ia]] — Proceso SDD completo
