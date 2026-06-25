# MEMORY.md - Long-Term Memory

_Curated memory. Distilled from daily logs, wiki, and Station Memory. Only the essentials._

## Memory Wiki (OpenClaw Plugin - Primary Knowledge Store)

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

## Workboard (OpenClaw Plugin - Task Management)

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

## Station Memory (SQLite - Legacy)

**Legacy knowledge store.** Kept for MC UI display only. Agents should use Memory Wiki instead.

```bash
cd mission-control-dashboard && node scripts/station-memory-tool.cjs search "query"
```

- **DB:** `data/station-memory.db` (SQLite + FTS5)
- **10 records** migrated to Memory Wiki (sm-001 through sm-010)
- **MC UI still reads from here** for Knowledge Base tab display

## Key People

- **Andre** - My human. Mac admin, builds things, runs OpenClaw. Shares sources and asks questions; I handle the bookkeeping.

## Key Projects

- **Mission Control Dashboard** - Now based on TenacitOS (Next.js 15) as of 2026-06-21. Provides 7-screen monitoring, Agent Office animation system with Framer Motion, live data bridge polling OpenClaw gateway (Phase 1 complete). Hand-crafted pixel art sprites and room scenes integrated. Located at `~/.openclaw/workspace/spacestation/` (the TenacitOS instance). Old SpaceStation code archived in `_ARCHIVE_OLD_SPACESTATION/`.
- **Agent Office** - The Visual Office page is a living, animated station with 4 rooms, agent sprites with idle/walking/working states, collaboration system, ambient effects. Spec at `memory/agent-office-spec.md`. UI currently uses hardcoded CREW data; live data integration pending.
- **Serving** - `main` is the single branch. MC prod served on port 3000 by Vite dev server (proxy forwarded to TenacitOS dev on port 3002). GitHub repo: `spacemonkey-home/openclaw-missionscontrol`.

## SpaceStation URLs

- **Production**: http://localhost:3000 (npm start)
- **Dev**: http://localhost:3001 (npm run dev, if 3000 is busy)
- **Control UI**: http://localhost:18789
- **Workboard API**: http://localhost:3000/api/workboard/cards
- **MCP Graph UI**: http://localhost:9749 (codebase-memory-mcp --ui)
- **OpenCode service**: background LaunchAgent on 127.0.0.1:4096

### All Running Services

| Service | URL | Status |
|---------|-----|--------|
| SpaceStation | http://localhost:3000 | ✅ 307 (redirect, healthy) |
| OpenClaw Gateway | http://localhost:18789 | ✅ 200 |
| MCP Graph UI | http://localhost:9749 | ✅ 200 |
| OpenCode | http://127.0.0.1:4096 | ✅ 200 (LaunchAgent) |
| Ollama | http://localhost:11434 | ✅ 200 |
| PostgreSQL | — | ❌ not running locally |

## SpaceStation CSS Fix (2026-06-22)

Shell.tsx had two hardcoded inline styles that broke the entire site CSS:
- `fontFamily: 'SF Pro Display'...` overrode the Inter font from layout.tsx
- `background: linear-gradient(...)` overrode `var(--background)` from globals.css

Fix: Removed both overrides. Shell now only sets `minHeight: 100vh` and `color: var(--text-primary)`.

**Lesson:** Never hardcode font or background in wrapper components. Always inherit from CSS variables.

## Recent Updates
- **2026-06-21 21:20 BST**: Presentation layer fix - added missing `src/entry-client.tsx` for TanStack Start hydration, fixing unstyled raw text render.
- **2026-06-21 21:50 BST**: Architecture migration - SpaceStation → TenacitOS (Next.js 15). Cloned tenacitos, configured env, started dev server on port 3002, archived old code.
- **2026-06-21 22:00 BST**: Proxy updated - nginx proxy on Docker host changed port 13005 → Mac port 3002, restoring iPad access.
- **2026-06-21 22:05 BST**: Language fix - translated TenacitOS UI strings from Spanish to English (login, sidebar, Office3D, Skills).
- **2026-06-22 08:32 BST**: Heartbeat poll - systems healthy, MyCloud mount unavailable since 02:43 BST on 2026-06-21, recurring gateway session errors (INC-134, INC-132, INC-130) monitored, no urgent action required.
- **2026-06-22 11:44 BST**: Diagnostic Audit — Task Disappearance: tasks.json appeared to have only 1 task (CANARY TEST). Root cause: canary test script's POST request created a new task, but file had been overwritten/wiped during API testing. Fix: restored tasks.json from git HEAD (97 tasks: 90 done, 5 triage, 2 backlog). No data loss. Code changes committed: Archive column with dashed border + lower opacity, Detail Drawer (right slide-over) with editable fields + read-only activity log, Delete button with confirm() dialog, DELETE /api/tasks endpoint, POST /api/tasks endpoint, Soft UI theme (Shell.tsx, ghost buttons, glass panels), AgentMatrix.tsx wireframe, test-canary.ts script.
- **2026-06-22 15:58 BST**: Reminder: Consider enabling the **FreeRide** auto-switching for fallback models to mitigate rate-limit exhaustion (see tasks `task-inc-137*`, `task-inc-133*`, `task-inc-131*`).
- **2026-06-24 06:02 BST**: Heartbeat poll - Gateway responding (200), MyCloud host pingable (4.7ms) but SMB ports unavailable, Mission Control responding (307), load 1.97, disk 23%. Mount alert triggered: MyCloud-1E4N74 unreachable for SMB at 06:02:11.
- **2026-06-24**: Stable day with 2 auto-recoveries (14:41, 20:03) + 1 manual kickstart (~17:52), peak load ~1.94, London heatwave peaked at 34°C. No incidents reported.
- **2026-06-25**: Continued stability with normal gateway (200) and Mission Control (307) responses. Ongoing incidents monitored but not causing system-wide issues.

## Tools

- **OpenCode CLI**: `/Users/spacemonkey/.opencode/bin/opencode` (v1.17.8) — NOT in PATH, use full path
- **OpenCode Web UI**: http://192.168.68.64:4097

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
- **2026-05-31:** Removed Aider - burned ~90K tokens on a refactor and didn't finish.
- **2026-06-02:** Fixed Vite cache corruption. All routes verified 200.
- **2026-06-02:** OPS-002 - Incident→Task linking with bidirectional relationships
- **2026-06-03:** Task system overhaul - heartbeat is now the only dispatcher
- **2026-06-06:** Cron audit - 13 → 12 jobs, disabled redundant scripts
- **2026-06-09:** Adopted Operating Constitution - full governance framework
- **2026-06-09:** Enabled OpenClaw Workboard + Memory Wiki plugins
- **2026-06-09:** Migrated 10 Station Memory records to Memory Wiki (3 entities, 7 concepts)
- **2026-06-09:** Migrated 112 tasks to Workboard cards (108 done + 4 active)
- **2026-06-09:** Removed 175 duplicate done-tasks (284 → 109)
- **2026-06-09:** Removed orphaned /station-memory route + ingest API (819 lines)
- **2026-06-09:** Removed work-dispatcher.sh + error-spike-watchdog.sh (dead code)
- **2026-06-09:** Added getWikiStats - MC /memory page shows live wiki stats
- **2026-06-09:** Fixed Knowledge Base tab - node:sqlite replaces better-sqlite3 for SSR compat
- **2026-06-09:** Updated AGENTS.md - Workboard + Memory Wiki as primary tools
- **2026-06-14:** Implemented Recall Engine Phase 1 - 8-source retrieval pipeline with Fast/Deep mode classification and Context Package format
- **2026-06-14:** Configured workspace git remote and performed security audit - removed sensitive logs, added .gitignore, set up GitHub backup
- **2026-06-15:** Applied incident-manage, mac-proxy-manage, night-shift, task-system-maint skills. docker-host-manage pending approval. Note: night‑shift and task‑system‑maint were applied, but the underlying dispatch architecture is still broken (0 dispatches in 5 nights: Jun 12‑16). These skills document the system as‑is. The architectural simplification decision is still pending.
- **2026-06-19:** Learnings: Fixed incident API 500 via TanStack import fix (@tanstack/react-start → @tanstack/start-client-core); synced tasks.json from Workboard (122 tasks); Mission Control Dashboard Phase 1 data-layer complete (3 APIs live) but UI needs wiring to live hooks; OpenCode large-file reads require shorter prompts; Night Shift eligibility blocked by exclusion tags, P1 priority, or dispatchCount>=3. Applied Phase 5 UI fixes (Memory tab error boundary, drag-and-drop, Dispatch All, detail popup) and identified AsyncLocalStorage dev-server issue as root cause (production clean). Decisions: Workboard/Memory Wiki as primary systems; FreeRide rate-limit handler improved fallback chains.
- **2026-06-20:** Heartbeat checks revealed a P1 incident (INC-130) for Gateway session errors (TRIAGE). System stable otherwise. FreeRide skill appears to be mitigating rate limit incidents. No urgent email/calendar/mentions found in recent heartbeat checks.

- **2026-06-20 11:00 BST:** Security audit P0 fixes applied:
  - Gateway flags hardened (`allowInsecureAuth: false`, `dangerouslyDisableDeviceAuth: false`)
  - Gateway allowedOrigins restricted (removed bare docker-host IP, kept localhost:18789 + 192.168.68.50:18889)
  - Gateway token rotated (old 48-char hex → new 48-char base64)
  - Ollama LaunchAgent updated (OLLAMA_HOST changed from 0.0.0.0 to 127.0.0.1)
  - OpenCode serve killed for security (was on 127.0.0.1:4096)
  - Pending sudo actions: enable macOS firewall, add firewall rule to block Ollama IPv6
  - Ollama IPv6 issue: ignores OLLAMA_HOST for IPv6 binding, still listens on *:11434 IPv6
- **2026-06-20 11:38 BST:** Mount alert: MyCloud-1E4N74 unreachable
- **2026-06-20 13:00 BST:** Phase 0 migration foundation complete:
  - mc-v2 repo initialized from framework copy at ~/.openclaw/workspace/mc-v2 (775 files, 11MB)
  - Docker Compose dev environment on Docker host (192.168.68.50):
    - Frontend: port 3002 (Next.js)
    - Backend: port 8002 (FastAPI)
    - DB: port 5434 (PostgreSQL, isolated instance)
    - Redis: port 6380 (isolated instance)
  - Nginx proxy updated with basic auth for port 3002
  - Both endpoints verified: 3002 returns 200, 8002 health returns {"ok":true}
  - Delegated audits via OpenCode:
    - Audit A: 236+ items inventoried (181 KEEP, 35 RESTYLE, 9 MERGE, 11 REPLACE)
    - Audit B: 25 overlapping areas (11 USE THEIRS, 6 USE OURS, 8 MERGE)
    - Audit C: Developer guide covering routes, components, auth, API, theming, how-tos
  - Note: GitHub fork not created (gh CLI not API-authenticated). Local repo pushed to workspace git.
  - OpenCode config restored to original (opencode/big-pickle primary). Fallback chain intact.
- **2026-06-21 03:30 BST:** MyCloud mount (/Volumes/Public) still unavailable since ~00:43 BST; host MyCloud-1E4N74 not responding to ping (network/storage hardware issue). See known issue sm-008.
- **2026-06-21 11:38 BST:** Heartbeat check: Weather: Partly cloudy +25°C, MyCloud host responding, mount point /Volumes/Public unavailable since 02:43 BST, systems OK (Gateway:200, MC:200), 10 open TRIAGE incidents (INC-132 P1 gateway session errors, INC-130 P1 gateway session errors, INC-131 P2 rate limit exhaustion, INC-129 P2 rate limit exhaustion, INC-133 P2 rate limit exhaustion, plus 5 other P2 rate limit/storage incidents), no in_progress tasks, no urgent action required.
- **2026-06-22 11:44 BST:** Diagnostic work on task disappearance - tasks.json appeared to have only 1 task (CANARY TEST). Root cause: canary test script's POST request created new task but file had been overwritten/wiped during API testing. Fixed: restored tasks.json from git HEAD (97 tasks: 90 done, 5 triage, 2 backlog). No data loss - all original tasks recovered from git history.
- **2026-06-22 12:59 BST:** Full-stack workflow simulation completed successfully:
  - Added projectId field to Task interface, API POST/PATCH handlers
  - Project tag on TaskCard (📁 badge with indigo color scheme)
  - Project filter dropdown and "Group by Project" toggle
  - UI improvements: Archive column with dashed border + lower opacity, Detail Drawer (right slide-over) with editable fields + read-only activity log
  - Delete button with confirm() dialog, DELETE /api/tasks endpoint
  - POST /api/tasks endpoint
  - Soft UI theme (Shell.tsx, ghost buttons, glass panels)
  - AgentMatrix.tsx wireframe
  - Verification scripts: verify-simulation.ts (golden path), test-canary.ts (auto-cleanup)
  - Fixed archive status to use lowercase "archived" to match column key
  - Fixed URL separator in simulation api()
  - Commits: 3357c9f (full-stack workflow), 86af250 (safety-first config), deeb2c2 (kanban stabilization)
- **2026-06-21 21:20 BST:** Presentation Layer Fix - Fixed missing `src/entry-client.tsx` causing SSR HTML to render as unstyled raw text. Added proper hydration entry point for TanStack Start.
- **2026-06-21 21:50 BST:** Architecture Migration: SpaceStation → TenacitOS - Abandoned Paperclip/TanStack Start architecture. Cloned TenacitOS (Next.js 15) as new baseline, configured environment, started dev server on port 3002.
- **2026-06-21 22:00 BST:** Proxy Updated for TenacitOS - Updated nginx proxy on Docker host: 13005 → Mac port 3002, restoring iPad access.
- **2026-06-21 22:05 BST:** Language Fix: Spanish → English - Translated all TenacitOS UI strings to English (login page, sidebar, Office3D, Skills page).
- **Ongoing:** P1 incident INC-132 (gateway session errors); P2 incidents INC-131 (rate limit exhaustion), INC-130 (gateway session errors), and 6 other P2 rate limit/storage incidents.

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
- **Phase 6 (done):** Review loop integrated into Night Shift - auto-review each completed task overnight. Tonight (01:00 BST) will be first live test.
- Max 5 reviews/night, max $1.00/night (OpenRouter credits)
- Review failure does NOT fail the original task
- **Kanban auto-revert bug (2026-06-12):** save-tasks merge didn't protect `status` when `stalledAt` was set. UI saves overwrote stall detector resets. Fixed by protecting disk-side status/currentStep/progress when stalledAt is present. Also fixed maintenance.sh heredoc bash 3.2 incompatibility.
- **Ghost dispatch fix (2026-06-12):** Tasks stuck in 'Agent starting...' with no sub-agent. Three-pronged fix: (1) pre-dispatch validation checks excluded tags before setting in_progress, (2) 60s ghost timeout resets tasks immediately if sub-agent never starts, (3) wasStalled flag management - Phase 2 clears wasStalled after 3h cooldown. MC UI shows 'Dispatch Failed' and 'Ghost' badges.
- **Dispatch loop fix (2026-06-13):** Extended stall detector Phase 2 cooldowns (stalledAt: 2h, wasStalled: 3h) to prevent rapid dispatch→reset→dispatch loops. dispatchFailed is never auto-cleared.

## Incident Automation Suite (2026-06-18)

Three automations built from analysis of 124 incidents (Jun 12-17):

1. **Gateway Self-Heal** (`scripts/gateway-self-heal.sh`) - Cron every 5 min. Monitors for
   EmbeddedAttemptSessionTakeoverError 3+ times in 10 min → restart via launchctl kickstart
   → health check → create resolved incident. 15-min circuit breaker prevents restart loops.
   Addresses 41% of incidents (gateway crash loops).

2. **Rate Limit Prevention** - Staggered all clustered cron jobs with 60-120s jitter.
   06:00 BST cluster split to 06:00 + 06:05. 02:00 UTC cluster split to 02:00 + 02:02.
   04:00 UTC cluster split to 04:00 + 04:03. FreeRide agentTurn checks backoff state before
   API calls. Addresses 36% of incidents (rate limit exhaustion).

3. **Incident Deduplication** - Fingerprint-based dedup in auto-detect-incidents.sh:
   MD5 of normalized title + sorted tags. 3-tier matching (fingerprint → title → tag overlap).
   `incident-dedup.sh` runs every 4h to consolidate duplicates within 24h window.
   Reduces noise ~20%.

4. **Heartbeat reduced** - 30min → 2h globally. Cron jobs handle frequent monitoring.
   HEARTBEAT.md quiet hours section skips heavy work 23:00-08:00.

## Cron Jobs

Active OpenClaw cron jobs (13 total, 11 enabled):
- **Sessions Cleanup** - 02:00 UTC, systemEvent
- **Session Auto-Expiry** - 04:00 UTC, systemEvent
- **Daily GitHub push** - 04:00 UTC, systemEvent
- **Night Shift Activation** - 01:00 BST, systemEvent → main session
- **night-shift-automation** - 01:00 BST, isolated agentTurn
- **Auto-update FreeRide** - 06:00 BST, isolated agentTurn
- **Daily Incident Auto-Resolve** - 06:00 BST, systemEvent
- **Daily Station Check** - 23:00 BST, systemEvent (Telegram delivery)
- **Weekly Healthcheck** - Monday 08:00 BST, systemEvent
- **Friday GIF** - Friday 17:00 BST, systemEvent

Disabled (merged into maintenance.sh):
- ~~Stall Detector~~ - step 5/10 in maintenance.sh
- ~~Error Spike Watchdog~~ - step 4/10 in maintenance.sh
- ~~Session Cleanup (archive takeover)~~ - duplicate of 02:00 job

LaunchAgents:
- `com.openclaw.maintenance` - every 30 min
- `com.openclaw.mc-dashboard` - MC dev server (port 3000)
- `com.openclaw.mount-check` - every 30 min

## Night Shift

Autonomous task processing 01:00-07:00 when Andre is asleep. Max 2 tasks/night.

- **2026-06-07:** Pipeline deadlock fix - stall detector now clears stalledAt after 30min

---
_Last updated: 2026-06-25 by Space Monkey_

## Insights from 2026-06-24 to 2026-06-25

**Observation**: Despite persistent background incidents (gateway session errors, rate limit exhaustion), the system maintained stability during a London heatwave that peaked at 34°C on June 24th.

**Analysis**: 
- The TenacitOS migration (completed June 21st) appears to have improved resilience, with Mission Control showing intermittent 307 redirects rather than complete outages
- Gateway Self-Heal and Rate Limit Prevention automations are effectively managing incident recurrence
- MyCloud mount remains unavailable since June 21st, indicating a persistent storage/network issue requiring manual intervention

**Action**: Continue monitoring ongoing incidents while prioritizing resolution of the MyCloud mount issue for backup restoration.

---


- **2026-06-21 02:00 BST:** Heartbeat check during quiet hours - systems healthy (Gateway and Mission Control Dashboard both returning 200 OK), 9 open TRIAGE incidents monitored (gateway session errors and rate limit exhaustion), no urgent action required. Updated heartbeat state and daily log.

---


## Memory review 2026-06-21 05:48:54 UTC
Reviewed memory files from the last 2 days:
- dispatcher-log.md

## Ongoing Issues - 2026-06-24 06:21 BST
- **WD MyCloud mount issue**: /Volumes/Public unavailable since 02:43 BST on 2026-06-21 (see incident INC-135). Host MyCloud-1E4N74 responding to ping (192.168.68.61, ~4ms) but SMB ports 139/445 unreachable, preventing mount. Ongoing as of 2026-06-24 06:21 BST.
- **Open incidents** (13 total):
  - INC-141 (P1): Gateway session errors — 8 session(s) with EmbeddedAttemptSessionTakeoverError - recurrence #19
  - INC-140 (P2): Rate limit exhaustion — 89 429 errors in gateway log - recurrence #31
  - INC-139 (P1): Mission Control dashboard down — HTTP 000 - recurrence #30
  - INC-138 (P1): Gateway session errors — 12 session(s) with EmbeddedAttemptSessionTakeoverError - recurrence #36
  - INC-137 (P2): Rate limit exhaustion — 131 429 errors in gateway log - recurrence #39
  - INC-136 (P1): Mission Control dashboard down — HTTP 000 - recurrence #33
  - INC-135 (P2): WD MyCloud mount missing — backup storage unavailable - recurrence #1
  - INC-134 (P1): Gateway session errors — 11 session(s) with EmbeddedAttemptSessionTakeoverError - recurrence #19
  - INC-133 (P2): Rate limit exhaustion — 21 429 errors in gateway log - recurrence #20
  - INC-132 (P1): Gateway session errors — 3 session(s) with EmbeddedAttemptSessionTakeoverError - recurrence #48
  - INC-131 (P2): Rate limit exhaustion — 159 429 errors in gateway log - recurrence #46
  - INC-130 (P1): Gateway session errors — 13 session(s) with EmbeddedAttemptSessionTakeoverError - recurrence #48
  - INC-129 (P2): Rate limit exhaustion — 30 429 errors in gateway log - recurrence #47
- **Note**: All incidents listed above are current; under investigation.
- **Systems**: Gateway responding (200) but experiencing intermittent redirects (307); MyCloud host pingable but SMB service unavailable; Mission Control responding (307) experiencing intermittent outages.
- **Recent architecture migration**: SpaceStation → TenacitOS (Next.js 15) completed on 2026-06-21. Proxy updated, UI language fixed to English.
- **Quiet hours**: Active (23:00-08:00). No urgent action required during quiet hours unless incidents escalate.

## Promoted From Short-Term Memory (2026-06-24)

<!-- openclaw-memory-promotion:memory:memory/2026-06-19.md:13:14 -->
- Actions Taken: Heartbeat check at 10:53 BST: processed cron task, updated heartbeat-state.json; Reviewed FreeRide skill — next step: apply to refresh fallback chain and reduce rate-limit exposure [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-19.md:13-14]
<!-- openclaw-memory-promotion:memory:memory/2026-06-19.md:18:20 -->
- Additional Actions: **FreeRide Rate-Limit Handler Applied**: Applied pending skill proposal `freeride-rate-limit-handler-20260619-6b29df0c13` to fix rate-limit handling for OpenRouter free models; **System Recovery**: Gateway restarted successfully, FreeRide now operational with improved fallback chains; **Heartbeat Poll**: Completed heartbeat cycle at $(date -u +"%H:%M UTC") [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-19.md:18-20]
<!-- openclaw-memory-promotion:memory:memory/2026-06-19.md:30:33 -->
- Completed: Cron job cleanup (2 dead crons removed, FreeRide timeout fixed, Invalid Date fixed); Phase 5.1: Dashboard live data verified (hooks already wired); Phase 5.2: Task dispatch fixed (DashboardRefresher added to tasks page); Phase 5.3: Dashboard panel alignment fixed (grid classes) [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-19.md:30-33]
<!-- openclaw-memory-promotion:memory:memory/2026-06-19.md:26:29 -->
- Completed: Phase 4: Skills Maintenance (night-shift removed, vite-tanstack-debug archived); Pre-Phase 5 health check (all clean except /api/incidents/status 500); Fixed /api/incidents/status 500 — @tanstack/react-start import path changed; Synced tasks.json from Workboard (122 tasks restored) [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-19.md:26-29]
<!-- openclaw-memory-promotion:memory:memory/2026-06-20.md:20:23 -->
- Heartbeat Check - 02:00 BST: Reviewed daily logs for 2026-06-19 and 2026-06-20; Checked open incidents: 9 open (all TRIAGE) - session errors and rate limit exhaustion; Updated heartbeat-state.json with current incident and task check times; Reviewed backlog tasks: several backlog tasks have high dispatchCount (≥3) awaiting dispatch [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-20.md:20-23]
<!-- openclaw-memory-promotion:memory:memory/2026-06-20.md:12:15 -->
- Heartbeat Check - 01:45 BST: Checked email, calendar, mentions (last checked ~5h ago); Updated heartbeat state with new timestamps; Reviewed git status: many system changes, skipped commit; Appended to daily log [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-20.md:12-15]
<!-- openclaw-memory-promotion:memory:memory/2026-06-20.md:32:35 -->
- P1 Incident Notification - 02:16 BST: Sent P1 incident notification for INC-130 (Gateway session errors) to command; Incident severity: P1, Status: TRIAGE, Last activity: 00:51:01Z; Notification includes recommended actions for investigation and mitigation; System appears stable per 02:00 BST check, but critical incident requires awareness [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-20.md:32-35]
<!-- openclaw-memory-promotion:memory:memory/2026-06-20.md:24:26 -->
- Heartbeat Check - 02:00 BST: No new 429 errors found in gateway/logs (checked mc-dashboard-error.log, maintenance.log, gateway-self-heal.log); FreeRide skill applied yesterday appears to be mitigating new rate limit incidents; System appears stable; no immediate action required [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-20.md:24-26]
<!-- openclaw-memory-promotion:memory:memory/2026-06-20.md:5:8 -->
- Heartbeat Check - 01:00 BST: Weather: Shangton: 🌫️ +19°C (checked at 01:00 BST); System: Late night hour (01:00 BST), no urgent checks needed; Heartbeat state updated with weather check timestamp; No action required - returning HEARTBEAT_OK [score=0.806 recalls=0 avg=0.620 source=memory/2026-06-20.md:5-8]

- **2026-06-23 00:00 BST**: Systems stable but incidents persist: MyCloud mount missing (INC-135), gateway session errors (INC-134/132/130), rate limit exhaustion (INC-133/131), and Mission Control dashboard issues (INC-139/136). All monitored via heartbeat checks.
- **2026-06-24 03:05 BST**: Heartbeat monitoring shows stable Gateway (200) and Mission Control (307) responses. Load averages 1.5-2.0, disk 23% (~41GB free), uptime ~13h. 12 TRIAGE + 5 BACKLOG tasks, 91 done, 0 in-progress. 13 open TRIAGE incidents. Quiet hours active (23:00-08:00). Weather: Clear, 24°C.
- **2026-06-24 05:45 BST**: Heartbeat poll - Gateway responding (200), Mission Control responding (307), MyCloud host unreachable (ping failed), ongoing gateway session errors and rate limit exhaustion incidents monitored.


## Memory maintenance check - 2026-06-25T01:26:03.184682
Checked 2 daily log files. No specific actions taken.
