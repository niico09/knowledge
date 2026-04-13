---
title: Service Mesh
description: Comunicación interna entre servicios con mTLS y observabilidad
tags: [arquitectura, microservices, observabilidad]
sources:
  - ByteByteGo EP208
status: stub
---

# Service Mesh

Capa de infraestructura para comunicación interna entre servicios. Provee:
- **mTLS** — comunicación cifrada entre servicios
- **Observabilidad** — métricas, tracing, logging entre servicios
- **Circuit breaking** — tolerancia a fallos

## Relacionado

- [[api-gateway]] — Entry point externo
- [[load-balancer]] — Distribución de tráfico
- [[arquitectura-index]] — Vista general de patrones
