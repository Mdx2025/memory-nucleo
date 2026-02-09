#!/bin/bash
# 🧠 Auto-Learning v2 - Detecta "ya te lo dije"
# Uso: ./memory-autolearn-v2.sh learn "query" "response"
#       ./memory-autolearn-v2.sh check "query"
#       ./memory-autolearn-v2.sh stats

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory-tracked"
LEARN_DIR="$MEMORY_DIR/autolearn"
mkdir -p "$LEARN_DIR"

# Guardar aprendizaje
learn() {
    local query="$1"
    local response="$2"
    [[ -z "$query" || -z "$response" ]] && { echo "❌ Uso: learn <query> <response>"; exit 1; }
    
    # Normalizar query (lowercase, trim)
    local normalized=$(echo "$query" | tr '[:upper:]' '[:lower:]' | xargs)
    local hash=$(echo "$normalized" | sha256sum | cut -d' ' -f1)
    local timestamp=$(date -Iseconds)
    
    cat > "$LEARN_DIR/${hash}.json" << EOF
{
  "query": "$query",
  "normalized": "$normalized",
  "hash": "$hash",
  "response": "$response",
  "timestamp": "$timestamp",
  "count": 1
}
EOF
    
    echo "✅ Aprendido: ${hash:0:12}..."
}

# Verificar si ya se respondió
check() {
    local query="$1"
    [[ -z "$query" ]] && { echo "❌ Uso: check <query>"; exit 1; }
    
    local normalized=$(echo "$query" | tr '[:upper:]' '[:lower:]' | xargs)
    local hash=$(echo "$normalized" | sha256sum | cut -d' ' -f1)
    
    # Buscar coincidencia exacta
    if [[ -f "$LEARN_DIR/${hash}.json" ]]; then
        local stored=$(cat "$LEARN_DIR/${hash}.json" | jq -r '.response')
        local count=$(cat "$LEARN_DIR/${hash}.json" | jq -r '.count')
        
        # Incrementar counter
        cat "$LEARN_DIR/${hash}.json" | jq ".count = ($count + 1)" > "$LEARN_DIR/${hash}.json.tmp"
        mv "$LEARN_DIR/${hash}.json.tmp" "$LEARN_DIR/${hash}.json"
        
        echo "DUPLICATE|$stored"
        return 0
    fi
    
    # Buscar similar (mismas palabras clave)
    local keywords=$(echo "$normalized" | grep -oE '\b[a-z]{4,}\b' | sort -u | head -5 | tr '\n' ' ' | xargs)
    
    if [[ -n "$keywords" ]]; then
        for kw in $keywords; do
            match=$(find "$LEARN_DIR" -name "*.json" -exec grep -l "$kw" {} \; 2>/dev/null | head -1)
            [[ -n "$match" ]] && {
                local stored=$(cat "$match" | jq -r '.response')
                echo "SIMILAR|$stored"
                return 0
            }
        done
    fi
    
    echo "NEW|"
    return 1
}

# Stats
stats() {
    echo "📊 Auto-Learn Stats"
    echo "==================="
    echo ""
    echo "Total learned: $(ls -1 "$LEARN_DIR"/*.json 2>/dev/null | wc -l)"
    
    local most_recent=$(find "$LEARN_DIR" -name "*.json" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    if [[ -n "$most_recent" ]]; then
        local timestamp=$(cat "$most_recent" | jq -r '.timestamp')
        echo "Último: $timestamp"
    fi
    
    local dupes=$(grep -r '"count":' "$LEARN_DIR"/*.json 2>/dev/null | awk -F': ' '{print $2}' | awk -F',' '{print $1}' | awk '$1 > 1' | wc -l)
    echo "Queries repetidas detectadas: $dupes"
}

# CLI
case "${1:-}" in
    learn)
        shift
        learn "$1" "$2"
        ;;
    check)
        shift
        check "$1"
        ;;
    stats)
        stats
        ;;
    *)
        echo "Usage: $0 <learn|check|stats> [args]"
        exit 1
        ;;
esac
