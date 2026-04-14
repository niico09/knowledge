#!/bin/bash
# lint.sh — Verificación de salud del wiki
# Uso: ./scripts/lint.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_DIR="$(dirname "$SCRIPT_DIR")"

NOTES_DIR="$WIKI_DIR/notes"
LOG_FILE="$WIKI_DIR/log.md"
INDEX_FILE="$WIKI_DIR/index.md"
ISSUES=0

echo "=== Lint: Knowledge Wiki ==="
echo ""

# 1. Buscar orphan pages (páginas sin incoming wiki-links)
echo "## 🔴 ORPHAN pages (sin referencias entrantes):"
ALL_PAGES=$(find "$NOTES_DIR" -name "*.md" -exec basename {} .md \; | sort)

# Extraer solo el target del wiki-link: [[target]] o [[target|desc]]
# Ignora lineas de tabla y listas que contienen [[ en otro contexto
LINKED_PAGES=$(grep -roh '\[\[[^|/]*' "$NOTES_DIR" | tr -d '[' | sort -u)

ORPHAN_COUNT=0
# Páginas meta que son孤儿 por diseño (no necesitan incoming links)
META_PAGES="index|log|wiki-lint-report"

for page in $ALL_PAGES; do
    # Skip páginas meta
    if echo "$page" | grep -qE "^($META_PAGES)$"; then
        continue
    fi
    # Buscar si alguna página tiene [[page]] o [[path/page]] o [[../path/page]]
    # -opcion 1: [[page]] (link directo al basename)
    # -opcion 2: [[subdir/page]] (path con subdirectorio)
    # -opcion 3: [[../otherdir/page]] (path relativo hacia arriba)
    if ! grep -rqE "\[\[$page\]\]|\[\[[^]]*/$page\]\]" "$NOTES_DIR" 2>/dev/null; then
        echo "  - $page (sin incoming links)"
        ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
    fi
done

if [ $ORPHAN_COUNT -eq 0 ]; then
    echo "  (ninguna) ✓"
fi
echo ""

# 2. Detectar wiki-links rotos
echo "## 🟡 Wiki-links rotos:"
BROKEN=0
# Solo wiki-links con nombres válidos: letras, números, guiones, guiones bajos, paths con /
# Excluye: variables shell ($VAR), URLs, código, tablas, archivos no-md
# Formato válido: [[name]] o [[path/name]] o [[name|desc]]
ALL_BROKEN=$(grep -rohE '\[\[[a-zA-Z0-9_/-]+(\|[^]]+)?\]\]' "$NOTES_DIR" --include="*.md" 2>/dev/null | \
    grep -v "/wiki-lint-report.md:" | \
    sed -E 's/\[\[([a-zA-Z0-9_/-]+)(\|[^]]+)?\]\]/\1/' | sort -u)

for link in $ALL_BROKEN; do
    # Ignorar wiki-lint-report (generado, contiene basura)
    if [ "$link" = "wiki-lint-report" ]; then
        continue
    fi
    # Buscar en subdirectorios de notes/
    if ! find "$NOTES_DIR" -name "${link##*/}.md" 2>/dev/null | grep -q .; then
        # Si es un path (contiene /), verificar tal cual
        if ! find "$NOTES_DIR" -path "*/$link.md" 2>/dev/null | grep -q .; then
            echo "  - [[$link]] → archivo no existe"
            BROKEN=$((BROKEN + 1))
        fi
    fi
done

if [ $BROKEN -eq 0 ]; then
    echo "  (ninguno) ✓"
fi
echo ""

# 3. Verificar stale claims (claims sin fecha)
echo "## 🟡 Claims sin fecha de verificación:"
STALE=$(grep -r "STALE:" "$NOTES_DIR" --include="*.md" -l 2>/dev/null || true)
if [ -n "$STALE" ]; then
    echo "$STALE" | while read f; do echo "  - ${f#$NOTES_DIR/}"; done
    ISSUES=$((ISSUES + 1))
else
    echo "  (ninguno) ✓"
fi
echo ""

# 4. Registrar en log
TOTAL_ISSUES=$((ORPHAN_COUNT + BROKEN))
if [ $TOTAL_ISSUES -gt 0 ]; then
    echo "⚠️ LINT: $TOTAL_ISSUES issues detectados"
    sed -i "1s/^/## $(date +"%Y-%m-%d %H:%M") — LINT: $TOTAL_ISSUES issues detectados\n/" "$LOG_FILE"
else
    echo "✓ LINT: Wiki saludable"
    sed -i "1s/^/## $(date +"%Y-%m-%d %H:%M") — LINT: Wiki saludable\n/" "$LOG_FILE"
fi