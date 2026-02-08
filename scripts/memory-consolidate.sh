#!/bin/bash
# Weekly consolidation script

MEMORY_DIR="/home/clawd/.openclaw/workspace/memory"
ARCHIVE="$MEMORY_DIR/archives/$(date +%Y-%m-%W).md"

echo "=== 🗄️ Weekly Consolidation ==="

# Get memories from last 7 days
last_week=$(find "$MEMORY_DIR" -name "????-??-??.md" -mtime -7 | sort)

if [ -z "$last_week" ]; then
    echo "No memories to consolidate"
    exit 0
fi

# Create archive file
cat > "$ARCHIVE" << ENTRY
# Week $(date +%Y-%W) Consolidation

## 📋 Index
| # | Type | Summary | Source | Date |
|---|------|---------|--------|------|
ENTRY

count=1
for file in $last_week; do
    date=$(basename "$file" .md)
    while IFS= read -r line; do
        if echo "$line" | grep -qE '^\| [0-9]+ |'; then
            echo "$line" | sed "s/|  */| $count |/" >> "$ARCHIVE"
            count=$((count + 1))
        fi
    done < "$file"
done

echo "✅ Consolidated $(($count - 1)) entries to $ARCHIVE"
echo "📁 Archive size: $(wc -c < "$ARCHIVE") bytes"
