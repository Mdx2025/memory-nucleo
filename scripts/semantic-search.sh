#!/bin/bash
# Hybrid Semantic + Keyword Search for RAG Index

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
RAG_DIR="${SKILL_DIR}/.rag-index"

query="${1:-}"

if [[ -z "$query" ]]; then
    echo "Usage: $0 <query>"
    echo ""
    echo "Hybrid search combining:"
    echo "  - Semantic search (embeddings + cosine similarity)"
    echo "  - Keyword search (grep)"
    exit 1
fi

# Script Python sin dependencias externas
cat > /tmp/semantic_calc.py << 'PYEOF'
import json
import subprocess
import math
import os
import sys

OLLAMA_URL = "http://localhost:11434"
EMBED_MODEL = "nomic-embed-text"

def get_embedding(text):
    text = text.replace('"', '\\"').replace('\n', ' ')
    result = subprocess.run(
        ['curl', '-s', f'{OLLAMA_URL}/api/embeddings', 
         '-d', f'{{"model":"{EMBED_MODEL}","prompt":"{text}"}}'],
        capture_output=True, text=True
    )
    try:
        data = json.loads(result.stdout)
        return data['embedding']
    except:
        return None

def dot_product(a, b):
    return sum(x*y for x, y in zip(a, b))

def norm(vec):
    return math.sqrt(sum(x*x for x in vec))

def cosine_sim(a, b):
    return dot_product(a, b) / (norm(a) * norm(b) + 1e-8)

rag_dir = sys.argv[1]
query = sys.argv[2]

print(f"🔍 Hybrid Search: '{query}'")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")

query_emb = get_embedding(query)
if query_emb is None:
    print("❌ Error getting query embedding")
    sys.exit(1)

results = []
for filename in os.listdir(rag_dir):
    if filename.endswith('.md'):
        md_file = os.path.join(rag_dir, filename)
        with open(md_file) as f:
            content = f.read()
        
        # Semantic search
        doc_emb = get_embedding(content)
        if doc_emb is None:
            semantic_score = 0.0
        else:
            semantic_score = cosine_sim(query_emb, doc_emb)
        
        # Keyword search
        keyword_count = content.lower().count(query.lower())
        keyword_score = min(keyword_count * 0.1 + 0.3 if keyword_count > 0 else 0.0, 1.0)
        
        # Hybrid score (60% semantic, 40% keyword)
        hybrid_score = semantic_score * 0.6 + keyword_score * 0.4
        
        results.append({
            'file': filename,
            'semantic': semantic_score,
            'keyword': keyword_count,
            'hybrid': hybrid_score,
            'content': content
        })

# Sort by hybrid score
results.sort(key=lambda x: x['hybrid'], reverse=True)

print("📖 Indexing RAG files...")
print("")
for r in results:
    print(f"  📄 {r['file']}")
    print(f"     └─ Semantic: {r['semantic']:.4f} | Keywords: {r['keyword']} | Total: {r['hybrid']:.4f}")

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 RESULTS (hybrid scoring: 60% semantic + 40% keyword)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")

for r in results:
    print(f"{r['hybrid']:.4f}  📄 {r['file']}")
    print(f"       ├─ Semantic: {r['semantic']:.4f} | Keywords: {r['keyword']}")
    print(f"       └─ Context:")
    lines = r['content'].split('\n')
    found = False
    for i, line in enumerate(lines):
        if query.lower() in line.lower():
            start = max(0, i-1)
            end = min(len(lines), i+3)
            for j in range(start, end):
                prefix = "  → " if j == i else "    "
                print(f"{prefix}{lines[j]}")
            found = True
            break
    if not found:
        print("    (no exact keyword match)")
    print("")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💡 Tip: Use quotes for multi-word queries")
PYEOF

python3 /tmp/semantic_calc.py "$RAG_DIR" "$query"
