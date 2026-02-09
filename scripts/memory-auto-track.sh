#!/bin/bash
# 🧠 Memory Auto-Track - Detecta y registra cambios en scripts críticos
# Uso: ./memory-auto-track.sh [--check|--track <file>]

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
TRACK_DIR="$WORKSPACE/memory-tracked"
HASH_FILE="$TRACK_DIR/.file-hashes.json"

# Scripts críticos a monitorear
CRITICAL_SCRIPTS=(
    "$WORKSPACE/scripts/rag-core.sh"
    "$WORKSPACE/scripts/rag-search.sh"
    "$WORKSPACE/scripts/rag-test.sh"
    "$WORKSPACE/scripts/memory-progressive.sh"
    "$WORKSPACE/scripts/memory-recall.sh"
    "$WORKSPACE/scripts/memory-search.sh"
    "$WORKSPACE/scripts/memory-consolidate.sh"
    "$WORKSPACE/scripts/session-summary.sh"
)

# Crear directorios si no existen
mkdir -p "$TRACK_DIR/updates"
mkdir -p "$TRACK_DIR/snapshots"

# Cargar hashes previos o crear archivo vacío
load_hashes() {
    if [[ -f "$HASH_FILE" ]]; then
        cat "$HASH_FILE"
    else
        echo "{}"
    fi
}

# Guardar hashes
save_hashes() {
    local hashes="$1"
    echo "$hashes" > "$HASH_FILE"
}

# Calcular hash SHA256
get_hash() {
    local file="$1"
    if [[ -f "$file" ]]; then
        sha256sum "$file" | cut -d' ' -f1
    else
        echo "FILE_NOT_FOUND"
    fi
}

# Detectar cambios
check_changes() {
    local changed=()
    
    for script in "${CRITICAL_SCRIPTS[@]}"; do
        if [[ ! -f "$script" ]]; then
            continue
        fi
        
        local current_hash=$(get_hash "$script")
        local prev_hash=$(load_hashes | jq -r ".\"$script\" // empty" 2>/dev/null || echo "")
        
        if [[ -z "$prev_hash" ]]; then
            # Archivo nuevo - primer snapshot
            echo "[NEW] $script"
            local rel_path="${script#$WORKSPACE/}"
            echo "{\"file\": \"$script\", \"rel\": \"$rel_path\", \"type\": \"script\", \"first_seen\": \"$(date -Iseconds)\", \"hash\": \"$current_hash\"}" > "$TRACK_DIR/snapshots/$(basename "$script" .sh).json"
        elif [[ "$current_hash" != "$prev_hash" ]]; then
            # Archivo modificado
            changed+=("$script")
            echo "[CHANGED] $script"
        else
            echo "[OK] $script"
        fi
    done
    
    # Actualizar hashes
    local new_hashes="{}"
    for script in "${CRITICAL_SCRIPTS[@]}"; do
        [[ -f "$script" ]] || continue
        local h=$(get_hash "$script")
        new_hashes=$(echo "$new_hashes" | jq --arg f "$script" --arg h "$h" '.[$f] = $h')
    done
    save_hashes "$new_hashes"
    
    # Retornar lista de cambiados
    printf '%s\n' "${changed[@]}"
}

# Trackear un archivo específico
track_file() {
    local file="$1"
    local description="${2:-Auto-tracked update}"
    
    [[ ! -f "$file" ]] && { echo "Error: $file no existe"; exit 1; }
    
    local filename=$(basename "$file" .sh)
    local timestamp=$(date -Iseconds)
    local hash=$(get_hash "$file")
    
    # Crear entrada de update
    cat > "$TRACK_DIR/updates/${timestamp:0:10}_${filename}.md" << EOF
# Update: $(basename "$file") - $timestamp

**File:** $file  
**Hash:** $hash  
**Description:** $description

## Cambios
$(git -C "$(dirname "$file")" log --oneline -5 -- "$file" 2>/dev/null || echo "Sin git")

## Snapshot
\`\`\`bash
$(head -30 "$file")
\`\`\`
EOF
    
    echo "✅ Guardado: $TRACK_DIR/updates/${timestamp:0:10}_${filename}.md"
}

# Mostrar estado de tracking
status() {
    echo "🧠 Memory Auto-Track Status"
    echo "============================"
    echo "Tracking ${#CRITICAL_SCRIPTS[@]} scripts críticos"
    echo ""
    
    load_hashes | jq -r 'keys[]' | while read -r script; do
        local status="OK"
        if [[ ! -f "$script" ]]; then
            status="MISSING"
        fi
        echo "[$status] $script"
    done
    
    echo ""
    echo "Updates guardados: $(ls -1 "$TRACK_DIR/updates/" 2>/dev/null | wc -l)"
    echo "Snapshots: $(ls -1 "$TRACK_DIR/snapshots/" 2>/dev/null | wc -l)"
}

# Buscar en updates
search() {
    local query="$1"
    echo "🔍 Buscando: $query"
    grep -r "$query" "$TRACK_DIR/updates/" --include="*.md" -l 2>/dev/null || echo "No encontrado"
}

# CLI
case "${1:-check}" in
    --check|check)
        check_changes
        ;;
    --track|track)
        track_file "$2" "${3:-Manual track}"
        ;;
    --status|status)
        status
        ;;
    --search|search)
        search "$2"
        ;;
    --sync|sync)
        # Sincronizar con memory progressive
        echo "🔄 Sincronizando con progressive memory..."
        ls "$TRACK_DIR/updates/"*.md 2>/dev/null | while read -r f; do
            echo "  - $(basename "$f")"
        done
        ;;
    *)
        echo "Usage: $0 [--check|--track <file>|--status|--search <query>|--sync]"
        exit 1
        ;;
esac
