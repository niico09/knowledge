#!/bin/bash
# ingest.sh — Pipeline de ingest de nuevas fuentes
# Uso: ./scripts/ingest.sh <type> <title> <url>
# Tipos: article, podcast, video

set -e

TYPE="$1"
TITLE="$2"
URL="$3"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
LOG_FILE="knowledge/log.md"
INDEX_FILE="knowledge/index.md"

if [ -z "$TYPE" ] || [ -z "$TITLE" ] || [ -z "$URL" ]; then
    echo "Uso: $0 <type> <title> <url>"
    echo "Tipos: article, podcast, video"
    exit 1
fi

# 1. Crear directorio destino en sources/
SOURCE_DIR="knowledge/sources/${TYPE}s"
mkdir -p "$SOURCE_DIR"

# 2. Generar filename sanitizado
FILENAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
DEST="${SOURCE_DIR}/${DATE}-${FILENAME}.md"

# 3. Crear archivo con metadata
cat > "$DEST" << EOF
---
title: "$TITLE"
url: "$URL"
date: $DATE
type: $TYPE
status: raw
---

## Resumen

_Auto-generado post-ingest. Completar tras síntesis._

## Conceptos extraídos

- (pendiente)

## Fuentes relacionadas

- (pendiente)
EOF

# 4. Registrar en log.md
sed -i "1s/^/## $TIMESTAMP — INGEST: $TYPE $TITLE → sources/${TYPE}s/${DATE}-${FILENAME}.md\n/" "$LOG_FILE"

echo "✓ Fuente ingestada: $DEST"
echo "✓ Registrar síntesis en notes/ y actualizar index.md"