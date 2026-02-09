# 🧠 Memory-Nucleo

Progressive memory system for OpenClaw. Manages inter-session memory, recall, and RAG integration.

## 📦 Estado: PRODUCTION READY

**Última actualización:** 2026-02-09  
**Fases:** ✅ Fases 1-4 completadas  
**Tokens/sesión:** ~400 max

## 📖 Documentación Completa

Ver: `memory-tracked/updates/2026-02-09_memory-nucleo_COMPLETE.md`

## 🚀 Quick Start

```bash
# Recall para heartbeat (~100 tokens)
./scripts/memory-recall.sh "lead,emailbot"

# Buscar en memoria
./scripts/memory-search.sh "SSH"

# Ver cambios en scripts
./scripts/memory-auto-track.sh --status

# Buscar en histórico (últimos 7 días)
./scripts/memory-cross-session.sh search "RAG" --days 7

# Ver timeline
./scripts/memory-cross-session.sh timeline

# Exportar contexto para modelo
./scripts/memory-cross-session.sh export 7

# Auto-learn: checkear si ya respondí
./scripts/memory-autolearn-v2.sh check "SSH access"
```

## 📊 Scripts del Sistema

| Script | Descripción |
|--------|-------------|
| `memory-progressive.sh` | Progressive recall |
| `memory-recall.sh` | Recall rápido para heartbeat |
| `memory-search.sh` | Búsqueda en memoria |
| `memory-consolidate.sh` | Consolidación semanal |
| `memory-auto-track.sh` | Detecta cambios en scripts críticos |
| `session-handoff.sh` | Preserva contexto entre sesiones |
| `memory-index-generate.sh` | Genera índices JSON |
| `memory-autolearn-v2.sh` | Detecta "ya te lo dije" |
| `memory-cross-session.sh` | Búsqueda histórica por días |
| `rag-core.sh` | Motor RAG principal |
| `rag-search.sh` | Búsqueda rápida KB |

## 📁 Estructura

```
memory-nucleo/
├── scripts/           # 10+ scripts
├── .memory-index/     # 43+ índices JSON
├── .session-handoff/  # Contexto sesiones
├── memory-tracked/    # Updates + snapshots + autolearn
└── skills/memory-nucleo/
```

## 🔄 Flujo de Memoria

```
Nueva Sesión → session-handoff --load → memory-recall → memory-index → Ready
```

## 🎯 Stats Commands

```bash
./scripts/memory-cross-session.sh stats
./scripts/memory-autolearn-v2.sh stats
./scripts/memory-index-generate.sh --status
./scripts/memory-auto-track.sh --status
```

---

**Costo:** $0/mes (100% local con llama3.2:3b)  
**Docs:** `memory-tracked/updates/2026-02-09_memory-nucleo_COMPLETE.md`
