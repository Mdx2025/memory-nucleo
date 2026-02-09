#!/bin/bash
# =============================================================================
# rag-agent-wrapper.sh - RAG Auto-check para integración con agente principal
# =============================================================================
# Este wrapper permite al agente principal verificar automáticamente el KB
# antes de responder a preguntas comunes.
#
# Uso en el agente:
#   result=$(rag_agent_check "mensaje del usuario")
#   if [[ "$result" == RAG_HIT* ]]; then
#       # Usar respuesta del KB
#   else
#       # Procesar normalmente
#   fi
# =============================================================================

WORKSPACE="/home/clawd/.openclaw/workspace"
SCRIPTS_DIR="$WORKSPACE/scripts"
RAG_CORE="$SCRIPTS_DIR/rag-core.sh"

# Cargar RAG Core si existe
if [ -f "$RAG_CORE" ]; then
    source "$RAG_CORE"
fi

# Función principal para el agente
rag_agent_check() {
    local user_message="$1"
    local check_result
    
    # Si no hay mensaje, retornar MISS
    if [ -z "$user_message" ]; then
        echo "RAG_MISS"
        return 1
    fi
    
    # Ejecutar auto-check del RAG
    check_result=$(rag_auto_check "$user_message" 2>/dev/null)
    
    # Retornar resultado
    if [[ "$check_result" == RAG_HIT* ]]; then
        echo "$check_result"
        return 0
    else
        echo "RAG_MISS"
        return 1
    fi
}

# Función para extraer solo la respuesta (sin prefijo RAG_HIT)
rag_extract_response() {
    local rag_result="$1"
    echo "$rag_result" | sed 's/^RAG_HIT|//'
}

# Función de conveniencia: check + extract en uno
rag_smart_response() {
    local user_message="$1"
    local result
    
    result=$(rag_agent_check "$user_message")
    
    if [[ "$result" == RAG_HIT* ]]; then
        rag_extract_response "$result"
        return 0
    fi
    
    return 1
}

# Función para logging de hits (útil para debugging)
rag_log_hit() {
    local query="$1"
    local response="$2"
    local log_file="$WORKSPACE/.rag-index/hits.log"
    
    echo "[$(date -Iseconds)] QUERY: $query | RESPONSE: ${response:0:50}..." >> "$log_file"
}

# Si se ejecuta directamente, hacer test
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    if [ -n "$1" ]; then
        echo "🔍 Testing RAG wrapper..."
        result=$(rag_agent_check "$1")
        if [[ "$result" == RAG_HIT* ]]; then
            echo "✅ RAG HIT!"
            echo "Response:"
            rag_extract_response "$result"
        else
            echo "❌ RAG MISS - No match in KB"
        fi
    else
        echo "RAG Agent Wrapper v1.0"
        echo "Usage: $0 'mensaje a verificar'"
        echo ""
        echo "Available functions:"
        echo "  rag_agent_check <message>    - Check if message matches KB patterns"
        echo "  rag_extract_response <result> - Extract clean response from RAG_HIT"
        echo "  rag_smart_response <message>  - Check and extract in one call"
    fi
fi
