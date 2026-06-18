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
- **2026-06-14:** Implemented Recall Engine Phase 1 — 8-source retrieval pipeline with Fast/Deep mode classification and Context Package format
- **2026-06-14:** Configured workspace git remote and performed security audit — removed sensitive logs, added .gitignore, set up GitHub backup
- **2026-06-15:** Applied incident-manage, mac-proxy-manage, night-shift, task-system-maint skills. docker-host-manage pending approval. Note: night-shift and task-system-maint were applied, but the underlying dispatch architecture is still broken (0 dispatches in 5 nights: Jun 12-16). These skills document the system as-is. The architectural simplification decision is still pending.

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
- **Phase 6 (done):** Review loop integrated into Night Shift — auto-review each completed task overnight. Tonight (01:00 BST) will be first live test.
- Max 5 reviews/night, max $1.00/night (OpenRouter credits)
- Review failure does NOT fail the original task
- **Kanban auto-revert bug (2026-06-12):** save-tasks merge didn't protect `status` when `stalledAt` was set. UI saves overwrote stall detector resets. Fixed by protecting disk-side status/currentStep/progress when stalledAt is present. Also fixed maintenance.sh heredoc bash 3.2 incompatibility.
- **Ghost dispatch fix (2026-06-12):** Tasks stuck in 'Agent starting…' with no sub-agent. Three-pronged fix: (1) pre-dispatch validation checks excluded tags before setting in_progress, (2) 60s ghost timeout resets tasks immediately if sub-agent never starts, (3) wasStalled flag management — Phase 2 clears wasStalled after 3h cooldown. MC UI shows 'Dispatch Failed' and 'Ghost' badges.
- **Dispatch loop fix (2026-06-13):** Extended stall detector Phase 2 cooldowns (stalledAt: 2h, wasStalled: 3h) to prevent rapid dispatch→reset→dispatch loops. dispatchFailed is never auto-cleared.

## Incident Automation Suite (2026-06-18)

Three automations built from analysis of 124 incidents (Jun 12-17):

1. **Gateway Self-Heal** (`scripts/gateway-self-heal.sh`) — Cron every 5 min. Monitors for
   EmbeddedAttemptSessionTakeoverError 3+ times in 10 min → restart via launchctl kickstart
   → health check → create resolved incident. 15-min circuit breaker prevents restart loops.
   Addresses 41% of incidents (gateway crash loops).

2. **Rate Limit Prevention** — Staggered all clustered cron jobs with 60-120s jitter.
   06:00 BST cluster split to 06:00 + 06:05. 02:00 UTC cluster split to 02:00 + 02:02.
   04:00 UTC cluster split to 04:00 + 04:03. FreeRide agentTurn checks backoff state before
   API calls. Addresses 36% of incidents (rate limit exhaustion).

3. **Incident Deduplication** — Fingerprint-based dedup in auto-detect-incidents.sh:
   MD5 of normalized title + sorted tags. 3-tier matching (fingerprint → title → tag overlap).
   `incident-dedup.sh` runs every 4h to consolidate duplicates within 24h window.
   Reduces noise ~20%.

4. **Heartbeat reduced** — 30min → 2h globally. Cron jobs handle frequent monitoring.
   HEARTBEAT.md quiet hours section skips heavy work 23:00-08:00.

## Cron Jobs

Active OpenClaw cron jobs (13 total, 11 enabled):
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

## Promoted From Short-Term Memory (2026-06-18)

<!-- openclaw-memory-promotion:memory:memory/2026-05-14.md:1:23 -->
- # 2026-05-14 — Daily Log ## Mission Control Dashboard — Session Summary ### Fixes Applied 1. **Dashboard layout** — Enlarged from `max-w-6xl` to `max-w-[1650px]` 2. **Agent sprite positioning** — Fixed from fixed pixels to percentages for responsive scaling 3. **Agent sprites** — Replaced with individual files from `owl_station_sprites` folder (320×240 each) 4. **Tasks page loader error** — Added missing `useRef` import 5. **Scheduler page** — Created `/api/crons` endpoint, fixed `execSync` PATH issue, now shows all cron jobs with toggle switches 6.... [score=0.850 recalls=7 avg=1.000 source=memory/2026-05-14.md:1-23]
<!-- openclaw-memory-promotion:memory:memory/2026-05-13.md:22:54 -->
- ### Andre's Directives - Dashboard should be the home page name (not Spacestation) - Live activity feed on the left side - Task detail should be centered modal (not right slide) - Dreaming toggle should show on/off state clearly - Scheduler should have on/off switches for each cron job - Telegram chat ID: 7507878944 ### Session End State - All pages loading (Home/Dashboard, Tasks, Settings, Scheduler) - 10 cron jobs created, all with Telegram delivery - 12 new sprites installed - Git committed through v1.9.0 ## Evening Session (continued) ### Completed - **Agent status display fixed** — Always-on agents (monkey, lifesupport) no... [score=0.833 recalls=7 avg=1.000 source=memory/2026-05-13.md:22-54]
<!-- openclaw-memory-promotion:memory:memory/2026-05-13.md:47:69 -->
- **openclaw CLI path fixed** — Full path /opt/homebrew/bin/openclaw ### Andre's Additional Feedback - Rename home to 'Dashboard' ✅ - Animation side revisited (collaboration walking between rooms) - Agent avatars showing as black and white — FIXED (was grayscale CSS on 'away' status) - Check all sprites are 100% updated — CONFIRMED (12 sprites at 240x320, RGB color) ### Key Technical Findings - getAgentStatus returns 'active' for always-on agents, 'standby' for on-demand - Old code checked status === 'active' which excluded 'standby' agents as 'away' - image-rendering: pixelated can cause blurriness on some browsers - createServerFn... [score=0.819 recalls=6 avg=1.000 source=memory/2026-05-13.md:47-69]
<!-- openclaw-memory-promotion:memory:memory/2026-05-13.md:1:30 -->
- # 2026-05-13 Daily Log (continued) ## Afternoon/Evening Session ### Completed - **Dashboard redesign (T-119)** — 3-column layout: Left=live activity feed, Center=Spacestation rooms, Right=quick actions - **Task detail panel** — Changed from right-slide to centered modal - **Dreaming toggle** — Proper on/off toggle with visual state indicator in QuickActions - **Scheduler page** — Shows all OpenClaw cron jobs with on/off toggle switches - **Telegram delivery fixed** — All cron jobs now deliver to chat ID 7507878944 - **Backup path fixed** — Changed from /Volumes/OpenClaw-WD to /Volumes/Public-1/openclaw-agent-backup - **openclaw CLI... [score=0.814 recalls=5 avg=1.000 source=memory/2026-05-13.md:1-30]
<!-- openclaw-memory-promotion:memory:memory/2026-05-15.md:139:165 -->
- Root cause: `server.ts` used `execSync` (child_process) which is stubbed in Cloudflare Workers runtime - Fix: Replaced `execSync` calls with direct `fs` reads/writes to `~/.openclaw/cron/jobs.json` and `jobs-state.json` - Cron enable/disable now writes directly to `jobs.json` instead of using CLI - `vite dev` serves API routes correctly (unlike `wrangler dev` which uses unenv stubs) ### Investigate → Task Flow - Investigate button on Scheduler Error Feed now auto-creates an "In Progress" task - Task includes error details, cron job info, and is tagged with `errorId` - Completing an error-linked task automatically updates cron error... [score=0.814 recalls=5 avg=1.000 source=memory/2026-05-15.md:139-165]
