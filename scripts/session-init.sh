#!/bin/bash
# Session initialization with progressive memory

WORKSPACE="/home/clawd/.openclaw/workspace"
TODAY=$(date +%Y-%m-%d)
TODAY_MEM="$WORKSPACE/memory/$TODAY.md"
SUMMARY_FILE="$WORKSPACE/session_summary.json"
UPDATE_SCRIPT="$WORKSPACE/scripts/update-system-prompt.sh"

echo "=== 🚀 Session Init ==="
echo "Date: $TODAY"

# Load core files
echo "📄 Loading core files..."
cat "$WORKSPACE/SOUL.md" > /tmp/session_context.txt 2>/dev/null
cat "$WORKSPACE/USER.md" >> /tmp/session_context.txt 2>/dev/null
cat "$WORKSPACE/IDENTITY.md" >> /tmp/session_context.txt 2>/dev/null

# Load session summary and update systemPrompt
if [ -f "$SUMMARY_FILE" ]; then
    echo "📋 Loading session summary..."
    echo "" >> /tmp/session_context.txt
    echo "=== 📋 SESSION SUMMARY ===" >> /tmp/session_context.txt
    cat "$SUMMARY_FILE" >> /tmp/session_context.txt
    echo "" >> /tmp/session_context.txt
    bash "$UPDATE_SCRIPT"
fi

# Load today's memory
if [ -f "$TODAY_MEM" ]; then
    echo "🧠 Loading today's memory..."
    echo "" >> /tmp/session_context.txt
    echo "=== 🧠 TODAY'S MEMORY ===" >> /tmp/session_context.txt
    grep -E '^#|^\| [0-9]+ |' "$TODAY_MEM" | head -15 >> /tmp/session_context.txt
fi

echo "✅ Context loaded: $(wc -c < /tmp/session_context.txt) bytes"
