# Audit: SpaceStation Tasks vs OpenClaw Workboard

**Date:** 2026-06-22  
**Auditor:** Station Architect (subagent)  
**Scope:** Feature comparison of two task management UIs — SpaceStation's Kanban board and the OpenClaw Control UI Workboard

---

## Part 1 — SpaceStation Tasks Page

**Source files:**
- `spacestation/src/app/(dashboard)/tasks/page.tsx` (1384 lines)
- `spacestation/src/app/api/tasks/route.ts`

### Feature List

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Kanban board** | 5-column board: Triage → Backlog → In Progress → Done → Archive |
| 2 | **Drag-and-drop** | @dnd-kit based drag-and-drop between columns with PointerSensor + KeyboardSensor |
| 3 | **Drag overlay** | Floating card overlay during drag with visual feedback (opacity, shadow, scale) |
| 4 | **Optimistic updates** | UI updates immediately on DnD; reverts on API failure |
| 5 | **Detail drawer** | Full edit modal (title, description, assignee) with backdrop blur glass effect |
| 6 | **Inline editing** | Title, note, assignee editable in drawer; Save/Cancel/Delete buttons |
| 7 | **Delete task** | Delete from drawer with `window.confirm()` |
| 8 | **Archive** | Move to Archive column; confirmation modal; Restore from archive |
| 9 | **Auto-assign (Load Balancer)** | When moved to `in_progress` with no assignee, auto-assigns to least-burdened agent (monkey/lion/owl/fox) |
| 10 | **Agent emoji indicators** | Visual emoji per agent (🐒 Space Monkey, 🥷🏽 Life Support, 🔧 Engineer, 📚 Archivist) |
| 11 | **Priority badges** | P1 (red), P2 (amber), P3 (purple) with color-coded backgrounds |
| 12 | **Priority filter** | Filter by P1/P2/P3/All |
| 13 | **Assignee filter** | Dropdown filter by assignee |
| 14 | **Project filter** | Dropdown filter by projectId |
| 15 | **Group by project** | Toggle to group cards within columns by projectId |
| 16 | **System health filters** | Filter by stalled/ghost tasks with one-click toggles |
| 17 | **Stall detection** | Visual indicator (red border + "STALLED — auto-reset by watchdog") when `stalledAt` is set |
| 18 | **Ghost detection** | Visual indicator (yellow border + "GHOST — agent never started") when `currentStep` is null/"Agent starting…" |
| 19 | **Stale detection** | Visual indicator (yellow clock + "STALE — Xm since last activity") when in_progress with >30min inactivity |
| 20 | **Previously stalled badge** | "Previously stalled" indicator on tasks that were stalled but recovered to backlog |
| 21 | **LIVE indicator** | Pulsing green dot + "LIVE" label when task has activity within last 5 minutes |
| 22 | **Dispatch count badge** | Shows dispatch count; red highlight when ≥3 (dispatch failure indicator) |
| 23 | **Linked incident badge** | Shows linkedIncidentId on card; links to incident actions |
| 24 | **Incident quick actions** | Resolve / Ignore / Escalate buttons on cards with linked incidents |
| 25 | **Activity log (card expand)** | Expandable card shows last 5 history entries (action, actor, details) |
| 26 | **Activity log (drawer)** | Full read-only activity log in detail drawer with timestamps |
| 27 | **Auto-refresh** | Polls `/api/tasks` every 30 seconds |
| 28 | **Pagination (Load more)** | PAGE_SIZE=10 per column; "Load more (N remaining)" button |
| 29 | **Summary counts** | Header shows total + P1/P2/P3 counts |
| 30 | **Timestamp display** | Relative time (just now, 5m ago, 2h ago, 15 Jun) on every card |
| 31 | **Project badge** | Shows 📁 projectId with monospace styling on card |
| 32 | **Keyboard navigation** | KeyboardSensor for accessible drag-and-drop |
| 33 | **Touch support** | PointerSensor with 5px activation constraint for mobile |
| 34 | **Test mode** | `?test=1` or `CANARY_USE_TEST_FILE=true` uses separate test data file |
| 35 | **API: GET** | Returns all tasks with total count |
| 36 | **API: POST** | Create task (title, description, assignee, priority, status, projectId) |
| 37 | **API: PATCH** | Status change (drag), field updates (title/note/assignee/projectId), archive action |
| 38 | **API: DELETE** | Hard delete by ID |
| 39 | **History tracking** | Every status change, field update, archive, create appends to `history[]` with actor + details |
| 40 | **Safe writes** | Uses `safeWrite` / `safeRead` service for atomic file I/O |

### Data Model (SpaceStation Task)

```
id, title, assignee, status, priority, ts, note, linkedIncidentId, tags[],
projectId, history[], lastActivity, currentStep, progress, stalledAt,
wasStalled, dispatchCount, dispatchFailed, dispatchFailedReason, rcaConfidence
```

### Column Definitions

| Key | Label | Icon |
|-----|-------|------|
| triage | Triage | AlertTriangle |
| backlog | Backlog | CircleDot |
| in_progress | In Progress | Zap |
| done | Done | CheckCircle2 |
| archived | Archive | Archive |

---

## Part 2 — OpenClaw Workboard

**Source:** OpenClaw Control UI (`/opt/homebrew/lib/node_modules/openclaw/dist/control-ui/assets/index-Wjxp3gyC.js`)

### API Endpoints (RPC-style via WebSocket)

| Method | Description |
|--------|-------------|
| `workboard.cards.list` | List all cards with statuses |
| `workboard.cards.create` | Create new card |
| `workboard.cards.update` | Patch card fields (status, priority, agentId, sessionKey, etc.) |
| `workboard.cards.delete` | Delete card + clean up links |
| `workboard.cards.move` | Move card to new status + position |
| `workboard.cards.archive` | Archive/unarchive a card |
| `workboard.cards.comment` | Add comment to card |
| `workboard.cards.dispatch` | Dispatch ready work to agents |
| `tasks.list` | List active tasks (with cursor pagination) |
| `tasks.cancel` | Cancel a running task |

### Feature List

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Kanban board** | 9-column board: Triage → Backlog → Todo → Scheduled → Ready → Running → Review → Blocked → Done |
| 2 | **Drag-and-drop** | Card repositioning within/between columns |
| 3 | **Card creation** | Inline draft form at bottom of any column; title, notes, priority, labels, agent, session key, template |
| 4 | **Card editing** | Full edit mode with all fields |
| 5 | **Card deletion** | Delete with link cleanup |
| 6 | **Card archival** | Archive/unarchive with `archivedAt` timestamp |
| 7 | **Card comments** | Threaded comments on cards |
| 8 | **Labels/tags** | Multi-label support (up to 12 labels per card, comma-separated) |
| 9 | **Priority levels** | 4 levels: low, normal, high, urgent |
| 10 | **Agent assignment** | Assign card to specific agent (agentId) |
| 11 | **Session linking** | Link card to an active session (sessionKey, runId) |
| 12 | **Auto session sync** | Card status auto-syncs based on linked session state (running→review, failed→blocked, etc.) |
| 13 | **Stale detection** | Detects stale cards where linked session hasn't reported activity |
| 14 | **Claim/heartbeat** | Cards can be "claimed" by an agent with token + heartbeat; expires after timeout |
| 15 | **Dispatch** | "Dispatch ready work" button dispatches queued cards to agents |
| 16 | **Auto-dispatch** | Autonomous mode auto-dispatches cards and updates status |
| 17 | **Manual mode** | Manual dispatch mode for human-triggered assignment |
| 18 | **Scheduled cards** | Cards with `scheduledAt` timestamp; can't dispatch before scheduled time |
| 19 | **Time tracking** | Duration/timer on cards |
| 20 | **Parent/child links** | Card linking: parent, child, blocks, blocked_by, relates_to |
| 21 | **Blocked detection** | Visual indicator when parent cards aren't done |
| 22 | **Worker logs** | Per-card worker logs with levels (info/warning/error) |
| 23 | **Worker protocol** | Real-time worker state (idle/running/completed/blocked/violated) |
| 24 | **Diagnostics** | Per-card diagnostics with severity (warning/critical) |
| 25 | **Proof of work** | Proof entries (status: unknown + label/command/url/note) |
| 26 | **Artifacts** | File artifacts (label, url, path, mimeType) |
| 27 | **Attachments** | File attachments (fileName, byteSize, mimeType, note) |
| 28 | **Notifications** | Per-card notifications (kind, message) |
| 29 | **Events log** | Event history (created, moved, status changes with from/to) |
| 30 | **Execution tracking** | Engine, mode, status, model, sessionKey, runId per card |
| 31 | **Template cards** | Cards can be created from templates (templateId) |
| 32 | **Automation metadata** | Automation config per card (boardId, skills, workspace, maxRuntime, maxRetries) |
| 33 | **Add session to Workboard** | Convert an active chat session into a Workboard card |
| 34 | **Position ordering** | Explicit `position` field for card ordering within columns |
| 35 | **Archived sessions** | Session picker can show/hide archived sessions |
| 36 | **Multi-board** | Board isolation via `boardId` (default board vs automation boards) |
| 37 | **Task-to-card mapping** | Maps external task IDs to Workboard card IDs for status sync |
| 38 | **Dispatch summary** | After dispatch, shows counts: started, failures, promoted, blocked, reclaimed, orchestrated |

### Data Model (Workboard Card)

```
id, title, status, priority, labels[], position, createdAt, updatedAt,
notes, agentId, sessionKey, runId, taskId, sourceUrl, execution{id,kind,engine,mode,status,model,sessionKey,runId,startedAt,updatedAt},
startedAt, completedAt, events[], metadata{attempts[], comments[], links[],
proof[], artifacts[], attachments[], workerLogs[], workerProtocol{state,updatedAt,detail},
automation{boardId,skills[],workspace,kind,path,branch,maxRuntimeSeconds,maxRetries,scheduledAt,summary,createdCardIds[]},
claim{ownerId,token,claimedAt,lastHeartbeatAt,expiresAt}, diagnostics[],
notifications[], templateId, archivedAt, stale{detectedAt,lastSessionUpdatedAt,reason},
lifecycleStatusSourceUpdatedAt, failureCount
```

### Column Definitions

| Key | Label |
|-----|-------|
| triage | Triage |
| backlog | Backlog |
| todo | Todo |
| scheduled | Scheduled |
| ready | Ready |
| running | Running |
| review | Review |
| blocked | Blocked |
| done | Done |

---

## Part 3 — Comparison Matrix

| Feature | SpaceStation | Workboard | Winner |
|---------|:------------:|:---------:|--------|
| **Columns** | 5 (Triage/Backlog/In Progress/Done/Archive) | 9 (Triage/Backlog/Todo/Scheduled/Ready/Running/Review/Blocked/Done) | Workboard — finer granularity |
| **Drag-and-drop** | ✅ @dnd-kit with overlay | ✅ Native | Tie |
| **Card creation** | ❌ No inline create (API only) | ✅ Inline draft form per column | Workboard |
| **Card editing** | ✅ Detail drawer (title/note/assignee) | ✅ Full edit (all fields) | Workboard — more fields |
| **Card deletion** | ✅ With confirm | ✅ With link cleanup | Workboard |
| **Archive** | ✅ With restore | ✅ With unarchive | Tie |
| **Priority levels** | 3 (P1/P2/P3) | 4 (low/normal/high/urgent) | Workboard |
| **Labels/tags** | ✅ `tags[]` (not UI-visible) | ✅ `labels[]` (UI-visible, filterable) | Workboard |
| **Agent assignment** | ✅ Auto-assign + manual in drawer | ✅ Manual + auto-dispatch | Tie |
| **Load balancer** | ✅ Least-burdened agent auto-assign | ❌ No equivalent | SpaceStation |
| **Session linking** | ❌ No equivalent | ✅ sessionKey + runId + auto-sync | Workboard |
| **Auto session sync** | ❌ | ✅ Status follows session state | Workboard |
| **Stall detection** | ✅ Visual (red border + indicator) | ✅ Via stale detection | SpaceStation — more visual |
| **Ghost detection** | ✅ Visual (yellow border + indicator) | ❌ No equivalent | SpaceStation |
| **Stale detection** | ✅ 30-min inactivity threshold | ✅ Session-based stale | Tie |
| **LIVE indicator** | ✅ Pulsing green dot + "LIVE" | ❌ No equivalent | SpaceStation |
| **Claim/heartbeat** | ❌ | ✅ Token + heartbeat + expiry | Workboard |
| **Dispatch** | ❌ | ✅ Manual + auto-dispatch | Workboard |
| **Scheduled tasks** | ❌ | ✅ scheduledAt + time-gated dispatch | Workboard |
| **Time tracking** | ❌ | ✅ Duration/timer | Workboard |
| **Parent/child links** | ❌ | ✅ 5 link types (parent/child/blocks/blocked_by/relates_to) | Workboard |
| **Blocked detection** | ❌ | ✅ Visual when parent not done | Workboard |
| **Comments** | ❌ | ✅ Threaded comments | Workboard |
| **Activity/events log** | ✅ History entries (last 5 on card, full in drawer) | ✅ Full events log with from/to status | Workboard |
| **Worker logs** | ❌ | ✅ Per-card worker logs | Workboard |
| **Proof of work** | ❌ | ✅ Proof entries | Workboard |
| **Artifacts/attachments** | ❌ | ✅ File artifacts + attachments | Workboard |
| **Notifications** | ❌ | ✅ Per-card notifications | Workboard |
| **Templates** | ❌ | ✅ Template-based card creation | Workboard |
| **Add session → card** | ❌ | ✅ Convert chat session to card | Workboard |
| **Position ordering** | ❌ (DOM order) | ✅ Explicit position field | Workboard |
| **Multi-board** | ❌ | ✅ boardId isolation | Workboard |
| **Auto-refresh** | ✅ 30s polling | ✅ WebSocket real-time | Workboard |
| **Project grouping** | ✅ Group by projectId | ❌ No equivalent | SpaceStation |
| **Incident linking** | ✅ linkedIncidentId + quick actions | ❌ No equivalent | SpaceStation |
| **Dispatch count badge** | ✅ Shows count, red at ≥3 | ❌ No equivalent | SpaceStation |
| **Test mode** | ✅ Separate test data file | ❌ No equivalent | SpaceStation |
| **Keyboard a11y** | ✅ KeyboardSensor | ✅ Accessible | Tie |
| **Touch support** | ✅ PointerSensor | ✅ Touch-friendly | Tie |
| **Data persistence** | File-based (tasks.json) | Gateway-managed (SQLite/plugin) | Workboard |

### Unique to SpaceStation

1. **Load Balancer** — Auto-assigns to least-burdened agent when moving to In Progress
2. **Ghost detection** — Identifies tasks where agent never started (yellow warning)
3. **LIVE indicator** — Real-time pulsing green dot for active tasks
4. **Incident integration** — Linked incidents with Resolve/Ignore/Escalate quick actions
5. **Project grouping** — Group cards by projectId within columns
6. **Dispatch count badge** — Visual indicator of dispatch failures
7. **Test mode** — Separate data file for safe testing
8. **RCA confidence** — `rcaConfidence` field for root cause analysis

### Unique to Workboard

1. **9-column board** — Finer workflow granularity (Scheduled, Ready, Running, Review, Blocked)
2. **Session linking + auto-sync** — Card status follows agent session state automatically
3. **Claim/heartbeat** — Agent claims card with token, heartbeat keeps it alive
4. **Dispatch system** — Manual + auto-dispatch of ready work to agents
5. **Scheduled tasks** — Time-gated card dispatch
6. **Parent/child dependencies** — 5 link types with blocked detection
7. **Comments** — Threaded discussions on cards
8. **Worker logs/diagnostics** — Rich execution observability
9. **Proof of work** — Structured evidence of task completion
10. **Artifacts/attachments** — File management per card
11. **Templates** — Reusable card templates
12. **Add session to Workboard** — Convert chat sessions to trackable cards
13. **Labels (UI)** — Visible, filterable labels
14. **Multi-board** — Isolated boards via boardId
15. **Real-time sync** — WebSocket-based (no polling)

---

## Recommendation

### Source of Truth: **OpenClaw Workboard**

**Rationale:**

1. **Superior workflow granularity** — 9 columns vs 5. Workboard's Scheduled/Ready/Running/Review/Blocked states map better to real agent-driven workflows. SpaceStation's "In Progress" is a black box; Workboard exposes the full lifecycle.

2. **Session integration is the killer feature** — Workboard cards can link to live agent sessions and auto-sync status. This is the bridge between "task management" and "agent execution." SpaceStation has no equivalent — its tasks are passive records.

3. **Dispatch + claim model** — Workboard's dispatch system actively pushes work to agents with claim/heartbeat semantics. This is how OpenClaw's agent fleet actually operates. SpaceStation's load balancer is a pale approximation.

4. **Dependency management** — Parent/child/blocks links with blocked detection are essential for complex multi-step work. SpaceStation has no dependency tracking.

5. **Observability** — Worker logs, diagnostics, proof of work, artifacts, notifications — Workboard provides full execution observability. SpaceStation's history log is append-only and limited.

6. **Real-time sync** — WebSocket-based updates vs 30-second polling.

7. **Scale** — Workboard already has 108+ completed tasks and is the operational backbone of OpenClaw. SpaceStation has ~104 tasks (91 done, mostly historical migration).

### What SpaceStation Should Keep

- **Incident integration** — The linkedIncidentId + Resolve/Ignore/Escalate pattern is valuable. Workboard should gain incident linking.
- **Ghost detection** — The visual "agent never started" warning is useful. Workboard's stale detection partially covers this but isn't as explicit.
- **Project grouping** — Useful for organizing cards. Workboard could add this.
- **LIVE indicator** — Nice UX touch. Workboard could add a similar active-session indicator.
- **Test mode** — Separate test data for safe experimentation.

### Migration Path

1. **Immediate:** SpaceStation tasks page should be read-only or deprecated for task management.
2. **Short-term:** SpaceStation should proxy to Workboard API for task CRUD operations.
3. **Medium-term:** Incident management features from SpaceStation should be ported to Workboard (incident-linked cards with quick actions).
4. **Long-term:** SpaceStation's dashboard should focus on monitoring/observability (station health, memory, weather) while Workboard owns task management.

---

## Appendix: Raw Counts

| Metric | SpaceStation | Workboard |
|--------|:------------:|:---------:|
| Total tasks | 104 | 108+ completed |
| Active columns | 5 | 9 |
| Statuses | triage/backlog/in_progress/done/archived | triage/backlog/todo/scheduled/ready/running/review/blocked/done |
| Priorities | P1/P2/P3 | low/normal/high/urgent |
| Link types | linkedIncidentId | parent/child/blocks/blocked_by/relates_to |
| API style | REST (HTTP) | WebSocket RPC |
| Refresh | 30s poll | Real-time WebSocket |
