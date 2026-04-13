# KV Cache

## Definición

Key-Value cache. Mecanismo de memorización en transformers que almacena los estados de atención (keys y values) de tokens previamente procesados para evitar recomputación en inferencia autoregresiva.

## Contexto

En generación autoregresiva, cada nuevo token necesita attend a todos los tokens anteriores. En lugar de recomputar attention para toda la secuencia en cada paso, se cachean los K y V de tokens previos. Solo el nuevo token se procesa, y sus K/V se append al cache.

## Relevancia en este contexto

- **Latent Briefing** opera directamente sobre el KV cache del worker model para comprimirlo sin convertir a texto
- **KV prefix caching** reutiliza 90%+ de representaciones entre llamadas de agente
