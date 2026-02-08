#!/bin/bash
# memory-nucleo CLI - Progressive Memory System for OpenClaw

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_DIR="${WORKSPACE_DIR}/memory"
RAG_DIR="${SKILL_DIR}/.rag-index"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_usage() {
    echo "memory-nucleo - Progressive Memory System for OpenClaw"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  add <type> <summary> <tokens> <context>  Add memory entry"
    echo "  search <query>                         Search memory"
    echo "  recall <tags>                          Progressive recall (~100 tokens)"
    echo "  update-status <id> <status>            Update entry status"
    echo "  reference <id>                         Update last_referenced"
    echo "  consolidate                            Weekly consolidation"
    echo "  health                                 System health check"
    echo "  rag-search <query>                     Search RAG knowledge base"
    echo "  auto-learn <pattern> <learning>        Auto-learn pattern"
    echo ""
    echo "Options:"
    echo "  --status active|paused|completed       Entry status"
    echo "  --priority high|medium|low             Entry priority"
    echo "  --dry-run                              Preview (for consolidate)"
    echo "  --help                                 Show this help"
    echo ""
    echo "Types: rule, decision, gotcha, project, task, note"
}

run_script() {
    local script="$1"
    shift
    "${SKILL_DIR}/scripts/${script}.sh" "$@"
}

cmd_add() {
    local type="" summary="" tokens="" context="" status="active" priority="high"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status)
                status="$2"
                shift 2
                ;;
            --priority)
                priority="$2"
                shift 2
                ;;
            *)
                if [[ -z "$type" ]]; then
                    type="$1"
                elif [[ -z "$summary" ]]; then
                    summary="$1"
                elif [[ -z "$tokens" ]]; then
                    tokens="$1"
                else
                    context="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$type" || -z "$summary" || -z "$tokens" || -z "$context" ]]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo "Usage: $0 add <type> <summary> <tokens> <context> [--status] [--priority]"
        exit 1
    fi
    
    run_script "memory-progressive.sh" "add" "$type" "$summary" "$tokens" "$context" "$status" "$priority"
}

cmd_search() {
    local query="$1"
    shift
    local status_filter=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status)
                status_filter="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Query required${NC}"
        exit 1
    fi
    
    if [[ -n "$status_filter" ]]; then
        run_script "memory-search.sh" "$query" "$status_filter"
    else
        run_script "memory-search.sh" "$query"
    fi
}

cmd_recall() {
    local tags="$1"
    shift
    
    if [[ -z "$tags" ]]; then
        tags="all"
    fi
    
    run_script "memory-recall.sh" "$tags"
}

cmd_update_status() {
    local id="$1"
    local status="$2"
    
    if [[ -z "$id" || -z "$status" ]]; then
        echo -e "${RED}Error: ID and status required${NC}"
        exit 1
    fi
    
    run_script "memory-progressive.sh" "update-status" "$id" "$status"
}

cmd_reference() {
    local id="$1"
    
    if [[ -z "$id" ]]; then
        echo -e "${RED}Error: ID required${NC}"
        exit 1
    fi
    
    run_script "memory-progressive.sh" "reference" "$id"
}

cmd_consolidate() {
    local dry_run=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ "$dry_run" == "true" ]]; then
        run_script "memory-consolidate.sh" "--dry-run"
    else
        run_script "memory-consolidate.sh"
    fi
}

cmd_health() {
    echo -e "${BLUE}🧠 memory-nucleo Health Check${NC}"
    echo "================================"
    
    # Check scripts
    echo -e "\n${YELLOW}Scripts:${NC}"
    for script in memory-progressive.sh memory-recall.sh memory-search.sh memory-consolidate.sh session-summary.sh rag-search.sh; do
        if [[ -x "${SKILL_DIR}/scripts/${script}" ]]; then
            echo -e "  ✅ $script"
        else
            echo -e "  ❌ $script (not executable)"
        fi
    done
    
    # Check memory dir
    echo -e "\n${YELLOW}Memory Directory:${NC}"
    if [[ -d "$MEMORY_DIR" ]]; then
        echo -e "  ✅ $MEMORY_DIR exists"
        local count=$(find "$MEMORY_DIR" -name "*.md" 2>/dev/null | wc -l)
        echo -e "  📊 $count memory files"
    else
        echo -e "  ⚠️  $MEMORY_DIR (will be created)"
    fi
    
    # Check RAG index
    echo -e "\n${YELLOW}RAG Index:${NC}"
    if [[ -f "${RAG_DIR}/critical-knowledge.md" ]]; then
        echo -e "  ✅ critical-knowledge.md exists"
    else
        echo -e "  ⚠️  critical-knowledge.md (not found)"
    fi
    
    echo -e "\n${GREEN}Health check complete${NC}"
}

cmd_rag_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Query required${NC}"
        exit 1
    fi
    
    run_script "rag-search.sh" "$query"
}

cmd_auto_learn() {
    local pattern="$1"
    local learning="$2"
    local context="${3:-}"
    
    if [[ -z "$pattern" || -z "$learning" ]]; then
        echo -e "${RED}Error: Pattern and learning required${NC}"
        exit 1
    fi
    
    "${SKILL_DIR}/scripts/auto-learn.sh" "$pattern" "$learning" "$context"
}

# Main
main() {
    if [[ $# -eq 0 ]]; then
        print_usage
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        add)
            cmd_add "$@"
            ;;
        search)
            cmd_search "$@"
            ;;
        recall)
            cmd_recall "$@"
            ;;
        update-status)
            cmd_update_status "$@"
            ;;
        reference)
            cmd_reference "$@"
            ;;
        consolidate)
            cmd_consolidate "$@"
            ;;
        health)
            cmd_health
            ;;
        rag-search)
            cmd_rag_search "$@"
            ;;
        auto-learn)
            cmd_auto_learn "$@"
            ;;
        --help|-h)
            print_usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            print_usage
            exit 1
            ;;
    esac
}

main "$@"
