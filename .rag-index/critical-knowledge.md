# Critical Knowledge Base

## Hosting & Infrastructure
- **Hosting:** mdx.agency → Hostinger VPS
- **Dominios:** Cloudflare (mdx.agency, mdxspace.com)
- **SSH Access:** `ssh mdxspace` o `ssh clawd@159.89.16.233`
- **SSH Key:** ~/.ssh/id_ed25519_mdxspace

## Credentials & Access
- **Sudo:** clawd tiene grupo sudo
- **Passwords:** Usar SSH key, no passwords

## Docker Containers
- **Emailbot:** `ssh mdxspace "sudo docker logs -f emailbot"`

## Sistema
- **OpenClaw Workspace:** /home/clawd/.openclaw/workspace
- **Memory:** /home/clawd/.openclaw/workspace/memory
- **Logs:** ~/.openclaw/logs

## Automation
- **Cron Jobs:** Permanentes, NO borrar sin aprobación
- **Heartbeat:** Ollama local (llama3.2:3b), $0/mes
- **EMAILBOT:** v3 en producción

## Modelos
- **Principal:** minimax/MiniMax-M2.1-Lightning
- **Coder:** openai-codex/gpt-5.2-codex
- **Writer:** anthropic/claude-opus-4-5
- **Local:** ollama/llama3.2:3b (gratis)

---
*Última actualización: 2026-02-08*
