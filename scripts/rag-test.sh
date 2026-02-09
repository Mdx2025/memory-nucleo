#!/bin/bash
# Test completo del sistema RAG

echo "=== 🧪 TEST SISTEMA RAG ==="
echo ""

# Test 1: KB existe
echo "1️⃣ KB Crítica:"
[ -f "/home/clawd/.openclaw/workspace/.rag-index/critical-knowledge.md" ] && echo "   ✅ critical-knowledge.md existe" || echo "   ❌ Falta KB"
echo ""

# Test 2: Auto-learn existe
echo "2️⃣ Auto-Learn:"
[ -f "/home/clawd/.openclaw/workspace/.rag-index/auto-learn.md" ] && echo "   ✅ auto-learn.md existe" || echo "   ❌ Falta auto-learn"
echo ""

# Test 3: Scripts RAG
echo "3️⃣ Scripts:"
[ -f "/home/clawd/.openclaw/workspace/scripts/rag-core.sh" ] && echo "   ✅ rag-core.sh" || echo "   ❌ Falta rag-core"
[ -f "/home/clawd/.openclaw/workspace/scripts/rag-search.sh" ] && echo "   ✅ rag-search.sh" || echo "   ❌ Falta rag-search"
echo ""

# Test 4: Búsquedas
echo "4️⃣ Búsquedas (rag-core.sh):"
source /home/clawd/.openclaw/workspace/scripts/rag-core.sh 2>/dev/null

test_patterns=(
    "ssh"
    "hosting"
    "logs emailbot"
    "docker"
)

for p in "${test_patterns[@]}"; do
    result=$(rag_quick "$p" 2>/dev/null)
    if [ -n "$result" ]; then
        echo "   ✅ \"$p\" → encontrado"
    else
        echo "   ❌ \"$p\" → no encontrado"
    fi
done
echo ""

# Test 5: Triggers prohibidos
echo "5️⃣ Triggers prohibidos (no preguntar):"
forbidden_test=(
    "dónde está el hosting"
    "qué contraseña tiene"
    "cómo accedo al VPS"
    "ver logs del emailbot"
)

all_pass=true
for q in "${forbidden_test[@]}"; do
    output=$(rag_auto_check "$q" 2>/dev/null)
    if echo "$output" | grep -q "RAG_HIT"; then
        echo "   ✅ \"$q\" → bloqueado, usar KB"
    else
        echo "   ❌ \"$q\" → no detectado"
        all_pass=false
    fi
done
echo ""

if $all_pass; then
    echo "🎉 TODOS LOS TESTS PASARON"
else
    echo "⚠️ Algunos tests fallaron"
fi
