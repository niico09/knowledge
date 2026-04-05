---
title: Paso 8 — Generación del Learning Path Personal
created: 2026-03-22
updated: 2026-03-22
tags: [NotebookLM, LearningPath, StudySystem]
sources:
  - "Workflow Overview — Los 7 Pasos"
---

# Paso 8 — Generación del Learning Path Personal

Paso complementario al workflow original, diseñado para el **learner autónomo**.

## El gap que resuelve

Los pasos 1-7 están pensados desde la perspectiva del **instructor**. Cuando usás el sistema como **learner autónomo**, llegás hasta el mapa de conocimiento pero sin respuesta a:
- ¿En qué orden aprendo esto?
- ¿Qué necesito saber antes de avanzar al siguiente tema?
- ¿Cómo sé que ya entendí suficiente para pasar?
- ¿Cuánto tiempo me va a llevar?

## Prerequisito

Tener el output del **Paso 2** (curriculum map con los 5 conceptos clave).

## Prompt principal

```javascript
Based on the curriculum map you generated, create a personal learning path
for someone studying this topic independently.

For each concept in the map:
1. Assign it to a week or phase
2. List the specific resources to read/watch that week
3. Define one concrete deliverable that proves understanding
4. List any prerequisite concepts that must be understood first
5. Estimate realistic time commitment in hours

At the end, add:
- A "Week 0" for any foundational prerequisites
- A final integration milestone that combines all concepts
- A list of 3 warning signs that indicate the learner should slow down
```

## Variante para temas técnicos (desarrollo de software)

```javascript
Based on the curriculum map, create a hands-on learning path for a developer.

Structure it as sprints of 1 week each. For each sprint:
1. One clear learning objective
2. Required reading/watching
3. One coding exercise that validates the objective
4. Common mistakes to avoid at this stage
5. Definition of Done

Mark which sprints must be completed before starting the next.
Identify which sprints can be done in parallel.
Finish with a capstone project that integrates all sprints.
```

## Output esperado

| Fase | Tema | Recursos | Entregable | Prerequisitos | Horas |
|------|------|---------|------------|---------------|-------|
| Semana 0 | Fundamentos previos | ... | ... | ninguno | ... |
| Semana 1 | Concepto 1 | Fuente A | Ejercicio concreto | Semana 0 | ... |
| Final | Integración | todos | Proyecto capstone | todas | ... |

## Relacionado

- [[workflow-7-pasos]] — Los 7 pasos originales
- [[guia-maestra-estudio]] — Sistema completo de estudio
