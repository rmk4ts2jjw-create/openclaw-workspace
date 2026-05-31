# Keep this file empty (or with only comments) to skip heartbeat API calls.

# Add tasks below when you want the agent to check something periodically.

## Task Pickup
- Read `data/tasks.json`, find tasks with `status: "backlog"`
- For each backlog task, spawn a sub-agent (or work directly if simple) to complete it
- Move task to `in_progress` when starting, `done` when complete
- Write completion summary before marking done (see task details)
- Only pick up one task per heartbeat to avoid overloading
- If a task is already `in_progress` and was started >2 hours ago with no progress update, reset it to backlog

## Rule: Sub-agent Timeout
- If a sub-agent runs for >5 minutes with no resolution, kill it and add the task to backlog
- If the main agent spends >10 minutes debugging the same issue, stop and add to backlog
- Always report what was tried and what the blocker is when adding to backlog
