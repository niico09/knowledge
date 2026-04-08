#!/bin/bash
# lint.sh — Detecta orphans, links rotos y archivos similares

WIKI_DIR="${WIKI_DIR:-/home/nico/knowledge/notes}"
REPORT="$WIKI_DIR/wiki-lint-report.md"

echo "# Wiki Lint Report" > "$REPORT"
echo "" >> "$REPORT"
echo "Generado: $(date '+%Y-%m-%d %H:%M')" >> "$REPORT"
echo "" >> "$REPORT"

# 1. Detectar links rotos ( [[archivo]] que no existe)
echo "## Links Rotos" >> "$REPORT"
echo "" >> "$REPORT"
BROKEN_LINKS=0
while IFS= read -r file; do
  # Buscar [[...]] que no tengan archivo corresponding
  while IFS= read -r link; do
    linkname=$(echo "$link" | sed 's/\[\[\(.*\)\]\]/\1/' | tr -d '\n')
    if [ ! -f "$WIKI_DIR/$linkname.md" ] && [ ! -f "$WIKI_DIR/${linkname}.md" ]; then
      echo "- $file: [[$linkname]]" >> "$REPORT"
      ((BROKEN_LINKS++))
    fi
  done < <(grep -hE '\[\[[^]]+\]\]' "$file" 2>/dev/null)
done < <(find "$WIKI_DIR" -name "*.md" ! -path "*/.wiki/*" -type f)

if [ "$BROKEN_LINKS" -eq 0 ]; then
  echo "- Ningun link roto encontrado" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 2. Detectar archivos huérfanos (sin inbound links)
echo "## Archivos Huérfanos" >> "$REPORT"
echo "" >> "$REPORT"
ALL_FILES=$(find "$WIKI_DIR" -name "*.md" ! -path "*/.wiki/*" ! -name "index.md" ! -name "log.md" ! -name "wiki-lint-report.md" -type f)
ORPHANS=0
for file in $ALL_FILES; do
  filename=$(basename "$file" .md)
  # Buscar si alguien linkea a este archivo
  LINKED=$(grep -l "\[\[$filename\]\]" "$WIKI_DIR"/**/*.md 2>/dev/null | grep -v "$file")
  if [ -z "$LINKED" ]; then
    echo "- $filename.md (sin inbound links)" >> "$REPORT"
    ((ORPHANS++))
  fi
done
if [ "$ORPHANS" -eq 0 ]; then
  echo "- Ningun archivo huérfano" >> "$REPORT"
fi
echo "" >> "$REPORT"

# 3. Resumen
echo "## Resumen" >> "$REPORT"
echo "" >> "$REPORT"
echo "- Links rotos: $BROKEN_LINKS" >> "$REPORT"
echo "- Archivos huérfanos: $ORPHANS" >> "$REPORT"