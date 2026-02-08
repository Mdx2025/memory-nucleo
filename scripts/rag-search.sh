#!/bin/bash
# RAG Search - Search critical knowledge base

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
RAG_DIR="${SKILL_DIR}/.rag-index"

query="${1:-}"

if [[ -z "$query" ]]; then
    echo "Usage: $0 <query>"
    exit 1
fi

# Search in critical-knowledge.md
if [[ -f "${RAG_DIR}/critical-knowledge.md" ]]; then
    echo "🔍 Searching: $query"
    echo ""
    
    # Simple grep search (can be upgraded to semantic search)
    grep -i -A 3 -B 1 "$query" "${RAG_DIR}/critical-knowledge.md" 2>/dev/null || {
        echo "No matches found in critical-knowledge.md"
    }
    
    echo ""
    
    # Also search auto-learn.md
    if [[ -f "${RAG_DIR}/auto-learn.md" ]]; then
        echo "📚 From auto-learn:"
        grep -i -A 3 -B 1 "$query" "${RAG_DIR}/auto-learn.md" 2>/dev/null || {
            echo "No matches found in auto-learn.md"
        }
    fi
else
    echo "⚠️  RAG index not found at ${RAG_DIR}"
    echo "Creating basic structure..."
    mkdir -p "$RAG_DIR"
    cat > "${RAG_DIR}/critical-knowledge.md" << 'MDX'
# Critical Knowledge Base

## SSH/Domain/Hosting
- Hosting: mdx.agency → Hostinger VPS
- Domain: Cloudflare (mdx.agency, mdxspace.com)
- SSH Key: ~/.ssh/id_ed25519_mdxspace
- Access: `ssh mdxspace`

## Email/Gmail
- EMAILBOT: Gmail → Automated responses
- Logs: `ssh mdxspace "sudo docker logs -f emailbot"`

## Credentials
- SSH Key: ~/.ssh/id_ed25519_mdxspace (main access)
- Sudo: clawd has sudo group

## System
- VPS: mdxspace (SSH access)
- Docker containers monitored
MDX
    echo "✅ Created ${RAG_DIR}/critical-knowledge.md"
fi
