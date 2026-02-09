# 🧠 Memory-Nucleo - Mejoras Planificadas

## 📋 Gap Analysis (2026-02-09)

### ❌ Problemas Identificados
1. Updates de scripts no se persisten entre sesiones
2. KB RAG está aislada de progressive memory
3. No hay auto-detección de cambios en scripts críticos
4. Session context se pierde al hacer /new
5. No hay tracking de decisiones/patrones entre sesiones

---

## 🚀 Mejoras a Implementar

### 1️⃣ Auto-Registro de Updates (`memory-auto-track.sh`)
**Objetivo:** Detectar y registrar cambios en scripts críticos automáticamente

```bash
# Scripts monitoreados:
/home/clawd/.openclaw/workspace/scripts/rag-core.sh
/home/clawd/.openclaw/workspace/scripts/rag-search.sh
/home/clawd/.openclaw/workspace/scripts/memory-*.sh
/home/clawd/.openclaw/workspace/skills/*/cli.sh
```

**Mecanismo:**
- Hash de archivos en cada ejecución
- Si cambió hash → auto-guardar en `memory-tracked/`
- Preguntar "¿Guardar summary?" o auto-detectar

---

### 2️⃣ Knowledge Base Indexada (`.memory-index/`)
**Objetivo:** Resúmenes indexables de todos los scripts/skills

```
.memory-index/
├── scripts/
│   ├── rag-core.sh.json    # {summary, last_updated, hash, commands}
│   ├── rag-search.sh.json
│   └── memory-*.sh.json
├── skills/
│   ├── memory-nucleo.json
│   └── otros-skills.json
└── rag-index/
    └── critical-knowledge.md.json
```

**Formato:**
```json
{
  "file": "/home/clawd/.openclaw/workspace/scripts/rag-core.sh",
  "summary": "Motor principal RAG con rag_search() y rag_auto_check()",
  "last_updated": "2026-02-09T07:30:00Z",
  "hash": "abc123...",
  "commands": ["rag_search", "rag_auto_check", "rag_quick"],
  "status": "production-ready"
}
```

---

### 3️⃣ Session Handoff (`session-handoff.sh`)
**Objetivo:** Preservar contexto entre sesiones (/new, /reset)

**Flujo:**
```
Nueva sesión inicia
    ↓
Cargar: SOUL.md, USER.md, IDENTITY
    ↓
Cargar: session-context.json (últimos updates)
    ↓
Cargar: memory-tracked/updates/*.md (updates de scripts)
    ↓
Cargar: .memory-index/*.json (índice de KB)
```

**session-context.json:**
```json
{
  "last_session": "2026-02-08",
  "pending_updates": ["rag-core.sh", "memory-nucleo cli"],
  "active_patterns": ["ssh_keepalive", "docker_alpine"],
  "rag_triggers": 15,
  "tests_passed": ["SSH", "Hosting", "Logs", "Docker"]
}
```

---

### 4️⃣ Auto-Learning Mejorado (`memory-auto-learn-v2.sh`)
**Objetivo:** Aprender de interacciones sin intervención

**Triggers:**
- ✅ "ya te lo dije" → buscar en memory-tracked/
- ✅ "esto ya lo vimos" → cross-session recall
- ✅ "recordá que..." → auto-add a progressive memory
- ✅ "el update de X" → trackear cambio de script

**Feedback Loop:**
```
Usuario: "ya te lo dije 3 veces"
    ↓
Sistema: Buscar en memory-tracked/updates/
    ↓
Encontrado: 2026-02-08_rag-core.md
    ↓
Responder: "Sí, está registrado desde 2026-02-08"
```

---

### 5️⃣ Cross-Session Recall
**Objetivo:** Acceder a memoria de días anteriores sin cargar todo

**Comando:**
```bash
memory-nucleo recall "lead,emailbot" --days 7  # Buscar en últimos 7 días
memory-nucleo recall "support,tool" --since 2026-02-07
```

**Índice por tags:**
```
memory-index/
├── by-tags/
│   ├── lead.json      # [2026-02-07, 2026-02-08]
│   ├── emailbot.json
│   └── support.json
```

---

### 6️⃣ Conversation Patterns (`memory-patterns/`)
**Objetivo:** Recordar patrones de discusión/decisiones

**Formato:**
```json
{
  "pattern": "ssh_keepalive",
  "first_seen": "2026-02-08",
  "discussions": 3,
  "decisions": [
    {
      "date": "2026-02-08",
      "summary": "Configurar ServerAliveInterval en sshd_config",
      "status": "active"
    }
  ],
  "related_patterns": ["docker_alpine", "multi_stage"]
}
```

---

## 📊 Métricas de Éxito

| Métrica | Antes | Después |
|---------|-------|---------|
| Recall de updates | 0% | 100% |
| Tokens en heartbeat | ~160 | ~200 |
| Cross-session recall | ❌ | ✅ |
| Auto-learning | ❌ | ✅ |
| KB indexada | ❌ | ✅ |

---

## 🔧 Fases de Implementación

### Fase 1 (hoy): Auto-Registry + Session Handoff
- [ ] `memory-auto-track.sh` - Detectar cambios en scripts
- [ ] `session-handoff.sh` - Preservar contexto entre sesiones
- [ ] Actualizar `session-init.sh` para usar handoff

### Fase 2: Knowledge Base Indexada
- [ ] `.memory-index/` con resúmenes JSON
- [ ] `memory-index-generate.sh` - Generar índices automáticamente
- [ ] Integrar con RAG

### Fase 3: Auto-Learning v2
- [ ] Detectar frases de repetición
- [ ] Auto-add a progressive memory
- [ ] Feedback loop mejorado

### Fase 4: Cross-Session + Patterns
- [ ] Búsqueda por días/rango de fechas
- [ ] Índices por tags
- [ ] Conversation patterns

---

**Status:** Planificado ✅
**Iniciar:** Fase 1
**Responsable:** Jarvis
