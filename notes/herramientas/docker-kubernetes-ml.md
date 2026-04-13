---
tags: [docker, kubernetes, containerization, ml-deployment, devops]
created: 2026-04-13
---

# Docker & Kubernetes for ML/AI

## Contexto

Agent pipeline (Devin + Claude Code) necesita deployment reproducible. El stack de ML/AI tiene requirements específicos: GPUs, large images, dependencies complejas.

## Docker Fundamentals

### Dockerfile para Python/ML

```dockerfile
FROM python:3.11-slim

# Install system dependencies for ML
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV TRANSFORMERS_CACHE=/app/models

# Run the application
CMD ["python", "main.py"]
```

### Multi-stage Build (Producción)

```dockerfile
# Stage 1: Build
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --target=/app/deps -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/deps /app/deps
COPY . .
ENV PYTHONPATH=/app/deps
CMD ["python", "main.py"]
```

### Docker Compose (Desarrollo)

```yaml
version: '3.8'

services:
  agent:
    build: .
    ports:
      - "8080:8080"
    environment:
      - HARNESS_ENDPOINT=http://harness:8080
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    volumes:
      - ./workspace:/workspace
    depends_on:
      - redis
      - postgres

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: agents
      POSTGRES_USER: agent
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

## Kubernetes Fundamentals

### Pod Spec (Agent Runner)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: agent-runner
  labels:
    app: agent
    version: v1
spec:
  containers:
  - name: claude-code
    image: claude/code:latest
    ports:
    - containerPort: 8080
    env:
    - name: MODEL_NAME
      value: "claude-opus-4"
    - name: MAX_TOKENS
      value: "8192"
    resources:
      requests:
        memory: "4Gi"
        cpu: "2"
        nvidia.com/gpu: "1"
      limits:
        memory: "8Gi"
        cpu: "4"
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  volumes:
  - name: workspace
    persistentVolumeClaim:
      claimName: workspace-pvc
```

### Deployment (Production)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agent-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: agent
  template:
    metadata:
      labels:
        app: agent
    spec:
      containers:
      - name: agent
        image: agent:latest
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 15
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: agent-service
spec:
  selector:
    app: agent
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

## GPU Support

### NVIDIA Device Plugin

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-agent
spec:
  template:
    spec:
      containers:
      - name: agent
        image: agent:latest
        resources:
          limits:
            nvidia.com/gpu: "1"  # Request 1 GPU
```

### Verify GPU Access

```bash
# Check nvidia device plugin is running
kubectl get pods -n kube-system | grep nvidia

# Test GPU in pod
kubectl run gpu-test --image=nvidia/cuda:11.0-base --rm -it -- nvidia-smi
```

## Helm Charts

### Structure

```
agent-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secrets.yaml
└── .helmignore
```

### values.yaml

```yaml
replicaCount: 3

image:
  repository: agent
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

resources:
  limits:
    memory: 8Gi
    cpu: 4
    nvidia.com/gpu: 1
  requests:
    memory: 4Gi
    cpu: 2

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

ingress:
  enabled: true
  host: agents.example.com
  tls:
    enabled: true
    secretName: agents-tls
```

### Commands

```bash
# Install
helm install agent ./agent-chart --namespace production

# Upgrade
helm upgrade agent ./agent-chart --values values-prod.yaml

# Rollback
helm rollback agent

# List releases
helm list -n production
```

## ML-Specific Considerations

### Large Model Images

```dockerfile
# Multi-stage para reducir imagen final
FROM nvidia/cuda:12.0-runtime-ubuntu22.04 AS base
WORKDIR /app

# Download models at build time (si son estáticas)
COPY model-cache/ /app/models

# Production image pequeño
FROM base
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "serve.py"]
```

### Model Storage

```yaml
# Persistent volume para modelos
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: model-storage
spec:
  storageClassName: standard
  resources:
    requests:
      storage: 100Gi
  accessModes:
    - ReadWriteOnce
---
# Mount en pod
volumeMounts:
- name: models
  mountPath: /app/models
```

### Environment Variables para ML

```yaml
env:
- name: TRANSFORMERS_CACHE
  value: /app/models/.cache
- name: HF_HOME
  value: /app/models/.cache
- name: CUDA_VISIBLE_DEVICES
  value: "0"
- name: OMP_NUM_THREADS
  value: "4"
```

## Deployment Patterns

### Blue-Green

```bash
# Deploy new version (green)
kubectl set image deployment/agent agent=agent:v2

# Wait for green to be ready
kubectl rollout status deployment/agent

# Switch traffic (cutover)
kubectl patch service agent-service -p '{"spec":{"selector":{"version":"v2"}}}'

# Keep old version (blue) for immediate rollback
kubectl rollout undo deployment/agent
```

### Canary

```yaml
# canary.yaml
apiVersion: v1
kind: Service
metadata:
  name: agent-canary
spec:
  selector:
    app: agent
    version: canary  # Only canary pods
  ports:
  - port: 80
---
# 5% traffic to canary
# 95% traffic to stable
```

```bash
# Canary deployment
kubectl scale deployment agent-canary --replicas=1
kubectl scale deployment agent-stable --replicas=19
```

### Rolling Update

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

## Resource Management

### Limit Ranges (namespace)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: ml-limits
spec:
  limits:
  - max:
      memory: "32Gi"
      cpu: "16"
    min:
      memory: "256Mi"
      cpu: "100m"
    default:
      memory: "4Gi"
      cpu: "2"
    defaultRequest:
      memory: "1Gi"
      cpu: "500m"
```

### Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ml-quota
spec:
  hard:
    requests.cpu: "32"
    requests.memory: "64Gi"
    pods: "50"
```

## Troubleshooting

### Common Issues

```bash
# Pod stuck in Pending
kubectl describe pod <pod-name>  # Check events
kubectl get events --sort-by='.lastTimestamp'

# ImagePullBackOff
kubectl get secrets # Ensure registry credentials
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io \
  --docker-username=user \
  --docker-password=pass

# OOMKilled
kubectl describe pod <pod-name> | grep -A5 "Last State"
# Increase memory limits

# GPU not available
kubectl describe node <node> | grep -A5 "Allocated Resources"
# Ensure nvidia-device-plugin is running
```

### Debug Tools

```bash
# Shell into pod
kubectl exec -it <pod-name> -- /bin/bash

# Copy files
kubectl cp <pod-name>:/app/logs ./local-logs

# Port forward (local debugging)
kubectl port-forward <pod-name> 8080:8080

# Check logs
kubectl logs -f <pod-name> --tail=100
```

## Security

### Non-Root User

```dockerfile
FROM python:3.11-slim
RUN useradd -m agent
WORKDIR /app
COPY --chown=agent:agent . .
USER agent
CMD ["python", "main.py"]
```

### Read-Only Root Filesystem

```yaml
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: agent-netpolicy
spec:
  podSelector:
    matchLabels:
      app: agent
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: ingress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: redis
```

## References

- [[ci-cd-agent-pipeline]] — CI/CD que usa Docker/K8s
- [[observability-agents]] — Monitoring de containers