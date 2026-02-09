---
name: memory-nucleo
description: Progressive memory system for OpenClaw. Manages inter-session memory, recall, and RAG integration.
metadata: {"clawdbot":{"emoji":"🧠"}}
---

# memory-nucleo

**Namespace:** `memory-nucleo`

Progressive memory system for OpenClaw. Manages inter-session memory, recall, and RAG integration.

## 🧠 Features

| Feature | Command | Description |
|---------|---------|-------------|
| **Add Entry** | `memory-nucleo add` | Add progressive memory entry with tags |
| **Update Status** | `memory-nucleo update-status` | Change entry status (active/paused/completed) |
| **Reference** | `memory-nucleo reference` | Update last_referenced timestamp |
| **Search** | `memory-nucleo search` | Search memory by query |
| **Recall** | `memory-nucleo recall` | Progressive recall (~100 tokens) |
| **Consolidate** | `memory-nucleo consolidate` | Weekly consolidation & archive |
| **Health** | `memory-nucleo health` | System health check |
| **RAG Search** | `memory-nucleo rag-search` | Search RAG knowledge base |

## 🚀 Quick Start

```bash
# Add entry
memory-nucleo add "project" "Launch v1" 150 "Context details" --status active --priority high

# Search
memory-nucleo search "launch"

# Recall for heartbeat
memory-nucleo recall "project,launch"

# Health check
memory-nucleo health
```

## 📋 Entry Format

```bash
memory-nucleo add <type> <summary> <tokens> <context> [--status active|paused|completed] [--priority high|medium|low]
```

**Types:** `rule`, `decision`, `gotcha`, `project`, `task`, `note`

## 🏗️ Architecture

```
memory-nucleo/
├── SKILL.md              # This file
├── README.md             # User docs
├── cli.sh                # Main entry point
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

## 🔗 Integrations

- **Heartbeat System**: Recall ~100 tokens for heartbeat checks
- **Session Init**: Injects context into new sessions
- **RAG System**: `.rag-index/` for critical knowledge base
- **OpenClaw**: Compatible with all agents

## 📊 Status Lifecycle

```
active → paused → archived
     ↓         ↓
   7 days   30 days
```

## 🔧 Configuration

Environment variables:
- `OPENCLAW_WORKSPACE`: Workspace path (default: `~/.openclaw/workspace`)
- `MEMORY_NUCLEO_DIR`: Memory directory (default: `$OPENCLAW_WORKSPACE/memory`)

## 📝 License

MIT - Part of OpenClaw ecosystem
