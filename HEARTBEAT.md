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
  - Update `currentStep` to a specific action before starting work
  - Update `lastActivity` to `datetime.now(timezone.utc).isoformat()` at each step
  - Update `progress` to reflect actual completion (10% start, 50% midway, 100% done)
  - Write a completion `summary` before setting status to `done`
  - Commit and push code changes when complete
- Only pick up ONE task per heartbeat to avoid overloading
- The main agent (Space Monkey) should handle P1 tasks directly; offload P2/P3 to crew agents
- Crew task routing: infra → lifesupport, code → engineer, knowledge → archivist, unknown → monkey

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

## Rule: Sub-agent Timeout
- If a sub-agent runs for >5 minutes with no resolution, kill it and add the task to backlog
- If the main agent spends >10 minutes debugging the same issue, stop and add to backlog
- Always report what was tried and what the blocker is when adding to backlog
