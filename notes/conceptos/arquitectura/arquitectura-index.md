---
name: arquitectura-index
description: Índice de conceptos de arquitectura de software — networking, APIs y patrones de comunicación
type: concepto
tags: [arquitectura, index]
status: synthesized
sources: []
last_lint: 2026-04-07
---

# Arquitectura — Índice

Documentación de patrones y componentes de arquitectura de infraestructura y networking.

## Networking & Infraestructura

| Concepto | Descripción | Madurez |
|----------|-------------|---------|
| [[load-balancer]] | Distribución de tráfico sin lógica de aplicación | Seed |
| [[api-gateway]] | Orquestación, auth, rate limiting, transformación | Seed |
| [[service-mesh]] | mTLS y observabilidad entre servicios internos | - |

## Patrones de Arquitectura

| Concepto | Descripción | Estado |
|----------|-------------|--------|
| [[patron-bff]] | Backend for Frontend — API gateway especializado por cliente | - |

## Arquitectura de Referencia

```
Internet
    │
    ▼
CDN / DDoS Protection (Cloudflare, Fastly)
    │
    ▼
API Gateway ──► Auth, Rate Limit, Logs
    │
    ├──► Load Balancer ──► Service A (N instancias)
    ├──► Load Balancer ──► Service B (N instancias)
    └──► Load Balancer ──► Service C (N instancias)
                │
                ▼
            Service Mesh ──► mTLS, retries, circuit breaking entre servicios
```

## Como usar este índice

1. **Decisión inicial**: [[load-balancer]] vs [[api-gateway]]
2. **Caso especializado**: [[patron-bff]] cuando tienes múltiples clientes distintos
3. **Comunicación interna**: [[service-mesh]] cuando necesitas observabilidad entre servicios

## Estado de documentación

- Los conceptos marcados como "Seed" tienen estructura básica y se expanden con casos reales
- Los que tienen "-" aún no están documentados

## Fuentes

- [[ByteByteGo EP208]] — Load Balancer vs API Gateway (fuente de los conceptos seed)
