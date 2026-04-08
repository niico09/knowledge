---
name: api-gateway
description: API Gateway — proxy inteligente que orquesta, transforma y protege el tráfico entre clientes y servicios backend
type: concepto
tags: [arquitectura, backend, networking, microservices]
status: synthesized
sources: []
last_lint: 2026-04-07
---

# API Gateway

## Concepto

Punto de entrada único que maneja lógica de negocio en el tráfico: autenticación, rate limiting, transformación de requests/responses, agregación de APIs y observabilidad.

**Capa**: L7 (aplicación)

## Productos

| Tipo | Opciones |
|------|----------|
| Open Source | Kong, APISIX, Tyk, Envoy |
| Cloud Gestionados | AWS API Gateway, Apigee, Azure API Management |
| Embedded | Express Gateway, Hocuspocus |

## Cuando aplicar (triggers)

- Cliente necesita llamar múltiples servicios diferentes
- Requeris autenticación/autorización centralizada
- Necesitas rate limiting por cliente/endpoint
- Transformación de payload entre formato cliente y formato interno
- Logs centralizados de tráfico de API

## Decision Tree

```
¿Necesitas lógica de negocio en el tráfico?
├── NO → Load Balancer puede ser suficiente
└── SÍ → ¿Rate limiting, auth, transformación?
    └── SÍ → API Gateway
```

## Trade-offs

| Aspecto | Impacto |
|---------|---------|
| Latencia | +5-15ms overhead |
| Complejidad | Alta — configuración y mantenimiento |
| Costo | Medio-alto (especialmente cloud gestionado) |
| Vendor Lock-in | Alto si usas cloud gestionado |
| Single Point of Failure | Sí — diseñar HA desde el inicio |

## Errores comunes

1. **Poner API Gateway sin HA** — se convierte en bottleneck
2. **Usar API Gateway para todo** — cuando un LB simple basta, añade complejidad
3. **Confundir con Service Mesh** — mesh opera entre servicios, no entre cliente y servicios
4. **Ignorar rate limiting en servicios** — gateway no es suficiente si hay bugs en código

## Escenarios reales

_Llenar con casos de tu propio desarrollo cuando aparezcan._

## Preguntas de diagnóstico

- ¿Cuántos servicios diferentes necesita el cliente llamar?
- ¿Necesitas transformar el payload?
- ¿Quién configura las rutas — equipo platform o producto?
- ¿Cuál es la tolerancia a latencia extra?
- ¿Cloud gestionado o on-prem?

## Conceptos relacionados

- [[load-balancer]] — distribuye tráfico sin lógica de aplicación
- [[patron-bff]] — Backend for Frontend, variante especializada
- [[service-mesh]] — comunicación interna entre servicios
- [[arquitectura-index]] — visión general de patrones de arquitectura

## Fuente

Basado en [[ByteByteGo EP208]] — Load Balancer vs API Gateway
