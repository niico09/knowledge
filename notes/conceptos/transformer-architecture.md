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

**Problema original:**
```
Standard attention: O(N²) memory
- Materializa N×N attention matrix completa
- 524K tokens × 524K tokens × 4 bytes = ~1TB para N=524K
- Imposible para context largo
```

**Solución: Block-wise processing**
```python
# No materializa matrix N×N
# Procesa en bloques que caben en SRAM

for block_i in blocks:
    for block_j in blocks:
        # Cargar bloque a SRAM fast
        Q_block = load_block(Q, block_i)
        K_block = load_block(K, block_j)
        V_block = load_block(V, block_j)

        # Online softmax accumulator
        exp_scores = exp(Q_block @ K_block.T / sqrt(d_k))
        # Mantiene running max y sum para estabilidad numerica
        ...
```
- **Speedup:** 3-4x en training, 2-3x en inference
- **Memory:** O(N) en vez de O(N²)
- **Trade-off:** Más FLOPs pero menos memory bandwidth

### Flash Attention v2 vs v3

| Característica | v2 | v3 |
|----------------|----|----|
| tiling | 2D | Mejorado |
| warp specialization | Sí | Sí + async |
| register pressure | Optimizado | Reducido |
| Speedup vs standard | ~3x | ~4x |

### Ring Attention

Para distribuir attention largo across multiple GPUs:
```
GPU 0          GPU 1          GPU 2          GPU 3
[seq 0-16K]    [seq 16K-32K]  [seq 32K-48K]  [seq 48K-64K]
     │              │              │              │
     ▼              ▼              ▼              ▼
  attention      attention      attention      attention
     │              │              │              │
     └──────────────┴──────►Ring communicate◄─┘
                        aggregated attention
```

- **Escala:** hasta millones de tokens
- **Communication:** overlap con computation

### KV Cache

**Problema:** En inference autoregressive, se recalcula toda la secuencia en cada paso.

```
Sin KV Cache (training forward):
x_1 → x_2 → x_3 → ... → x_t
  │     │     │          │
  ▼     ▼     ▼          ▼
 h_1   h_2   h_3        h_t    ← recalcula todo

Con KV Cache:
  x_1 → cache K,V_1
  x_2 → cache K,V_1,2
  x_3 → cache K,V_1,2,3
  ...

Solo calcula para x_t nuevo, usa cache para el resto
```

**Implementation:**
```python
class KVCache:
    def __init__(self, batch_size, num_heads, seq_len, head_dim):
        self.k = torch.zeros(batch_size, num_heads, seq_len, head_dim)
        self.v = torch.zeros(batch_size, num_heads, seq_len, head_dim)

    def update(self, pos, k_new, v_new):
        self.k[:, :, pos:pos+1] = k_new
        self.v[:, :, pos:pos+1] = v_new

    def get(self):
        return self.k, self.v
```

**Memory calculation:**
```
For Llama 3 70B:
- 8 KV heads (GQA), head_dim = 128
- 128K context
- KV cache = 2 * 8 * 128K * 128 * 2 bytes (bfloat16)
- ≈ 512 MB solo para KV cache
```

### Prefill vs Decode

| Fase | Qué hace | Complejidad |
|------|----------|-------------|
| **Prefill** | Procesa prompt completo | O(L²) parallel |
| **Decode** | Genera un token a la vez | O(L) per token |

```
Prefill: Todo el prompt → kv_cache → primer token
Decode:  kv_cache + token_n → kv_cache + token_(n+1)
         ↑ esto crece linealmente con contexto
```

### Speculative Decoding

**Idea:** Un modelo pequeño (draft) genera múltiples tokens, el grande los verifica en paralelo.

```
Draft (pequeño):        [the] [cat] [sat] [on] [mat]    ← 5 tokens
                        ↓     ↓     ↓     ↓     ↓
Big (grande):           ✓     ✓     ✗     ✓     ✓    ← rechaza "sat"
                        ↓
Token generado:         [mat]                              ← resampling

Resultado: the cat on mat — más rápido que generar token por token
```

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

### GEGLU Activation
```python
def geglu(x):
    return F.gelu(x) * x  # GELU * input
```
Alternativa a SwiGLU en varios modelos.

## Efficient Transformers

### Comparación de Complexidades

| Método | Memory | Time | Trade-off |
|--------|--------|------|----------|
| **Standard** | O(L²) | O(L²) | Baseline |
| **Flash Attention** | O(L) | O(L²) | Más rápido, menos memory |
| **Linformer** | O(L) | O(L) | Proyección lineal |
| **Reformer** | O(L log L) | O(L log L) | LSHS attention |
| **Performer** | O(L) | O(L) | Random feature approximation |
| **BigBird** | O(L) | O(L) | Sparse + global tokens |

### Linformer
```python
# Proyecta K, V de (seq_len, d_model) a (k, d_model)
# donde k << seq_len

K_proj = K @ W_k_proj  # (batch, k, d_model)
V_proj = V @ W_v_proj  # (batch, k, d_model)

# Attention ahora O(k * L) en vez de O(L²)
scores = Q @ K_proj.transpose  # (batch, seq_len, k)
```

### Reformer (LSH Attention)
- Locality Sensitive Hashing (LSH) para encontrar tokens similares
- Solo atiende a buckets cercanos en vez de todos los tokens
- Good for very long sequences with local patterns

### Performer (Random Feature)
```python
# Aproxima exp(QK^T) con random features
# exp(QK^T) ≈ φ(Q) @ φ(K)^T
# donde φ usa random projection

def random_feature_attention(Q, K, V, num_features=256):
    φ_Q = random_features(Q, num_features)  # (batch, seq, d_rand)
    φ_K = random_features(K, num_features)
    return (F.softmax(φ_Q @ φ_K.transpose, dim=-1) @ V)
```

### BigBird (Sparse + Global)
```
Token:  [G] [a] [b] [c] [d] [e] [f] [g] [h] [i] [j]
               ↓   ↓   ↓       ↓   ↓   ↓       ↓
Attention: Global token ve todo
           + sparse local (window)
           + random connections
```

## Mixture of Experts (MoE)

### Concepto
```
Standard:      FFN → [expert_1]
Every token    FFN → [expert_1]
passes through FFN → [expert_1]

MoE:           FFN → [expert_1, expert_2, ..., expert_8]
Tokens choose  FFN → [router selects top-k experts]
top-k experts  FFN → [only 2 experts active per token]
```

** sparsity activa:**
```python
class MoELayer(nn.Module):
    def __init__(self, d_model, num_experts=8, top_k=2):
        self.router = nn.Linear(d_model, num_experts)
        self.experts = nn.ModuleList([FeedForward() for _ in range(num_experts)])
        self.top_k = top_k

    def forward(self, x):
        gates = self.router(x)  # (batch, seq, num_experts)
        top_k_gates, top_k_idx = torch.topk(gates, self.top_k, dim=-1)

        output = torch.zeros_like(x)
        for i in range(self.top_k):
            expert = self.experts[top_k_idx[:, :, i]]
            output += top_k_gates[:, :, i:i+1] * expert(x)
        return output
```

### Mixtral 8x7B
- 8 expertos, 2 activos por token
- Equivalente a ~12B params active, 46B total
- Cada expert es un FFN completo

## State Space Models (Mamba)

**Alternativa a Transformers** con complexity O(L) y calidad cercana.

```
Differential equation: h' = Ah + Bx
                        y = Ch + Dx

Equivalente a RNN continua,
discretizada para inference discrete.
```

**Ventajas:**
- O(L) memory durante generation
- Selection mechanism para qué recordar
- Puede procesar contextos de millones de tokens

**Comparación:**
| Modelo | Complexity | Performance |
|--------|------------|-------------|
| Transformer | O(L²) | SOTA |
| Mamba | O(L) | Cercano a Transformer |
| Hybrid (Jamba) | O(L) | Mezcla ambos |

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

## Training Details

### AdamW Optimizer
```python
# Adam con weight decay correcto (no es simplemente L2)
# Decoupling de weight decay del gradient

θ_{t+1} = θ_t - lr * (m_t / (√v_t + ε) + wd * θ_t)
```

**Problema con Adam + L2:**
```
L2 regularization adiciona wd * θ a gradient
Adam combina gradient con momentum
→ Effective learning rate depende de θ (no deseable)
```

**Solución AdamW:** Decouple weight decay del gradient
```
θ_{t+1} = θ_t - lr * m_t / (√v_t + ε) - lr * wd * θ_t
```

### Learning Rate Schedule

```
Learning Rate
     │
     │▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
     │                    ╱
     │                  ╱  ← warmup (ej: 4000 steps)
     │               ╱
     │            ╱
     │         ╱
     │      ╱
     │   ╱
     │▄▄
     └────────────────────────────────────→ Steps
```

```python
# Original paper schedule
lr = d_model^-0.5 * min(step^-0.5, step * warmup^-1.5)

# Cosine decay (modernos)
lr = lr_max * cos((step - warmup) / (total - warmup) * π/2)
```

### Gradient Clipping
```python
# Prevenir exploding gradients
torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
```

**Por qué 1.0?**
- Gradientes muy grandes → oscilación / divergence
- Gradientes muy pequeños → vanishing
- 1.0 es balance empírico común

### Mixed Precision Training

```python
# BF16 (brain float) para forward/backward
# FP32 para optimizer states

with torch.cuda.amp.autocast(dtype=torch.bfloat16):
    output = model(input)

# Gradients en FP32 para actualizar optimizer exactamente
scaler = GradScaler()
with autocast():
    loss = model(input)
scaler.scale(loss).backward()
scaler.step(optimizer)
scaler.update()
```

**Ventajas:**
- ~2x speedup en A100/H100
- Menor memory (half precision)
- Quality casi idéntico con BF16

### ZeRO (Zero Redundancy Optimizer)

**Stage 1:** Shard optimizer states across GPUs
```
GPU 0: optimizer states para [0-20B params]
GPU 1: optimizer states para [20-40B params]
GPU 2: optimizer states para [40-60B params]
```

**Stage 2:** + gradients sharded

**Stage 3:** + parameters sharded

| Stage | Memory por GPU | Communication |
|-------|---------------|----------------|
| Baseline | 80GB | - |
| ZeRO-1 | 40GB | ~1.5x |
| ZeRO-2 | 20GB | ~1.5x |
| ZeRO-3 | ~2GB | ~4x |

### Data Parallelism

```
Batch de 4M tokens:
         ┌──────┐
GPU 0 ←──┤ data │ batch 1-4M
GPU 1 ←──┤      │ batch 4M-8M
GPU 2 ←──┤      │ batch 8M-12M
GPU 3 ←──┤      │ batch 12M-16M
         └──────┘

AllGPU ──► forward + backward ──► allreduce gradients
```

### Pipeline Parallelism

```
Layer 1-4    Layer 5-8    Layer 9-12   Layer 13-16
   │             │            │             │
   ▼             ▼            ▼             ▼
GPU 0          GPU 1         GPU 2         GPU 3

Micro-batches para minimizar pipeline bubbles:
[1][2][3][4][5][6][7][8] → [1][2][3][4][5][6][7][8]
  │  │  │  │  │  │  │  │
  ▼  ▼  ▼  ▼  ▼  ▼  ▼  ▼
Bubble overhead: (num_layers - 1) * micro_batch_size
```

### Tensor Parallelism (Megatron)

```
Single matrix multiply: W @ X
                        ↓
              ┌────┬────┬────┐
              │ W/4│ W/4│ W/4│  ← Column shards
              └──┬─┴──┬─┴──┬─┘
                 │    │    │
                 ▼    ▼    ▼
               GPU0  GPU1  GPU2
```

- Cada GPU calcula parte del output
- All-gather para resultado completo

## Attention Variants

### Bi-Directional Attention (BERT-style)
```
"the cat" attention:
     the   cat
the   0.5   0.5
cat   0.5   0.5

→ Cada token ve todos los otros (presente + futuro)
```

### Causal (GPT-style)
```
"the cat" attention:
     the   cat
the   1.0   0.0
cat   1.0   0.0

→ Cada token solo ve anteriores
```

### Prefix LM (T5-style)
```
Prefix: "Translate to French: hello"
Target: "bonjour"

Prefix attention: bidirectional
Target attention: causal

→ Permite que el prompt se procese eficientemente
```

### Glancing Transformer
```python
# during training, let decoder peek at encoder hidden states
# via additional attention layer

def glancing_attention(decoder_state, encoder_output):
    # Standard cross-attention
    scores = decoder_state @ encoder_output.transpose(-2, -1)

    # Glancing: bias towards aligned positions
    glancing_mask = create_diagonal_mask(seq_len)
    scores = scores + glancing_mask * large_value

    return softmax(scores) @ encoder_output
```

## Regularization

### Dropout
```python
class TransformerLayer(nn.Module):
    def __init__(self):
        self.attention = MultiHeadAttention()
        self.feed_forward = FeedForward()
        self.dropout = nn.Dropout(p=0.1)

    def forward(self, x):
        x = x + self.dropout(self.attention(x))  # attention dropout
        x = x + self.dropout(self.feed_forward(x))  # FFN dropout
        return x
```

**En inference:** Dropout desactivado (no stochasticity)

### Embedding Dropout
```python
def forward(self, x):
    emb = self.embedding(x)
    if self.training:
        emb = F.dropout(emb, p=0.1)
    return emb
```

### Label Smoothing
```python
# Cross-entropy with label smoothing
def label_smoothed_cross_entropy(logits, targets, eps=0.1):
    num_classes = logits.size(-1)
    log_probs = F.log_softmax(logits, dim=-1)

    # Smooth target: [0.9, 0.1] en vez de [1, 0]
    smooth_targets = (1 - eps) * one_hot + eps / num_classes
    loss = -(smooth_targets * log_probs).sum(dim=-1)

    return loss.mean()
```

**Efecto:** Previene over-confidence, mejora generalization

### Weight Tying
```python
# Compartir embeddings entre input y output
self.embedding = self.output_proj.weight.T
```

**Ahorro:** ~2 * vocab_size * d_model parámetros

## Loss Functions

### Cross-Entropy
```python
def compute_loss(logits, targets):
    # logits: (batch, seq_len, vocab_size)
    # targets: (batch, seq_len)

    loss = F.cross_entropy(
        logits.view(-1, vocab_size),
        targets.view(-1),
        reduction='mean'
    )
    return loss
```

### NLL (Negative Log Likelihood)
```
Loss = -log P(token_t | context)
     = -sum(log softmax(logits[token_t]))
```

Minimizar cross-entropy = maximizar likelihood

## Embeddings

### Learned vs Sinusoidal

| Característica | Sinusoidal | Learned |
|----------------|------------|---------|
| Trainable | No | Sí |
| Length extrapolation | limited | No |
| Generalization | Bueno para distances | Depende de datos |
| Memory | No extra params | + seq_len * d_model |

### Subword Tokenization (BPE/WordPiece)

```
"Tokenizer" → ["Token", "ize", "r"]
            ↑
            Vocab: 50,000 tokens típico

Ventajas:
- Maneja OOV (out-of-vocabulary)
- Representa subword patterns
- Balance entre char-level y word-level
```

```python
# SentencePiece (Usado en Llama, T5)
tokenizer = SentencePieceProcessor()
tokenizer.Load('model.sp')

ids = tokenizer.Encode("Hello world")
ids = tokenizer.Decode(ids)
```

### Positional Embeddings vs RoPE

| Característica | Absolute PE | RoPE |
|----------------|-------------|------|
| Parametros | O(L) | O(1) |
| Length extrapolation | Poor | Good |
| Relative distance encoding | No | Sí |
| Used by | Original, T5 | Llama, Falcon, Mistral |

## Large Language Models

### GPT Series Architecture

```
GPT-3 (175B):
  96 layers
  d_model = 12288
  num_heads = 96
  d_head = 128
  d_ff = 4 * d_model = 49152

Context: 2048 tokens
Training: 300B tokens
```

### LLaMA Architecture

```
LLaMA 3 70B:
  80 layers
  d_model = 8192
  num_heads = 8 (GQA)
  d_head = 128
  d_ff = 28672 (SwiGLU)

Context: 128K tokens (LLaMA 3.1)
```

### Chain of Thought (CoT)

```
Standard prompting:
Q: "If John has 5 apples and gives 2 to Mary..."
A: "12"  ← Wrong, no reasoning shown

CoT prompting:
Q: "If John has 5 apples and gives 2 to Mary..."
A: "First, John has 5 apples...
   Then he gives 2 to Mary...
   So he has 3 left.
   Mary had 3, so together they have 6.
   Answer: 6"  ← Correct reasoning
```

**Habilitado por:**
- Large scale pre-training
- Instruction tuning
- RLHF

### Retrieval Augmented Generation (RAG)

```
User Query ──────┐
                ▼
         ┌──────────────┐
         │  Vector DB   │
         │  (embeddings)│
         └──────┬───────┘
                ▼ retrieved docs
         ┌──────────────┐
         │    LLM       │
         │ + retrieved  │
         └──────┬───────┘
                ▼
           Response
```

### Tool Use / Function Calling

```python
# Schema for tool definition
tools = [
    {
        "name": "calculate",
        "description": "Perform math calculations",
        "parameters": {
            "expression": "2 + 2 * 3"
        }
    }
]

# Model output format
response = {
    "tool_calls": [{
        "id": "call_123",
        "name": "calculate",
        "arguments": {"expression": "2 + 2 * 3"}
    }]
}
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

11. **¿Por qué Flash Attention usa block-wise processing?**
    - Evita materializar matrix N×N, reduce memory de O(N²) a O(N)

12. **¿Qué es el KV cache y por qué es necesario?**
    - Guarda K,V computados para no recalcular toda la secuencia en cada token generado

13. **¿Cuál es la diferencia entre prefill y decode?**
    - Prefill: procesa prompt completo O(L²). Decode: genera token a la vez O(L)

14. **¿Cómo funciona speculative decoding?**
    - Modelo pequeño genera drafts, modelo grande verifica en paralelo

15. **¿Qué es ZeRO y qué stage reduce más memory?**
    - Zero Redundancy Optimizer. ZeRO-3 puede reducir ~40x con sharding de parameters

16. **¿Por qué LLaMA usa SwiGLU en vez de ReLU?**
    - SwiGLU tiene mejor performance empírica en tareas de lenguaje

17. **¿Qué advantage tiene MoE sobre dense models?**
    - Permite más parámetros totales con menos cómputo activo por token

18. **¿Cómo funciona Mamba (SSM)?**
    - Discretiza differential equation continua, logra O(L) complexity

19. **¿Qué es label smoothing y por qué ayuda?**
    - Targets [0.9, 0.1] en vez de [1, 0] → previene over-confidence

20. **¿Qué tradeoff existe entre attention variants (GQA vs MHA)?**
    - GQA menos memory pero puede perder calidad si reduce demasiado KV heads

## Referencias

- "Attention Is All You Need" (Vaswani et al., 2017)
- "Language Models are Few-Shot Learners" (GPT-3)
- "Training Language Models to Follow Instructions with Human Feedback" (InstructGPT)
- "Chinchilla: Training Compute-Optimal Large Language Models" (Hoffmann et al., 2022)
- [[memory-caching]] — extiende RNNs con memoria creciente para cerrar el gap con Transformers