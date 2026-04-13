# Multi-Tenancy

## Definición

**Multi-tenancy** es la capacidad de un sistema para servir a múltiples usuarios o equipos (tenants) desde una misma infraestructura compartida, manteniendo aislamiento completo entre ellos — cada tenant cree que tiene su propia instancia privada del sistema.

En agent systems, multi-tenancy significa:
- Cada developer/team ve sus propios archivos y configuraciones
- Las políticas de enterprise se aplican solo a los devs correctos
- Los API keys y rate limits son por tenant
- Los datos de un tenant son inaccesibles para otros

## Single-Tenant vs Multi-Tenant

### Single-Tenant (Siloed)

```
Tenant A → Su propia infraestructura completa
Tenant B → Su propia infraestructura completa
Tenant C → Su propia infraestructura completa

Costo: Alto (3x infrastructure)
Aislamiento: Físico (100% seguro)
Maintenance: Por tenant
```

### Multi-Tenant (Shared)

```
┌─────────────────────────────────────────────────────────┐
│                    Shared Infrastructure                │
│                                                         │
│  Tenant A  │  Tenant B  │  Tenant C  │  Tenant D     │
│  (aislado) │  (aislado) │  (aislado) │  (aislado)    │
│                                                         │
└─────────────────────────────────────────────────────────┘

Costo: Bajo (1x infrastructure)
Aislamiento: Lógico (enforceado por software)
Maintenance: Centralizado
```

## Multi-Tenancy en Claude Code

### Dimensiones del Aislamiento

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Multi-Tenant Architecture                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Tenant Isolation Dimensions:                                         │
│                                                                      │
│  1. FILESYSTEM          → Project directories, home dirs              │
│  2. CONFIGURATION       → CLAUDE.md per level                        │
│  3. CREDENTIALS        → API keys per tenant                        │
│  4. RATE LIMITS         → Per-tenant quotas                          │
│  5. AUDIT LOGS          → Tenant-specific logging                    │
│  6. SESSION STATE       → Per-tenant compaction & history             │
│  7. NETWORK             → Tenant-specific MCP connections             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 1. Filesystem Isolation

```typescript
// Cada tenant tiene sus propios directorios
const TENANT_PATHS = {
  enterprise: '/etc/claude-code/',    // IT admin-only
  project: './.claude/',               // Per-project
  user: '~/.claude/',                 // Per-user home
  local: './CLAUDE.local.md',         // Per-workspace
};

// Lectura de configuración
async function readConfig(tenantId: string, level: ConfigLevel) {
  const basePath = TENANT_PATHS[level];

  // Path traversal prevention
  if (tenantId.includes('..') || tenantId.includes('/')) {
    throw new Error('Invalid tenant ID');
  }

  const configPath = path.join(basePath, tenantId, 'CLAUDE.md');
  return fs.readFile(configPath, 'utf-8');
}
```

### 2. Configuration Hierarchy

```typescript
interface TenantContext {
  tenantId: string;
  enterprisePolicies: Policy[];
  projectPolicies: Policy[];
  userPolicies: Policy[];
  localOverrides: Policy[];

  // Scoping de API calls
  apiKey: string;       // Tenant-specific
  rateLimits: {
    requestsPerMinute: number;
    tokensPerMinute: number;
  };

  // Allowed tools y resources
  allowedTools: string[];
  deniedPaths: string[];
}

function buildTenantContext(tenantId: string): TenantContext {
  return {
    tenantId,
    enterprisePolicies: loadEnterprisePolicies(tenantId),
    projectPolicies: loadProjectPolicies(tenantId),
    userPolicies: loadUserPolicies(tenantId),
    localOverrides: loadLocalOverrides(),

    apiKey: getAPIKeyForTenant(tenantId),
    rateLimits: getRateLimitsForTenant(tenantId),
    allowedTools: getAllowedTools(tenantId),
    deniedPaths: getDeniedPaths(tenantId),
  };
}
```

### 3. API Key Isolation

```typescript
// Cada tenant tiene su propia API key
class TenantAPIKeyManager {
  private keys = new Map<string, string>(); // tenantId → key

  async getKey(tenantId: string): Promise<string> {
    if (!this.keys.has(tenantId)) {
      // Load from secure storage (Vault, AWS Secrets Manager, etc)
      this.keys.set(tenantId, await vault.get(`api-key/${tenantId}`));
    }
    return this.keys.get(tenantId);
  }

  // Cada API call usa la key del tenant
  async callModel(tenantId: string, messages: Message[]) {
    const key = await this.getKey(tenantId);
    return openai.chat.completions.create({
      model: 'claude',
      messages,
      headers: {
        'Authorization': `Bearer ${key}`,
        'X-Tenant-ID': tenantId, // Para audit
      }
    });
  }
}
```

### 4. Rate Limiting por Tenant

```typescript
class TenantRateLimiter {
  private limits = new Map<string, TokenBucket>();

  getLimiter(tenantId: string): TokenBucket {
    if (!this.limits.has(tenantId)) {
      // Different tiers get different limits
      const tier = getTenantTier(tenantId);
      this.limits.set(tenantId, new TokenBucket({
        capacity: tier.requestsPerMinute,
        refillRate: tier.requestsPerMinute / 60,
      }));
    }
    return this.limits.get(tenantId);
  }

  async checkLimit(tenantId: string, tokens: number): Promise<boolean> {
    const limiter = this.getLimiter(tenantId);
    return limiter.tryConsume(tokens);
  }
}
```

### 5. Audit Logging por Tenant

```typescript
class TenantAuditLogger {
  async log(tenantId: string, event: AuditEvent): Promise<void> {
    const entry = {
      tenantId,
      timestamp: new Date().toISOString(),
      ...event,
    };

    // Cada tenant tiene su propio log stream
    await this.tenantStreams.get(tenantId).write(JSON.stringify(entry));

    // Enterprise admins pueden ver todos
    if (isEnterpriseAdmin(currentUser)) {
      await this.globalStream.write(JSON.stringify(entry));
    }
  }

  // Solo el tenant owner puede leer sus logs
  async getLogs(tenantId: string, filter: LogFilter): Promise<LogEntry[]> {
    if (currentTenantId !== tenantId && !isEnterpriseAdmin(currentUser)) {
      throw new Error('Unauthorized');
    }
    return this.queryLogs(tenantId, filter);
  }
}
```

## Por Qué Importa

### Enterprise Adoption

> *"Without multi-tenancy, every developer needs their own Claude Code installation, their own API keys, their own configuration. That's 1000 developers = 1000 installations to manage."*

Con multi-tenancy:
- Enterprise admin configura políticas una vez
- Todos los developers heredan automáticamente
- API keys centralizadas y auditadas
- Compliance reporting agregado

### Cost Efficiency

```
100 developers
├── Single-tenant: 100 × $20/month = $2,000/month
└── Multi-tenant: 1 × $100/month + overhead = ~$300/month
```

## Aislamiento de Sesiones

```typescript
class TenantSessionManager {
  // Cada sesión sabe su tenant
  createSession(tenantId: string): Session {
    return {
      id: uuid(),
      tenantId,
      createdAt: Date.now(),
      compactionState: initialCompactionState(tenantId),
      claudeMdStack: loadAllClaudeMd(tenantId),
    };
  }

  // Sesiones no pueden cross-contaminate
  async executeInSession<T>(
    sessionId: string,
    fn: (context: SessionContext) => Promise<T>
  ): Promise<T> {
    const session = this.getSession(sessionId);

    // Aislar filesystem operations
    const originalCwd = process.cwd();
    const sessionDir = getSessionDir(session.tenantId);

    process.chdir(sessionDir); // Cambiar a dir del tenant

    try {
      return await fn({
        ...session,
        // Inyectar tenant-specific deps
        apiKey: await this.apiKeyManager.getKey(session.tenantId),
        rateLimiter: this.rateLimiters.get(session.tenantId),
      });
    } finally {
      process.chdir(originalCwd); // Restaurar cwd
    }
  }
}
```

## RBAC Integration

Multi-tenancy y RBAC son complementarios:

```typescript
interface RBACPolicy {
  role: 'developer' | 'senior' | 'lead' | 'admin';
  permissions: Permission[];
}

const ROLE_PERMISSIONS: Record<string, RBACPolicy> = {
  developer: {
    role: 'developer',
    permissions: [
      'read:own-project',
      'write:own-project-files',
      'execute:allowed-tools',
      'read:own-sessions',
    ]
  },
  admin: {
    role: 'admin',
    permissions: [
      '*', // Everything
    ]
  }
};

// Combinar tenant isolation + RBAC
async function authorize(
  tenantId: string,
  userId: string,
  action: string,
  resource: string
): Promise<boolean> {
  const tenantPolicy = await getTenantPolicy(tenantId);
  const userRole = await getUserRole(userId);
  const userPermissions = ROLE_PERMISSIONS[userRole].permissions;

  // Tenant-level check
  if (!tenantPolicy.allows(action, resource)) {
    return false;
  }

  // RBAC check
  if (!userPermissions.includes('*') &&
      !userPermissions.includes(action)) {
    return false;
  }

  return true;
}
```

## Diferencia con Single-Tenancy

| Aspecto | Single-Tenant | Multi-Tenant |
|--------|---------------|--------------|
| Infrastructure | Dedicated per user | Shared |
| Cost | $100/user/month | $5-20/user/month |
| Isolation | Physical | Logical |
| Maintenance | Per-instance | Centralized |
| Compliance | Per-customer | Enterprise-wide |
| Onboarding | Days | Minutes |

## References

- **[[enterprise-mdm]]**: Policy enforcement a nivel enterprise
- **[[permission-system]]**: Permissions específicos
- **[[layer-4-infrastructure]]**: La capa de infrastructure que soporta multi-tenancy
