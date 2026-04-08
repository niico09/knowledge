---
title: Skills que se auto-mejoran — el problema real y cómo resolverlo
created: 2026-03-25
updated: 2026-03-25
tags: [Skills, SelfImprovement, SDD, FeedbackLoop]
sources:
  - "Debate propio basado en cognee-skills"
status: synthesized
last_lint: 2026-04-07
---

# Skills que se auto-mejoran: el problema real y cómo resolverlo

## El problema que el post identifica (y el que no menciona)

Los skills son archivos estáticos en un entorno que cambia constantemente. Pero hay un problema más fundamental: **los skills no tienen contrato de éxito definido**. Sin eso, ningún loop de mejora puede arrancar.

## El prerequisito: el contrato del skill

**Capa 1 — Corrección funcional**
¿El resultado hace lo que se esperaba? Tests E2E.

**Capa 2 — Corrección de calidad**
¿Cumple las métricas del skill? Script verificable post-ejecución.

**Capa 3 — Corrección intencional**
¿El agente siguió el approach que el skill propone? Requiere un LLM judge.

## El checklist de post-ejecución

```markdown
## Post-execution checklist
- [ ] Correr: `mvn test` — todos los tests pasan
- [ ] Correr: `./scripts/quality-check.sh` — sin violaciones
- [ ] Reportar: cambios en formato structured

Si algún check falla, documentalo en SKILL_FAILURE.md con el contexto.
```

## SKILL_FAILURE.md: el formato de transporte

```javascript
tonk-tools/
  failures/
    java-spring-refactor/
      2026-03-25-14-30.md
    code-review/
      2026-03-20-11-00.md
```

## El loop completo

```
Proyecto cliente
  → skill corre con checklist de post-ejecución
  → Capas 1, 2, 3 de verificación
  → Si hay fallo: escribe SKILL_FAILURE.md en tonk-tools/failures/
        ↓
tonk-tools
  → LLM judge: {intent_match, failed_instruction, antipatterns, confidence}
  → Si confidence ≥ 0.7: skill-creator propone enmienda
  → PR con la enmienda para revisión humana
  → Merge o rollback — historial queda en git
```

## El LLM judge

Prompt de input:
```
Sos un evaluador de skill execution.
SKILL INTENT: [extracto del SKILL.md]
CÓDIGO ORIGINAL: [diff before]
CÓDIGO REFACTORIZADO: [diff after]
QUALITY CHECK: [output del script]
E2E RESULT: PASS

Output en JSON:
{"intent_match": "yes|partial|no", "failed_instruction": "...", "antipatterns": [...], "confidence": 0-1}
```

Solo actuar cuando `confidence ≥ 0.7`.

## Los tres gaps que el post no resuelve

1. **Sin contrato, el loop arranca ciego** — la especificación es prerequisito
2. **El problema de distribución en setups multi-repo** — SKILL_FAILURE.md auto-contenido
3. **Evaluate necesita métricas objetivas, no solo el judge** — E2E + quality checks como base

## Relacionado

- [[sdd]] — Spec Driven Development
- [[skill-anatomia]] — Anatomía de SKILL.md
- [[asset-generator-v3]] — Asset Generator
