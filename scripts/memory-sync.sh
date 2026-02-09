#!/bin/bash
# =============================================================================
# memory-sync.sh - Sincronización entre progressive memory e index.jsonl
# =============================================================================
# Este script mantiene sincronizados dos sistemas de memoria:
# 1. Progressive Memory: archivos diarios YYYY-MM-DD.md en /memory/
# 2. Index JSONL: archivo estructurado .memory/index.jsonl
#
# Uso: ./memory-sync.sh [full|incremental]
#   full:        Reconstruye todo el índice desde cero
#   incremental: Solo añade entradas nuevas (default)
# =============================================================================

WORKSPACE="/home/clawd/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
MEMORY_INDEX="$WORKSPACE/.memory/index.jsonl"
SYNC_LOG="$WORKSPACE/.memory/sync.log"
SYNC_STATE="$WORKSPACE/.memory/sync-state.json"

# Modo de operación
MODE="${1:-incremental}"

# Logging
log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$SYNC_LOG"
}

# Inicializar archivos si no existen
init() {
    if [ ! -f "$MEMORY_INDEX" ]; then
        echo "[]" > "$MEMORY_INDEX"
        log "✓ Created new index.jsonl"
    fi
    
    if [ ! -f "$SYNC_STATE" ]; then
        echo '{"last_sync": "", "entries_count": 0}' > "$SYNC_STATE"
    fi
}

# Extraer entradas de un archivo markdown
parse_markdown_entries() {
    local file="$1"
    local date=$(basename "$file" .md)
    local entries=""
    
    # Leer cada línea de notas con formato ### #N
    grep -E "^### #[0-9]+ \|" "$file" 2>/dev/null | while read line; do
        local num=$(echo "$line" | sed -E 's/.*### #([0-9]+) .*/\1/')
        local summary=$(echo "$line" | sed -E 's/.*### #[0-9]+ \| ([^|]+) \|.*/\1/' | xargs)
        local tokens=$(echo "$line" | grep -oE '~[0-9]+ tokens' | grep -oE '[0-9]+' || echo "100")
        
        # Extraer metadata
        local type=$(sed -n "/^### #$num /,/^### [0-9]\|^$/p" "$file" | grep "^\*\*Type:\*\*" | sed 's/\*\*Type:\*\* //' | head -1 | xargs)
        local status=$(sed -n "/^### #$num /,/^### [0-9]\|^$/p" "$file" | grep "^\*\*Status:\*\*" | sed 's/\*\*Status:\*\* //' | head -1 | xargs)
        local priority=$(sed -n "/^### #$num /,/^### [0-9]\|^$/p" "$file" | grep "^\*\*Priority:\*\*" | sed 's/\*\*Priority:\*\* //' | head -1 | xargs)
        local created=$(sed -n "/^### #$num /,/^### [0-9]\|^$/p" "$file" | grep "^\*\*Created:\*\*" | sed 's/\*\*Created:\*\* //' | head -1 | xargs)
        local context=$(sed -n "/^### #$num /,/^### [0-9]\|^$/p" "$file" | grep "^\*\*Context:\*\*" | sed 's/\*\*Context:\*\* //' | head -1 | xargs)
        
        # Valores por defecto
        [ -z "$type" ] && type="note"
        [ -z "$status" ] && status="active"
        [ -z "$priority" ] && priority="medium"
        [ -z "$created" ] && created="${date}T00:00:00+00:00"
        
        # Generar JSON
        echo "{\"id\": \"${date}-${num}\", \"date\": \"$date\", \"num\": $num, \"summary\": \"$summary\", \"type\": \"$type\", \"status\": \"$status\", \"priority\": \"$priority\", \"tokens\": $tokens, \"context\": \"$context\", \"created\": \"$created\", \"synced_at\": \"$(date -Iseconds)\"}"
    done
}

# Sync completo
sync_full() {
    log "🔄 Starting FULL sync..."
    
    # Crear archivo temporal
    local temp_file=$(mktemp)
    echo "[" > "$temp_file"
    
    local first=true
    # Procesar todos los archivos de memoria
    for md_file in "$MEMORY_DIR"/*.md; do
        [ -e "$md_file" ] || continue
        
        log "Processing: $(basename "$md_file")"
        
        while read entry; do
            [ -z "$entry" ] && continue
            
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$temp_file"
            fi
            echo -n "$entry" >> "$temp_file"
        done < <(parse_markdown_entries "$md_file")
    done
    
    echo "" >> "$temp_file"
    echo "]" >> "$temp_file"
    
    # Reemplazar archivo original
    mv "$temp_file" "$MEMORY_INDEX"
    
    local count=$(grep -c '"id":' "$MEMORY_INDEX" 2>/dev/null || echo "0")
    log "✅ Full sync complete: $count entries indexed"
    
    # Actualizar estado
    echo "{\"last_sync\": \"$(date -Iseconds)\", \"entries_count\": $count, \"mode\": \"full\"}" > "$SYNC_STATE"
}

# Sync incremental
sync_incremental() {
    log "🔄 Starting INCREMENTAL sync..."
    
    local last_sync=$(cat "$SYNC_STATE" | grep -o '"last_sync": "[^"]*"' | sed 's/.*: "\(.*\)".*/\1/')
    local new_entries=0
    
    # Procesar archivos modificados después del último sync
    for md_file in "$MEMORY_DIR"/*.md; do
        [ -e "$md_file" ] || continue
        
        # Verificar si fue modificado después del último sync
        if [ -n "$last_sync" ]; then
            local file_mtime=$(stat -c %Y "$md_file" 2>/dev/null || stat -f %m "$md_file" 2>/dev/null)
            local sync_time=$(date -d "$last_sync" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$last_sync" +%s 2>/dev/null)
            
            if [ -n "$sync_time" ] && [ "$file_mtime" -lt "$sync_time" ]; then
                continue  # Archivo no modificado, saltar
            fi
        fi
        
        log "Processing (new/modified): $(basename "$md_file")"
        
        while read entry; do
            [ -z "$entry" ] && continue
            
            local id=$(echo "$entry" | grep -o '"id": "[^"]*"' | sed 's/.*: "\(.*\)".*/\1/')
            
            # Verificar si ya existe
            if ! grep -q "\"id\": \"$id\"" "$MEMORY_INDEX" 2>/dev/null; then
                # Añadir nueva entrada (esto es simplificado, en producción usar jq)
                echo "$entry" >> "$MEMORY_INDEX.tmp"
                new_entries=$((new_entries + 1))
            fi
        done < <(parse_markdown_entries "$md_file")
    done
    
    log "✅ Incremental sync complete: $new_entries new entries"
    
    # Actualizar estado
    local total=$(grep -c '"id":' "$MEMORY_INDEX" 2>/dev/null || echo "0")
    echo "{\"last_sync\": \"$(date -Iseconds)\", \"entries_count\": $total, \"mode\": \"incremental\", \"new_entries\": $new_entries}" > "$SYNC_STATE"
}

# Mostrar estadísticas
stats() {
    echo "=== 📊 Memory Sync Stats ==="
    if [ -f "$SYNC_STATE" ]; then
        cat "$SYNC_STATE" | python3 -m json.tool 2>/dev/null || cat "$SYNC_STATE"
    fi
    echo ""
    echo "Index file: $MEMORY_INDEX"
    if [ -f "$MEMORY_INDEX" ]; then
        local count=$(grep -c '"id":' "$MEMORY_INDEX" 2>/dev/null || echo "0")
        echo "Total indexed entries: $count"
    fi
}

# Main
case "$MODE" in
    full)
        init
        sync_full
        ;;
    incremental)
        init
        sync_incremental
        ;;
    stats)
        stats
        ;;
    *)
        echo "Usage: $0 {full|incremental|stats}"
        echo ""
        echo "Modes:"
        echo "  full        - Rebuild entire index from markdown files"
        echo "  incremental - Only add new/modified entries (default)"
        echo "  stats       - Show synchronization statistics"
        exit 1
        ;;
esac
