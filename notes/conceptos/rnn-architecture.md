---
name: rnn-architecture
description: Arquitectura RNN — vanishing gradients, LSTM, GRU, y el compromiso con Transformers
tags: [ai, ml, nlp, rnn, sequence-modeling, lstm, gru]
created: 2026-04-22
---

# RNN: Redes Neuronales Recurrentes

## Problema: Dependencias de Largo Alcance

```
Secuencia: "El gato negro saltó sobre la valla"

RNN procesa secuencialmente:
Step 1: "El" → h1
Step 2: h1 + "gato" → h2 (info de "El" ya diluida)
...
Step 8: h7 + "valla" → h8 (olvido completo de "gato")

→ Long-range dependency problem
→ Vanishing gradients
→ Sequential processing (sin paralelismo)
```

## LSTM (Long Short-Term Memory)

**Solución:** Celda con puertas (gates) que controlan qué olvidar y qué recordar.

```
Arquitectura LSTM:

┌─────────────────────────────────────────────────────────┐
│                    CELDA LSTM                          │
│                                                         │
│  h_{t-1} ──┐                                             │
│            │                                             │
│            ▼                                             │
│  ┌─────────────────┐                                     │
│  │  Forget Gate    │ → qué discard del cell state        │
│  │  σ(W_f · [h_{t-1}, x_t])                            │
│  └────────┬────────┘                                     │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │   Input Gate    │ → qué nueva info store             │
│  │  σ(W_i · [h_{t-1}, x_t])                            │
│  └────────┬────────┘                                     │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │  Cell State     │ → memoria de largo plazo            │
│  │  C_t = f_t*C    │
│  │    + i_t*~C     │
│  └────────┬────────┘                                     │
│           │                                              │
│           ▼                                              │
│  ┌─────────────────┐                                     │
│  │  Output Gate    │ → qué parte del cell state output  │
│  │  σ(W_o · [h_{t-1}, x_t])                            │
│  └────────┬────────┘                                     │
│           │                                              │
│           ▼                                              │
│  h_t = o_t * tanh(C_t)                                  │
└─────────────────────────────────────────────────────────┘
```

### Puertas LSTM

| Puerta | Función | Ecuación |
|---------|---------|----------|
| **Forget** | Qué descartar | `f_t = σ(W_f·[h_{t-1}, x_t])` |
| **Input** | Qué nueva info agregar | `i_t = σ(W_i·[h_{t-1}, x_t])` |
| **Output** | Qué output | `o_t = σ(W_o·[h_{t-1}, x_t])` |

### Cell State

```
C_t = f_t * C_{t-1} + i_t * ~C_t

~C_t = tanh(W_c·[h_{t-1}, x_t])
```

## GRU (Gated Recurrent Unit)

Variante más simple que LSTM (2 puertas en vez de 3):

```
z_t = σ(W_z·[h_{t-1}, x_t])      # Update gate
r_t = σ(W_r·[h_{t-1}, x_t])      # Reset gate

h_t = (1-z_t)*h_{t-1} + z_t*~h_t
~h_t = tanh(W·[r_t*h_{t-1}, x_t])
```

## Comparación RNN vs LSTM vs Transformer

| Aspecto | RNN | LSTM/GRU | Transformer |
|---------|-----|----------|-------------|
| **Complejidad** | O(L) | O(L) | O(L²) |
| **Paralelismo** | Bajo | Bajo | Alto |
| **Long-range deps** | Malas | Mejor | Excelente |
| **Memory** | Fija (h_t) | Fija (C_t) | Creciente (attention) |
| **Throughput** | Medio | Medio | Bajo (O(L²)) |

## Trade-off Fundamental

```
RNN:        Memoria FIJA → O(L) pero no escala con contexto
Transformer: Memoria CRECE → O(L²) pero retrieval perfecto

→ Memory Caching busca el medio: O(N·L) con N = segmentos cacheados
```

## Referencias

- "Long Short-Term Memory" (Hochreiter & Schmidhuber, 1997)
- "Learning Phrase Representations using RNN Encoder-Decoder for Statistical Machine Translation" (Cho et al., 2014) — GRU
