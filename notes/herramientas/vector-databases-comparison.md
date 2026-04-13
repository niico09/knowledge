---
tags: [vector-db, pinecone, chroma, pgvector, weaviate, comparison, rag]
created: 2026-04-13
---

# Vector Databases Comparison

## Overview

Vector databases almacenan embeddings de alta dimensionalidad para búsqueda semántica. Son el backbone de RAG systems.

```
Text → Embedding Model → 1536-dim vector → Vector DB
Query → Embedding → Similarity Search → Top-K results
```

## Comparison Matrix

| Database | Best For | Scalability | Deployment | Pricing | Maintenance |
|----------|----------|-------------|------------|---------|-------------|
| **Pinecone** | Production RAG | Excellent | Managed | Pay-per-use | Zero (managed) |
| **Chroma** | Prototyping | Limited | Local/Self-hosted | Free (OSS) | Low |
| **pgvector** | Existing Postgres | Good | Self-hosted | Included w/ Postgres | Medium |
| **Weaviate** | Hybrid search | Good | Docker/K8s | Open source | Medium |
| **Qdrant** | High performance | Excellent | Self-hosted/Cloud | Open source | Medium |
| **Milvus** | Massive scale | Excellent | Docker/K8s | Open source | High |
| **ElasticSearch** | Existing ES users | Good | Self-hosted/Cloud | Expensive | Low |

## 1. Pinecone

### Pros
- **Managed** — zero infrastructure overhead
- **Serverless** — automatic scaling
- **Multi-tenancy** — built-in namespace isolation
- **Filtering** — metadata pre-filtering antes de vector search

### Cons
- **Vendor lock-in** — proprietary
- **Cost** — puede ser caro en escala (~$70/1M vectors)
- **Latency** — network round-trip para cada query

### Pricing Tiers

| Tier | Price | Vectors | Operations |
|------|-------|---------|------------|
| Starter | $70/mo | 100K | 100K ops/day |
| Standard | $200/mo | 1M | 500K ops/day |
| Enterprise | Custom | Unlimited | Unlimited |

### Use Cases
- Production RAG sin infrastructure team
- Startups que quieren move fast
- When you need filtering + vector search

## 2. Chroma

### Pros
- **Simple** — single file database, easy to understand
- **Local dev** — perfect for prototyping
- **Python-first** — native Python client
- **Fast** — in-process, no network latency

### Cons
- **Limited scale** — no horizontal scaling built-in
- **No cloud offering** — self-hosted only
- **Single node** — no distributed query

### Installation

```bash
pip install chromadb

# Or with HuggingFace integration
pip install chromadb sentence-transformers
```

### Usage Example

```python
import chromadb

client = chromadb.Client()
collection = client.create_collection("documents")

# Add embeddings
collection.add(
    ids=["1", "2"],
    embeddings=[[0.1, 0.2, ...], [0.3, 0.4, ...]],
    documents=["Doc 1 text", "Doc 2 text"],
    metadatas=[{"source": "web"}, {"source": "pdf"}]
)

# Query
results = collection.query(
    query_embeddings=[[0.1, 0.2, ...]],
    n_results=2
)
```

### Use Cases
- Local prototyping
- Small-scale applications (< 100K vectors)
- When you need quick iteration

## 3. pgvector (PostgreSQL Extension)

### Pros
- **No new system** — extend existing Postgres
- **SQL integration** — JOIN con datos relacionales
- **ACID compliance** — transacciones
- **Mature** — Postgres es battle-tested

### Cons
- **Not specialized** — vector ops no son el focus
- **Index options limited** — IVFFlat, HNSW only
- **Scaling** — vertical scaling hasta cierto punto

### Installation

```sql
-- Enable extension
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536),
    metadata JSONB
);

-- Create index
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);
```

### Usage Example

```python
# psycopg2 or asyncpg
result = await conn.fetch("""
    SELECT content, metadata
    FROM documents
    ORDER BY embedding <=> $1
    LIMIT 5
""", embedding)
```

### Use Cases
- Already using Postgres
- Need relational + vector data
- When you want ACID guarantees

## 4. Weaviate

### Pros
- **Hybrid search** — vector + keyword (BM25) built-in
- **GraphQL API** — flexible querying
- **Multi-modal** — supports images, audio embeddings
- **Open source** — no vendor lock-in

### Cons
- **Complexity** — más setup que Chroma
- **Resource usage** — heavier than Chroma
- **Documentation** — learning curve

### Docker Setup

```yaml
version: '3.4'
services:
  weaviate:
    image: semitechnologies/weaviate:latest
    ports:
    - "8080:8080"
    environment:
    - QUERY_MAXIMUM_RESULTS=10000
    - PERSISTENCE_DATA_PATH=/var/lib/weaviate
    - AUTHENTICATION_ANONYMOOUS_ACCESS_ENABLED=true
```

### Usage Example

```python
import weaviate

client = weaviate.Client("http://localhost:8080")

# Add objects
client.data_object.create(
    class_name="Document",
    data_object={
        "content": "Document text",
        "category": "technical"
    },
    vector=[0.1, 0.2, ...]
)

# Query with hybrid search
result = client.query.get("Document", ["content", "category"])\
    .with_hybrid("query text", alpha=0.5)\
    .with_limit(5)\
    .do()
```

### Use Cases
- When you need hybrid search (vector + keyword)
- Multi-modal data (images + text)
- Graph-like relationships between data

## 5. Qdrant

### Pros
- **Performance** — fastest for high-dimensional vectors
- **Rust-based** — memory efficient
- **Filtered search** — powerful payload filtering
- **Cloud offering** — Qdrant Cloud available

### Cons
- **Younger** — less community than Weaviate
- **Learning curve** — new API paradigm

### Docker Setup

```bash
docker run -p 6333:6333 \
    -v $(pwd)/qdrant_storage:/qdrant/storage \
    qdrant/qdrant
```

### Usage Example

```python
from qdrant_client import QdrantClient

client = QdrantClient("localhost", port=6333)

# Create collection
client.create_collection("documents", vector_size=1536)

# Add vectors
client.upsert(
    collection_name="documents",
    points=[
        {"id": 1, "vector": [...], "payload": {"content": "..."}},
    ]
)

# Search with filter
results = client.search(
    collection_name="documents",
    query_vector=[...],
    query_filter={
        "must": [{"key": "category", "match": {"value": "technical"}}]
    },
    limit=5
)
```

### Use Cases
- Latency-critical applications
- High-dimensional vectors (1536+)
- When filtering is complex

## 6. Milvus

### Pros
- **Massive scale** — billions of vectors
- **Distributed** — built-in sharding
- **GPU support** — accelerated indexing

### Cons
- **Complexity** — needs Kubernetes for production
- **Resource heavy** — significant infrastructure
- **Steep learning curve**

### Use Cases
- Enterprise scale (billions of vectors)
- When you need GPU acceleration
- Distributed architecture required

## Decision Framework

```
START
  ↓
How critical is vendor lock-in?
  ↓
├── Don't care → Check scale requirement
│   └── < 100K vectors → Chroma (free, simple)
│   └── > 100K vectors → Pinecone (managed)
│
Concerned about lock-in?
  ↓
Already using Postgres?
  └── Yes → pgvector (extend existing)
  └── No → Check requirements
        ↓
        Need hybrid search (vector + keyword)?
        └── Yes → Weaviate or Qdrant
        └── No → Qdrant (fastest pure vector)
```

## Performance Benchmarks

| DB | 1M vectors (768d) | Latency P99 | Index Time |
|----|-------------------|-------------|------------|
| Pinecone | 45ms | 120ms | 8min |
| Chroma | 12ms | 35ms | 12min |
| pgvector | 85ms | 200ms | 15min |
| Weaviate | 28ms | 75ms | 10min |
| Qdrant | 18ms | 50ms | 7min |

*Note: Results vary by hardware, embedding model, and index type*

## Migration Path

```
Chroma (dev) → Pinecone (prod) # Simple, swap client
Chroma (dev) → Qdrant (prod) # More complex, export/import
pgvector (existing) → Pinecone # If Postgres is bottleneck
```

## Integration con RAG

Ver: [[rag-architecture]]

> ⚠️ **Contexto teórico:** [[no-escape-theorem-semantic-memory]] — el teorema no-escape prueba que todas las vector DBs suffer inevitablemente de olvido y false recall al escalar, independientemente de la arquitectura.

## References

- [[rag-architecture]] — Context de uso en RAG systems