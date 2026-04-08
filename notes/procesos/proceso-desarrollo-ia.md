---
title: Proceso de Desarrollo con IA — Guía Práctica
created: 2026-04-04
updated: 2026-04-04
tags: [SDD, SpecDrivenDevelopment, AIAgents, Devin, Jira, AgentHarness]
sources:
  - "Notion → migrado 2026-04-04"
status: synthesized
last_lint: 2026-04-07
---

# Proceso de Desarrollo con IA — Guía Práctica

> **Origen:** Borrador propio refinado a partir del post de Julián de Angelis sobre Spec Driven Development
> **Nivel SDD:** Este proceso implementa **SDD Nivel 1 — Spec-First**: la spec se crea antes de codificar y puede descartarse al entregar.

## Principio Rector

> *"Developers need to shift from 'describe the code I want' to 'describe the behavior I need.'"*

Los agentes de IA no fallan porque el modelo sea débil. Fallan porque las instrucciones son ambiguas. Este proceso define cómo estructurar el trabajo para que el agente tenga todo lo que necesita antes de escribir una línea de código.

---

## Cuándo aplicar este proceso

**Aplicar cuando:**
- La feature toca múltiples servicios o dominios
- Hay lógica de negocio no obvia para el agente
- Cambios multi-archivo o en repos legacy
- El impacto de un error es alto

**No aplicar cuando:**
- Bug fix simple o puntual
- Config update
- Cambio de una línea o refactor mínimo

---

## Contexto Base — Agent Harness

SDD solo no alcanza. Para que el agente construya correctamente en nuestro stack, necesita el contexto de la organización. Eso es el **Agent Harness**.

| Componente | Qué hace |
|------------|---------|
| **Rules** | Estándares de código, convenciones, patrones prohibidos |
| **Skills** | Conocimiento de dominio empaquetado |
| **MCPs** | Conexión a sistemas internos: base de datos, APIs internas, herramientas de infraestructura |

El harness debe estar configurado **antes de arrancar cualquier paso del proceso**.

---

## Los 3 Niveles de Madurez SDD

### Nivel 1 — Spec-First

Spec antes de codificar, descartada al entregar. Elimina la ambigüedad para ese ciclo. **Es donde estamos hoy.**

### Nivel 2 — Spec-Anchored

La spec vive en el repo y evoluciona junto al código. Se convierte en documentación viva para el equipo.

> El Plan en Markdown adjunto al ticket de Jira es el primer paso natural hacia Nivel 2.

### Nivel 3 — Spec-as-Source

La spec es el artefacto primario. Se edita la spec y el código se regenera para coincidir.

---

## Métricas SDD

### Redirecciones (Scope Creep evitado)

| Tipo | Señal | Umbral OK |
|------|-------|-----------|
| Redirección menor | Agente pregunta "debería también..." | < 1 por task |
| Redirección mayor | Agente implementa algo no especificado | 0 por task |
| Redirección bloqueante | Se requiere volver a especificar | < 5% de tasks |

### Ciclos (Cycles to Accept)

| Evento | Cuenta como |
|--------|------------|
| Primera entrega | Ciclo 1 |
| Request changes | +1 ciclo |
| Conversation restart | +1 ciclo |

**Benchmarks:**
- SDD Nivel 1: ~2.5 ciclos promedio
- SDD Nivel 2: ~1.8 ciclos promedio
- SDD Nivel 3: ~1.2 ciclos promedio

### Cobertura (Edge Cases Specified)

```javascript
Cobertura = (Edge cases en spec ∩ encontrados en prod) / (edge cases encontrados en prod)
```

| Nivel | Target | Ejemplo |
|-------|--------|---------|
| Bueno | 60-70% | Los edge cases obvios cubiertos |
| Excelente | 80%+ | Casos borde no evidentes también |

---

## Anti-patrones SDD

### Anti-patrón 1 — Spec vaga (Ambiguous Spec)

- **Qué parece:** "Una API que gestione usuarios"
- **Cómo detectarlo:** 3+ preguntas de clarificación antes de empezar
- **Cómo corregir:** Aplicar Given/When/Then hasta que no haya ambigüedad

### Anti-patrón 2 — Plan sin tasks (Big-Bang Plan)

- **Qué parece:** "Implementar auth con JWT" como una sola task
- **Cómo detectarlo:** La task toma +3 horas o múltiples sesiones
- **Cómo corregir:** Dividir en: schema DB, endpoints, middleware, tests, docs

### Anti-patrón 3 — Tasks sin output verificable (Blackbox Tasks)

- **Qué parece:** "Investigar patrones de caching"
- **Cómo detectarlo:** No hay criterio de aceptación claro
- **Cómo corregir:** Terminar con: documento/decisión + código generado

### Anti-patrón 4 — Spec que es código (Spec-is-Code)

- **Qué parece:** La spec dice "usar Spring Data JPA" en lugar de describir comportamiento
- **Cómo detectarlo:** La spec contiene nombres de clases, librerías o sintaxis
- **Cómo corregir:** Reescribir en lenguaje funcional: "los datos se persisten automáticamente"

### Anti-patrón 5 — Plan que ignora constraints (Ignorar Vinculación)

- **Qué parece:** Plan sin mencionar performance, seguridad o deuda técnica existente
- **Cómo detectarlo:** Reviews donde el agente viola constraints conocidas
- **Cómo corregir:** Incluir sección "Constraints conocidas" en el Plan

---

## SDD + TDD — Given/When/Then como generador de tests

El formato Given/When/Then mapea directo a estructura de test:

```javascript
Given un usuario no autenticado,
When hace GET /dashboard,
Then recibe 401 Unauthorized
```

Se convierte en:

```python
def test_get_dashboard_without_auth_returns_401():
    # Given
    user = None
    # When
    response = client.get("/dashboard", user=user)
    # Then
    assert response.status_code == 401
```

---

## Paso 1 — Spec: La Historia en Jira (el QUÉ)

Cada tarea debe nacer como una historia en Jira que describa el comportamiento esperado, **no la implementación**.

**La historia debe incluir:**
- Qué debe desarrollarse y cuál es su propósito
- Con qué servicios o sistemas se comunica (a nivel lógico, no técnico)
- Los límites del alcance
- Los criterios de aceptación en formato **Given/When/Then**

**Formato Given/When/Then:**
```javascript
Given [contexto o estado inicial]
When [acción del usuario o del sistema]
Then [resultado esperado]
```

**Ejemplo — Alta de un ítem desde el backoffice:**
```javascript
Given un administrador autenticado en el backoffice interno
When envía una solicitud para crear un nuevo ítem con datos válidos
Then el ítem es persistido y se retorna confirmación al cliente

Given un administrador que intenta crear un ítem ya existente
When envía la solicitud con el mismo identificador
Then el sistema retorna un error indicando que el recurso ya existe (operación idempotente)

Given un administrador autenticado
When la comunicación con la base de datos se interrumpe durante la operación
Then el sistema retorna un error controlado sin persistir estado inconsistente
```

---

## Paso 2 — Plan: El Adjunto Técnico en Markdown (el CÓMO)

Una vez definida la historia, se le adjunta un documento técnico **en formato Markdown**. Este documento traduce el "qué" funcional al "cómo" técnico.

**El Plan debe incluir:**
- Proyectos y módulos involucrados (con paths relevantes)
- Decisiones de arquitectura: patrones a seguir, convenciones del codebase
- Modelos de datos y contratos de API
- Librerías y versiones a utilizar
- Rules, Skills y MCPs que el agente debe usar
- Restricciones de performance o seguridad relevantes
- Definición de límites: qué cambia y qué no debe tocarse

---

## Paso 3 — Tasks: Los Pasos de Ejecución

El Plan se divide en tareas pequeñas, **ordenadas y autocontenidas**. Cada tarea debe ser completable en una sola sesión del agente.

**Criterios de una buena task:**
- El agente no necesita buscar contexto adicional
- Produce un cambio atómico y testeable
- Si requiere que el agente adivine algo, no está lista

**¿Cuántas tasks necesito?** Una buena heurística: **una task por decisión técnica separable**. Entre 3 y 6 tasks cubre la mayoría de features estándar.

**¿Cuándo está lista una task?** Cada task está completa cuando produce un cambio verificable con al menos una de:
- Un test (unitario o de integración) que cubre el comportamiento definido
- El cambio puede validarse manualmente contra los criterios Given/When/Then

**Ejemplo — Tasks para el CREATE de un ítem:**
```javascript
Task 1 — Definición de la interfaz
  Crear el endpoint POST /items con su contrato de request/response.
  Validaciones: campos requeridos, tipos, formato.

Task 2 — Clases afectadas
  Identificar y actualizar ItemController, ItemService e ItemRepository.
  Seguir el patrón existente en el módulo de productos.

Task 3 — Alta en base de datos
  Implementar la persistencia. Manejar:
  - Caso feliz: ítem nuevo → persistir y retornar 201
  - Prueba de borde: ítem ya existe → retornar 409 (idempotencia)
  - Prueba de borde: falla de conexión con BD → retornar 503 sin estado inconsistente

Task 4 — Respuesta al cliente
  Formatear y retornar la respuesta según contrato definido en Task 1.
  Incluir tests de integración que cubran los tres escenarios.
```

---

## Paso 4 — Ejecución y Verificación Final

Con el harness configurado, el plan definido y las tasks divididas, el agente ejecuta **una task a la vez**.

**Protocolo de ejecución:**
- Pasar al agente: la task + el Plan técnico como contexto
- El agente no debe necesitar buscar contexto adicional
- Revisar el output contra los Given/When/Then antes de pasar a la siguiente task

**Qué hacer cuando el agente se desvía:**

| Síntoma | Causa probable | Acción |
|---------|----------------|--------|
| Implementó algo distinto a lo pedido | Ambigüedad en la task | Corregir la descripción de la task, re-ejecutar |
| Tocó archivos fuera del alcance | Límites mal definidos en el Plan | Agregar sección "Límites" al Plan |
| Usó una librería diferente a la especificada | El Plan no era suficientemente explícito | Agregar versiones y librerías exactas |
| El output no compila / tiene errores obvios | La task era demasiado grande | Dividir en tasks más pequeñas |

> Si el agente se desvía en más del 30% de las tasks de un plan, el problema está en el Plan, no en el agente.

---

## Handoff Spec → Devin

**Paso 1 — Verificar completitud antes de entregar**
- [ ] La historia en Jira tiene Given/When/Then completos
- [ ] El Plan técnico está adjunto y referenciado
- [ ] Las tasks están divididas y ordenadas
- [ ] El Agent Harness está configurado

**Paso 2 — Entregar a Devin**
- Pasar la task actual + Plan técnico como contexto
- NO agregar instrucciones vagas como "implementá lo que haga falta"

**Paso 3 — Criteria para aceptar output de Devin**
- [ ] Compila sin errores
- [ ] Pasa los tests derivados de Given/When/Then
- [ ] No modificó archivos fuera del alcance
- [ ] Code review approval

---

## Tradeoffs SDD

SDD **no es gratis**. El ciclo spec-plan-task consume 2-3x más tokens que el prompting directo. No aplica para cambios pequeños, bug fixes o config updates.

Brilla cuando la feature es lo suficientemente compleja como para que la ambigüedad cause que el agente se desvíe: cambios multi-archivo, features que tocan múltiples dominios, repos legacy, o lógica de negocio no obvia.

---

## Resumen del Flujo

```
╔══════════════════════════════════════════════════════════════╗
║              CONTEXTO BASE — Agent Harness                   ║
║           Rules + Skills + MCPs  (siempre activo)            ║
╠══════════════╦═══════════════════╦═══════════════════════════╣
║   Paso 1     ║     Paso 2        ║   Pasos 3 y 4             ║
║   SPEC       ║     PLAN          ║   TASKS + EJECUCIÓN       ║
║   Jira       ║   Adjunto MD      ║   Tasks atómicas          ║
║   QUÉ        ║   CÓMO            ║   Una a la vez            ║
╚══════════════╩═══════════════════╩═══════════════════════════╝
```

---

## Relacionado

- [[sdd]] — Spec Driven Development (genérico)
- [[skill-anatomia]] — Anatomía de SKILL.md (Agent Harness skills)
- [[rules-idoneas]] — Rules Idóneas en Claude Code (Agent Harness rules)
