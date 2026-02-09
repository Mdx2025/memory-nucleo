#!/bin/bash
# RAG Core - Motor de búsqueda para KB crítica
# Uso: source rag-core.sh && rag_auto_check "mensaje"

RAG_KB="/home/clawd/.openclaw/workspace/.rag-index/critical-knowledge.md"

rag_search() {
    local query="$1"
    local result
    
    # Búsqueda en KB
    if [ -f "$RAG_KB" ]; then
        result=$(grep -A 5 -i "$query" "$RAG_KB" 2>/dev/null | head -20)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        fi
    fi
    return 1
}

rag_auto_check() {
    local message="$1"
    
    # Patrones prohibidos (ya están en KB) - EXPANDIDOS
    local forbidden_patterns=(
        # Hosting/Dominio/Servidor
        "dónde.*hosting" "dónde.*dominio" "dónde.*servidor" "dónde.*el.*servidor"
        "dónde.*el.*hosting" "dónde.*el.*dominio"
        
        # Contraseñas/Keys/Tokens
        "qué.*contraseña" "qué.*password" "qué.*clave" "qué.*key"
        "app.*password" "app.*password" "la.*password" "la.*contraseña"
        "el.*password" "el.*contraseña" "tiene.*password" "tiene.*contraseña"
        "no.*tiene.*contraseña" "no.*tiene.*password" "no.*la.*contraseña"
        "necesito.*contraseña" "necesito.*password" "necesito.*clave"
        "dónde.*contraseña" "dónde.*password" "dónde.*clave"
        
        # Acceso/SSH/Conectar
        "cómo.*accedo" "cómo.*conectar" "cómo.*ssh" "cómo.*entro"
        "acceso.*vps" "acceso.*servidor" "acceso.*hosting"
        "cómo.*accedo.*al.*vps" "cómo.*accedo.*al.*servidor"
        
        # IP/Servidor
        "cuál.*ip" "cuál.*servidor" "cual.*ip" "cual.*servidor"
        "ip.*del.*servidor" "ip.*del.*vps" "dónde.*ip"
        
        # Sudo/Permisos
        "acceso.*sudo" "permisos.*sudo" "tiene.*sudo"
        "qué.*acceso.*sudo" "qué.*permisos.*sudo"
        "qué.*puedo.*hacer.*sudo" "qué.*comandos.*sudo"
        
        # Logs/Contenedores/Docker
        "ver.*logs" "ver.*contenedores" "ver.*docker"
        "ver.*logs.*emailbot" "logs.*emailbot" "docker.*logs"
        "reiniciar.*nginx" "reiniciar.*docker" "reiniciar.*servicio"
        
        # Scripts/Ubicación
        "dónde.*está.*el.*script" "dónde.*script" "ubicación.*script"
        "dónde.*están.*los.*scripts" "ruta.*script"
        
        # Feedback Loop (no repetir info)
        "necesito.*repetir" "ya.*te.*lo.*dije" "te.*lo.*volví.*a.*decir"
        "ya.*te.*lo.*dije.*otra.*vez" "cuántas.*veces.*te.*lo.*digo"
        "esto.*ya.*lo.*sabés" "esto.*ya.*lo.*sabes"
    )
    
    for pattern in "${forbidden_patterns[@]}"; do
        if echo "$message" | grep -iqE "$pattern"; then
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

rag_quick() {
    local query="$1"
    rag_search "$query"
}

# Test si se ejecuta directamente
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    echo "🔍 RAG Core - Test de patrones expandidos:"
    rag_auto_check "dónde está el hosting"
fi
