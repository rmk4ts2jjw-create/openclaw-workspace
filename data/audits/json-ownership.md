# JSON File Ownership Audit — Mission Control

Audited all files in `src/lib/server-data/` and `src/server.ts` for JSON file read/write patterns.
Date: 2026-06-18

## Legend

- **Readers**: functions that read the file (may be multiple paths to same file)
- **Writers**: functions that write to the file
- **Race Condition Risk**:
  - **High**: Multiple writers + no atomic write pattern (writeFileSync without temp file + rename)
  - **Medium**: Multiple writers with some atomic patterns
  - **Low**: Single writer, or multiple writers but all use atomic writes
- **Ownership Clarity**: **Clear** = single writer or clearly designated owner; **Unclear** = multiple writers, no designated primary

---

## Inventory

### `data/tasks.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getTasks` (tasks.ts:11), `getBacklogCount` (tasks.ts:16), `saveTasks` (tasks.ts:29), `getOpenClawStatus` (openclaw-status.ts:50), `getAwaitingReviewCount` (openclaw-status.ts:97), `getActivityFeed` (activity.ts:14), `search` (search.ts:17), `getAgentStatus` (agent-status.ts:15), `readTasks` (timeline-data.ts:47), `server.ts:/api/save-tasks` (91-93), `server.ts:/api/tasks` (647-649), `server.ts:/api/tasks/add` (351-353), `server.ts:/api/events` (674-676), `server.ts:/api/agent-status` (607-610), `server.ts:/api/station-memory/suggest` (399) |
| **Writers** | `saveTasks` (tasks.ts:48-49, atomic: tmp + rename), `server.ts:/api/save-tasks` (120-121, atomic: tmp + rename), `server.ts:/api/tasks/add` (366, direct writeFileSync) |
| **# Writers** | 3 |
| **Race Risk** | **Medium** — two writes use atomic write pattern (tmp+rename), but `/api/tasks/add` does a direct `writeFileSync` without atomic pattern. All three are separate request handlers that could interleave. |
| **Ownership** | **Unclear** — three different writer paths (server fn `saveTasks`, raw API `/api/save-tasks`, raw API `/api/tasks/add`) all write to the same file. No single owner designated. |

**Recommendation**: Consolidate to **single-writer**. Make `/api/save-tasks` the sole write path. Convert `saveTasks` server fn (tasks.ts) to delegate to the API. Convert `/api/tasks/add` to also delegate. Use atomic write (tmp+rename) — which `/api/save-tasks` already does.

---

### `data/queue.json`

| Column | Detail |
|--------|--------|
| **Readers** | `dispatchTask` (tasks.ts:60), `getQueue` (tasks.ts:76), `server.ts:/api/dispatch` (143) |
| **Writers** | `dispatchTask` (tasks.ts:71, direct writeFileSync), `server.ts:/api/dispatch` (153, direct writeFileSync) |
| **# Writers** | 2 |
| **Race Risk** | **High** — both use raw `writeFileSync` without atomic pattern. Two concurrent dispatches could clobber each other. |
| **Ownership** | **Unclear** — duplicate logic in `tasks.ts` and `server.ts` both write to queue.json with different code paths. |

**Recommendation**: Consolidate to **single-writer**. Remove the `dispatchTask` server fn (tasks.ts) and route all dispatches through `/api/dispatch` in `server.ts` (which already exists). Add atomic write (tmp+rename) to the survivor.

---

### `data/incidents.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getActivityFeed` (activity.ts:24), `getIncidents` (incidents.ts:10), `readIncidentsList` (incidents.ts:20), `search` (search.ts:32), `readIncidents` (timeline-data.ts:53), `server.ts:/api/events` (690), `server.ts:/api/incidents/update` (280), `server.ts:/api/incidents/timeline` (317), `server.ts:/api/station-memory/suggest` (437) |
| **Writers** | `writeIncidentsList` → `createIncident` (incidents.ts:23-25, direct writeFileSync), `server.ts:/api/incidents/update` (285, direct writeFileSync), `server.ts:/api/incidents/timeline` (330, direct writeFileSync) |
| **# Writers** | 3 |
| **Race Risk** | **High** — three writer paths, all using raw `writeFileSync`. Concurrent create + update + timeline append will cause data loss. No atomic writes anywhere. |
| **Ownership** | **Unclear** — three writer paths with no coordination. The `incidents.ts` `createIncident` server fn and the raw API handlers in `server.ts` are independent. |

**Recommendation**: Consolidate to **single-writer**. Route all incident mutations through a single write gate. Add `writeIncidentsList` as the sole function that touches disk, and have the `server.ts` handlers import and call it instead of writing directly. Add atomic write (tmp+rename).

---

### `data/cron-errors.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getActivityFeed` (activity.ts:30), `server.ts:/api/cron-errors` GET (216), `server.ts:/api/cron-errors` POST (231), `server.ts:/api/cron-errors/update` POST (255), `server.ts:/api/events` (700) |
| **Writers** | `server.ts:/api/cron-errors` POST (239, direct writeFileSync), `server.ts:/api/cron-errors/update` POST (263, direct writeFileSync) |
| **# Writers** | 2 (both in server.ts, different routes) |
| **Race Risk** | **Medium** — both writers are in the same file (`server.ts`) but are separate request handlers that can interleave. Both use raw `writeFileSync`. |
| **Ownership** | **Clear** — both writers live in `server.ts` only. No other module writes to this file. However, no coordination between the two routes. |

**Recommendation**: **Keep as-is** but extract to a shared write helper with atomic pattern. Both routes are in `server.ts` already; extract a `writeCronErrors()` helper that reads, patches, and atomically writes. This eliminates the interleave risk between the two POST handlers.

---

### `data/projects.json`

| Column | Detail |
|--------|--------|
| **Readers** | `search` (search.ts:25) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers found. Read-only from MC perspective. Written externally. |
| **Ownership** | **Clear** — MC only reads this file. External/other tool owns writes. |

**Recommendation**: **Keep as-is**.

---

### `data/prediction-state.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getPredictionState` (predictions.ts:53), `getRiskMeterItems` (predictions.ts:88) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers found in MC. Written by external system. |
| **Ownership** | **Clear** — MC only reads. |

**Recommendation**: **Keep as-is**.

---

### `data/auto-heal-state.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getAutoHealState` (predictions.ts:65) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers found in MC. |
| **Ownership** | **Clear** — MC only reads. |

**Recommendation**: **Keep as-is**.

---

### `data/auto-heal-audit.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getAutoHealAudit` (predictions.ts:77) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers found in MC. |
| **Ownership** | **Clear** — MC only reads. |

**Recommendation**: **Keep as-is**.

---

### `data/performance-state.json`

| Column | Detail |
|--------|--------|
| **Readers** | `getPerformanceState` (performance.ts:50) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers found in MC. |
| **Ownership** | **Clear** — MC only reads. |

**Recommendation**: **Keep as-is**.

---

### `data/station-memory.json`

| Column | Detail |
|--------|--------|
| **Readers** | `server.ts:/api/station-memory/suggest` (391), `server.ts:/api/station-memory/add` (491) |
| **Writers** | `server.ts:/api/station-memory/add` (511-513, atomic: tmp + rename) |
| **# Writers** | 1 |
| **Race Risk** | **Low** — single writer with atomic write pattern (tmp+rename). No write contention. |
| **Ownership** | **Clear** — only `/api/station-memory/add` writes. All reads also in `server.ts`. |

**Recommendation**: **Keep as-is**. Well done — single writer, atomic pattern.

---

### `data/crons.json`

| Column | Detail |
|--------|--------|
| **Readers** | `readCrons` (timeline-data.ts:58) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers in MC. |
| **Ownership** | **Clear** — MC only reads. |

**Recommendation**: **Keep as-is**.

---

### `~/.openclaw/openclaw.json` (external config)

| Column | Detail |
|--------|--------|
| **Readers** | `getSystemStats` (system.ts:10), `getOpenClawStatus` (openclaw-status.ts:9), `getAgentStatus` (agent-status.ts:9), `search` (search.ts:66), `server.ts:/api/agent-status` (595-596) |
| **Writers** | *(none in audited files)* |
| **# Writers** | 0 |
| **Race Risk** | **Low** — no writers in MC. Read-only. |
| **Ownership** | **Clear** — MC only reads. External tool (openclaw CLI) owns writes. |

**Recommendation**: **Keep as-is**.

---

### `data/queue-paused.flag` (not JSON, but notable)

| Column | Detail |
|--------|--------|
| **Writers** | `pauseQueue` (quick-actions.ts:36, writeFileSync), `resumeQueue` (quick-actions.ts:43, rm) |
| **Ownership** | **Clear** — both in `quick-actions.ts`. Since this is a flag file (presence or absence), race conditions are benign. |

**Recommendation**: **Keep as-is**.

---

## Summary

| File | Writers | Race Risk | Ownership | Recommendation |
|------|---------|-----------|-----------|----------------|
| `data/tasks.json` | 3 | Medium | Unclear | **Single-writer**: route all writes through `/api/save-tasks` |
| `data/queue.json` | 2 | High | Unclear | **Single-writer**: consolidate into `/api/dispatch` |
| `data/incidents.json` | 3 | High | Unclear | **Single-writer**: consolidate into `writeIncidentsList` helper with atomic write |
| `data/cron-errors.json` | 2 | Medium | Clear | **Keep as-is** but extract shared atomic write helper |
| `data/projects.json` | 0 | Low | Clear | **Keep as-is** |
| `data/prediction-state.json` | 0 | Low | Clear | **Keep as-is** |
| `data/auto-heal-state.json` | 0 | Low | Clear | **Keep as-is** |
| `data/auto-heal-audit.json` | 0 | Low | Clear | **Keep as-is** |
| `data/performance-state.json` | 0 | Low | Clear | **Keep as-is** |
| `data/station-memory.json` | 1 | Low | Clear | **Keep as-is** |
| `data/crons.json` | 0 | Low | Clear | **Keep as-is** |
| `~/.openclaw/openclaw.json` | 0 | Low | Clear | **Keep as-is** |
| `data/queue-paused.flag` | 2 | Low | Clear | **Keep as-is** (flag semantics) |

## Critical Findings

1. **`data/tasks.json`** has the worst ownership problem — 3 writers across 2 files (tasks.ts and server.ts), with `/api/tasks/add` missing the atomic write pattern that `saveTasks` and `/api/save-tasks` use. The `/api/save-tasks` handler in `server.ts` (line 78) and the `saveTasks` server fn in `tasks.ts` (line 22) are essentially duplicate implementations of the same merge+write logic. These should be unified.

2. **`data/queue.json`** has high race risk because both `dispatchTask` (tasks.ts) and `/api/dispatch` (server.ts) write directly without coordination. The server.ts version handles the raw API path, while the tasks.ts version handles the server fn path. They should be unified.

3. **`data/incidents.json`** has 3 writers, none using atomic writes. Concurrent `createIncident`, `/api/incidents/update`, and `/api/incidents/timeline` calls can corrupt data. All writes should route through a single function.

4. Overall, **5 of 13** tracked files have ownership or race condition issues worth addressing.
