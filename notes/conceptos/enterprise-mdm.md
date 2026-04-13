# Enterprise MDM (Mobile Device Management)

## Definición

**MDM** en el contexto de agent systems no es mobile device management literal, sino el concepto de **enterprise-wide policy enforcement** — la capacidad de que administrators de IT enforceable políticas sobre el comportamiento de agents para toda la organización.

Así como MDM permite a IT admins enforce configuraciones de seguridad sobre todos los dispositivos de la empresa, el **CLAUDE.md hierarchy** permite a enterprise admins enforceable políticas sobre todos los agents que developers usan.

## El Problema que Resuelve

### Sin Policy Enforcement

```
Enterprise tiene rules:
- No commit directly a main
- All bash commands require confirmation
- Certain directories are off-limits
- Code must pass lint before commit

¿Cómo asegurar compliance?

Opción 1: Documentar → Developers ignoran
Opción 2: Training → Developers forget
Opción 3: Peer review → Bottleneck, expensive
Opción 4: MDM-style enforcement → No opción de bypass
```

## CLAUDE.md Hierarchy

El sistema de hierarchy tiene 4 niveles, analogous a MDM profiles:

```
┌─────────────────────────────────────────────────────────┐
│  LEVEL 1: Enterprise (MDM-Enforced)                    │
│  /etc/claude-code/CLAUDE.md                            │
│                                                         │
│  IT Admin configura, developers no pueden modificar     │
│  Policies apply to EVERYONE in the organization         │
├─────────────────────────────────────────────────────────┤
│  LEVEL 2: Project                                      │
│  .claude/CLAUDE.md                                      │
│                                                         │
│  Project maintainers configuran conventions             │
│  Apply to project contributors                          │
├─────────────────────────────────────────────────────────┤
│  LEVEL 3: User                                         │
│  ~/.claude/CLAUDE.md                                    │
│                                                         │
│  Developers configuran preferencias personales           │
│  Pueden override project settings                        │
├─────────────────────────────────────────────────────────┤
│  LEVEL 4: Local                                        │
│  CLAUDE.local.md (not in version control)               │
│                                                         │
│  Overrides privados para debugging                       │
│  Never se compromete al repo                            │
└─────────────────────────────────────────────────────────┘
```

## Ejemplo: Enterprise MDM Profile

```markdown
# /etc/claude-code/CLAUDE.md
# Enterprise Security Policies (MDM-Enforced)
---
name: enterprise-security
appliesTo: everyone
enforced: true
---

## Safety Rules (Cannot Be Overridden)

### Dangerous Commands
- NEVER execute: `rm -rf /`, `rm -rf node_modules`, `find / -delete`
- NEVER execute: Any command containing `sudo rm`
- NEVER modify files outside the project directory

### Code Review
- All commits must go through PR review
- Direct commits to main are blocked at permission level
- Lint must pass before commit is allowed

### Data Privacy
- Do NOT access: /etc/secrets, /production-configs, ~/.aws/credentials
- Do NOT read files outside current project
- Do NOT execute commands that output credentials

## Compliance Rules (Can Be Overridden Per-Project)

### Testing
- Unit tests required for all new functions
- Test coverage must be > 80%

### Documentation
- Public APIs must have documentation
- README must be updated for significant changes

## Audit
- All agent actions are logged to: /var/log/claude/audit.log
- Session transcripts preserved for 90 days
```

## Cómo Opera el Enforcement

### Check en Cada Tool Execution

```typescript
interface PermissionContext {
  enterprisePolicies: Policy[];
  projectPolicies: Policy[];
  userPolicies: Policy[];
  localOverrides: Policy[];
}

async function checkPermission(
  tool: ToolCall,
  context: PermissionContext
): Promise<PermissionResult> {
  // 1. Collect all applicable policies (bottom-up)
  const allPolicies = [
    ...context.localOverrides,
    ...context.userPolicies,
    ...context.projectPolicies,
    ...context.enterprisePolicies,
  ];

  // 2. Check DENY rules first (enterprise-level denials are final)
  for (const policy of allPolicies) {
    if (policy.type === 'deny' && policy.matches(tool)) {
      if (policy.enforced) {
        return { allowed: false, reason: policy.reason, canOverride: false };
      }
    }
  }

  // 3. Check ALLOW rules
  for (const policy of allPolicies) {
    if (policy.type === 'allow' && policy.matches(tool)) {
      return { allowed: true };
    }
  }

  // 4. Default: prompt user
  return { allowed: false, reason: 'No policy found', canOverride: true };
}
```

### Ejemplo: Command Filtering

```typescript
class DangerousCommandFilter {
  private patterns = [
    /^rm\s+-rf\s+/,           // rm -rf anything
    /^\s*find\s+\/\s+-delete/, // find / -delete
    /^sudo\s+rm/,             // sudo rm
    /;\s*rm\s+/,              // ; rm (command chaining)
  ];

  check(command: string): FilterResult {
    for (const pattern of this.patterns) {
      if (pattern.test(command)) {
        return {
          allowed: false,
          reason: `Command matches blocked pattern: ${pattern}`,
          suggestAlternative: 'Use interactive rm or specify exact path'
        };
      }
    }
    return { allowed: true };
  }
}
```

## @include Directive

Permite composition sin duplicación:

```markdown
# Enterprise base policy
# /etc/claude-code/CLAUDE.md

## Security Policies
@./security-policies.md

## Compliance Policies
@./compliance-policies.md

## Coding Standards
@./coding-standards.md
```

```markdown
# Project .claude/CLAUDE.md
# Hereda TODAS las enterprise policies
# sin tener que copy-paste

@/etc/claude-code/CLAUDE.md

## Project-Specific Additions

## Testing
- All PRs must include tests

## Documentation
- API changes must update OpenAPI spec
```

## RBAC (Role-Based Access Control)

### Roles Típicos en Enterprise

```typescript
interface RBACConfig {
  roles: {
    'developer': {
      canModifyOwnFiles: true,
      canRunTests: true,
      canCommitToFeatureBranches: true,
      canCommitToMain: false,
      canAccessProduction: false,
    },
    'senior-developer': {
      canModifyOwnFiles: true,
      canRunTests: true,
      canCommitToFeatureBranches: true,
      canCommitToMain: true,
      canAccessProduction: true,
    },
    'admin': {
      // All permissions
    }
  };
}
```

### Integración con SSO

```typescript
async function getUserRole(userId: string): Promise<Role> {
  // Integración con enterprise SSO (Okta, Azure AD, etc)
  const ssoUser = await ssoClient.getUser(userId);
  const groups = ssoUser.groups;

  if (groups.includes('claude-admin')) return 'admin';
  if (groups.includes('claude-senior')) return 'senior-developer';
  return 'developer';
}
```

## Por Qué Es Layer 4: Infrastructure

> *"This is infrastructure engineering, not harness engineering."*

El agent loop, el streaming, la compaction — eso es el harness (Layer 3). Pero un agent que opera en producción empresarial necesita:

```
Layer 4: Infrastructure
├── Multi-tenancy (aislamiento entre users)
├── RBAC (quién puede hacer qué)
├── Policy enforcement (reglas que no se pueden bypass)
├── Audit trails (logging de todo lo que ocurre)
├── Compliance (regulatory requirements)
├── SSO integration (identity management)
└── Session management (cómo se persiste el estado)
```

Estos NO son problemas del agent harness — son problemas de infrastructure empresarial.

## MDM vs Traditional Security

### Traditional Security (After the Fact)

```
Developer writes code → commits → gets rejected en PR review
Developer wasted time writing code that violates policy
Security team reviews PR → bottleneck
Delays merge by hours or days
```

### MDM-Style Enforcement (Before the Fact)

```
Developer tries to run forbidden command
→ Permission denied immediately
→ Policy reason displayed
→ Alternative suggested
No time wasted, no security breach
```

## Limitations y Challenges

### 1. False Positives

```markdown
# Blocking "rm -rf" might block legitimate:
rm -rf ./node_modules
rm -rf ./dist
rm -rf ./build

# Necesitas context-aware filtering:
rm -rf ONLY IF in root dir AND not in project
```

### 2. Usability vs Security

```
Too restrictive → developers work around the system
Too permissive → security gaps

Finding the balance is hard
```

### 3. Policy Updates

```
Enterprise updates policy → how propagate?
Options:
1. Restart all running agents (disruptive)
2. Apply on next turn (may not catch immediate violations)
3. Hybrid (immediate for dangerous, next turn for minor)
```

## Referencias

- **[[multi-tenancy]]**: El concepto más amplio de servir múltiples tenants
- **[[permission-system]]**: El sistema de permisos detallado
- **[[layer-4-infrastructure]]**: La capa de infrastructure
