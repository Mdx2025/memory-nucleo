#!/bin/bash
# 🔄 Session Handoff - Preserva contexto entre sesiones
# Uso: ./session-handoff.sh [--load|--save|--status]

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
HANDOFF_DIR="$WORKSPACE/.session-handoff"
CONTEXT_FILE="$HANDOFF_DIR/session-context.json"
LAST_UPDATES_DIR="$WORKSPACE/memory-tracked/updates"

mkdir -p "$HANDOFF_DIR"

# Guardar contexto de sesión actual
save_context() {
    local agent="${1:-Jarvis}"
    local summary="${2:-}"
    
    cat > "$CONTEXT_FILE" << EOF
{
  "session_id": "$(date +%s)",
  "timestamp": "$(date -Iseconds)",
  "agent": "$agent",
  "summary": "$summary",
  "pending_updates": [],
  "active_patterns": [],
  "rag_triggers": 0,
  "tests_passed": [],
  "memory_entries": 0,
  "last_commands": [],
  "decisions": []
}
EOF
    
    echo "✅ Contexto guardado: $CONTEXT_FILE"
}

# Cargar contexto para nueva sesión
load_context() {
    if [[ ! -f "$CONTEXT_FILE" ]]; then
        echo "⚠️ No hay contexto previo"
        return 1
    fi
    
    echo "🔄 Cargando contexto de sesión anterior..."
    echo ""
    
    # Mostrar resumen
    local last_session=$(cat "$CONTEXT_FILE" | jq -r '.timestamp')
    local agent=$(cat "$CONTEXT_FILE" | jq -r '.agent')
    local summary=$(cat "$CONTEXT_FILE" | jq -r '.summary // empty')
    local pending=$(cat "$CONTEXT_FILE" | jq -r '.pending_updates | length')
    local patterns=$(cat "$CONTEXT_FILE" | jq -r '.active_patterns | length')
    
    echo "📋 Sesión Anterior:"
    echo "  • Fecha: $last_session"
    echo "  • Agente: $agent"
    [[ -n "$summary" ]] && echo "  • Resumen: $summary"
    [[ "$pending" != "0" ]] && echo "  • Updates pendientes: $pending"
    [[ "$patterns" != "0" ]] && echo "  • Patrones activos: $patterns"
    echo ""
    
    # Cargar updates recientes
    echo "📦 Updates recientes:"
    ls -t "$LAST_UPDATES_DIR"/*.md 2>/dev/null | head -5 | while read -r f; do
        echo "  • $(basename "$f")"
    done
    
    # Retornar JSON para procesamiento
    cat "$CONTEXT_FILE"
}

# Agregar update pendiente
add_pending() {
    local update="$1"
    local current=$(cat "$CONTEXT_FILE" 2>/dev/null | jq '.pending_updates // []')
    local updated=$(echo "$current" | jq --arg u "$update" '. += [$u]')
    cat "$CONTEXT_FILE" | jq ".pending_updates = $updated" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
    echo "✅ Agregado: $update"
}

# Agregar patrón activo
add_pattern() {
    local pattern="$1"
    local current=$(cat "$CONTEXT_FILE" 2>/dev/null | jq '.active_patterns // []')
    local exists=$(echo "$current" | jq --arg p "$pattern" 'index($p)')
    
    if [[ "$exists" == "null" ]]; then
        local updated=$(echo "$current" | jq --arg p "$pattern" '. += [$p]')
        cat "$CONTEXT_FILE" | jq ".active_patterns = $updated" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
        echo "✅ Patrón agregado: $pattern"
    fi
}

# Registrar decisión
record_decision() {
    local decision="$1"
    local current=$(cat "$CONTEXT_FILE" 2>/dev/null | jq '.decisions // []')
    local new_entry="{\"timestamp\": \"$(date -Iseconds)\", \"decision\": \"$decision\"}"
    local updated=$(echo "$current" | jq ". += [$new_entry]")
    cat "$CONTEXT_FILE" | jq ".decisions = $updated" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
    echo "✅ Decisión registrada: $decision"
}

# Generar contexto resumido para el modelo (~100 tokens)
generate_summary() {
    local context=$(load_context 2>/dev/null | head -c 2000)
    
    echo "$context" | jq -r '
    "=== SESSION CONTEXT ===",
    "Last session: " + (.timestamp // "unknown"),
    "Agent: " + (.agent // "unknown"),
    "",
    if (.pending_updates | length) > 0 then
      "Pending updates:\n" +
      (.pending_updates[] | "  • " + .)
    else "" end,
    "",
    if (.active_patterns | length) > 0 then
      "Active patterns:\n" +
      (.active_patterns[] | "  • " + .)
    else "" end,
    "",
    if (.decisions | length) > 0 then
      "Recent decisions:\n" +
      (.decisions[-3:][] | "  • " + .decision)
    else "" end,
    "======================"
    ' | head -20
}

# Mostrar estado
status() {
    echo "🔄 Session Handoff Status"
    echo "=========================="
    echo ""
    
    if [[ -f "$CONTEXT_FILE" ]]; then
        echo "✅ Contexto existe"
        cat "$CONTEXT_FILE" | jq '.'
    else
        echo "⚠️ No hay contexto guardado"
    fi
    
    echo ""
    echo "Updates disponibles: $(ls -1 "$LAST_UPDATES_DIR"/*.md 2>/dev/null | wc -l)"
}

# CLI
case "${1:-status}" in
    --save|save)
        save_context "$2" "$3"
        ;;
    --load|load)
        load_context
        ;;
    --summary|summary)
        generate_summary
        ;;
    --status|status)
        status
        ;;
    --add-pending|add-pending)
        add_pending "$2"
        ;;
    --add-pattern|add-pattern)
        add_pattern "$2"
        ;;
    --record|record)
        record_decision "$2"
        ;;
    *)
        echo "Usage: $0 [--save <agent> <summary>|--load|--summary|--status|--add-pending <update>|--add-pattern <pattern>|--record <decision>]"
        exit 1
        ;;
esac
