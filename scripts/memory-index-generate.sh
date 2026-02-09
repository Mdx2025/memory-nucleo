#!/bin/bash
# 📋 Memory Index Generator - Genera índices de KB
# Uso: ./memory-index-generate.sh [--scripts|--skills|--all]

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
INDEX_DIR="$WORKSPACE/.memory-index"

mkdir -p "$INDEX_DIR/scripts" "$INDEX_DIR/skills" "$INDEX_DIR/rag-index"

# Generar índice de un script
index_script() {
    local file="$1"
    [[ ! -f "$file" ]] && return 1
    
    local name=$(basename "$file" .sh)
    local rel_path="${file#$WORKSPACE/}"
    local first_lines=$(head -20 "$file" | grep -E "^#|description|Usage" | head -5 | sed 's/#//' | tr '\n' ' ' | xargs)
    local hash=$(sha256sum "$file" | cut -d' ' -f1)
    local last_mod=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    
    # Extraer funciones
    local funcs=$(grep -oE "^[a-zA-Z_][a-zA-Z0-9_]*\(\)" "$file" 2>/dev/null | head -10 | while read -r f; do
        echo "\"${f%()}\""
    done | tr '\n' ',' | sed 's/,$//')
    
    cat > "$INDEX_DIR/scripts/${name}.json" << EOF
{
  "file": "$file",
  "rel_path": "$rel_path",
  "name": "$name",
  "summary": "$first_lines",
  "hash": "$hash",
  "last_modified": "$(date -Iseconds -d "@$last_mod" 2>/dev/null || date -Iseconds)",
  "commands": [$funcs],
  "status": "active"
}
EOF
}

# Generar índice de un skill
index_skill() {
    local skill_path="$1"
    [[ ! -d "$skill_path" ]] && return 1
    
    local name=$(basename "$skill_path")
    local description=""
    
    if [[ -f "$skill_path/SKILL.md" ]]; then
        description=$(grep -m1 "description:" "$skill_path/SKILL.md" | sed 's/description: //' || echo "Sin descripción")
    fi
    
    cat > "$INDEX_DIR/skills/${name}.json" << EOF
{
  "name": "$name",
  "path": "$skill_path",
  "description": "$description",
  "commands": [],
  "status": "active"
}
EOF
}

# Indexar KB RAG
index_rag() {
    local rag_file="$WORKSPACE/.rag-index/critical-knowledge.md"
    [[ ! -f "$rag_file" ]] && return 1
    
    local hash=$(sha256sum "$rag_file" | cut -d' ' -f1)
    local sections=$(grep -c "^## " "$rag_file" 2>/dev/null || echo "0")
    local triggers=$(grep -c "→" "$rag_file" 2>/dev/null || echo "0")
    
    cat > "$INDEX_DIR/rag-index/critical-knowledge.json" << EOF
{
  "file": "$rag_file",
  "hash": "$hash",
  "sections": $sections,
  "triggers": $triggers,
  "status": "active",
  "indexed_at": "$(date -Iseconds)"
}
EOF
}

# Indexar todos los scripts
index_all_scripts() {
    echo "📁 Indexando scripts..."
    
    for script in "$WORKSPACE/scripts"/*.sh; do
        [[ -f "$script" ]] || continue
        index_script "$script"
        echo "  ✅ $(basename "$script")"
    done
    
    for script in "$WORKSPACE/skills"/*/cli.sh; do
        [[ -f "$script" ]] || continue
        index_script "$script"
        echo "  ✅ $(basename "$(dirname "$script")")/cli.sh"
    done
    
    echo "✅ $(ls -1 "$INDEX_DIR/scripts/"*.json 2>/dev/null | wc -l) scripts indexados"
}

# Indexar todos los skills
index_all_skills() {
    echo "🎯 Indexando skills..."
    
    for skill in "$WORKSPACE/skills"/*/; do
        index_skill "$skill"
        echo "  ✅ $(basename "$skill")"
    done
    
    echo "✅ $(ls -1 "$INDEX_DIR/skills/"*.json 2>/dev/null | wc -l) skills indexados"
}

# Buscar en índice
search() {
    local query="$1"
    echo "🔍 Buscando: $query"
    
    echo "=== Scripts ==="
    grep -l "$query" "$INDEX_DIR/scripts/"*.json 2>/dev/null | head -5 | while read -r f; do
        local name=$(basename "$f" .json)
        local summary=$(cat "$f" | jq -r '.summary' 2>/dev/null)
        echo "  📄 $name: $summary"
    done
    
    echo "=== Skills ==="
    grep -l "$query" "$INDEX_DIR/skills/"*.json 2>/dev/null | head -5 | while read -r f; do
        local name=$(cat "$f" | jq -r '.name')
        local desc=$(cat "$f" | jq -r '.description')
        echo "  🎯 $name: $desc"
    done
}

# Mostrar estado
status() {
    echo "📋 Memory Index Status"
    echo "======================="
    echo ""
    
    echo "Scripts indexados: $(ls -1 "$INDEX_DIR/scripts/"*.json 2>/dev/null | wc -l)"
    echo "Skills indexados: $(ls -1 "$INDEX_DIR/skills/"*.json 2>/dev/null | wc -l)"
    echo "RAG indexados: $(ls -1 "$INDEX_DIR/rag-index/"*.json 2>/dev/null | wc -l)"
    echo ""
    echo "Última actualización: $(stat -c %y "$INDEX_DIR" 2>/dev/null | cut -d' ' -f1 || echo "unknown")"
}

# CLI
case "${1:-all}" in
    --scripts|scripts)
        index_all_scripts
        ;;
    --skills|skills)
        index_all_skills
        ;;
    --rag|rag)
        index_rag
        ;;
    --all|all)
        index_all_scripts
        index_all_skills
        index_rag
        status
        ;;
    --search|search)
        search "$2"
        ;;
    --status|status)
        status
        ;;
    *)
        echo "Usage: $0 [--scripts|--skills|--rag|--all|--search <query>|--status]"
        exit 1
        ;;
esac
