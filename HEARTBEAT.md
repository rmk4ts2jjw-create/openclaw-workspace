# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

## Task Pickup
- Read `data/tasks.json`, find tasks with `status: "backlog"`
- For each backlog task, spawn a sub-agent (or work directly if simple) to complete it
- Move task to `in_progress` when starting, `done` when complete
- Write completion summary before marking done (see task details)
- Only pick up one task per heartbeat to avoid overloading

## Stall Detection (CRITICAL — check EVERY heartbeat)
- For EVERY task with `status: "in_progress"`, calculate staleness:
  - Use `lastActivity` if set and is a valid ISO timestamp
  - Else use the `ts` field if it's a valid ISO timestamp (skip if it's "just now" or non-parseable)
  - Else use the most recent `history[].ts` entry
  - If NO valid timestamp can be found at all, treat as stalled (it's broken data)
- If staleness > 2 hours: reset to `backlog`, set `stalledAt` to the current ISO timestamp, add history entry explaining why. The `stalledAt` field prevents the work-dispatcher from immediately re-dispatching the same task.
- ALSO increment `dispatchCount` by 1 (set to at least 1 if not present). If `dispatchCount >= 3`, the dispatcher will skip the task entirely via its `dispatchCount < 3` filter. This is a secondary guard against the race condition where `stalledAt` gets cleared by the save-tasks merge logic.
- If staleness > 30 minutes but < 2 hours: log a warning but don't reset yet
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
