#!/bin/bash
# Memory Recall - Recupera memoria progresiva basada en keywords
# Uso: memory-recall.sh "keyword1 keyword2 ..."

MEMORY_DIR="/home/clawd/.openclaw/workspace/memory"
KEYWORDS="${1:-password api process service}"

echo "🔍 Recall para: $KEYWORDS"
echo "================================"

# Buscar en últimos 7 días
for day in $(ls -t "$MEMORY_DIR"/*.md 2>/dev/null | head -7); do
    if [ -f "$day" ]; then
        filename=$(basename "$day")
        echo "📅 $filename"
        grep -i "$KEYWORDS" "$day" 2>/dev/null | head -5
        echo ""
    fi
done
