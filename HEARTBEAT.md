# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

## Task Pickup
- Read `data/tasks.json`, find tasks with `status: "backlog"`
- ONLY pick tasks that are truly dispatchable: no `stalledAt`, `dispatchCount < 3`, not `wasStalled`
- Sort by priority (P1 > P2 > P3), then by age (oldest first)
- Spawn a sub-agent with a clear task brief including: task ID, title, note/description, and expected output
- Move task to `in_progress` when starting, `done` when complete
- **The sub-agent MUST update `currentStep` and `lastActivity` (ISO timestamp) every 5-10 min with specific actions** — NOT "Agent starting…". Example: "Reading AppSidebar.tsx", "Editing nav order", "Verifying app loads". Without `lastActivity` updates, stall detection cannot function.
- Write completion summary before marking done
- **Sub-agent task brief MUST include these instructions:**
  - Update `currentStep` to a specific action BEFORE starting work (e.g. "Reading tasks.tsx")
  - Update `lastActivity` to `datetime.now(timezone.utc).isoformat()` at EACH step
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
  - Run this update at EVERY meaningful step — not just at start and completion
- Only pick up ONE task per heartbeat to avoid overloading
- The main agent (Space Monkey) should handle P1 tasks directly; offload P2/P3 to crew agents
- Crew task routing: infra → lifesupport, code → engineer, knowledge → archivist, unknown → monkey
- **🚫 NO GHOST DISPATCHES:** If you pick up a task, you MUST either work on it directly in this session or spawn a sub-agent. NEVER mark a task `in_progress` and then walk away without doing the work. This is the #1 cause of stale tasks. If you can't work on it immediately, leave it in `backlog`.

## Stall Detection (CRITICAL — check EVERY heartbeat)
- For EVERY task with `status: "in_progress"`, calculate staleness:
  - Use `lastActivity` if set and is a valid ISO timestamp
  - Else use the `ts` field if it's a valid ISO timestamp (skip if it's "just now" or non-parseable)
  - Else use the most recent `history[].ts` entry
  - If NO valid timestamp can be found at all, treat as stalled (it's broken data)
- If staleness > 2 hours: reset to `backlog`, set `stalledAt` to the current ISO timestamp, add history entry explaining why. The `stalledAt` field prevents the heartbeat from immediately re-dispatching the same task.
- ALSO increment `dispatchCount` by 1 (set to at least 1 if not present). If `dispatchCount >= 3`, the dispatcher will skip the task entirely via its `dispatchCount < 3` filter. This is a secondary guard against the race condition where `stalledAt` gets cleared by the save-tasks merge logic.
- If staleness > 30 minutes but < 2 hours: log a warning. If currentStep is still "Agent starting…" or null, reset immediately — the task was never actually picked up by an agent
- The `startedAt` field is NOT reliable — do not use it for stall detection
- After resetting, commit the change so the Kanban reflects reality immediately

## Task Archive Maintenance
- **Done tasks live in the Kanban Done column** — never remove them just because they're complete
- Only archive done tasks older than 30 days to `data/tasks-archive.json`
- When archiving: append to existing archive, remove from `tasks.json`, commit + push
- The Done column should always show recent completions (last 30 days minimum)
- Archive is for long-term storage only — the Kanban is the source of truth

## Night Shift (01:00-07:00 BST)

Autonomous task processing when Andre is asleep. Design doc: `NIGHT_SHIFT.md`.

### Activation (triggered by cron at 01:00)
ALL conditions must be true:
- Time is 01:00-07:00 BST
- Dispatchable backlog tasks exist (see eligibility below)
- No 429 rate limit errors in last 30 minutes
- No Andre activity in last 2 hours

If any condition fails → log reason, skip Night Shift this cycle.

### Task Eligibility
- `status: "backlog"`, no `stalledAt`, `dispatchCount < 3`, not `wasStalled`
- Priority P2 or P3 only (P1 excluded)
- No exclusion tags: `needs-human-input`, `planning`, `design`, `roadmap`
- Sort: P2 before P3, then oldest first
- **Max 2 tasks tonight** (first night trial — increase after 2 successful nights)
- No new tasks after 06:30. Hard stop at 07:00.
- Token limit: 100K total per night

### Dispatch
- Pick ONE eligible task, spawn sub-agent with full task brief
- Sub-agent MUST update `currentStep` and `lastActivity` every 5-10 min — this is CRITICAL. Without intermediate updates, stall detection cannot function and the morning report cannot assess agent behavior.
- **Night Shift stall rule:** If a task has been in_progress for >30 min with no `lastActivity` update (or currentStep still shows "Agent starting…"), reset it to backlog immediately. Do NOT let Night Shift tasks sit frozen. The 07:00 morning report should never show a task that's been stuck for hours.
- On completion: mark done with summary, pick next eligible task
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

## Rule: Sub-agent Timeout
- If a sub-agent runs for >5 minutes with no resolution, kill it and add the task to backlog
- If the main agent spends >10 minutes debugging the same issue, stop and add to backlog
- Always report what was tried and what the blocker is when adding to backlog
