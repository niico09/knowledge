#!/bin/bash
# lint.sh — Verificación de salud del wiki
# Uso: ./scripts/lint.sh

set -e

NOTES_DIR="knowledge/notes"
LOG_FILE="knowledge/log.md"
INDEX_FILE="knowledge/index.md"
ISSUES=0

echo "=== Lint: Knowledge Wiki ==="
echo ""

# 1. Buscar orphan pages (páginas sin incoming wiki-links)
echo "## 🔴 ORPHAN pages (sin referencias entrantes):"
ALL_PAGES=$(find "$NOTES_DIR" -name "*.md" -exec basename {} .md \; | sort)
LINKED_PAGES=$(grep -roh '\[\[.*\]\]' "$NOTES_DIR" | tr -d '[]' | sort -u)

for page in $ALL_PAGES; do
    if ! echo "$LINKED_PAGES" | grep -q "^${page}$"; then
        echo "  - $page (sin incoming links)"
        ISSUES=$((ISSUES + 1))
    fi
done

if [ $ISSUES -eq 0 ]; then
    echo "  (ninguna) ✓"
fi
echo ""

# 2. Detectar wiki-links rotos
echo "## 🟡 Wiki-links rotos:"
BROKEN=0
grep -r '\[\[[^]]*\]\]' "$NOTES_DIR" --include="*.md" -h | \
    sed 's/.*\[\[\([^]]*\)\]\].*/\1/g' | sort -u | while read link; do
    if ! find "$NOTES_DIR" -name "${link}.md" 2>/dev/null | grep -q .; then
        echo "  - [[$link]] → archivo no existe"
        BROKEN=$((BROKEN + 1))
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
if [ $ISSUES -gt 0 ]; then
    echo "⚠️ LINT: $ISSUES issues detectados"
    sed -i "1s/^/## $(date +"%Y-%m-%d %H:%M") — LINT: $ISSUES issues detectados\n/" "$LOG_FILE"
else
    echo "✓ LINT: Wiki saludable"
    sed -i "1s/^/## $(date +"%Y-%m-%d %H:%M") — LINT: Wiki saludable\n/" "$LOG_FILE"
fi