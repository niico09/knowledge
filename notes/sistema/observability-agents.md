---
tags: [observability, tracing, monitoring, agent-telemetry, llm-ops]
created: 2026-04-13
---

# Observability for AI Agents

## Contexto

[[agent-harness-engineering]] necesita datos para funcionar. Los evals son el "training data" del agent, pero para mejorarlos necesitamos visibility completa del sistema.

```
Harness Engineering:
  Traces → Evals → Optimization → Better Traces → Better Evals
                   ↑
            Feedback loop necesita observabilidad
```

## The Three Pillars

### 1. Traces

Captura completa de cada agent execution:

```json
{
  "trace_id": "uuid",
  "timestamp": "2026-04-13T10:00:00Z",
  "agent_id": "claude-code",
  "task": "Fix login bug",
  "steps": [
    {
      "step": 0,
      "action": "read_file",
      "params": {"path": "auth/login.py"},
      "result": {"success": true, "lines": 145},
      "duration_ms": 120
    },
    {
      "step": 1,
      "action": "grep",
      "params": {"pattern": "null", "file": "auth/login.py"},
      "result": {"matches": 3},
      "duration_ms": 45
    }
  ],
  "final_result": {"success": true, "fix_applied": true},
  "total_duration_ms": 4500
}
```

### 2. Metrics

#### Latency Metrics
| Metric | What it measures | Target |
|--------|------------------|--------|
| Time to First Token | TTFT del modelo | < 500ms |
| Tokens per Second | Throughput | > 50 tok/s |
| End-to-End Latency | Task completion | < baseline + 20% |
| P50/P95/P99 | Distribution | P99 < 2x P50 |

#### Quality Metrics
| Metric | Formula | Target |
|--------|---------|--------|
| Accuracy | evals passed / total | > 85% |
| Task Completion | successful tasks / total | > 90% |
| Tool Success Rate | successful calls / total calls | > 98% |
| Error Rate | errors / total executions | < 2% |

#### Cost Metrics
| Metric | Unit | Budget |
|--------|------|--------|
| Tokens per Task | tokens | < 10k/task |
| Cost per Task | $ | < $0.50/task |
| API Calls | calls | < 50/task |

### 3. Logs

Structured logs para debugging:

```python
# Structured logging
logger.info(
    "tool_executed",
    extra={
        "trace_id": trace_id,
        "tool": "read_file",
        "params": {"path": "..."},
        "duration_ms": 120,
        "success": True
    }
)
```

## Tracing Implementation

### OpenTelemetry Integration

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp import OTLPSpanExporter

# Configure tracing
trace.set_tracer_provider(TracerProvider(
    resource=Resource.create({"service.name": "agent-runner"})
))
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://otel:4317"))
)
```

### Span Structure

```
Root Span (Agent Task)
├── Child Span (Planning)
├── Child Span (Tool Call: read_file)
├── Child Span (Tool Call: grep)
├── Child Span (Tool Call: edit)
└── Child Span (Verification)
```

## Metrics Collection

### Prometheus Metrics

```python
from prometheus_client import Counter, Histogram, Gauge

# Counters
tool_calls_total = Counter(
    'agent_tool_calls_total',
    'Total tool calls',
    ['tool_name', 'status']
)

# Histograms
task_duration = Histogram(
    'agent_task_duration_seconds',
    'Task duration in seconds',
    ['task_type', 'agent_id']
)

# Gauges
active_tasks = Gauge(
    'agent_active_tasks',
    'Number of active tasks'
)
```

### Custom Business Metrics

```python
# Agent-specific metrics
eval_pass_rate = Gauge('agent_eval_pass_rate', 'Eval pass rate', ['eval_set'])
harness_score = Gauge('agent_harness_score', 'Overall harness quality')
trace_quality = Gauge('agent_trace_quality', 'Trace completeness score')
```

## Dashboards

### Grafana Dashboard Structure

#### Panel 1: Task Overview
- Tasks completed (rate)
- Success rate over time
- Active tasks gauge

#### Panel 2: Latency Distribution
- P50/P95/P99 latency over time
- Time per step breakdown
- Bottleneck identification

#### Panel 3: Quality Trends
- Eval pass rate by category
- Regression detection alerts
- Harness score trend

#### Panel 4: Cost Analysis
- Tokens per task
- Cost per hour/day
- Budget utilization

## Alerting

### Alert Rules

```yaml
# prometheus alerting rules
groups:
- name: agent_alerts
  rules:
  - alert: HighErrorRate
    expr: rate(agent_errors_total[5m]) / rate(agent_tasks_total[5m]) > 0.05
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Agent error rate > 5%"

  - alert: LatencyRegression
    expr: histogram_quantile(0.95, agent_task_duration) > 1.2 * baseline_p95
    for: 10m
    labels:
      severity: critical
    annotations:
      summary: "Latency regression detected"

  - alert: EvalPassRateDrop
    expr: agent_eval_pass_rate < 0.85
    for: 15m
    labels:
      severity: warning
    annotations:
      summary: "Eval pass rate below threshold"
```

### Alert Workflow

```
Alert fires
    ↓
Page on-call (PagerDuty/Slack)
    ↓
On-call reviews trace in Jaeger
    ↓
Identifies root cause
    ↓
Creates ticket if needed
    ↓
Dissects trace → new eval if bug found
```

## Debugging Flow

### 1. Identify Issue

```bash
# Find traces with errors
grep "status=error" traces/*.json | head -10

# Get specific trace
cat traces/trace-abc123.json | jq '.steps[] | select(.status == "error")'
```

### 2. Replay in Debug Mode

```bash
# Enable verbose logging
export TRACE_MODE=verbose
export LOG_LEVEL=debug

# Re-run the task
python -m agent.run --task="fix login bug" --debug

# Compare traces
python -m harness.diff trace-baseline.json trace-debug.json
```

### 3. Add Eval if Bug Found

```python
# New eval to catch this bug
new_eval = Eval(
    id="login-null-check",
    task="Login with null session should return error",
    expected_behavior=["check for null", "return error message"],
    validation=lambda trace: "null check" in trace and "error" in trace.final_result
)
# Add to eval set
```

## Instrumentation Checklist

- [ ] Add OpenTelemetry tracing to agent execution
- [ ] Instrument all tool calls (read, write, bash, etc.)
- [ ] Export metrics to Prometheus
- [ ] Setup structured logging (JSON format)
- [ ] Configure Grafana dashboards
- [ ] Setup alerting rules
- [ ] Create runbook for common issues
- [ ] Test alerting (chaos engineering)

## Cost Tracking

```python
# Track cost per task
def calculate_task_cost(trace: Trace, model_pricing: Dict) -> float:
    input_tokens = trace.total_input_tokens
    output_tokens = trace.total_output_tokens

    input_cost = input_tokens * model_pricing["input"]
    output_cost = output_tokens * model_pricing["output"]

    return input_cost + output_cost

# Budget alerts
if cumulative_cost > daily_budget * 0.8:
    send_alert("80% of daily budget used")
```

## Integration con Harness

Observability feeds back into [[agent-harness-engineering]]:

```
1. Traces collected → 2. Evals updated → 3. Harness optimized → 4. Better traces
```

### Closed Loop Example

```
1. Observability detects: "multi-step tasks failing 40% of time"
2. Analyze traces: root cause = planning step missing context
3. Add eval for "multi-step planning with context"
4. Optimize harness: add "context preservation" prompt instruction
5. Deploy new harness
6. Observability confirms improvement (40% → 15% failure rate)
```

## Tools & Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Tracing | Jaeger, Tempo | Distributed tracing |
| Metrics | Prometheus | Time-series metrics |
| Dashboards | Grafana | Visualization |
| Logs | Loki, ELK | Log aggregation |
| Alerting | AlertManager | Alert routing |
| Error Tracking | Sentry | Exception tracking |

## Referencias

- [[agent-harness-engineering]] — Framework que requiere observabilidad
- [[agent-loop]] — Agent execution model
- [[tool-use]] — Tool calling observability