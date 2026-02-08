# memory-nucleo

Progressive memory system for OpenClaw agents.

## Installation

```bash
# Clone or download to skills directory
cd ~/.openclaw/workspace/skills/memory-nucleo
chmod +x cli.sh scripts/*.sh
```

## Usage

### Add Memory Entry

```bash
# Add a rule
./cli.sh add "rule" "No auto-load MEMORY.md" 80 "Optimization rule" --status active --priority high

# Add a decision
./cli.sh add "decision" "Use Ollama local" 100 "Cost optimization" --status completed --priority high

# Add a project
./cli.sh add "project" "EMAILBOT v3" 200 "Production deployment" --status active --priority medium
```

### Search Memory

```bash
# Search all
./cli.sh search "optimization"

# Search with filters
./cli.sh search "email" --status active
```

### Progressive Recall

```bash
# For heartbeats (~100 tokens)
./cli.sh recall "lead,emailbot,notion"

# Full recall
./cli.sh recall "all"
```

### Update Status

```bash
# Mark complete
./cli.sh update-status 5 completed

# Pause entry
./cli.sh update-status 3 paused
```

### Reference Entry

```bash
# Update timestamp (prevents expiration)
./cli.sh reference 5
```

### Consolidate

```bash
# Weekly archive
./cli.sh consolidate --dry-run  # Preview
./cli.sh consolidate            # Execute
```

### Health Check

```bash
./cli.sh health
```

## RAG Integration

```bash
# Search critical knowledge
./cli.sh rag-search "ssh"

# Auto-learn pattern
./cli.sh auto-learn "pattern" "learning" "context"
```

## Examples

### Session Summary

```bash
# Add decision
./cli.sh add "decision" "Cron jobs permanent" 120 "All cron jobs are permanent" --status completed --priority high

# Add next step
./cli.sh add "task" "Implement email automation" 150 "Use EMAILBOT v3" --status active --priority medium
```

### Quick Reference

```bash
# Find all active rules
./cli.sh search "rule" --status active

# Find recent decisions
./cli.sh search "decision" --status completed
```

## File Structure

```
memory-nucleo/
├── README.md
├── SKILL.md
├── cli.sh              # Main entry point
├── scripts/
│   ├── memory-progressive.sh
│   ├── memory-recall.sh
│   ├── memory-search.sh
│   ├── memory-consolidate.sh
│   ├── session-summary.sh
│   └── rag-search.sh
└── .rag-index/
    ├── critical-knowledge.md
    └── auto-learn.md
```

## License

MIT
