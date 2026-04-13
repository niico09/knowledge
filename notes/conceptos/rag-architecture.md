---
tags: [rag, retrieval, vector-db, knowledge-system, architecture]
created: 2026-04-13
---

# RAG Architecture

## Concepto Central

**RAG** = Retrieval Augmented Generation. Combina búsqueda vectorial con LLMs para generar respuestas contextuales basadas en documentos.

```
Query → Embedding → Vector Search → Retrieved Docs → LLM → Response
```

## Components

### 1. Document Processing
- **Chunking** — dividir documentos en fragmentos manejables
- **Embedding** — convertir texto a vectores (OpenAI, Cohere, sentence-transformers)
- **Metadata extraction** — títulos, fechas, fuentes para filtrado

### 2. Vector Store
| Database | Best For | Pros | Cons |
|----------|----------|------|------|
| **Pinecone** | Production | Managed, scalable | Vendor lock-in |
| **Chroma** | Development | Local, simple | Limited scaling |
| **pgvector** | Existing Postgres | SQL integration | Requires Postgres |
| **Weaviate** | Hybrid search | Built-in vector + scalar | Complexity |

### 3. Retrieval Strategies

#### Semantic Search
```python
# Basic retrieval
query_embedding = embed(query)
results = vector_store.search(query_embedding, top_k=5)
```

#### Hybrid Search
Combina búsqueda vectorial + keyword (BM25) para mejor coverage.

```python
hybrid_score = 0.7 * semantic_score + 0.3 * keyword_score
```

#### Parent Document Retrieval
Recupera chunks más grandes primero, luego sub-chunks relevantes.

```
Document → Chunk 1 (parent) → Sub-chunks → Grounded response
```

### 4. Reranking
Post-retrieval reordering con cross-encoders (Cohere Rerank, sentence-transformers).

```python
# Re-ranking workflow
retrieved = vector_search(query, top_k=20)
reranked = cross_encoder.rerank(query, retrieved, top_k=5)
```

## RAG Patterns

### Naive RAG
```
Query → Embed → Search → LLM → Answer
```
Limitaciones: context length, noise in retrieval

### Advanced RAG

#### Chunking Optimization
- **Sentence splitting**: para precisión
- **Recursive chunking**: por headers/paragraphs
- **Semantic chunking**: por significado, no tamaño fijo

#### Self-Querying
LLM genera filtros de metadata automáticamente.

```
"projects from last month" → metadata filter: {date: > 2026-03-01}
```

### Agentic RAG

Múltiples retrieval cycles con self-correction:

```
Query → Embed → Search → LLM → Judge relevance
         ↑ if not relevant        ↓ if relevant
         Refine query         Generate answer
```

## Chunking Strategies Comparison

| Strategy | Chunk Size | Best For | Typical Use Case |
|----------|-----------|----------|------------------|
| Fixed | 512 tokens | Simple docs | Fast prototyping |
| Recursive | 256-512 tokens | Technical docs | Headers, paragraphs |
| Semantic | Variable | Knowledge bases | Coherent sections |
| Sentence | 1-3 sentences | High precision | Fact extraction |

## Evaluation

### RAGAS Metrics
- **Faithfulness** — respuesta alineada con contexto recuperado
- **Answer Relevance** — respuesta responde query
- **Context Relevance** — contexto relevante al query

### Retrieval Metrics
- **Hit Rate** — relevante en top-k
- **MRR** — Mean Reciprocal Rank
- **NDCG** — Normalized DCG para ranking

## Integration con Knowledge System

El sistema actual usa:
- **Notion** como primary knowledge (no es vector store puro)
- **Obsidian** como local wiki (sin embedding)
- **NotebookLM** para active learning

Gap: No hay ingestion pipeline que sincronice Notion → Vector DB.

## Workflow: Add New Knowledge Source

```
1. Source identification (Notion page, docs, etc.)
2. Extract text content
3. Chunk with strategy (recursive recommended)
4. Embed with provider (OpenAI ada, Cohere)
5. Store in vector DB with metadata
6. Create index mapping in wiki
```

## Implementation Checklist

- [ ] Elegir vector DB (Pinecone para prod, Chroma para dev)
- [ ] Definir chunking strategy
- [ ] Implementar embedding pipeline
- [ ] Setup hybrid search
- [ ] Integrar reranking
- [ ] Add monitoring (retrieval quality, latency)

## Referencias

- [[notion-kb-overview]] — Overview del sistema de conocimiento actual
- [[notebooklm-workflow]] — Sistema de aprendizaje activo