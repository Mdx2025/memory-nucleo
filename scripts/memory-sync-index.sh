#!/bin/bash
# memory-sync-index.sh - Sincroniza progressive memory a .memory/index.jsonl
# Uso: ./memory-sync-index.sh
# Cron: 0 * * * * /home/clawd/.openclaw/workspace/scripts/memory-sync-index.sh

set -e

WORKSPACE="/home/clawd/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
INDEX_FILE="$WORKSPACE/.memory/index.jsonl"
LOCK_FILE="/tmp/memory-sync.lock"

# Prevenir ejecuciones simultáneas
if [ -f "$LOCK_FILE" ]; then
    PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        echo "⏳ Sincronización ya en progreso (PID: $PID)"
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"

# Crear directorios si no existen
mkdir -p "$WORKSPACE/.memory"
mkdir -p "$MEMORY_DIR/archives"

# Inicializar index.jsonl si no existe
if [ ! -f "$INDEX_FILE" ]; then
    echo '{"type":"init","created":"'$(date -Iseconds)'","version":"1.0"}' > "$INDEX_FILE"
fi

echo "🔄 Sincronizando índices de memoria..."

# Contadores
ADDED=0
SKIPPED=0

# Procesar archivos de memoria (últimos 30 días)
find "$MEMORY_DIR" -name "2*.md" -type f -mtime -30 | while read -r memfile; do
    filename=$(basename "$memfile")
    date_str=$(echo "$filename" | sed 's/.md$//')
    
    # Extraer entradas del índice del archivo
    awk '
        /^\| [0-9]+ \|/ {
            # Parsear fila de tabla: | # | Type | Status | Priority | Summary | ~Tok |
            gsub(/^\| +| +\|$/, "");
            split($0, cols, "|");
            
            num = trim(cols[1]);
            type = trim(cols[2]);
            status = trim(cols[3]);
            priority = trim(cols[4]);
            summary = trim(cols[5]);
            tokens = trim(cols[6]);
            
            if (num ~ /^[0-9]+$/) {
                printf "{\"date\":\"%s\",\"entry\":%s,\"type\":\"%s\",\"status\":\"%s\",\"priority\":\"%s\",\"summary\":\"%s\",\"tokens\":\"%s\",\"synced\":\"%s\"}\n",
                    date_str, num, type, status, priority, summary, tokens, strftime("%Y-%m-%dT%H:%M:%S%z");
            }
        }
        function trim(s) {
            gsub(/^[ \t]+|[ \t]+$/, "", s);
            return s;
        }
    ' date_str="$date_str" "$memfile" 2>/dev/null || true
done > /tmp/new_entries.jsonl

# Agregar solo entradas nuevas al índice
if [ -s /tmp/new_entries.jsonl ]; then
    while read -r entry; do
        # Crear firma única para evitar duplicados
        sig=$(echo "$entry" | md5sum | cut -d' ' -f1)
        
        # Verificar si ya existe
        if ! grep -q "$sig" "$INDEX_FILE" 2>/dev/null; then
            echo "$entry" >> "$INDEX_FILE"
            ((ADDED++)) || true
        else
            ((SKIPPED++)) || true
        fi
    done < /tmp/new_entries.jsonl
fi

# Limpiar
rm -f "$LOCK_FILE" /tmp/new_entries.jsonl

# Estadísticas
TOTAL=$(wc -l < "$INDEX_FILE" | tr -d ' ')

echo "✅ Sincronización completada:"
echo "   - Entradas nuevas: $ADDED"
echo "   - Entradas existentes: $SKIPPED"
echo "   - Total en índice: $TOTAL"

# Compactar si el archivo es muy grande (>10000 líneas)
if [ "$TOTAL" -gt 10000 ]; then
    echo "📦 Compactando índice..."
    tail -n 5000 "$INDEX_FILE" > "$INDEX_FILE.tmp"
    mv "$INDEX_FILE.tmp" "$INDEX_FILE"
    echo "✅ Índice compactado a 5000 entradas recientes"
fi
