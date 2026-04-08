#!/bin/bash
# build-index.sh — Genera index.md con todos los archivos de la wiki

WIKI_DIR="${WIKI_DIR:-$HOME/knowledge/notes}"
OUTPUT="$WIKI_DIR/index.md"

# Encabezado
echo "# Índice de Conocimiento" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "Generado: $(date '+%Y-%m-%d %H:%M')" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "---" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Categorías a incluir (orden priorizado)
CATEGORIES="conceptos procesos herramientas sistema articulos personas proyectos arquitectura"

for cat in $CATEGORIES; do
  if [ -d "$WIKI_DIR/$cat" ]; then
    echo "## $cat/" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    # Lista archivos markdown con fecha y resumen (primera línea)
    while IFS= read -r file; do
      filename=$(basename "$file" .md)
      moddate=$(date -r "$file" '+%Y-%m-%d' 2>/dev/null || echo "unknown")
      # Primera línea como resumen (sin # ni espacios extra)
      summary=$(head -1 "$file" 2>/dev/null | sed 's/^#* *//' | cut -c1-80)
      echo "- [[$filename]] ($moddate) — ${summary:-Sin descripción}" >> "$OUTPUT"
    done < <(find "$WIKI_DIR/$cat" -name "*.md" -type f | sort)
    echo "" >> "$OUTPUT"
  fi
done

# Total de archivos
total=$(find "$WIKI_DIR" -name "*.md" -type f ! -name "index.md" ! -path "*/.wiki/*" | wc -l)
echo "---" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "*Total: $total archivos*" >> "$OUTPUT"
