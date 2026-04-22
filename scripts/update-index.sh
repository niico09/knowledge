#!/bin/bash
# update-index.sh — Actualiza index.md con nueva entrada
# Uso: ./scripts/update-index.sh <entry_type> <title> <tags> <fuentes> <destino>
# Ejemplo: ./scripts/update-index.sh sistema "AI Second Brain" "obsidian,claude" "post:aiedge_" notas/sistema/

ENTRY_TYPE="$1"
TITLE="$2"
TAGS="$3"
FUENTES="$4"
DESTINO="$5"
DATE=$(date +%Y-%m-%d")

INDEX_FILE="knowledge/index.md"

if [ -z "$ENTRY_TYPE" ] || [ -z "$TITLE" ]; then
    echo "Uso: $0 <entry_type> <title> <tags> <fuentes> <destino>"
    echo "entry_type: conceptos, procesos, herramientas, sistema"
    exit 1
fi

# Construir entrada
ENTRY="| ${DATE}-${ENTRY_TYPE} | $TAGS | $FUENTES | $DATE |"

# Determinar línea después de la cual insertar
case "$ENTRY_TYPE" in
    conceptos) SECTION_HEADER="| Página | Tags | Fuentes | Ultima actualización |" ;;
    procesos) SECTION_HEADER="## Procesos" ;;
    herramientas) SECTION_HEADER="## Herramientas" ;;
    sistema) SECTION_HEADER="## Sistema" ;;
esac

# Buscar línea del header de sección y insertar después
# (简易版本 - en producción usar gawk para más robustez)
echo "Entry: $ENTRY"
echo "Para actualizar index.md manualmente, agregar esta línea en la sección $ENTRY_TYPE:"
echo ""
echo "$ENTRY"
echo ""
echo "Luego ejecutar: ./scripts/lint.sh"
