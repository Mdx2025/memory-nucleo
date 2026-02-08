#!/bin/bash
# Memory Search - Búsqueda completa en toda la memoria
# Uso: memory-search.sh "query"

MEMORY_DIR="/home/clawd/.openclaw/workspace/memory"
QUERY="${1:-.}"

if [ -z "$QUERY" ] || [ "$QUERY" = "." ]; then
    echo "❌ Uso: memory-search.sh \"query\""
    exit 1
fi

echo "🔍 Buscando: '$QUERY'"
echo "================================"

# Buscar en todos los archivos de memoria
results=$(grep -r -n -i "$QUERY" "$MEMORY_DIR" --include="????-??-??.md" 2>/dev/null)

if [ -z "$results" ]; then
    echo "❌ No encontrado"
    exit 1
fi

echo "$results" | head -20
echo ""
echo "Total matches: $(echo "$results" | wc -l)"
