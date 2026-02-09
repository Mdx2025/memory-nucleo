#!/bin/bash
# Sync progressive memory entries to .memory/index.jsonl
# Run after creating new memory entries

MEMORY_DIR="/home/clawd/.openclaw/workspace/memory"
INDEX_FILE="/home/clawd/.openclaw/.memory/index.jsonl"

for file in "$MEMORY_DIR"/2026-*.md; do
    [ -f "$file" ] || continue
    while IFS= read -r line; do
        if [[ "$line" =~ ^###\ #[0-9]+\ \|\ (.+)\ \|\ ~([0-9]+)\ tokens ]]; then
            title="${BASH_REMATCH[1]}"
            tokens="${BASH_REMATCH[2]}"
            date=$(basename "$file" .md)
            echo "{\"date\":\"$date\",\"title\":\"$title\",\"tokens\":$tokens}" >> "$INDEX_FILE"
        fi
    done < "$file"
done
echo "✅ Index synced: $(wc -l < "$INDEX_FILE") entries"
