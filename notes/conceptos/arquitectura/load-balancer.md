---
name: load-balancer
description: Load Balancer — distribuye tráfico entre instancias de servidor sin lógica de aplicación
type: concepto
tags: [arquitectura, backend, networking, infrastructure]
---

# Load Balancer

## Concepto

Componente de infraestructura que distribuye tráfico entre múltiples instancias de servidor. Solo se preocupa de entregar requests de forma eficiente, sin analizar el contenido.

**Capa**: L4 (TCP) o L7 (HTTP)

## Productos

| Tipo | Opciones |
|------|----------|
| Open Source | NGINX, HAProxy, Envoy |
| Cloud Gestionados | AWS ALB/NLB, GCP Cloud LB, Azure Load Balancer |
| Hardware | F5, Citrix ADC |

## Cuando aplicar (triggers)

- Múltiples instancias del mismo servicio
- Necesidad de failover automático
- Health checks de servidor
- Scaling horizontal

## Decision Tree

```
¿Necesitas lógica de negocio en el tráfico?
├── NO → ¿Solo distribuir?
│   └── SÍ → Load Balancer
└── SÍ → API Gateway puede ser mejor punto de entrada
```

## Tipos de Balanceo

| Tipo | Capa | Routing basado en |
|------|------|-------------------|
| L4 | TCP | IP + puerto |
| L7 | HTTP | Contenido del request (headers, path) |

## Trade-offs

| Aspecto | Impacto |
|---------|---------|
| Latencia | ~1-2ms overhead (mínimo) |
| Complejidad | Baja |
| Costo | Bajo-medio |
| Vendor Lock-in | Bajo |
| State | Generalmente stateless (excepto sticky sessions) |

## Errores comunes

1. **Single LB sin HA** — si cae, todo cae
2. **Ignorar health checks** — tráfico va a instancias down
3. **Sticky sessions sin entender implicaciones** — rompe horizontal scaling
4. **Sobre-engineering** — un LB simple puede ser suficiente

## Escenarios reales

_Llenar con casos de tu propio desarrollo cuando aparezcan._

## Preguntas de diagnóstico

- ¿Solo necesitas distribuir tráfico o también proteger/transformar?
- ¿L4 o L7? (¿necesitas inspeccionar contenido HTTP?)
- ¿Cuántas instancias tienes ahora? ¿Scalean?
- ¿Necesitas SSL termination en el LB o en los servicios?

## Conceptos relacionados

- [[api-gateway]] — tiene lógica de aplicación, va "antes" en la cadena
- [[arquitectura-index]] — visión general de patrones de arquitectura
- [[service-mesh]] — análogo pero para comunicación interna entre servicios

## Fuente

Basado en [[ByteByteGo EP208]] — Load Balancer vs API Gateway
