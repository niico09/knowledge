#!/bin/bash
# query.sh — Query del wiki con síntesis
# Uso: ./scripts/query.sh <keyword1> [keyword2...]

set -e

KEYWORDS="$*"
INDEX="knowledge/index.md"

if [ -z "$KEYWORDS" ]; then
    echo "Uso: $0 <keyword1> [keyword2...]"
    exit 1
fi

echo "=== Query: $KEYWORDS ==="
echo ""

# 1. Buscar en index.md
echo "## Páginas relacionadas (index):"
grep -i "$KEYWORDS" "$INDEX" | head -10 || echo "(ninguna)"
echo ""

# 2. Buscar en notes/
echo "## Contenido matching:"
for kw in $KEYWORDS; do
    grep -ri "$kw" knowledge/notes/ --include="*.md" -l 2>/dev/null | head -5
done | sort -u | while read file; do
    echo "  [[${file#knowledge/notes/}]]"
done

echo ""
echo "=== Para síntesis con NotebookLM, usar: notebooklm_query <topic> ==="