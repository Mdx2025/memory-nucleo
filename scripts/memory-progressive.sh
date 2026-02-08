#!/bin/bash
# Progressive Memory Manager - Auto-learning system with tags

MEMORY_DIR="/home/clawd/.openclaw/workspace/memory"
TODAY=$(date +%Y-%m-%d)
FILE="$MEMORY_DIR/$TODAY.md"

# Initialize today's memory file if not exists
init_daily() {
    if [ ! -f "$FILE" ]; then
        cat > "$FILE" << 'TEMPLATE'
# $(date +%Y-%m-%d) (Jarvis)

## 📋 Index (~80 tokens)
| # | Type | Status | Priority | Summary | ~Tok |
|---|------|--------|----------|---------|------|

---

## Notes
TEMPLATE
    fi
}

# Add memory entry with progressive format and tags
add() {
    local type="$1"
    local summary="$2"
    local tokens="${3:-100}"
    local context="$4"
    local status="${5:-active}"
    local priority="${6:-medium}"
    
    init_daily
    
    # Find next entry number
    local last_num=$(grep -E '^\| [0-9]+ \|' "$FILE" 2>/dev/null | tail -1 | sed 's/| \([0-9]*\) |.*/\1/' || echo "0")
    local next_num=$((last_num + 1))
    
    # Get icon based on type
    local icon=$(get_icon "$type")
    
    # Add to index with tags
    sed -i "/^|---|------|--------|----------|-----|$/a| $next_num | $icon | $status | $priority | $summary | $tokens |" "$FILE"
    
    # Add full entry with metadata
    cat >> "$FILE" << ENTRY

### #$next_num | $icon $summary | ~$tokens tokens
**Type:** $type
**Status:** $status
**Priority:** $priority
**Context:** $context
**Last Referenced:** $(date -Iseconds)
**Created:** $(date -Iseconds)
ENTRY
    
    echo "✅ Entry #$next_num added: $summary [$status, $priority]"
}

get_icon() {
    case "$1" in
        rule) echo "🚨" ;;
        gotcha) echo "🔴" ;;
        fix) echo "🟡" ;;
        how) echo "🔵" ;;
        change) echo "🟢" ;;
        discovery) echo "🟣" ;;
        why) echo "🟠" ;;
        decision) echo "🟤" ;;
        tradeoff) echo "⚖️" ;;
        *) echo "🔵" ;;
    esac
}

# Update entry status
update_status() {
    local num="$1"
    local new_status="$2"
    
    if [ ! -f "$FILE" ]; then
        echo "❌ No memory file for today"
        return 1
    fi
    
    # Update index
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/\1 | $new_status | \2 |/" "$FILE"
    
    # Update full entry
    sed -i "s/\*\*Status:\*\* \(.*\)/\*\*Status:\*\* $new_status/" "$FILE"
    sed -i "s/\*\*Last Referenced:\*\*/\*\*Last Referenced:\*\* $(date -Iseconds)/" "$FILE"
    
    echo "✅ Entry #$num status → $new_status"
}

# Update entry priority
update_priority() {
    local num="$1"
    local new_priority="$2"
    
    if [ ! -f "$FILE" ]; then
        echo "❌ No memory file for today"
        return 1
    fi
    
    # Update index
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/\1 | \2 | $new_priority | \3 |/" "$FILE"
    
    # Update full entry
    sed -i "s/\*\*Priority:\*\* \(.*\)/\*\*Priority:\*\* $new_priority/" "$FILE"
    
    echo "✅ Entry #$num priority → $new_priority"
}

# Mark entry as referenced (updates timestamp)
reference() {
    local num="$1"
    
    if [ ! -f "$FILE" ]; then
        echo "❌ No memory file for today"
        return 1
    fi
    
    sed -i "s/\*\*Last Referenced:\*\* \(.*\)/\*\*Last Referenced:\*\* $(date -Iseconds)/" "$FILE"
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/\1 | \2 | \3 |/" "$FILE"
    
    echo "✅ Entry #$num referenced"
}

# Scan index only (fast) - show only active entries
scan_index() {
    init_daily
    echo "=== 📋 Index for $TODAY (active only) ==="
    grep -E '^#|^\| [0-9]+ | active |' "$FILE" | head -20
}

# Scan all entries regardless of status
scan_all() {
    init_daily
    echo "=== 📋 Index for $TODAY (all) ==="
    grep -E '^#|^\| [0-9]+ |' "$FILE" | head -20
}

# Show entry by number
show() {
    local num="$1"
    local content=$(sed -n "/^### #$num |/,/^### [0-9]/p" "$FILE" | head -20)
    echo "$content"
}

# List all entries
list() {
    grep -E '^\| [0-9]+ |' "$FILE"
}

# List only active entries
list_active() {
    grep -E '^\| [0-9]+ |.*| active |' "$FILE"
}

# Stats
stats() {
    echo "=== 📊 Memory Stats ==="
    echo "Today's entries: $(grep -c '^\| [0-9]+ |' "$FILE" 2>/dev/null || echo 0)"
    echo "Active: $(grep -c '| active |' "$FILE" 2>/dev/null || echo 0)"
    echo "Paused: $(grep -c '| paused |' "$FILE" 2>/dev/null || echo 0)"
    echo "Completed: $(grep -c '| completed |' "$FILE" 2>/dev/null || echo 0)"
    echo "Total tokens indexed: $(grep -E '^\| [0-9]+ |' "$FILE" 2>/dev/null | awk -F'|' '{sum+=$6} END {print sum+0}')"
}

# Auto-learn: Detect patterns from conversation
auto_learn() {
    local pattern="$1"
    local learning="$2"
    local context="$3"
    
    # Check if this pattern already exists
    if grep -q "$pattern" "$FILE" 2>/dev/null; then
        echo "⏭️ Pattern already known: $pattern"
        return 1
    fi
    
    # Add as discovery with high priority
    add "discovery" "$learning" "150" "$context" "active" "high"
    echo "🧠 Learned: $learning"
}

# Search with status filter
search() {
    local query="$1"
    local status_filter="${2:-all}"
    
    echo "=== 🔍 Search: '$query' ==="
    
    if [ "$status_filter" = "all" ]; then
        grep -r -n "$query" "$MEMORY_DIR" --include="????-??-??.md" 2>/dev/null | head -10
    else
        grep -r -n "$query" "$MEMORY_DIR" --include="????-??-??.md" 2>/dev/null | while read line; do
            if grep -q "| $status_filter |" "$(echo "$line" | cut -d: -f1)"; then
                echo "$line"
            fi
        done | head -10
    fi
}

case "$1" in
    init) init_daily ;;
    add) add "$2" "$3" "$4" "$5" "$6" "$7" ;;
    update-status) update_status "$2" "$3" ;;
    update-priority) update_priority "$2" "$3" ;;
    reference) reference "$2" ;;
    scan) scan_index ;;
    scan-all) scan_all ;;
    show) show "$2" ;;
    list) list ;;
    list-active) list_active ;;
    stats) stats ;;
    auto_learn) auto_learn "$2" "$3" "$4" ;;
    search) search "$2" "$3" ;;
    *) echo "Usage: $0 {init|add|type|summary|tokens|context|status|priority|update-status|num|status|update-priority|num|priority|reference|num|scan|scan-all|show|num|list|list-active|stats|auto_learn|pattern|learning|context|search|query|status}" ;;
esac

# ========================================
# RAG INTEGRATION - Auto-búsqueda en KB
# ========================================

rag_search() {
    local query="$1"
    local result
    
    # Si el script existe, usarlo
    if [ -f "$SCRIPT_DIR/rag-search.sh" ]; then
        result=$("$SCRIPT_DIR/rag-search.sh" "$query" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi
    
    # Fallback: grep directo
    local kb_file="/home/clawd/.openclaw/workspace/.rag-index/critical-knowledge.md"
    if [ -f "$kb_file" ]; then
        grep -A 3 -i "$query" "$kb_file" 2>/dev/null | head -15
    fi
    return 1
}

rag_auto_check() {
    local message="$1"
    
    # Patrones que NO deben preguntar (ya están en KB)
    local forbidden_patterns=(
        "dónde.*hosting" "dónde.*dominio" "dónde.*el.*servidor"
        "qué.*contraseña" "qué.*password" "qué.*clave"
        "cómo.*accedo" "cómo.*conectar" "cómo.*ssh"
        "cuál.*ip" "cuál.*servidor" "dónde.*está.*el"
        "app.*password" "token.*dónde" "clave.*dónde"
        "acceso.*sudo" "permisos.*sudo" "tiene.*sudo"
        "ver.*logs" "ver.*contenedores" "reiniciar.*nginx"
    )
    
    for pattern in "${forbidden_patterns[@]}"; do
        if echo "$message" | grep -iqE "$pattern"; then
            # Buscar en KB
            local kb_result
            kb_result=$(rag_search "$pattern")
            if [ -n "$kb_result" ]; then
                echo "RAG_HIT|$kb_result"
                return 0
            fi
        fi
    done
    
    echo "RAG_MISS"
    return 1
}

# Alias rápido para usar en el flujo
rag() {
    rag_search "$1"
}
