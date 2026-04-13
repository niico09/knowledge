# Compaction Hierarchy

## Definición

**Compaction hierarchy** es un sistema ordenado de estrategias para reducir el contexto cuando se acerca al límite,starting desde la más barata hasta la más cara.

En lugar de un solo mecanismo de compaction (ej: summarization), hay una jerarquía donde cada nivel se intenta antes de escalar al siguiente.

## La Jerarquía (cheapest → most expensive)

```
┌─────────────────────────────────────────────┐
│  1. Microcompact (costo ~0)                  │
│     Cached references para tools repetidos   │
├─────────────────────────────────────────────┤
│  2. Snip Compact (costo ~0, lossy)          │
│     Remueve mensajes del inicio              │
├─────────────────────────────────────────────┤
│  3. Auto Compact (costo = 1 model call)     │
│     Summarization del conversation history   │
├─────────────────────────────────────────────┤
│  4. Context Collapse (costo alto, multi-fase)│
│     Staged compression (feature flag)        │
└─────────────────────────────────────────────┘
```

## Principio Fundamental

> *"Pay para expensive compaction solo cuando cheap compaction fails."*

La mayoría de los harnesses que implementan compaction saltan directo a summarization. Microcompact y Snip manejan un alto porcentaje de casos con cero model calls.

## Protected Tail

Cuando compaction corre, los mensajes recientes (**protected tail**) nunca se resumen:

```
Conversation:
[Msg 1] [Msg 2] [Msg 3] ... [Msg N-3] [Msg N-2] [Msg N-1] [Msg N]
                    ↑
            Protected tail (últimos N mensajes)
```

El modelo mantiene full fidelity en las últimas exchanges. Puede seguir su plan actual sin perder track de lo que acaba de hacer.

## Referencias

- [[microcompact]]
- [[snip-compact]]
- [[auto-compact]]
- [[context-collapse]]
