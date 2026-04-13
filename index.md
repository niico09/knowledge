# Knowledge Wiki — Index

Catálogo de todas las páginas del wiki. Actualizado post-ingest.

## Conceptos (`notes/conceptos/`)

| Página | Tags | Fuentes | Ultima actualización |
|--------|------|---------|---------------------|
| (vacío) | | | |

## Procesos (`notes/procesos/`)

| Página | Tags | Fuentes | Ultima actualización |
|--------|------|---------|---------------------|
| (vacío) | | | |

## Herramientas (`notes/herramientas/`)

| Página | Tags | Fuentes | Ultima actualización |
|--------|------|---------|---------------------|
| (vacío) | | | |

## Sistema (`notes/sistema/`)

| Página | Tags | Fuentes | Ultima actualización |
|--------|------|---------|---------------------|
| notion-kb-overview | notebooklm, workflow | post:ihtesham2005 | 2026-04-04 |
| bytebytego-sources | arquitectura, podcast | blog.bytebytego.com | 2026-04-05 |
| claude-desktop-configuracion | claude-desktop, mcp | notebooklm | 2026-03-29 |
| java-event-driven | java, kafka, events | java-17+ notebook | 2026-03-26 |
| java-spring-ai | java, springai, rag | java-17+ notebook | 2026-03-26 |
| skills-en-produccion-lecciones | skills, claude | thariq tweet | 2026-03-26 |
| ai-second-brain-claude-obsidian | obsidian, llm, second-brain | posts karpathy + kanika + aiedge_ | 2026-04-12 |

## Raw Sources (`sources/`)

| Fuente | Tipo | Estado | Destino |
|--------|------|--------|---------|
| 2026-04-07-llm-wiki-karpathy | gist | ✅ synthesized | notes/sistema/ai-second-brain |
| 2026-04-09-claude-code--obsidian-ultimate-guide | x-post | ✅ synthesized | notes/sistema/ai-second-brain |

## Vault Structure

```
knowledge/
├── 00 - Inbox/           # Captura rápida, sin procesar
├── 01 - Raw Sources/      # (usar sources/ en su lugar)
├── 02 - Wiki/             # (usar notes/sistema/ en su lugar)
├── notes/                 # Wiki pages
├── sources/               # Raw sources
├── scripts/               # Pipeline scripts
├── index.md               # Catálogo
├── log.md                 # Registro append-only
└── CLAUDE.md.local        # Schema
```

---

## Búsqueda rápida

- **Arquitectura de software:** [[sistema/bytebytego-sources]]
- **Java/Spring:** [[sistema/java-event-driven]], [[sistema/java-spring-ai]]
- **Skills/Claude Code:** [[sistema/skills-en-produccion-lecciones]], [[sistema/ai-second-brain-claude-obsidian]]
- **Learning Engine:** [[sistema/notion-kb-overview]], [[sistema/claude-desktop-configuracion]]
