#!/bin/bash
# =============================================================================
# .session-init.sh - Auto-load memory at session start
# =============================================================================
# Este script se ejecuta automáticamente al inicio de cada sesión para cargar
# el contexto de memoria progresiva y el sistema RAG.
# 
# Uso: source /home/clawd/.openclaw/workspace/.session-init.sh
# =============================================================================

WORKSPACE="/home/clawd/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
SCRIPTS_DIR="$WORKSPACE/scripts"
TODAY=$(date +%Y-%m-%d)

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        🧠 MEMORY SYSTEM INITIALIZATION v2.0            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Cargar RAG Core
if [ -f "$SCRIPTS_DIR/rag-core.sh" ]; then
    source "$SCRIPTS_DIR/rag-core.sh"
    echo -e "${GREEN}✓${NC} RAG Core loaded"
else
    echo -e "${YELLOW}⚠${NC} RAG Core not found"
fi

# 2. Cargar Progressive Memory
if [ -f "$SCRIPTS_DIR/memory-progressive.sh" ]; then
    source "$SCRIPTS_DIR/memory-progressive.sh"
    echo -e "${GREEN}✓${NC} Progressive Memory loaded"
else
    echo -e "${YELLOW}⚠${NC} Progressive Memory not found"
fi

# 3. Mostrar resumen de memoria de hoy
echo ""
echo -e "${BLUE}📋 Today's Memory ($TODAY):${NC}"
TODAY_FILE="$MEMORY_DIR/$TODAY.md"
if [ -f "$TODAY_FILE" ]; then
    # Mostrar índice de hoy (primeras 30 líneas)
    head -30 "$TODAY_FILE" | grep -E "^#|^\| [0-9]+ |^|---|"
    
    # Stats rápidas
    ENTRY_COUNT=$(grep -cE '^\| [0-9]+ \|' "$TODAY_FILE" 2>/dev/null || echo "0")
    echo ""
    echo -e "${GREEN}✓${NC} $ENTRY_COUNT entries loaded"
else
    echo -e "${YELLOW}⚠${NC} No memory file for today (will be created on first write)"
fi

# 4. Cargar contexto reciente (últimas 3 memorias)
echo ""
echo -e "${BLUE}📚 Recent Memory Files:${NC}"
ls -1t "$MEMORY_DIR"/*.md 2>/dev/null | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" | head -3 | while read file; do
    filename=$(basename "$file" .md)
    entries=$(grep -cE '^\| [0-9]+ \|' "$file" 2>/dev/null || echo "0")
    echo "  • $filename ($entries entries)"
done

# 5. Verificar sistema de consolidación
if [ -f "$SCRIPTS_DIR/memory-consolidate.sh" ]; then
    echo ""
    echo -e "${GREEN}✓${NC} Weekly consolidation enabled"
fi

echo ""
echo -e "${GREEN}🧠 Memory systems ready!${NC}"
echo ""

# Exportar función para uso en el agente
export MEMORY_INIT_DONE=1
