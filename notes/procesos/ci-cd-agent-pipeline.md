---
tags: [ci-cd, deployment, docker, kubernetes, devin, claude-code]
created: 2026-04-13
---

# CI/CD Pipeline for AI Agents

## Contexto

Workflow actual: Devin (plannificación) → Claude Code (ejecución) → git → deploy manual.

Gap: No hay pipeline automatizado para这段 workflow.

## Pipeline Architecture

```
[Devin] → Plan → [Claude Code] → Code → [GitHub] → [CI] → [CD] → [Production]
              ↑                              ↓
              └────────── Harness Loop ─────┘
```

## CI Stage

### 1. Lint & Format
```yaml
- name: Lint
  run: |
    ruff check .
    ruff format --check .
```

### 2. Type Check
```yaml
- name: Type Check
  run: |
    mypy . --strict
```

### 3. Test Suite
```yaml
- name: Tests
  run: |
    pytest tests/ -v --tb=short
    pytest tests/integration/ -v
```

### 4. Security Scan
```yaml
- name: Security
  run: |
    bandit -r .
    semgrep --config=auto .
```

### 5. Agent Evals (NEW)
```yaml
- name: Agent Evals
  run: |
    python -m harness.run_eval \
      --test-set=production_traces \
      --baseline=main
```

**Evals en CI** es el feedback loop del [[agent-harness-engineering]] integrado al pipeline.

## CD Stage

### Deployment Options

#### Option A: Simple Docker Push
```yaml
- name: Deploy
  run: |
    docker build -t app:$GITHUB_SHA .
    docker push registry/app:$GITHUB_SHA
    kubectl set image deployment/app app=registry/app:$GITHUB_SHA
```

#### Option B: Blue-Green
```yaml
- name: Deploy Blue-Green
  run: |
    kubectl apply -f k8s/blue-green.yaml
    # Wait for validation
    # Switch traffic
```

#### Option C: Canary
```yaml
- name: Deploy Canary
  run: |
    kubectl apply -f k8s/canary.yaml
    # 5% traffic initially
    # Monitor error rate
    # Gradually increase
```

## Agent-Specific Pipeline

Para agentes (Devin, Claude Code), el pipeline incluye:

### 1. Trace Collection
```yaml
- name: Collect Traces
  run: |
    # Enable trace collection
    export TRACE_MODE=true
    # Run agent on eval tasks
    python -m agent.run --tasks=eval_set
    # Upload traces to evaluation system
    python -m harness.upload_traces --run-id=$GITHUB_SHA
```

### 2. Harness Evaluation
```yaml
- name: Harness Eval
  run: |
    # Compare against baseline
    python -m harness.compare \
      --baseline=main \
      --candidate=$GITHUB_SHA \
      --metrics=accuracy,latency,cost
```

### 3. Human Review Gate
```yaml
- name: Human Review
  if: github.event.pull_request
  run: |
    # Post results as PR comment
    python -m harness.post_results \
      --pr=$PR_NUMBER \
      --results=eval_results.json
    # Wait for approval
```

## Kubernetes Configuration

### Pod Spec for AI Agents
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: agent-runner
spec:
  containers:
  - name: devin
    image: devin/runtime:latest
    env:
    - name: HARNESS_ENDPOINT
      value: "http://harness-service:8080"
    - name: TRACE_MODE
      value: "true"
    resources:
      requests:
        memory: "4Gi"
        cpu: "2"
      limits:
        memory: "8Gi"
        cpu: "4"
  - name: claude-sidecar
    image: claude/code:latest
    volumeMounts:
    - name: workspace
      mountPath: /workspace
```

### Service for Harness
```yaml
apiVersion: v1
kind: Service
metadata:
  name: harness-service
spec:
  selector:
    app: harness
  ports:
  - port: 8080
```

## Helm Charts Structure

```
agent-pipeline/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── ingress.yaml
└── tests/
    └── test_pipeline.py
```

## Environment Promotion

```
develop → staging → production
```

### Develop
- Feature branches
- Auto-deploy on PR
- Full eval suite
- Debug traces enabled

### Staging
- Merge to main
- Canary deployment (10%)
- Monitor for 24h
- Full production traffic simulation

### Production
- Manual promotion from staging
- Blue-green deployment
- Instant rollback capability
- A/B testing for harness improvements

## Monitoring & Alerts

### Key Metrics
| Metric | Target | Alert |
|--------|--------|-------|
| Agent Accuracy | > 90% | < 85% |
| Mean Time to Merge | < 2h | > 4h |
| Evals Pass Rate | > 95% | < 90% |
| Deploy Frequency | > 5/day | < 1/day |
| Error Rate Post-Deploy | < 0.1% | > 0.5% |

### Logging
```yaml
# Fluentd config for agent traces
<source>
  @type tail
  path /var/log/agent/traces/*.json
  pos_file /var/log/td-agent/agent_traces.pos
  format json
  tag agent.trace
</source>
```

## Rollback Strategy

```bash
# Immediate rollback
kubectl rollout undo deployment/app

# Specific revision
kubectl rollout undo deployment/app --to-revision=3

# Automated rollback on error rate
if error_rate > threshold:
    trigger_rollback()
    notify_team()
    create_incident()
```

## GitHub Actions Workflow

```yaml
name: Agent Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: ruff check . && ruff format --check .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: pytest tests/ -v

  evals:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - name: Run Agent Evals
        run: python -m harness.run_eval --test-set=ci
        env:
          HARNESS_API_KEY: ${{ secrets.HARNESS_API_KEY }}

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: [evals]
    runs-on: ubuntu-latest
    steps:
      - name: Build and Deploy
        run: |
          docker build -t app:$GITHUB_SHA .
          kubectl set image deployment/app app=app:$GITHUB_SHA

  rollback-check:
    runs-on: ubuntu-latest
    needs: [deploy]
    continue-on-error: true
    steps:
      - name: Monitor for regressions
        run: python -m harness.monitor --duration=1h
```

## Secrets Management

```yaml
# External secrets via External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: agent-secrets
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: agent-secrets
  data:
  - secretKey: HARNESS_API_KEY
    remoteRef:
      key: prod/agents/harness
      property: api_key
```

## Referencias

- [[agent-harness-engineering]] — Framework para mejorar agents
- [[devin-harness-integration]] — Integración específica con Devin
- [[swe-bench]] — Benchmark para validar agent performance