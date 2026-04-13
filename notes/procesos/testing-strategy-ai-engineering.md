---
tags: [testing, evals, tdd, agent-quality, quality-automation]
created: 2026-04-13
---

# Testing Strategy for AI Engineering

## Concepto Central

Testing en AI Engineering ≠ testing tradicional. El "correcto" es probabilístico, no determinístico. El foco cambia de "does this pass" a "does this behave well".

```
Traditional: Assert(output == expected)
AI/Agent:    Eval(behavior == desired_behavior)
```

## Testing Layers

### Layer 1: Unit Tests (Traditional)
```python
def test_calculate_score():
    result = calculate_score(user_data)
    assert result == 42  # Deterministic

def test_transformer_forward():
    output = model(input_ids)
    assert output.shape == (batch, seq_len, vocab_size)
```

### Layer 2: Integration Tests (API/Database)
```python
def test_rag_retrieval():
    docs = vector_store.search("query", top_k=5)
    assert len(docs) == 5
    assert all(doc.has_embedding for doc in docs)

def test_agent_tool_call():
    result = executor.execute("read_file", {"path": "test.txt"})
    assert result.success == True
```

### Layer 3: Agent Evals (Behavioral)
```python
# Eval = task + expected behavior + scoring
eval = AgentEval(
    task="Fix the login bug",
    expected_behavior=[
        "reads the login code",
        "identifies the null pointer",
        "applies a fix",
        "writes a test for the edge case"
    ],
    scoring={
        "complete": 1.0,      # All steps done
        "partial": 0.5,       # Some steps
        "failed": 0.0         # No progress
    }
)
```

## Eval Framework

### Anatomy of an Eval

```python
@dataclass
class Eval:
    id: str
    task: str                    # What to do
    setup: Optional[Callable]     # Prepare environment
    expected_steps: List[str]    # Trace of expected behavior
    validation: Callable         # How to check success
    metrics: Dict[str, float]    # Scores for different aspects

    # Thresholds
    passing_threshold: float = 0.8
    regression_threshold: float = 0.05  # Allow 5% regression
```

### Eval Categories

| Category | What it measures | Example |
|----------|-----------------|---------|
| **Correctness** | Output is right | "Fix returns correct value" |
| **Behavior** | Agent follows steps | "Reads file before editing" |
| **Efficiency** | Uses resources wisely | "Completes in < 5 tool calls" |
| **Robustness** | Handles errors | "Fails gracefully on bad input" |
| **Safety** | No destructive actions | "Doesn't delete prod data" |

## Test Data Management

### Sourcing Test Data

```
1. Hand-curated examples (high value, low volume)
2. Production traces (high volume, needs filtering)
3. Synthetic data (unlimited, needs validation)
4. External benchmarks (SWE-bench, HumanEval, etc.)
```

### Test Data Split

```python
def split_test_data(examples: List[EvalExample]):
    # Holdout = never seen during development
    holdout = examples[::10]  # Every 10th

    # Optimization set = used during iteration
    optimization = examples[1::10]  # Every 10th, offset 1

    # Sanity set = smoke tests
    sanity = examples[:5]  # First 5

    return holdout, optimization, sanity
```

**Regla crítica:** Holdout set evita overfitting a los evals.

## Regression Detection

### Pipeline

```
Pull Request
    ↓
Run full eval suite (holdout + optimization)
    ↓
Compare against: main branch baseline
    ↓
Pass/Fail/Regression
    ↓
If regression > threshold:
    block merge
    post comment with regression details
```

### Regression Report Format

```json
{
  "baseline": "main",
  "candidate": "pr-123",
  "regression_detected": true,
  "metrics": {
    "accuracy": {"baseline": 0.87, "candidate": 0.82, "delta": -0.05},
    "latency_p50": {"baseline": "2.3s", "candidate": "2.8s", "delta": "+0.5s"}
  },
  "failing_evals": [
    {"id": "eval-45", "name": "multi-step Planning", "delta": -0.15}
  ],
  "recommendation": "BLOCK - accuracy regressed beyond threshold"
}
```

## Coverage Metrics

### Traditional Coverage (Less Relevant)

```bash
pytest --cov=. --cov-report=term-missing
# Lines executed / total lines
# This tells you WHAT code ran, not IF behavior was correct
```

### Behavioral Coverage (More Relevant)

```python
# Track which eval categories have passing examples
coverage = {
    "correctness": 15 / 20,  # 75%
    "behavior": 12 / 15,    # 80%
    "efficiency": 8 / 10,    # 80%
    "safety": 5 / 5         # 100%
}

# Alert if any category < 70%
```

## Test Maintenance

### Stale Evals

Evals se vuelven obsoletos si:
- La task ya no es relevante
- El expected behavior cambió
- El benchmark está saturado

```python
def detect_stale_evals(evals: List[Eval], threshold: float = 0.95) -> List[Eval]:
    # If pass rate > threshold, eval is "too easy"
    # Consider removing or making harder
    return [e for e in evals if e.pass_rate > threshold]
```

### Drift Detection

```python
# If baseline performance changes without code change
# = environmental drift (model version, API changes, etc.)
def detect_drift(baseline_history: List[Metric], current: Metric) -> bool:
    # Simple: if current is 2 std deviations from history
    mean = np.mean(baseline_history)
    std = np.std(baseline_history)
    return abs(current - mean) > 2 * std
```

## Test Execution

### Local Development

```bash
# Run sanity set (fast)
pytest tests/evals/sanity/ -v

# Run optimization set (medium)
pytest tests/evals/optimization/ -v --tb=short

# Run full suite (slow, only before merge)
pytest tests/evals/full/ -v --tb=short --harness-report
```

### CI Integration

```yaml
# .github/workflows/test.yml
- name: Run Evals
  run: |
    python -m harness.run \
      --test-set=ci \
      --output=eval_results.json
    python -m harness.post_results \
      --results=eval_results.json \
      --pr=${{ github.event.pull_request.number }}
```

## Assertions

### Hard Assertions (Must Pass)
```python
assert eval.pass_rate >= 0.8, "Pass rate below threshold"
assert "dangerous_action" not in trace, "Safety violation"
```

### Soft Assertions (Warning)
```python
if latency_p95 > threshold:
    logger.warning(f"Latency elevated: {latency_p95}")
    # Don't block, but alert
```

## Benchmark Integration

| Benchmark | What it measures | Connection |
|-----------|-------------------|------------|
| **SWE-bench** | Real bug fixes | [[swe-bench]] — coding agents |
| **HumanEval** | Python code generation | Standard for LLMs |
| **MBPP** | Basic Python | Simpler tasks |
| **BigCodeBench** | Realistic coding |より難しい tasks |

## References

- [[tdd-prompt-agente]] — TDD approach con agents
- [[agent-harness-engineering]] — Harness engineering framework
- [[swe-bench]] — Benchmark específico para coding agents