# tasks.json → Workboard Migration Plan

**Status:** Planning (awaiting approval)
**Priority:** P2 — Large architectural change
**Created:** 2026-06-09

## Current State

- `data/tasks.json`: 109 tasks (108 done, 1 backlog)
- Workboard: 4 cards (3 incidents + 1 backlog task)
- MC `/tasks` page: reads/writes `tasks.json` via `getTasks()` / `saveTasks()`
- MC `/incidents` page: reads `incidents.json`, links to tasks via `linkedIncidentId`

## Mapping: Task Fields → Workboard Cards

| tasks.json field | Workboard field | Notes |
|-----------------|----------------|-------|
| `id` | card id | Generate WB-compatible ID |
| `title` | title | Direct map |
| `status` | status | Map: done→done, backlog→backlog, in_progress→running |
| `priority` | priority | Map: P1→urgent, P2→high, P3→normal |
| `assignee` | agent id | Map crew names to agent IDs |
| `tags` | labels | Direct map |
| `note` | notes | Direct map |
| `summary` | notes (append) | Append to notes field |
| `linkedIncidentId` | linked task/session | Use workboard_link |
| `history` | card events | Import as events |
| `completedAt` | completion metadata | Store in execution metadata |
| `startedAt` | claim metadata | Store in execution metadata |

## Migration Steps

### Phase A: Export (one-time)
1. Read all 109 tasks from `tasks.json`
2. For each task, create a Workboard card via `openclaw workboard create`
3. Set correct status, priority, labels, agent
4. Import history as card comments
5. Link incident-related cards via `workboard_link`

### Phase B: Cutover (requires approval)
1. Switch MC `/tasks` page to read from Workboard API instead of `tasks.json`
2. Switch MC `/tasks` page to write via `workboard_create`/`workboard_update` instead of `saveTasks`
3. Update heartbeat stall detection to use `workboard_list` instead of reading JSON
4. Update Night Shift dispatch to use `workboard_claim` instead of JSON manipulation

### Phase C: Cleanup
1. Archive `tasks.json` (rename to `tasks.json.archived`)
2. Remove `getTasks()`, `saveTasks()` server functions
3. Remove `/api/save-tasks` and `/api/dispatch` endpoints
4. Update AGENTS.md to reference Workboard tools instead of JSON files

## Rollback Plan
- Keep `tasks.json` as backup until Phase C
- If Workboard issues: switch MC page back to JSON reads
- Workboard cards can be exported via `openclaw workboard list --json`

## Risks
- **Medium**: Workboard API may not support all our custom fields (history, summaries)
- **Low**: 108 done tasks are historical — only 1 active task needs live migration
- **Low**: MC UI may need adjustments for Workboard's different status enum

## Recommendation
**Approve Phase A now** (export done tasks as archived Workboard cards — low risk).
**Defer Phase B** until Andre approves (requires UI changes + testing).
**Phase C** follows naturally after Phase B is stable.
