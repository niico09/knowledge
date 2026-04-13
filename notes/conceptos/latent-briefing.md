# Latent Briefing

## Definición

Técnica de Ramp Labs para compartir "memoria" relevante entre agentes en sistemas multi-agente, operando directamente sobre el KV cache del modelo worker. El orquestador comprime su reasoning trajectory usando los attention patterns del worker como señal de relevancia.

## Origen

- **Paper:** Ramp Labs (Ben Geist et al.), abril 2026
- **Conferencia:** Post en X @RampLabs

## Idea core

En arquitecturas jerárquicas (orquestador → workers), el worker normalmente recibe solo (query + documento raw), perdiendo el contexto rico que el orquestador construyó. En vez de convertir ese contexto a texto (costoso, lento, perd 정보), se comprime el KV cache del worker a nivel de representación.

## Relación con otros conceptos

- [[kv-cache]] — el objeto que se comprime
- [[attention-matching]] — el framework base para la compresión
- [[rlm-recursive-language-model]] — la arquitectura de agente donde se aplica
