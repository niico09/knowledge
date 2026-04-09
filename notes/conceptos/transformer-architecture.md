---
name: transformer-architecture
description: Guía completa de Arquitectura Transformer - desde Atención hasta LLMs modernos
tags: [ai, ml, nlp, transformers, attention, llm]
created: 2026-04-08
---

# Arquitectura Transformer

## De RNN a Transformer

### Problema: RNN/LSTM

```
Secuencia: "El gato negro saltó sobre la valla"

RNN procesa secuencialmente:
Step 1: "El" → h1
Step 2: h1 + "gato" → h2 (info de "El" ya diluida)
...
Step 8: h7 + "valla" → h8 (olvido completo de "gato")

→ Long-range dependency problem (vanishing gradients)
→ Sequential processing (sin paralelismo)
```

### Solución: Parallel attention global

```
" El gato negro saltó sobre la valla "

Todos los tokens se miran simultáneamente:
"gato" puede ver directamente "saltó", "valla", incluso "El"
(no hay distancia en attention, solo relevancia)
```

## Componentes Fundamentales

### Tokenization
- Divide texto en tokens (palabras, sub-palabras, caracteres)
- Modelo solo trabaja con números
- "I love learning" → ["I", "love", "learning"]

### Embedding
- Convierte cada token en vector de números (embedding)
- Análogo a "huella digital" del palabra
- Palabras similares = vectores similares
- `embedding("happy")` ≈ `embedding("joyful")`,很远 de `embedding("car")`

### Positional Encoding

```python
# PE(pos, 2i)   = sin(pos / 10000^(2i/d_model))
# PE(pos, 2i+1) = cos(pos / 10000^(2i/d_model))

def positional_encoding(seq_len, d_model):
    PE = torch.zeros(seq_len, d_model)
    positions = torch.arange(0, seq_len).unsqueeze(1)
    div_term = torch.exp(torch.arange(0, d_model, 2) * -(math.log(10000.0) / d_model))
    PE[:, 0::2] = torch.sin(positions * div_term)
    PE[:, 1::2] = torch.cos(positions * div_term)
    return PE
```

**Propiedades:**
- Cada posición tiene encoding único
- Valores bounded [-1, 1], no explosion
- Distancias relaciones preservadas

## Attention Mechanism

### Las tres componentes (Q, K, V)

| Componente | Qué representa | Analogía |
|------------|-----------------|----------|
| **Query (Q)** | Qué busca este token | "Estoy buscando información sobre X" |
| **Key (K)** | Qué ofrece este token | "Yo tengo información sobre Y" |
| **Value (V)** | Información real del token | El contenido en sí |

### Proceso paso a paso

```python
# Input: Q, K, V — shape (batch, seq_len, d_model)

# 1. Attention scores: qué tan relevante es cada par de tokens
scores = Q @ K.transpose(-2, -1)  # (batch, seq_len, seq_len)

# 2. Scale: evita softmax saturado
scaled_scores = scores / math.sqrt(d_k)

# 3. Softmax → probabilidades [0,1] que suman 1
attn_weights = F.softmax(scaled_scores, dim=-1)

# 4. Weighted sum de Values
output = attn_weights @ V
```

### Ejemplo: "The cat sat on the mat because it was tired"

```
Word "it" attention weights:
- "cat": 0.847 ← altissimo (it refiere a cat)
- "mat": 0.023 ← muy bajo
- "because": 0.045
- "was": 0.032
```

### Multi-Head Attention

```
Concepto: múltiples "editores" en paralelo, cada uno focus en diferente relación

Input
  │
  ├──► Head 1 (subject-verb: "cat" ↔ "sat")
  ├──► Head 2 (adj-noun: "black" ↔ "cat")
  ├──► Head 3 (coreference: "it" ↔ "cat")
  └──► Head N (other relationships)
  │
  ▼
Concatenate → Linear projection
```

```python
class MultiHeadAttention(nn.Module):
    def __init__(self, d_model=768, num_heads=12):
        super().__init__()
        self.num_heads = num_heads
        self.d_k = d_model // num_heads  # 64 por head

        self.W_q = nn.Linear(d_model, d_model)
        self.W_k = nn.Linear(d_model, d_model)
        self.W_v = nn.Linear(d_model, d_model)
        self.W_o = nn.Linear(d_model, d_model)

    def forward(self, x):
        batch, seq_len, d_model = x.shape

        Q = self.W_q(x).view(batch, seq_len, self.num_heads, self.d_k).transpose(1, 2)
        K = self.W_k(x).view(batch, seq_len, self.num_heads, self.d_k).transpose(1, 2)
        V = self.W_v(x).view(batch, seq_len, self.num_heads, self.d_k).transpose(1, 2)

        scores = Q @ K.transpose(-2, -1) / math.sqrt(self.d_k)
        attn_weights = F.softmax(scores, dim=-1)
        context = attn_weights @ V

        context = context.transpose(1, 2).contiguous().view(batch, seq_len, d_model)
        return self.W_o(context)
```

## Feed-Forward Network

- Refinamiento individual por token
- `d_ff = 4 * d_model` (original)
- Pointwise: cada token independientemente
- ~2/3 de parámetros del transformer

```python
class FeedForward(nn.Module):
    def __init__(self, d_model=768, d_ff=3072):
        super().__init__()
        self.linear1 = nn.Linear(d_model, d_ff)
        self.linear2 = nn.Linear(d_ff, d_model)
        self.relu = nn.ReLU()

    def forward(self, x):
        return self.linear2(self.relu(self.linear1(x)))
```

## Layer Normalization

```python
class LayerNorm(nn.Module):
    def __init__(self, d_model, eps=1e-6):
        super().__init__()
        self.gamma = nn.Parameter(torch.ones(d_model))  # scale
        self.beta = nn.Parameter(torch.zeros(d_model))   # shift

    def forward(self, x):
        mean = x.mean(-1, keepdim=True)
        std = x.std(-1, keepdim=True)
        return self.gamma * (x - mean) / (std + eps) + self.beta
```

## Residual Connections

```
output = sublayer(input) + input
```

**Propósito:** Evita pérdida de información en capas profundas

## Encoder vs Decoder

### Encoder

```
Input: [I] [love] [learning]

Cada capa:
  ├── Self-Attention (bidirectional)
  │     └── cada token ve todos los otros
  ├── Residual + Norm
  ├── Feed-Forward
  └── Residual + Norm

Output: Representación contextual rica
  → Cada token "sabe" sobre toda la secuencia
```

### Decoder

```
Input: [<start>]

Genera un token a la vez:

Paso 1: [<start>]
  ├── Masked Self-Attention (solo ve anteriores)
  ├── Cross-Attention (mira output encoder)
  ├── FFN
  └── Linear + Softmax → "J'"

Paso 2: [<start>, J']
  → "adore"

Paso 3: [<start>, J', adore]
  → "apprendre"

...

Paso N:
  → [</end>] → stop
```

### Causal Masking

```
         start   J'    adore  appr
start      0     0      0      0
J'         1     0      0      0    ← máscara superior = no atender
adore      1     1      0      0
appr       1     1      1      0

0 = puede atender, 1 = masking
```

### Cross-Attention

```
┌─────────────────────────────────────────────────────┐
│                      ENCODER                         │
│  [I]──►Layer1──►...──►Layer6──► encoder_output     │
└─────────────────────────────────────────────────────┘
                              │
                              ▼ K, V
┌─────────────────────────────────────────────────────┐
│                      DECODER                         │
│  [J']──►Masked SA──►Cross-Attn──►FFN──► output    │
│                      ▲                               │
│                      └─────────── Q                 │
└─────────────────────────────────────────────────────┘

Q viene del decoder, K,V del encoder
Permite "preguntar" al encoder mientras genera
```

## Las 3 Variantes

| Variante | Attention | Genera | Ejemplo | Uso |
|----------|------------|--------|---------|-----|
| **Encoder-only** | Bidirectional | No | BERT | Clasificación, sentiment, QA |
| **Decoder-only** | Causal | Sí | GPT, Llama | Text generation, chatbots |
| **Encoder-Decoder** | Ambos | Sí | T5 | Traducción, summarization |

### Encoder-Only (BERT)
- Self-attention bidirectional completo
- [CLS] token para clasificación
- No puede generar, solo entender

### Decoder-Only (GPT)
- Solo atención causal (masked)
- Predicción下一个 token
- Arquitectura de la mayoría de LLMs modernos

### Encoder-Decoder (T5)
- Encoder procesa input
- Decoder genera output
- Cross-attention conecta ambos

## Positional Encoding: Evolución

### Sinusoidal (original Transformer)
- Matriz fija, no learnable
- Generaliza mal a secuencias más largas

### Learned Absolute Position
- Embedding tabla posición
- Problema: no extrapola a > training length

### Rotary Position Embedding (RoPE) - Llama, Falcon

```python
def rotate_half(x):
    x1 = x[..., :x.shape[-1] // 2]
    x2 = x[..., x.shape[-1] // 2:]
    return torch.cat([-x2, x1], dim=-1)

def apply_rotary_pos_emb(q, k, cos, sin):
    q = (q * cos) + (rotate_half(q) * sin)
    k = (k * cos) + (rotate_half(k) * sin)
    return q, k
```

**Ventajas:**
- Mejor length extrapolation
- Más eficiente computacionalmente
- Frequencies diferentes por dimensión

### ALiBi (Attention with Linear Biases)
- No positional encoding en embedding
- Bias lineal en attention scores: `score(i,j) -= |i-j| * m`
- Extrapolation a secuencias más largas

## Sampling Strategies

### Greedy
```python
next_token = argmax(logits)
```
Siempre el más probable. Problema: repetitivo.

### Temperature
```python
probs = F.softmax(logits / temperature, dim=-1)
```
- T=1.0: sin cambio
- T→0: greedy-like
- T→2: más random

### Top-K
```python
top_k_logits, top_k_indices = torch.topk(logits, 50)
probs = F.softmax(top_k_logits, dim=-1)
next_token = choice(top_k_indices, probs)
```
Mantiene solo los k más probables.

### Top-P (Nucleus)
```python
sorted_probs = torch.sort(probs, descending=True)
cumsum = torch.cumsum(sorted_probs, dim=-1)
mask = cumsum < 0.9  # incluir hasta 90% cumulativa
```
Mantiene tokens hasta acumulada ≥ p.

## Scaling Laws (Chinchilla, 2022)

```
L(D) = 8.74 × 10^(-0.077) × D^(-0.096) × T^(-0.092)

D = parámetros, T = tokens de training
```

**Conclusión:** Para mismo compute, óptimal ~20 tokens por parámetro.

## Optimizaciones Modernas

### Grouped Query Attention (GQA)
- Reduce KV heads (ej: 24 Q heads, 8 K/V heads)
- Menos memory inference
- Quality similar a MHA completo

### Flash Attention
- No materializa N×N matrix (O(N²) memory)
- Procesa en bloques (tiles)
- Usa SRAM fast
- ~3-4x speedup

## Innovations en FFN

### SwiGLU Activation (Llama 3)
```python
def swiglu(x):
    return F.silu(x) * x  # Swish: x * sigmoid(x)
```
Mejor performance en tareas de lenguaje.

### RMSNorm
```python
def rms_norm(x, weight, eps=1e-6):
    rms = torch.sqrt(x.pow(2).mean(-1, keepdim=True) + eps)
    return weight * x / rms
```
Más rápido que LayerNorm (sin shift/bias).

## Arquitectura Visual Completa

```
══════════════════════════════════════════════════════
                    TRANSFORMER
══════════════════════════════════════════════════════

INPUT: "I love learning" → "J'adore apprendre"

┌──────────────────────────────────────────────────────┐
│                   ENCODER STACK                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  [I] ─── embedding + positional encoding            │
│  [love]                                             │
│  [learning]                                         │
│       │                                             │
│       ▼                                             │
│  ┌──────────────────────────────────────────────┐   │
│  │                 LAYER 1                       │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │ Multi-Head Self-Attention (12 heads)  │  │   │
│  │  │  • Q, K, V projections                 │  │   │
│  │  │  • Scaled dot-product attention        │  │   │
│  │  │  • Todos tokens ven todos              │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │                          │                    │   │
│  │                          ▼ (residual + norm) │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │ Feed-Forward (3072 hidden)             │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │                          │                    │   │
│  └──────────────────────────────────────────────┘   │
│                            │                         │
│                            ▼ (× 6 capas)             │
│                                                      │
│  Output: Rich contextualized embeddings             │
└──────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────┐
│                   DECODER STACK                     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  [<start>]                                          │
│       │                                             │
│       ▼                                             │
│  ┌──────────────────────────────────────────────┐   │
│  │                 LAYER 1                       │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │ Masked Self-Attention (Causal)         │  │   │
│  │  │  • Solo ve tokens anteriores           │  │   │
│  │  │  • Future tokens masked                │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │                          │                    │   │
│  │                          ▼ (residual + norm) │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │ Cross-Attention                        │  │   │
│  │  │  • Q from decoder                      │  │   │
│  │  │  • K, V from encoder                   │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  │                          │                    │   │
│  │                          ▼ (residual + norm) │   │
│  │  ┌────────────────────────────────────────┐  │   │
│  │  │ Feed-Forward                           │  │   │
│  │  └────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                            │                         │
│                            ▼ (× 6 capas)             │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ Linear + Softmax → Next Token Probabilities  │   │
│  │  • 50,000 vocab scores                       │   │
│  │  • Sampling (temp/top-k/top-p)               │   │
│  └──────────────────────────────────────────────┘   │
│                            │                         │
│                     ┌──────┴──────┐                  │
│                     ▼             ▼                  │
│               [J']          [adjective?]             │
│                            │                         │
│                            ▼ (loop hasta <end>)      │
└──────────────────────────────────────────────────────┘
```

## Preguntas de Verificación

1. **¿Por qué attention es O(N²) en memory?**
   - N×N attention matrix, cada par de tokens tiene un score

2. **¿Qué diferencia hay entre cross-attention y self-attention?**
   - Cross: Q del decoder, K/V del encoder. Self: Q,K,V del mismo contexto

3. **¿Por qué necesitamos masking en decoder?**
   - Prevenir ver future tokens durante training (data leakage)

4. **¿Cómo RoPE logra length extrapolation?**
   - Rotación geométrica en espacio 2D, frecuencias diferentes por dimensión

5. **¿Cómo funciona causal masking?**
   - Matriz triangular superior = -inf → softmax → 0

6. **¿Por qué GPT no tiene cross-attention?**
   - Decoder-only no necesita encoder para generación autoregressive

7. **¿Qué problema resuelve GQA?**
   - Reduce KV heads → menos memory en inference sin perder calidad

8. **¿Por qué residual connections?**
   - Evita vanishing gradients, permite flujo de información directo

9. **¿Qué hace Layer Normalization?**
   - Normaliza media=0, std=1 por feature dimension, estabiliza training

10. **¿Cómo selecciona el decoder el siguiente token?**
    - Linear layer → logits → softmax → probabilidades → sampling

## Referencias

- "Attention Is All You Need" (Vaswani et al., 2017)
- "Language Models are Few-Shot Learners" (GPT-3)
- "Training Language Models to Follow Instructions with Human Feedback" (InstructGPT)
- "Chinchilla: Training Compute-Optimal Large Language Models" (Hoffmann et al., 2022)