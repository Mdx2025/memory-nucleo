#!/bin/bash
# RAG Auto-Check wrapper - integra en el flujo del agente
# Usage: rag_auto_check "user_message"
# Returns: "RAG_HIT: answer" o "RAG_MISS"

msg="$1"
source /home/clawd/.openclaw/workspace/scripts/rag-core.sh

# Check RAG patterns
result=$(rag-search "$msg" 2>/dev/null)
if [ -n "$result" ] && [ "$result" != "No results found" ]; then
    echo "RAG_HIT: $result"
else
    echo "RAG_MISS"
fi
