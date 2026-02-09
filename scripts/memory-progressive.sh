#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# MEMORY-NUCLEO: Progressive Memory System v2.0
# ═══════════════════════════════════════════════════════════════

MEMORY_DIR="${MEMORY_DIR:-/home/clawd/.openclaw/workspace/memory}"
TODAY=$(date +%Y-%m-%d)
NOW=$(date -Iseconds)
FILE="$MEMORY_DIR/$TODAY.md"

# Initialize today's memory file if not exists
init_daily() {
    if [ ! -f "$FILE" ]; then
        cat > "$FILE" << TEMPLATE
# $TODAY (Jarvis)

## 📋 Index (~80 tokens)
| # | Type | Status | Priority | Summary | ~Tok |
|---|------|--------|----------|---------|------|

---

## Notes
TEMPLATE
    fi
}

# Add new entry
add() {
    local type="$1"
    local summary="$2"
    local tokens="$3"
    local context="$4"
    local status="${5:-active}"
    local priority="${6:-medium}"
    
    init_daily
    
    # Find next number
    local next_num=1
    if grep -q "| [0-9]+ |" "$FILE" 2>/dev/null; then
        next_num=$(grep "| [0-9]+ |" "$FILE" | tail -1 | sed 's/| \([0-9]*\) |.*/\1/' | awk '{print $1 + 1}')
    fi
    [ -z "$next_num" ] && next_num=1
    
    # Prevent duplicates - check if summary exists
    if grep -qF "$summary" "$FILE" 2>/dev/null; then
        echo "⚠️ Entry already exists: $summary"
        return 1
    fi
    
    # Build icon
    local icon="🔵"
    case "$type" in
        rule) icon="🚨" ;;
        gotcha) icon="🔴" ;;
        fix) icon="🟡" ;;
        decision) icon="🟤" ;;
        project) icon="🔵" ;;
        change) icon="🟣" ;;
        discovery) icon="🟢" ;;
    esac
    
    # Add to index
    sed -i "/^## 📋 Index.*/a| $next_num | $icon | $status | $priority | ${summary:0:50}... | ~$tokens |" "$FILE"
    
    # Add full entry
    cat >> "$FILE" << ENTRY

### #$next_num | $icon $type | ~$tokens tokens
**Type:** $type
**Status:** $status
**Priority:** $priority
**Context:** ~$tokens
**Last Referenced:** $NOW
**Created:** $NOW

$context

ENTRY
    
    echo "✅ Entry #$next_num added: $summary [$status, $priority]"
}

get_icon() {
    case "$1" in
        rule) echo "🚨" ;;
        gotcha) echo "🔴" ;;
        fix) echo "🟡" ;;
        decision) echo "🟤" ;;
        project) echo "🔵" ;;
        change) echo "🟣" ;;
        discovery) echo "🟢" ;;
        *) echo "🔵" ;;
    esac
}

# List entries
list() {
    init_daily
    echo "=== 📋 All entries for $TODAY ==="
    grep -E '^### #|^\| [0-9]+ |' "$FILE" | head -30
}

# List active only
list_active() {
    init_daily
    echo "=== 📋 Active entries for $TODAY ==="
    grep -E '^### #|^\| [0-9]+ | active |' "$FILE" | head -30
}

# Stats
stats() {
    init_daily
    echo "=== 📊 Memory Stats ==="
    echo "Total entries: $(grep -c '^### #' "$FILE" 2>/dev/null || echo 0)"
    echo "Active: $(grep -c '| active |' "$FILE" 2>/dev/null || echo 0)"
    echo "Paused: $(grep -c '| paused |' "$FILE" 2>/dev/null || echo 0)"
    echo "Completed: $(grep -c '| completed |' "$FILE" 2>/dev/null || echo 0)"
}

# Update entry status
update_status() {
    local num="$1"
    local new_status="$2"
    
    if [ ! -f "$FILE" ]; then
        echo "❌ No memory file for today"
        return 1
    fi
    
    # Update index - fix sed pattern for the specific format
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/| $num | \1 | $new_status | \3 |/" "$FILE"
    
    # Update full entry
    sed -i "s/\*\*Status:\*\* \(.*\)/\*\*Status:\*\* $new_status/" "$FILE"
    sed -i "s/\*\*Last Referenced:\*\*/\*\*Last Referenced:\*\* $NOW/" "$FILE"
    
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
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/| $num | \1 | \2 | $new_priority |/" "$FILE"
    
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
    
    sed -i "s/\*\*Last Referenced:\*\* \(.*\)/\*\*Last Referenced:\*\* $NOW/" "$FILE"
    sed -i "s/| $num | \(.\) | \(.\) | \(.\) |/\1 | \2 | \3 |/" "$FILE"
    
    echo "✅ Entry #$num referenced"
}

# Scan index only (fast) - show only active entries
scan_index() {
    init_daily
    echo "=== 📋 Index for $TODAY (active only) ==="
    grep -E '^#|^\| [0-9]+ | active |' "$FILE" | head -20
}

# Scan all
scan_all() {
    init_daily
    echo "=== 📋 Full Index for $TODAY ==="
    grep -E '^#|^\| [0-9]+ |' "$FILE" | head -40
}

# Show entry details
show() {
    local num="$1"
    if [ -z "$num" ]; then
        echo "Usage: $0 show <num>"
        return 1
    fi
    
    if [ ! -f "$FILE" ]; then
        echo "❌ No memory file for today"
        return 1
    fi
    
    echo "=== Entry #$num ==="
    sed -n "/^### #$num /,/^### /p" "$FILE" | head -20
}

# Auto-learn pattern
auto_learn() {
    local pattern="$1"
    local learning="$2"
    local context="$3"
    
    add "discovery" "$pattern" 50 "$context" "active" "high"
}

# Search entries
search() {
    local query="$1"
    local status_filter="${2:-}"
    
    if [ -z "$query" ]; then
        echo "Usage: $0 search <query> [status]"
        return 1
    fi
    
    echo "=== 🔍 Search: $query ==="
    if [ -n "$status_filter" ]; then
        grep -B2 -A2 "$query" "$MEMORY_DIR"/*.md 2>/dev/null | grep -E "$status_filter|^\|.*$query" || echo "No matches found"
    else
        grep -B2 -A2 "$query" "$MEMORY_DIR"/*.md 2>/dev/null || echo "No matches found"
    fi
}

# Quick context for LLM prompts
context() {
    init_daily
    echo "=== 🧠 Quick Context ==="
    grep "| active |" "$FILE" | head -5 | sed 's/| [0-9]* | \(.\) | active | \(.\) | \(.\) | \(.*\) |.*/\1 \2 \3: \4/'
}

# Show today's file
today() {
    if [ -f "$FILE" ]; then
        cat "$FILE"
    else
        echo "No memory file for today"
    fi
}

# Main dispatcher
case "$1" in
    init) init_daily ;;
    add) add "$2" "$3" "$4" "$5" "$6" "$7" ;;
    list) list ;;
    list-active) list_active ;;
    stats) stats ;;
    update-status) update_status "$2" "$3" ;;
    update-priority) update_priority "$2" "$3" ;;
    reference) reference "$2" ;;
    scan) scan_index ;;
    scan-all) scan_all ;;
    show) show "$2" ;;
    auto_learn) auto_learn "$2" "$3" "$4" ;;
    search) search "$2" "$3" ;;
    context) context ;;
    today) today ;;
    *) 
        echo "Memory-Nucleo v2.0 - Progressive Memory System"
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  init              Initialize today's memory file"
        echo "  add <type> <summary> <tokens> <context> [status] [priority]"
        echo "  list              List all entries"
        echo "  list-active       List only active entries"
        echo "  stats             Show statistics"
        echo "  update-status # <status>    Change entry status"
        echo "  update-priority # <priority> Change entry priority"
        echo "  reference #       Update timestamp"
        echo "  scan              Fast scan active index"
        echo "  scan-all          Full scan"
        echo "  show #            Show entry details"
        echo "  auto_learn <pattern> <learning> <context>"
        echo "  search <query> [status]  Search entries"
        echo "  context           Quick context for LLM"
        echo "  today             Show today's file"
        ;;
esac
