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

## Night Shift

Autonomous task processing during 01:00-07:00 when Andre is asleep. Design doc at `NIGHT_SHIFT.md`. Not yet implemented — pending Andre's review.

---
_Last updated: 2026-06-03 by Space Monkey_
