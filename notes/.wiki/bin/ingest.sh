#!/bin/bash
# ingest.sh — Procesa nuevos sources y genera stub en wiki
# Uso: ./ingest.sh <url|path> <categoria> [titulo]

set -e

WIKI_DIR="${WIKI_DIR:-/home/nico/knowledge/notes}"
CATEGORIA="${2:-conceptos}"
SOURCE="$1"
TITLE="${3:-}"

if [ -z "$SOURCE" ]; then
  echo "Uso: $0 <url|path> <categoria> [titulo]"
  exit 1
fi

# Timestamp para文件名
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

# Determinar tipo y guardar en articulos/
if [[ "$SOURCE" =~ ^http ]]; then
  # Es URL — descargar
  mkdir -p "$WIKI_DIR/articulos"
  FILENAME="$WIKI_DIR/articulos/${TIMESTAMP}.html"
  curl -sL "$SOURCE" -o "$FILENAME"
  # Extraer título si no se proveyó
  if [ -z "$TITLE" ]; then
    TITLE=$(grep -o '<title>[^<]*</title>' "$FILENAME" 2>/dev/null | head -1 | sed 's/<[^>]*>//g' || echo "articulo-$TIMESTAMP")
  fi
else
  # Es path — copiar
  mkdir -p "$WIKI_DIR/articulos"
  cp "$SOURCE" "$WIKI_DIR/articulos/${TIMESTAMP}-$(basename "$SOURCE")"
  FILENAME="$WIKI_DIR/articulos/${TIMESTAMP}-$(basename "$SOURCE")"
fi

# Generar stub
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]+/-/g' | sed 's/^-//;s/-$//')
STUB_FILE="$WIKI_DIR/$CATEGORIA/${SLUG}.md"

cat > "$STUB_FILE" <<EOF
---
title: $TITLE
source: $SOURCE
date: $(date '+%Y-%m-%d')
tags: []
---

# $TITLE

## Resumen


## Key Takeaways


## Ver También

EOF

echo "Stub generado: $STUB_FILE"
echo "Source guardado: $FILENAME"