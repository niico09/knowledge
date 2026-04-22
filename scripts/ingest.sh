#!/bin/bash
# ingest.sh — Pipeline de ingest de nuevas fuentes
# Uso: ./scripts/ingest.sh <type> <title> <url> [destino]
# Tipos: article, podcast, video
# Destino opcional: notas/conceptos/, notas/procesos/, etc.

set -e

# Detectar directorio base del wiki
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_DIR="$(dirname "$SCRIPT_DIR")"

TYPE="$1"
TITLE="$2"
URL="$3"
DEST_DIR="${4:-notas/sistema}"

LOG_FILE="$WIKI_DIR/log.md"
INDEX_FILE="$WIKI_DIR/index.md"

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")

if [ -z "$TYPE" ] || [ -z "$TITLE" ] || [ -z "$URL" ]; then
    echo "Uso: $0 <type> <title> <url> [destino]"
    echo "Tipos: article, podcast, video"
    echo "Destino: notas/conceptos/, notas/procesos/, notas/herramientas/, notas/sistema/"
    exit 1
fi

# 1. Crear directorio destino en sources/
SOURCE_DIR="$WIKI_DIR/sources/${TYPE}s"
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
ingested_by: ingest.sh
---

## Resumen

_Auto-generado post-ingest. Completar tras sintesis._

## Conceptos extraidos

- (pendiente)

## Fuentes relacionadas

- (pendiente)
EOF

# 4. Registrar en log.md (append-only, formato correcto)
echo "" >> "$LOG_FILE"
echo "## $TIMESTAMP — INGEST: $TYPE \"$TITLE\" → sources/${TYPE}s/${DATE}-${FILENAME}.md" >> "$LOG_FILE"

echo ""
echo "=== INGEST COMPLETADO ==="
echo "Fuente guardada: $DEST"
echo "Registrado en log.md"
echo ""
echo "=== SIGUIENTE PASO ==="
echo "1. Analizar contenido y guardar sintesis en notes/<categoria>/"
echo "2. Crear pagina de sintesis (ver template abajo)"
echo "3. Actualizar index.md con entrada en la categoria correspondiente"
echo "4. Ejecutar ./scripts/lint.sh para verificar"
echo ""
echo "=== TEMPLATE SINTESIS ==="
echo ""
cat << 'TEMPLATE'
---
title: "<titulo>"
date: YYYY-MM-DD
type: synthesis
source: [[sources/TIPO/fecha-titulo]]
category: sistema
tags: [tag1, tag2]
---

## Resumen

(3-5 oraciones resumiendo el contenido)

## Conceptos Clave

### Concepto 1
Descripcion.

### Concepto 2
Descripcion.

## Conexiones

- Relacionado con: [[pagina existente]]
- Contradice: [[pagina existente]] ⚠️ CONTRADICTION

## Notas Personales

(reflexiones/uso pratico)

## Fuentes

- [[sources/TIPO/fecha-titulo]]
TEMPLATE
