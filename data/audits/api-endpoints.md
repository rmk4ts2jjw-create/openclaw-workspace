# API Endpoint Audit — Mission Control Dashboard

**Date:** 2026-06-18
**Scope:** All endpoints dispatched from `src/server.ts:handleApiRequest` + 14 files in `src/routes/api/`
**Router:** TanStack Router with file-based routing (`-` prefix = excluded from routing)
**Dispatch order:** `handleApiRequest` runs FIRST (server.ts:743); TanStack router runs only if it returns null.

The `-` prefix on route files excludes them from the generated route tree (`routeTree.gen.ts`). Files with real handler logic but `-` prefix are **dead code** — never invoked by any request path.

---

## Legend

| Column | Meaning |
|--------|---------|
| Path | URL path + HTTP method |
| Handler | Where the response logic lives (file:line). "server.ts" = `handleApiRequest`. "route file" = TanStack stubs in `src/routes/api/` |
| Called by | Client components/pages that fetch this endpoint |
| R/W | Read, Write, or Both |
| Dup? | Duplicate handler across server.ts + route file |
| Dead? | Handler exists but is never reachable |

---

## 1. Live Endpoints (server.ts — actively serving)

| # | Path | Handler | Called By | R/W | Dup? | Dead? | Verdict |
|---|------|---------|-----------|-----|------|-------|---------|
| 1 | `POST /api/save-tasks` | server.ts:79 | `Dashboard.tsx:419,453,593`, `tasks.tsx:11` | Write | Yes (-save-tasks.tsx) | No | **KEEP** — critical merge-based save, multiple callers |
| 2 | `POST /api/dispatch` | server.ts:134 | `tasks.tsx:25`, `lib/api.ts:21` | Write | Yes (-dispatch.tsx) | No | **KEEP** — dispatches tasks to queue, has exported wrapper |
| 3 | `GET /api/crons` | server.ts:166 | `scheduler/useCronData.ts:42` | Read | Yes (-crons.tsx stub) | No | **KEEP** — reads cron jobs from SQLite |
| 4 | `GET /api/cron-errors` | server.ts:208 | `scheduler/useCronData.ts:43` | Read | Yes (-cron-errors.tsx) | No | **KEEP** — fetches cron error statuses |
| 5 | `POST /api/cron-errors` | server.ts:222 | `tasks.tsx:1181,1236`, `useCronData.ts:173` | Write | Yes (-cron-errors.tsx) | No | **KEEP** — updates cron error status (3 call sites) |
| 6 | `POST /api/incidents/update` | server.ts:271 | `IncidentDetailsDrawer.tsx:504` | Write | Yes (-incidents-update.tsx) | No | **KEEP** — merges actions array into incident |
| 7 | `POST /api/incidents/timeline` | server.ts:299 | `tasks.tsx:1207` | Write | Yes (-incidents-timeline.tsx) | No | **KEEP** — appends timeline entry, triggers auto-resolve |
| 8 | `POST /api/tasks/add` | server.ts:342 | `IncidentDetailsDrawer.tsx:561`, `useCronData.ts:199` | Write | Yes (-tasks-add.tsx) | No | **KEEP** — adds task with duplicate detection |
| 9 | `GET /api/station-memory/suggest` | server.ts:379 | `tasks.tsx:403`, `IncidentDetailsDrawer.tsx:463` | Read | None | No | **KEEP** — generates memory suggestions from completed items |
| 10 | `POST /api/station-memory/add` | server.ts:483 | `tasks.tsx:418`, `IncidentDetailsDrawer.tsx:478` | Write | None | No | **KEEP** — writes record to station-memory.json |
| 11 | `POST /api/cron-toggle` | server.ts:525 | `scheduler/useCronData.ts:137` | Write | Yes (-cron-toggle.tsx stub) | No | **KEEP** — enables/disables cron via CLI |
| 12 | `GET /api/agent-status` | server.ts:584 | `useAgentStatus.ts:15`, `live-data.ts:69` | Read | None | No | **KEEP** — computes agent workload, polled every 10s |
| 13 | `GET /api/tasks` | server.ts:640 | `useTaskStream.ts:89,107`, `lib/api.ts:7` | Read | None | No | **KEEP** — reads all tasks, critical for page load |
| 14 | `GET /api/events` | server.ts:664 | `useTaskStream.ts:90,115` | Read | None | No | **KEEP** — reads activity feed for sidebar |

---

## 2. Server-Only Endpoints (no client caller, possible external use)

| # | Path | Handler | Called By | R/W | Dup? | Dead? | Verdict |
|---|------|---------|-----------|-----|------|-------|---------|
| 15 | `POST /api/cron/enable` | server.ts:545 | No caller found (possibly CLI/script) | Write | None | No (external) | **KEEP** — standalone cron enable, separate from toggle. Consider unifying with `/api/cron-toggle`. |
| 16 | `POST /api/cron/disable` | server.ts:564 | No caller found (possibly CLI/script) | Write | None | No (external) | **KEEP** — standalone cron disable, same note as above. |
| 17 | `POST /api/cron-errors/update` | server.ts:246 | No caller found | Write | None | **No (server-side)** | **REMOVE or add callers** — duplicate of `POST /api/cron-errors`. Client uses `/api/cron-errors` POST directly. This `/update` sub-path is dead code. |

---

## 3. Broken Endpoints (called from client but NO handler — 404)

| # | Path | Handler | Called By | R/W | Status | Verdict |
|---|------|---------|-----------|-----|--------|---------|
| 18 | `POST /api/incidents/status` | **NONE** | `IncidentDetailsDrawer.tsx:512` | Write | **BROKEN** — 404 on every call | **FIX** — no handler in server.ts or route tree. Route file `-incidents-status.tsx` exists but is excluded by `-` prefix. Must add handler to server.ts or wire route file into router. |
| 19 | `POST /api/incidents/resolve` | **NONE** | `IncidentDetailsDrawer.tsx:616` | Write | **BROKEN** — 404 on every call | **FIX** — same issue as #18. Route file `-incidents-resolve.tsx` exists but is excluded. Must add handler to server.ts. |
| 20 | `POST /api/tasks/${taskId}` | **NONE** | `useTaskStream.ts:182,234` | Write | **BROKEN** — 404 on assign/dismiss | **FIX** — no dynamic route handler exists anywhere. These calls silently fail. Must add a PATCH-like handler for `/api/tasks/:id`. |

---

## 4. Dead Route Files (excluded by `-` prefix, never invoked)

These files export real `GET()`/`POST()` handler functions, but the `-` prefix excludes them from TanStack's route tree. No code path ever calls them.

| # | Path | File | Exports | Verdict |
|---|------|------|---------|---------|
| 21 | `/api/incidents/create` | `-incidents-create.tsx` | `POST()` | **REMOVE** — full create-incident logic with runbook integration. Move to server.ts if needed, otherwise delete. |
| 22 | `/api/incidents/auto-resolve` (GET+POST) | `-incidents-auto-resolve.tsx` | `GET()`, `POST()` | **REMOVE** — bulk auto-resolve logic with dry-run support. Move to server.ts if needed, otherwise delete. |
| 23 | `/api/remediate` (GET+POST) | `-remediate.tsx` | `GET()`, `POST()` | **REMOVE** — runs auto-remediation rules. Move to server.ts if needed, otherwise delete. |
| 24 | `/api/retry-policy` (GET+POST) | `-retry-policy.tsx` | `GET()`, `POST()` | **REMOVE** — retry state machine + incident creation. Move to server.ts if needed, otherwise delete. |

---

## 5. Duplicate Handlers (server.ts + route file — route file is dead)

| # | Path | server.ts handler | Route file handler | Verdict |
|---|------|-------------------|---------------------|---------|
| 25 | `POST /api/save-tasks` | server.ts:79 | `-save-tasks.tsx:44` (full logic, mutex, station-memory ingestion) | **REMOVE route file** — server.ts handler runs first. Save-tasks has critical merge+mutex logic; keep only `server.ts`. |
| 26 | `POST /api/dispatch` | server.ts:134 | `-dispatch.tsx:8` (full logic + ship-log) | **REMOVE route file** — server.ts handler runs first. The route file has extra ship-log writing not in server.ts — consider incorporating that. |
| 27 | `GET/POST /api/cron-errors` | server.ts:208,222 | `-cron-errors.tsx:8,21` (full GET+POST) | **REMOVE route file** — server.ts handlers run first. Logic is identical. |
| 28 | `POST /api/incidents/update` | server.ts:271 | `-incidents-update.tsx:8` (full POST) | **REMOVE route file** — server.ts runs first. Logic is identical. |
| 29 | `POST /api/incidents/timeline` | server.ts:299 | `-incidents-timeline.tsx:9` (full POST + auto-resolve) | **REMOVE route file** — server.ts runs first. Logic is identical. |
| 30 | `POST /api/tasks/add` | server.ts:342 | `-tasks-add.tsx:8` (full POST + duplicate check) | **REMOVE route file** — server.ts runs first. Logic is identical. |

---

## 6. Stub-Only Route Files (no real logic — just suppress TanStack warnings)

| # | Path | File | Exports | Verdict |
|---|------|------|---------|---------|
| 31 | `/api/crons` | `-crons.tsx` | `Route()` → null | **REMOVE** — server.ts:166 handles this. Stub is unnecessary noise. |
| 32 | `/api/cron-toggle` | `-cron-toggle.tsx` | `Route()` → null | **REMOVE** — server.ts:525 handles this. Stub is unnecessary noise. |

---

## 7. Summary

### Live & Healthy: 14 endpoints
1–14 (all in `server.ts`, called from components)

### Server-Only / OK: 3 endpoints
15–17 (cron/enable, cron/disable, cron-errors/update — no client caller but may have external use)

### Broken (called, no handler): 3 endpoints
18–20 (`/api/incidents/status`, `/api/incidents/resolve`, `/api/tasks/${taskId}`)

### Dead Route Files (real logic, never hit): 4 files
21–24 (`-incidents-create.tsx`, `-incidents-auto-resolve.tsx`, `-remediate.tsx`, `-retry-policy.tsx`)

### Duplicate Handlers (route file dead): 6 files
25–30 (save-tasks, dispatch, cron-errors, incidents-update, incidents-timeline, tasks-add)

### Stub Files (no logic): 2 files
31–32 (`-crons.tsx`, `-cron-toggle.tsx`)

### Recommended Actions

1. **Fix broken endpoints** — add handlers in `server.ts` for:
   - `POST /api/incidents/status` (copy from `-incidents-status.tsx`)
   - `POST /api/incidents/resolve` (copy from `-incidents-resolve.tsx`)
   - `POST /api/tasks/:id` (needs new handler — or route through save-tasks)

2. **Delete dead route files** — remove all 12 files in `src/routes/api/`:
   - Content files with real logic (6 duplicate + 4 orphaned)
   - Stub files (2)

3. **Before deleting duplicates**: diff each route file vs server.ts handler to see if the route file has extra features (e.g., `-dispatch.tsx` writes to ship-log; `-save-tasks.tsx` has mutex + station-memory ingestion; `-incidents-timeline.tsx` has auto-resolve). Incorporate missing features into server.ts before deletion.

4. **Consider unifying** `/api/cron-toggle`, `/api/cron/enable`, `/api/cron/disable` into a single endpoint.
