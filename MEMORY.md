# MEMORY.md — Long-Term Memory

_Curated memory. Distilled from daily logs and the wiki. Only the essentials._

## The Wiki

I now maintain a **Karpathy-style LLM Wiki** at `memory/wiki/`. This is my primary knowledge management system — a structured, interlinked collection of markdown pages that compounds over time.

- **Index:** `memory/wiki/index.md` — content catalog of all pages
- **Overview:** `memory/wiki/overview.md` — high-level synthesis
- **Log:** `memory/wiki/log.md` — chronological activity record
- **Schema:** `memory/wiki/schema.md` — conventions and workflows
- **Entities:** `memory/wiki/entities/` — people, projects, tools
- **Concepts:** `memory/wiki/concepts/` — ideas, patterns, themes
- **Sources:** `memory/wiki/sources/` — ingested document summaries
- **Raw sources:** `raw/sources/` — immutable originals

When answering questions, I check the wiki index first, then drill into relevant pages.

## Key People

- **Andre** — My human. Mac admin, builds things, runs OpenClaw. Shares sources and asks questions; I handle the bookkeeping.

## Key Projects

- **Mission Control Dashboard** — 7-screen monitoring app (TanStack Start, dark theme). Agent Office animation system fully built with Framer Motion. Live data bridge polling OpenClaw gateway. Hand-crafted pixel art sprites and room scenes integrated. Located at `~/.openclaw/workspace/mission-control-dashboard/` (the single master repo).
- **Agent Office** — The Visual Office page is a living, animated station with 4 rooms, agent sprites with idle/walking/working states, collaboration system, ambient effects. Spec at `memory/agent-office-spec.md`.
- **Dev/Prod Strategy** — `main` branch = prod (port 3000), `dev` branch = dev (port 3001). Dev server launcher at `scripts/dev-server.sh`. GitHub repo: `spacemonkey-home/openclaw-missionscontrol`.

## Operating Protocol

- Running under `openclaw-agent` standard macOS account (non-admin)
- No sudo, no brew install, no system config changes
- Report blockers to Andre with exact commands needed
- Workspace: `~/.openclaw/workspace/`

## Key Decisions

- **2026-05-12:** Adopted Karpathy LLM Wiki pattern for compounding memory
- **2026-05-12:** Moved to constrained `openclaw-agent` account
- **2026-05-15:** Adopted Framer Motion for Agent Office animations (no game engine)
- **2026-05-15:** Event-driven state management via stationReducer for all visual changes
- **2026-05-15:** Andre sharing hand-crafted pixel art assets (sprites + rooms) as HTML canvas drawings
- **2026-05-15:** Established single master repo at `mission-control-dashboard`, deleted Downloads copy
- **2026-05-15:** Dev/prod branch strategy — `main` = prod (port 3000), `dev` = dev (port 3001)
- **2026-05-15:** API server uses `fs` reads instead of `execSync` for cron data (Cloudflare Workers compat)
- **2026-05-15:** Investigate → Task → Error Resolution flow implemented (bidirectional linking)

---
_Last updated: 2026-05-15 by Space Monkey_
