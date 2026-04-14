#!/bin/bash
# synthesize.sh — Pipeline de síntesis: raw source → wiki page con LLM
# Uso: ./scripts/synthesize.sh <source_file> [destino] [categoria]
# Usa MiniMax M2.7 via mmx para generar la síntesis automáticamente
#
# Ejemplo: ./scripts/synthesize.sh sources/articulos/2026-04-09-post.md notes/sistema/ sistema

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIKI_DIR="$(dirname "$SCRIPT_DIR")"

SOURCE_FILE="$1"
DEST_DIR="${2:-notes/sistema}"
CATEGORIA="${3:-sistema}"

if [ -z "$SOURCE_FILE" ]; then
    echo "Uso: $0 <source_file> [destino] [categoria]"
    echo "Ejemplo: $0 sources/articulos/2026-04-09-post.md notes/sistema/ sistema"
    exit 1
fi

if [ ! -f "$WIKI_DIR/$SOURCE_FILE" ]; then
    echo "ERROR: Source file not found: $WIKI_DIR/$SOURCE_FILE"
    exit 1
fi

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
LOG_FILE="$WIKI_DIR/log.md"

# Extraer metadata del source
TITLE=$(grep "^title:" "$WIKI_DIR/$SOURCE_FILE" | cut -d'"' -f2 | head -1)
URL=$(grep "^url:" "$WIKI_DIR/$SOURCE_FILE" | cut -d'"' -f2 | head -1)
TAGS=$(grep "^tags:" "$WIKI_DIR/$SOURCE_FILE" | cut -d'[' -f2 | tr -d ']' | head -1)
TAGS=${TAGS:-untagged}

# Extraer contenido (todo después del frontmatter)
CONTENT=$(awk 'BEGIN{in_frontmatter=1} /^---$/{if(in_frontmatter){in_frontmatter=0;next}else in_frontmatter=1} in_frontmatter==0{print}' "$WIKI_DIR/$SOURCE_FILE" | head -200)

# Generar filename
FILENAME=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
DEST_PATH="${DATE}-${FILENAME}.md"
DEST="$DEST_DIR/$DEST_PATH"

mkdir -p "$WIKI_DIR/$DEST_DIR"

echo "=== SYNTHESIZING with MiniMax M2.7 ==="
echo "Source: $SOURCE_FILE"
echo "Dest: $DEST"
echo ""

# Llamar a mmx para sintetizar
SYNTHESIS=$(mmx text chat \
  --system "Eres un wiki maintainer disciplinado. Tu tarea es convertir articles raw en páginas wiki dentro del sistema LLM Wiki de Karpathy. Formato: markdown plano con frontmatter YAML. NO usar code fences. Devuelve SOLO el markdown completo, sin comentarios tuyos. Idioma: SOLO español. No mezcles texto en otros idiomas." \
  --message "user:Synthesiza el siguiente article en una página wiki.

## Reglas
- Devuelve markdown plano, SIN code fences (sin \`\`\`)
- SOLO español — sin texto en inglés, chino ni ningún otro idioma
- Frontmatter YAML en la parte superior
- Sections: ## Resumen, ## Conceptos Clave, ## Conexiones, ## Notas Personales, ## Fuentes
- En Conexiones usa [[wiki-links]] reales:
  - Para archivos en sources/: usa paths relativos desde notes/sistema/ (ej: [[../../../sources/articulos/2026-04-07-llm-wiki-karpathy]])
  - Para archivos en notes/: usa solo el nombre sin path (ej: [[ai-second-brain-claude-obsidian]])
- En Notas Personales escribe reflexiones genuinas, no placeholders
- Longitud: resumen 3-5 oraciones, 2-4 conceptos clave

## Article a sintetizar:
$CONTENT" \
  --output json 2>&1)

# Extraer el text del response JSON (ultimo content item con type=text)
TEXT=$(echo "$SYNTHESIS" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for item in reversed(d.get('content',[])):
    if item.get('type') == 'text':
        print(item.get('text',''))
        break
" 2>/dev/null)

# Limpiar code fences si las hay
TEXT=$(echo "$TEXT" | sed -E 's/^```markdown$//g' | sed -E 's/^```$//g')

# Escribir resultado
echo "$TEXT" > "$WIKI_DIR/$DEST"

# Verificar que se escribió algo
if [ ! -s "$WIKI_DIR/$DEST" ]; then
    echo "ERROR: Synthesis falló o devolvió vacío"
    exit 1
fi

echo "=== SYNTHESIS COMPLETADA ==="
echo "Archivo: $DEST"

# Actualizar frontmatter del source a synthesized
sed -i 's/^status: raw$/status: synthesized/' "$WIKI_DIR/$SOURCE_FILE"
sed -i "s/^synthesized_date:.*$/synthesized_date: $DATE/" "$WIKI_DIR/$SOURCE_FILE"

# Registrar en log
echo "" >> "$LOG_FILE"
echo "## $TIMESTAMP — SYNTHESIS: $TITLE → $DEST" >> "$LOG_FILE"

# Verificar con lint
echo ""
echo "=== LINT ==="
bash "$SCRIPT_DIR/lint.sh"

echo ""
echo "=== DONE ==="
echo "Revisar: $DEST"
