# RLM (Recursive Language Model)

## Definición

Arquitectura de sistema multi-agente propuesta por Zhang et al. (2025) donde un orquestador fuerte descompone tareas y hace llamadas repetidas a un worker model a través de un entorno REPL.

## Componentes

- **Orquestador**: Modelo fuerte (e.g., Claude Sonnet 4) que descompone la tarea, envía queries targeting al worker, y agrega resultados
- **Worker**: Modelo que recibe queries específicas + documento raw, responde con análisis/verificación/extracción
- **REPL**: Entorno donde el worker ejecuta operaciones y retorna outputs

## El problema que resuelve RLM

Modelos con long context management fuerte (e.g., Claude) pero son menos eficientes que LLMs tradicionales y usan significativamente más tokens. Además, el worker solo ve lo que el orquestador explícitamente le pasa.

## El problema de RLM (token inefficiency)

El orquestador acumula reasoning trajectory rico a través de muchas llamadas: hipótesis probadas, pasajes identificados, dead ends eliminados, cross-references descubiertas. Ese contexto acumulado podría ayudar al worker, pero pasarlo todo como texto infla costos. El worker termina con vista narrow mientras el entendimiento broad del orquestador queda sin usar.

## Relación con Latent Briefing

[[latent-briefing]] fue evaluado usando RLM como arquitectura base, con Claude Sonnet 4 como orquestador y Qwen3-14B como worker.

## Referencia

- Zhang et al., 2025 — arXiv:2512.24601
