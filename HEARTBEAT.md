# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

## Quiet Hours (23:00-08:00 BST)
- If current time is between 23:00-08:00, ONLY run these checks:
  - Stall Detection (quick scan)
  - Circuit Breaker check
- SKIP during quiet hours:
  - Task pickup/dispatch
  - Incident auto-resolve (cron handles this at 06:00)
  - Memory maintenance
  - Any non-urgent work
- Reply HEARTBEAT_OK if nothing urgent found.

## Task Pickup
- Read `data/tasks.json`, find tasks with `status: "backlog"`
- ONLY pick tasks that are truly dispatchable: no `stalledAt`, `dispatchCount < 3`, not `wasStalled`
- **Exclude tasks with blocking tags:** `needs-human-input`, `planning`, `design`, `roadmap`, `phase-2-dependent`, `phase-3-dependent`, `large-change`, `prevention`, `predictive`, etc. If a tag clearly indicates the task is blocked on something that doesn't exist yet, skip it.
- **Pre-dispatch validation:** Before moving a task to `in_progress`, verify:
  - `dispatchCount < 3` (hard limit — never exceed)
  - No excluded tags present
  - Task is not already being worked on (check `currentStep` is not set by another agent)
  - If validation fails → leave in `backlog`, add history entry with failure reason, DO NOT set `in_progress`
- Sort by priority (P1 > P2 > P3), then by age (oldest first)
- **Only dispatch ONE task per heartbeat cycle** — quality over quantity
- Spawn a sub-agent with a clear task brief including: task ID, title, note/description, and expected output
- Move task to `in_progress` when starting, `done` when complete
- **CRITICAL: When moving a task to `in_progress`, you MUST set `lastActivity` to the current ISO timestamp IMMEDIATELY.** This is the #1 defense against ghost dispatches. If you dispatch a task and the sub-agent never starts, stall detection needs this timestamp to catch it within 30 minutes.
- **NEVER set `currentStep` to "Agent starting…"** — this is the #1 cause of ghost dispatches. Either:
  - Set `currentStep` to the FIRST REAL ACTION (e.g. "Reading tasks.tsx"), OR
  - Leave `currentStep` as `null` until the sub-agent reports its first step
- **The sub-agent MUST update `currentStep` and `lastActivity` (ISO timestamp) every 5-10 min with specific actions** — NOT "Agent starting…". Example: "Reading AppSidebar.tsx", "Editing nav order", "Verifying app loads". Without `lastActivity` updates, stall detection cannot function.
- **Ghost dispatch timeout:** If a task has been `in_progress` with `currentStep: null` or `currentStep: "Agent starting…"` for >60 seconds, the stall detector will auto-reset it. Don't fight this — fix the dispatch pattern instead.
- Write completion summary before marking done
- **Sub-agent task brief MUST include these instructions:**
  - Update `currentStep` to a specific action BEFORE starting work (e.g. "Reading tasks.tsx")
  - Update `lastActivity` to `datetime.now(timezone.utc).isoformat()` at EACH step
  - **Set `lastActivity` IMMEDIATELY when the task is created/moved to in_progress — not just when the sub-agent starts working**
  - Update `progress` to reflect actual completion (10% start, 25% early, 50% midway, 75% late, 100% done)
  - Write a completion `summary` before setting status to `done`
  - Commit and push code changes when complete
  - **Use a Python script to update tasks.json — do NOT edit manually. Example:**
    ```python
    import json
    from datetime import datetime, timezone
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json') as f:
        tasks = json.load(f)
    for t in tasks:
        if t['id'] == 'TASK_ID_HERE':
            t['currentStep'] = 'Specific action'
            t['progress'] = 50
            t['lastActivity'] = datetime.now(timezone.utc).isoformat()
            break
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'w') as f:
        json.dump(tasks, f, indent=2)
    ```
  - **ALWAYS set `lastActivity` when creating a task AND when moving it to in_progress.** Example for task creation:
    ```python
    import json
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    new_task = {
        'id': 'task-xxx',
        'title': '...',
        'status': 'backlog',
        'ts': now,
        'lastActivity': now,  # <-- ALWAYS set this
        'currentStep': None,
        'progress': 0,
        'history': [{'ts': now, 'action': 'created', 'actor': 'monkey', 'details': '...'}]
    }
    ```
  - Run this update at EVERY meaningful step — not just at start and completion
- Only pick up ONE task per heartbeat to avoid overloading
- The main agent (Space Monkey) should handle P1 tasks directly; offload P2/P3 to crew agents
- Crew task routing: infra → lifesupport, code → engineer, knowledge → archivist, unknown → monkey
- **🚫 NO GHOST DISPATCHES:** If you pick up a task, you MUST either work on it directly in this session or spawn a sub-agent. NEVER mark a task `in_progress` and then walk away without doing the work. This is the #1 cause of stale tasks. If you can't work on it immediately, leave it in `backlog`.

## Stall Detection (CRITICAL — check EVERY heartbeat)
- For EVERY task with `status: "in_progress"`, calculate staleness:
  - Use `lastActivity` if set and is a valid ISO timestamp
  - Else use the `ts` field if it's a valid ISO timestamp (skip if it's "just now" or non-parseable)
  - Else use the most recent `history[].ts` entry (including the `created` event)
  - If NO valid timestamp can be found at all, treat as stalled (it's broken data)
- **HARD RULE: If `lastActivity` is null/empty AND the task has been in_progress for >30 minutes, RESET IMMEDIATELY.** No task should sit in_progress without a `lastActivity` update for more than 30 minutes. This catches ghost dispatches where the sub-agent never started.
- If staleness > 2 hours: reset to `backlog`, set `stalledAt` to the current ISO timestamp, add history entry explaining why. The `stalledAt` field prevents the heartbeat from immediately re-dispatching the same task.
- ALSO increment `dispatchCount` by 1 (set to at least 1 if not present). If `dispatchCount >= 3`, the dispatcher will skip the task entirely via its `dispatchCount < 3` filter. This is a secondary guard against the race condition where `stalledAt` gets cleared by the save-tasks merge logic.
- If staleness > 30 minutes but < 2 hours: log a warning. If currentStep is still "Agent starting…" or null, reset immediately — the task was never actually picked up by an agent
- **Ghost dispatch fast-path (Phase 0):** If `currentStep` is "Agent starting…" (or null) AND `lastActivity` is >60 seconds old, reset IMMEDIATELY — don't wait 30 minutes. The sub-agent never started.
- The `startedAt` field is NOT reliable — do not use it for stall detection
- After resetting, commit the change so the Kanban reflects reality immediately

### Stall Detection Bug Fix (2026-06-04)
- **Root cause**: The browser automation task (task-browser-auto-001) sat in_progress for 316+ minutes because:
  1. It was created with `ts="just now"` (non-parseable) and no `lastActivity`
  2. The sub-agent never updated `lastActivity` (ghost dispatch)
  3. Stall detection skipped `ts="just now"` and had no other fallback
  4. The "no valid timestamp" catch-all only triggered after 2 hours
- **Fix applied**:
  1. `history[].ts` (including `created` event) is now used as fallback before "no valid timestamp"
  2. New HARD RULE: any in_progress task with no `lastActivity` for >30 min is immediately reset
  3. Task creation now always sets `lastActivity` to prevent the gap
- **Prevention**: The Task Pickup section now requires `lastActivity` to be set BEFORE dispatch, not just after

## Task Archive Maintenance
- **Done tasks live in the Kanban Done column** — never remove them just because they're complete
- Only archive done tasks older than 30 days to `data/tasks-archive.json`
- **Archive date logic**: Use `completedAt` field first, fall back to the `ts` of the last `completed` history entry. If neither exists, keep in tasks.json (don't archive undated tasks).
- When archiving: append to existing archive, remove from `tasks.json`, commit + push
- The Done column should always show recent completions (last 30 days minimum)
- Archive is for long-term storage only — the Kanban is the source of truth
- **git-push.sh** archives `tasks-archive.json` to GitHub for off-Mac backup

## Circuit Breaker (check EVERY heartbeat)
- Before ANY automated processing (dispatch, incident creation, task pickup), run:
  `bash /Users/spacemonkey/.openclaw/workspace/scripts/circuit-breaker.sh check <error_type>`
- If TRIPPED → log reason, skip that operation
- Error types: `task-dispatch`, `incident-create`, `night-shift`, `auto-resolve`
- 5 identical errors in 10 minutes = 30-minute halt
- Manual reset: `bash /Users/spacemonkey/.openclaw/workspace/scripts/circuit-breaker.sh reset`
- Status: `bash /Users/spacemonkey/.openclaw/workspace/scripts/circuit-breaker.sh status`

## Night Shift (01:00-07:00 BST)

Autonomous task processing when Andre is asleep. Design doc: `NIGHT_SHIFT.md`.

### Activation (triggered by cron at 01:00)
ALL conditions must be true:
- Time is 01:00-07:00 BST
- Dispatchable backlog tasks exist (see eligibility below)
- No 429 rate limit errors in last 30 minutes
- No Andre activity in last 2 hours
- Circuit breaker `night-shift` is NOT tripped (check with `circuit-breaker.sh check night-shift`)

If any condition fails → log reason, skip Night Shift this cycle.

### Task Eligibility
- `status: "backlog"`, no `stalledAt`, `dispatchCount < 3`, not `wasStalled`
- Priority P2 or P3 only (P1 excluded)
- No exclusion tags: `needs-human-input`, `planning`, `design`, `roadmap`, `prevention`, `predictive`
- Sort: P2 before P3, then oldest first
- **Max 2 tasks tonight** (first night trial — increase after 2 successful nights)
- No new tasks after 06:30. Hard stop at 07:00.
- Token limit: 100K total per night

### Dispatch
- Pick ONE eligible task, spawn sub-agent with full task brief
- Sub-agent MUST update `currentStep` and `lastActivity` every 5-10 min — this is CRITICAL. Without intermediate updates, stall detection cannot function and the morning report cannot assess agent behavior.
- **Night Shift stall rule:** If a task has been in_progress for >30 min with no `lastActivity` update (or currentStep still shows "Agent starting…"), reset it to backlog immediately. Do NOT let Night Shift tasks sit frozen. The 07:00 morning report should never show a task that's been stuck for hours.
- On completion: mark done with summary, run review loop (see Review Loop section below), then pick next eligible task
- On failure: move back to backlog with failure note, no retry
- Stop immediately if 429s detected or Andre sends a message
- **Night Shift sub-agent brief MUST include:**
  - The exact Python script to update tasks.json at every step (copy from Task Pickup section)
  - Explicit instruction: "Run the update script after EVERY file read, edit, test, or decision — not just at start and completion"
  - Warning: "The morning report will flag tasks with no intermediate progress updates"

### Forbidden
- Never modify openclaw.json, cron jobs, LaunchAgents, or gateway config
- Never delete tasks — only move to Done with summary
- Never dispatch P1 tasks
- Max 5 min per sub-agent (kill if exceeded)

### State
- Track progress in `data/night-shift-state.json`
- Archive to `data/night-shift-archive/` after each night

### Morning Report (07:00)
Send Telegram sitrep:
```
🌙 Night Shift Report — [date]
✅ Completed: X tasks | ⏭️ Skipped: Y | ❌ Failed: Z | 🪙 Tokens: ~N

Completed:
• [Task] — [one-line summary]
  ↳ Progress updates: [N] intermediate steps logged — [good/needs improvement]

── Agent Behavior ──
📈 Tasks with intermediate progress updates: X/Y
⚠️ Tasks that went straight start→complete with no steps: [list or "None"]

── Station Status ──
💾 Disk: workspace X GB / MC repo Y GB
🚨 Incidents overnight: [count or "None"]
⏱️ Gateway uptime: Xh Ym
📊 Backlog: N tasks (M night-shift eligible)
```

**Progress update assessment:** For each completed task, check its history. If there are no `progress` or `step_update` entries between `started` and `completed`, flag it. The goal is at least 2-3 intermediate updates per task.

### Review Loop (after each completed Night Shift task)
When a Night Shift task is marked `done` and has code changes (non-null `summary` or git diff):
1. Check circuit breaker: `bash scripts/circuit-breaker.sh check night-shift` — if TRIPPED, skip review
2. Check review count in `data/night-shift-state.json` — if `reviewsRun >= 5`, skip review
3. Generate review package: `bash scripts/generate-review-package.sh "<feature title>"`
4. Submit via OpenCode: `opencode run --model openrouter/qwen/qwen3-coder --print-logs "$(cat /tmp/review-pkg-<feature>.md)"`
5. Parse JSON recommendations from output
6. Evaluate each: Accept / Reject / Defer (with reasoning)
7. Implement accepted changes:
   - Single-file targeted edits → use direct `edit` tool
   - Multi-file changes → use `opencode run --model openrouter/qwen/qwen3-coder`
8. Log decisions to `review-system/decisions/REV-<date>-<feature>-decision.md`
9. Update Station Memory wiki with any new lessons
10. Update `night-shift-state.json`: increment `reviewsRun`, add findings
- **Max $1.00/night** for reviews (OpenRouter credits)
- **Review failure does NOT fail the original task** — task stays done, review deferred
- **No review for:** research tasks, config-only changes, or if rate limits detected

## Incident Auto-Resolve (check EVERY heartbeat)
- Read `data/incidents.json`, count open (non-RESOLVED) incidents
- If open incidents > 10: run auto-resolve
  - POST to `/api/incidents/auto-resolve` with `{ closeOldDays: 5 }`
  - This endpoint resolves incidents whose linked tasks are done and closes old orphans
  - If the endpoint doesn't exist yet, run the equivalent Python script directly:
    ```python
    # See /api/incidents/auto-resolve.tsx for logic
    # Resolve: linked task done → incident RESOLVED
    # Close: no linked task AND age >= 5 days → RESOLVED
    ```
- This prevents the incident graveyard from building up again
- The daily 6 AM cron does this automatically; heartbeat is a safety net

## Rule: Sub-agent Timeout
- If a sub-agent runs for >5 minutes with no resolution, kill it and add the task to backlog
- If the main agent spends >10 minutes debugging the same issue, stop and add to backlog
- Always report what was tried and what the blocker is when adding to backlog

# Reminder: INC-130 (gateway session takeover) — 48 recurrences, still open. Known issue, needs human.
# Last checked: 2026-06-22 16:59 BST