#!/bin/bash
# 🔄 Cross-Session Recall - Búsqueda por días
# Uso: ./memory-cross-session.sh search "query" --days 7
#       ./memory-cross-session.sh timeline [YYYY-MM-DD]
#       ./memory-cross-session.sh stats

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="$WORKSPACE/memory-tracked"
UPDATES_DIR="$MEMORY_DIR/updates"
SNAPSHOTS_DIR="$MEMORY_DIR/snapshots"
SESSION_DIR="$WORKSPACE/.session-handoff"

mkdir -p "$UPDATES_DIR" "$SNAPSHOTS_DIR" "$SESSION_DIR"

# Buscar en sesiones históricas
search() {
    local query="$1"
    local days=7
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --days)
                days="$2"
                shift 2
                ;;
            *)
                query="$1"
                shift
                ;;
        esac
    done
    
    local cutoff=$(date -d "-$days days" +%Y-%m-%d 2>/dev/null || date -v-"${days}d" +%Y-%m-%d 2>/dev/null || echo "2026-02-02")
    
    echo "🔍 Buscando '$query' en últimos $days días (desde $cutoff)"
    echo ""
    
    local found=0
    
    for f in "$UPDATES_DIR"/*.md; do
        [[ -f "$f" ]] || continue
        local date=$(basename "$f" | cut -d'_' -f1)
        
        if [[ "$date" > "$cutoff" ]]; then
            if grep -qi "$query" "$f" 2>/dev/null; then
                echo "📝 $(basename "$f")"
                grep -B1 -A1 "$query" "$f" 2>/dev/null | head -5
                echo ""
                ((found++))
            fi
        fi
    done
    
    for f in "$SESSION_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        if grep -qi "$query" "$f" 2>/dev/null; then
            echo "🔄 $(basename "$f")"
            grep -o '"summary"[^,]*' "$f" 2>/dev/null | head -2
            echo ""
            ((found++))
        fi
    done
    
    for f in "$MEMORY_DIR/autolearn"/*.json; do
        [[ -f "$f" ]] || continue
        if grep -qi "$query" "$f" 2>/dev/null; then
            local ts=$(cat "$f" | jq -r '.timestamp' | cut -d'T' -f1)
            echo "🧠 $(basename "$f") ($ts)"
            cat "$f" | jq -r '.query' 2>/dev/null
            echo ""
            ((found++))
        fi
    done
    
    [[ $found -eq 0 ]] && echo "❌ No encontrado" || echo "✅ $found fuentes"
}

timeline() {
    local target_date="${1:-}"
    
    echo "📅 Timeline"
    echo "==========="
    echo ""
    
    if [[ -n "$target_date" ]]; then
        echo "📌 $target_date"
        ls "$UPDATES_DIR"/*${target_date}*.md 2>/dev/null | while read -r f; do echo "  📝 $(basename "$f")"; done
        ls "$SNAPSHOTS_DIR"/*${target_date}*.json 2>/dev/null | while read -r f; do echo "  📸 $(basename "$f")"; done
    else
        echo "Updates recientes:"
        ls -t "$UPDATES_DIR"/*.md 2>/dev/null | head -5 | while read -r f; do echo "  📝 $(basename "$f")"; done
        
        echo ""
        echo "Sessions:"
        ls -t "$SESSION_DIR"/*.json 2>/dev/null | head -3 | while read -r f; do echo "  🔄 $(basename "$f")"; done
        
        echo ""
        echo "Auto-learn:"
        ls -t "$MEMORY_DIR/autolearn"/*.json 2>/dev/null | head -3 | while read -r f; do echo "  🧠 $(basename "$f")"; done
    fi
}

stats() {
    echo "📊 Cross-Session Stats"
    echo "======================"
    echo ""
    
    echo "Updates: $(ls -1 "$UPDATES_DIR"/*.md 2>/dev/null | wc -l)"
    echo "Snapshots: $(ls -1 "$SNAPSHOTS_DIR"/*.json 2>/dev/null | wc -l)"
    echo "Sessions: $(ls -1 "$SESSION_DIR"/*.json 2>/dev/null | wc -l)"
    echo "Auto-learn: $(ls -1 "$MEMORY_DIR/autolearn"/*.json 2>/dev/null | wc -l)"
}

export_context() {
    local days="${1:-3}"
    local cutoff=$(date -d "-$days days" +%Y-%m-%d 2>/dev/null || echo "2026-02-06")
    
    echo '{"memory": ['
    local first=1
    
    for f in "$UPDATES_DIR"/*.md; do
        [[ -f "$f" ]] || continue
        local date=$(basename "$f" | cut -d'_' -f1)
        
        if [[ "$date" > "$cutoff" ]]; then
            [[ $first -eq 0 ]] && echo ","
            first=0
            local summary=$(head -2 "$f" | tail -1 | sed 's/## //' | xargs)
            echo -n '{"date": "'"$date"'", "topic": "'"$summary"'"}'
        fi
    done
    
    echo "], "autolearn": ["
    first=1
    for f in "$MEMORY_DIR/autolearn"/*.json; do
        [[ -f "$f" ]] || continue
        [[ $first -eq 0 ]] && echo ","
        first=0
        local q=$(cat "$f" | jq -r '.query' | tr -d '"')
        local ts=$(cat "$f" | jq -r '.timestamp' | cut -d'T' -f1)
        echo -n '{"query": "'"$q"'", "date": "'"$ts"'"}'
    done
    
    echo "]}"
}

case "${1:-}" in
    search)
        shift
        search "$@"
        ;;
    timeline)
        shift
        timeline "$1"
        ;;
    stats)
        stats
        ;;
    export)
        shift
        export_context "$1"
        ;;
    *)
        echo "Usage: $0 <search|timeline|stats|export> [args]"
        exit 1
        ;;
esac
