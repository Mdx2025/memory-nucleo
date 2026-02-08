#!/bin/bash
# Session Summary Manager - Persist context between sessions

SUMMARY_FILE="/home/clawd/.openclaw/workspace/session_summary.json"

# Get current timestamp
NOW=$(date -Iseconds)

# Update current project
update_project() {
    local name="$1"
    local description="$2"
    local status="$3"
    local priority="$4"
    
    python3 << PYEOF
import json

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(f)

data["current_project"] = {
    "name": "$name",
    "description": "$description",
    "status": "$status",
    "priority": "$priority"
}
data["last_updated"] = "$NOW"

with open("$SUMMARY_FILE", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "✅ Project updated: $name ($status)"
}

# Add decision
add_decision() {
    local description="$1"
    local impact="$2"
    
    python3 << PYEOF
import json
from datetime import datetime

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(f)

new_id = f"D{len(data['decisions']) + 1}"
data["decisions"].append({
    "id": new_id,
    "description": "$description",
    "date": datetime.now().strftime("%Y-%m-%d"),
    "impact": "$impact"
})
data["last_updated"] = "$NOW"

with open("$SUMMARY_FILE", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "✅ Decision added: $description"
}

# Add next step
add_next_step() {
    local step="$1"
    
    python3 << PYEOF
import json

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(f)

data["next_steps"].append("$step")
data["last_updated"] = "$NOW"

with open("$SUMMARY_FILE", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "✅ Next step added: $step"
}

# Complete next step (remove by index or text)
complete_step() {
    local step="$1"
    
    python3 << PYEOF
import json

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(f)

data["next_steps"] = [s for s in data["next_steps"] if s != "$step"]
data["last_updated"] = "$NOW"

with open("$SUMMARY_FILE", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "✅ Step completed: $step"
}

# Get summary for injection into prompts
get_summary() {
    cat "$SUMMARY_FILE"
}

# Show current context
show() {
    echo "=== 📊 Session Summary ==="
    python3 << PYEOF
import json

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(f)

print(f"Last Updated: {data['last_updated']}")
print(f"\n📌 Current Project: {data['current_project']['name']}")
print(f"   Status: {data['current_project']['status']}")
print(f"   Priority: {data['current_project']['priority']}")
print(f"   {data['current_project']['description']}")

print(f"\n📋 Decisions ({len(data['decisions'])}):")
for d in data['decisions']:
    print(f"   [{d['id']}] {d['description']} ({d['impact']})")

print(f"\n🎯 Next Steps ({len(data['next_steps'])}):")
for i, step in enumerate(data['next_steps'], 1):
    print(f"   {i}. {step}")
PYEOF
}

# Update focus
update_focus() {
    local focus="$1"
    
    python3 << PYEOF
import json

with open("$SUMMARY_FILE", "r") as f:
    data = json.load(data)

data["active_context"]["focus"] = "$focus"
data["last_updated"] = "$NOW"

with open("$SUMMARY_FILE", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

    echo "✅ Focus updated: $focus"
}

case "$1" in
    update-project) update_project "$2" "$3" "$4" "$5" ;;
    add-decision) add_decision "$2" "$3" ;;
    add-step) add_next_step "$2" ;;
    complete-step) complete_step "$2" ;;
    get) get_summary ;;
    show) show ;;
    update-focus) update_focus "$2" ;;
    *) echo "Usage: $0 {update-project|name|desc|status|priority|add-decision|impact|add-step|step|get|show|update-focus|focus}" ;;
esac
