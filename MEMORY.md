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

- **Mission Control Dashboard** - 7-screen monitoring app (TanStack Start, dark theme). Agent Office animation system fully built with Framer Motion. Live data bridge polling OpenClaw gateway: Phase 1 complete (`/api/agent-status`, `/api/tasks`, `/api/events` live); Phase 2 (UI integration) in progress. Hand-crafted pixel art sprites and room scenes integrated. Located at `~/.openclaw/workspace/mission-control-dashboard/` (the single master repo).
- **Agent Office** - The Visual Office page is a living, animated station with 4 rooms, agent sprites with idle/walking/working states, collaboration system, ambient effects. Spec at `memory/agent-office-spec.md`. UI currently uses hardcoded CREW data; live data integration pending.
- **Serving** - `main` is the single branch, served on port 3000 by Vite dev server. No dev branch. GitHub repo: `spacemonkey-home/openclaw-missionscontrol`.

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
_Last updated: 2026-06-20 by Space Monkey_

## Insights from 2026-06-19

# Daily Log - 2026-06-19

## System Status
- Gateway: rate-limit incidents active
- Memory config: OpenAI API key missing
- OpenRouter free model pool exhausted

## Actions Taken
1. Created new daily log
2. Will apply FreeRide patch to fix rate-limit handling

---


- **2026-06-21 02:00 BST:** Heartbeat check during quiet hours - systems healthy (Gateway and Mission Control Dashboard both returning 200 OK), 9 open TRIAGE incidents monitored (gateway session errors and rate limit exhaustion), no urgent action required. Updated heartbeat state and daily log.

---


## Promoted From Short-Term Memory (2026-06-21)

<!-- openclaw-memory-promotion:memory:memory/2026-06-17.md:6:6 -->
- **2026-06-21 06:23 BST:** MyCloud mount still unavailable; host responding to ping; mount attempt failed due to insufficient privileges (requires sudo). See daily log for details.
- Daily Station Check — 2026-06-17 23:00: Status: ✅ ALL SYSTEMS NOMINAL [score=0.811 recalls=0 avg=0.620 source=memory/2026-06-17.md:6-6]
