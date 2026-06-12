# MEMORY.md — Long-Term Memory

_Curated memory. Distilled from daily logs, wiki, and Station Memory. Only the essentials._

## Memory Wiki (OpenClaw Plugin — Primary Knowledge Store)

**Primary knowledge management system.** OpenClaw plugin with bridge mode auto-importing from memory plugin.
```
wiki_search "[query]"                 # Search all wiki pages
wiki_get "entities/sm-001.md"        # Read specific page
wiki_apply                            # Create/update pages
wiki_lint                             # Check structure, contradictions
wiki_status                           # Vault health
```

- **Vault:** `~/.openclaw/wiki/main`
- **Bridge mode:** Auto-imports dream reports, daily notes, memory root (43 artifacts)
- **10 manual pages:** 3 entities (decisions, issues) + 7 concepts (lessons, rules)
- **All Station Memory records migrated here** (sm-001 through sm-010)
- **Search backend:** local (shared requires OpenAI API key)

## Workboard (OpenClaw Plugin — Task Management)

**Primary task management system.** Replaces `data/tasks.json`.
```
workboard_list                        # List all cards
workboard_list --status backlog       # Find dispatchable work
workboard_claim                       # Claim a card
workboard_complete                    # Mark done
```

- **112 cards** migrated from tasks.json (108 done + 4 active)
- **Features:** Claim/heartbeat/complete lifecycle, agent assignment, session linking, priority labels
- **Legacy:** `data/tasks.json` still exists with 110 historical tasks. MC `/tasks` page reads from it.

## Station Memory (SQLite — Legacy)

**Legacy knowledge store.** Kept for MC UI display only. Agents should use Memory Wiki instead.

```bash
cd mission-control-dashboard && node scripts/station-memory-tool.cjs search "query"
```

- **DB:** `data/station-memory.db` (SQLite + FTS5)
- **10 records** migrated to Memory Wiki (sm-001 through sm-010)
- **MC UI still reads from here** for Knowledge Base tab display

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
- **2026-05-15:** Event-driven state management via stationReducer for visual changes
- **2026-05-15:** Andre sharing hand-crafted pixel art assets (sprites + rooms) as HTML canvas drawings
- **2026-05-15:** Established single master repo at `mission-control-dashboard`, deleted Downloads copy
- **2026-06-03:** Removed dev branch. `main` is now the single source of truth.
- **2026-05-31:** Removed Aider — burned ~90K tokens on a refactor and didn't finish.
- **2026-06-02:** Fixed Vite cache corruption. All routes verified 200.
- **2026-06-02:** OPS-002 — Incident→Task linking with bidirectional relationships
- **2026-06-03:** Task system overhaul — heartbeat is now the only dispatcher
- **2026-06-06:** Cron audit — 13 → 12 jobs, disabled redundant scripts
- **2026-06-09:** Adopted Operating Constitution — full governance framework
- **2026-06-09:** Enabled OpenClaw Workboard + Memory Wiki plugins
- **2026-06-09:** Migrated 10 Station Memory records to Memory Wiki (3 entities, 7 concepts)
- **2026-06-09:** Migrated 112 tasks to Workboard cards (108 done + 4 active)
- **2026-06-09:** Removed 175 duplicate done-tasks (284 → 109)
- **2026-06-09:** Removed orphaned /station-memory route + ingest API (819 lines)
- **2026-06-09:** Removed work-dispatcher.sh + error-spike-watchdog.sh (dead code)
- **2026-06-09:** Added getWikiStats — MC /memory page shows live wiki stats
- **2026-06-09:** Fixed Knowledge Base tab — node:sqlite replaces better-sqlite3 for SSR compat
- **2026-06-09:** Updated AGENTS.md — Workboard + Memory Wiki as primary tools

## External AI Review Loop

Integrated 2026-06-12. Full pipeline:
1. Generate review package from git history → `scripts/generate-review-package.sh`
2. Submit via OpenCode + OpenRouter (`opencode run --model openrouter/qwen/qwen3-coder`)
3. Parse structured JSON recommendations
4. Evaluate: Accept / Reject / Defer
5. Implement accepted changes (direct edit for single-file, OpenCode for multi-file)
6. Log decisions to `review-system/decisions/`
7. Update Station Memory wiki

- **Phase 5 (validated):** 65 seconds, $0.04 total, pipeline works end-to-end
- **Phase 6 (in progress):** Wire into Night Shift — auto-review each completed task overnight
- Max 5 reviews/night, max $1.00/night (OpenRouter credits)
- Review failure does NOT fail the original task

## Cron Jobs

Active OpenClaw cron jobs (12 total, 10 enabled):
- **Sessions Cleanup** — 02:00 UTC, systemEvent
- **Session Auto-Expiry** — 04:00 UTC, systemEvent
- **Daily GitHub push** — 04:00 UTC, systemEvent
- **Night Shift Activation** — 01:00 BST, systemEvent → main session
- **night-shift-automation** — 01:00 BST, isolated agentTurn
- **Auto-update FreeRide** — 06:00 BST, isolated agentTurn
- **Daily Incident Auto-Resolve** — 06:00 BST, systemEvent
- **Daily Station Check** — 23:00 BST, systemEvent (Telegram delivery)
- **Weekly Healthcheck** — Monday 08:00 BST, systemEvent
- **Friday GIF** — Friday 17:00 BST, systemEvent

Disabled (merged into maintenance.sh):
- ~~Stall Detector~~ — step 5/10 in maintenance.sh
- ~~Error Spike Watchdog~~ — step 4/10 in maintenance.sh
- ~~Session Cleanup (archive takeover)~~ — duplicate of 02:00 job

LaunchAgents:
- `com.openclaw.maintenance` — every 30 min
- `com.openclaw.mc-dashboard` — MC dev server (port 3000)
- `com.openclaw.mount-check` — every 30 min

## Night Shift

Autonomous task processing 01:00-07:00 when Andre is asleep. Max 2 tasks/night.

- **2026-06-07:** Pipeline deadlock fix — stall detector now clears stalledAt after 30min

---
_Last updated: 2026-06-09 by Space Monkey_
