# MEMORY.md — Long-Term Memory

_Curated memory. Distilled from daily logs, wiki, and Station Memory. Only the essentials._

## Station Memory (SQLite Knowledge Store)

**Any agent session** can query institutional knowledge without conversation history:
```bash
cd mission-control-dashboard && node scripts/station-memory-tool.cjs search "query"
```

- **DB:** `data/station-memory.db` (SQLite + FTS5)
- **8 knowledge types:** architecture-decision, lesson-learned, incident-knowledge, completed-task-summary, operational-decision, framework-rule, runbook, known-issue
- **Auto-ingestion:** tasks → knowledge on completion, incidents → knowledge on resolution
- **Always query before starting work:** "Have we solved this before? Is there a framework rule?"
- **Tool docs:** `TOOLS.md` → Station Memory section

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
- **Serving** — `main` is the single branch, served on port 3000 by Vite dev server. No dev branch. GitHub repo: `spacemonkey-home/openclaw-missionscontrol`.

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
- **2026-06-03:** Removed dev branch (was stale Lovable-era prototype). `main` is now the single source of truth — one branch, one server on port 3000.
- **2026-05-15:** API server uses `fs` reads instead of `execSync` for cron data (Cloudflare Workers compat)
- **2026-05-15:** Investigate → Task → Error Resolution flow implemented (bidirectional linking)
- **2026-05-31:** Removed Aider — burned ~90K tokens on a refactor and didn't finish. Multi-file refactors now done via sequential direct edits (one file at a time, commit after each). Zero token cost.
- **2026-06-02:** Removed Sprite Generator page (/sprites) — old PNG sprite generator from Lovable era, obsolete since we use canvas sprites. Deleted route file + component + sidebar entry.
- **2026-06-02:** Fixed Vite cache corruption (504 Outdated Optimize Dep errors). Killed dev server, `rm -rf node_modules/.vite .vite`, restarted with `--force`. All routes verified 200.
- **2026-06-02:** OPS-002 — Incident→Task linking: `Task.linkedIncidentId` is source of truth, `Incident.linkedTaskIds` derived at runtime. Auto-created tasks start in `triage` (not backlog). Task status changes auto-append to incident timeline. Incident resolution separate from task completion.
- **2026-06-02:** Added `triage` to Task.status union, new Triage Kanban column, Linked Incident section in TaskDetailPanel, `/api/incidents-timeline` endpoint.
- **2026-06-02:** Updated auto-detect-incidents.sh to create linked tasks + severity-based response actions per incident.

- **2026-06-02:** OPS-002 — Incident→Task Linking: `Task.linkedIncidentId` is source of truth (not `Incident.linkedTaskIds`). Auto-detect creates linked triage tasks. Task status changes auto-append to incident timeline via `/api/incidents/timeline`. Added `triage` to Task status union, new Triage Kanban column, Linked Incident section in task detail, derived linked tasks in IncidentDetailsDrawer.
- **2026-06-03:** Task system overhaul — removed work-dispatcher.sh (was flipping JSON without spawning agents). Heartbeat is now the only dispatcher. 28 stale/protected tasks cleaned up (6 incident artifacts → obsolete, 22 strategic → deferred). End-to-end test passed: sub-agent dispatched, completed, moved to Done with summary. 16 planning tasks remain in backlog for human triage.
- **2026-06-06:** tasks.json wiped by heartbeat cleanup (commit a5aaff3) — Python script wrote dict format instead of array, reducing 104 tasks to 1. Restored from git history (commit 3e5ef20, 99 tasks). Root cause: heartbeat bypasses /api/save-tasks merge protection by writing directly via Python. Fix: heartbeat must use atomic write + validate format before writing.
- **2026-06-06:** Cron audit — removed duplicate session cleanup (38ac51a4), disabled standalone stall detector and error spike watchdog (merged into maintenance.sh), fixed night-shift-automation Telegram error (delivery: none). 13 → 12 jobs (10 enabled, 2 disabled).
- **2026-06-06:** Circuit breaker confirmed as inline guard (not a cron job) — checked by heartbeat and maintenance.sh before any automated processing.
- **2026-06-06:** Daily Incident Auto-Resolve confirmed intentionally added — safety net to prevent incident graveyard buildup.

## Cron Jobs

Active OpenClaw cron jobs (12 total, 10 enabled):
- **Sessions Cleanup** — 02:00 UTC, systemEvent (shell via `openclaw sessions cleanup`)
- **Session Auto-Expiry** — 04:00 UTC, systemEvent (shell script)
- **Daily GitHub push** — 04:00 UTC, systemEvent (shell script)
- **Night Shift Activation** — 01:00 BST, systemEvent → main session
- **night-shift-automation** — 01:00 BST, isolated agentTurn (delivery: none)
- **Auto-update FreeRide** — 06:00 BST, isolated agentTurn (only token-burning cron)
- **Daily Incident Auto-Resolve** — 06:00 BST, systemEvent → POST /api/incidents/auto-resolve
- **Daily Station Check** — 23:00 BST, systemEvent (shell script, Telegram delivery)
- **Weekly Healthcheck** — Monday 08:00 BST, systemEvent (shell script)
- **Friday GIF** — Friday 17:00 BST, systemEvent (shell-only, gifgrep)

Disabled (merged into maintenance.sh):
- ~~Stall Detector~~ — was every 15 min, now step 5/10 in maintenance.sh (every 30 min)
- ~~Error Spike Watchdog~~ — was every 15 min agentTurn, now step 4/10 in maintenance.sh (shell-only)
- ~~Session Cleanup (archive takeover)~~ — was every 6h agentTurn, duplicate of 02:00 systemEvent job

LaunchAgents (separate from cron):
- `com.openclaw.maintenance` — every 30 min (stall detection, error watchdog, dispatch, incidents)
- `com.openclaw.mc.dashboard` — MC dev server (port 3000)
- `com.openclaw.mount-check` — every 30 min

**Circuit Breaker**: Not a cron job — it's a guard function checked inline by heartbeat and maintenance.sh before any automated processing. State in `data/circuit-breaker-state.json`.

## Night Shift

Autonomous task processing during 01:00-07:00 when Andre is asleep. Design doc at `NIGHT_SHIFT.md`. Implemented — Phase 2 test passed, enabled for nightly runs (max 2 tasks).

- **2026-06-07:** Pipeline deadlock investigation — `stalledAt` set by stall detector was never cleared, permanently blocking all 4 backlog tasks from dispatch. Root cause: stall detector Phase 1 (reset in_progress→backlog + set stalledAt) but no Phase 2 to clear it after cooldown. Fix: stall-detector.sh now clears stalledAt after 30min in backlog. Also fixed maintenance.sh dispatcher (false positive logging, no lastActivity on dispatch, no priority sorting). E2E test passed: task created→dispatched→worked→done.

---
_Last updated: 2026-06-07 by Space Monkey_
