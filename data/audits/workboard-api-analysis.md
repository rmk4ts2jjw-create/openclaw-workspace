# Workboard API Analysis

**Date:** 2026-06-22
**Source:** OpenClaw docs (`/opt/homebrew/lib/node_modules/openclaw/docs/`) + minified Control UI bundle

---

## 1. Workboard RPC Methods (Gateway API)

All methods are under the `workboard.*` namespace, called via Gateway WebSocket RPC.

### Card CRUD

| Method | Permission | Description |
|--------|-----------|-------------|
| `workboard.cards.list` | `operator.read` | List all cards with statuses |
| `workboard.cards.create` | `operator.write` | Create new card |
| `workboard.cards.update` | `operator.write` | Patch card fields (status, priority, agentId, sessionKey, etc.) |
| `workboard.cards.move` | `operator.write` | Move card to new status + position |
| `workboard.cards.delete` | `operator.write` | Delete card + clean up links |
| `workboard.cards.archive` | `operator.write` | Archive/unarchive a card |
| `workboard.cards.comment` | `operator.write` | Add comment to card |
| `workboard.cards.dispatch` | `operator.write` | Dispatch ready work to agents |

### Card Data Methods

| Method | Permission | Description |
|--------|-----------|-------------|
| `workboard.cards.export` | `operator.read` | Export card data |
| `workboard.cards.diagnostics` | `operator.read` | Get card diagnostics |
| `workboard.cards.diagnostics.refresh` | `operator.write` | Refresh diagnostics |

### Task Methods (linked to cards)

| Method | Permission | Description |
|--------|-----------|-------------|
| `tasks.list` | `operator.read` | List active tasks (cursor pagination) |
| `tasks.cancel` | `operator.write` | Cancel a running task |

### Notification Methods

| Method | Permission | Description |
|--------|-----------|-------------|
| `workboard.notify_subscribe` | `operator.write` | Subscribe to notifications |
| `workboard.notify_list` | `operator.read` | List notifications |
| `workboard.notify_events` | `operator.read` | Read notification events |
| `workboard.notify_advance` | `operator.write` | Advance notification cursor |
| `workboard.notify_unsubscribe` | `operator.write` | Unsubscribe |

### Board Management

| Method | Permission | Description |
|--------|-----------|-------------|
| `workboard.board_create` | `operator.write` | Create a board |
| `workboard.board_archive` | `operator.write` | Archive a board |
| `workboard.board_delete` | `operator.write` | Delete a board |
| `workboard.boards` | `operator.read` | List boards |
| `workboard.stats` | `operator.read` | Board queue stats |

### Agent Tools (for worker agents)

| Method | Description |
|--------|-------------|
| `workboard_list` | List compact cards with claim/diagnostic state |
| `workboard_read` | Return one card + bounded worker context |
| `workboard_create` | Create card with parents, tenant, skills, workspace |
| `workboard_link` | Link parent card to child card |
| `workboard_claim` | Claim card for calling agent, move to `running` |
| `workboard_heartbeat` | Refresh claim heartbeat |
| `workboard_release` | Release claim, move to next status |
| `workboard_complete` | Complete card with summary, proof, artifacts |
| `workboard_block` | Block card with reason |
| `workboard_unblock` | Move blocked card back to `todo` |
| `workboard_promote` | Nudge dependency promotion |
| `workboard_reassign` | Reassign card to different agent |
| `workboard_reclaim` | Reclaim stuck work |
| `workboard_comment` | Add handoff notes |
| `workboard_proof` | Attach proof/artifact references |
| `workboard_dispatch` | Dispatch ready work |
| `workboard_specify` | Clarify triage/backlog card into `todo` |
| `workboard_decompose` | Fan parent card into linked children |
| `workboard_attachment_add` | Store small card attachments |
| `workboard_attachment_read` | Read card attachments |
| `workboard_attachment_delete` | Delete card attachments |
| `workboard_worker_log` | Record worker log lines |
| `workboard_protocol_violation` | Block card when worker stops without completing |
| `workboard_runs` | Get persisted run-attempt history |
| `workboard_boards` | Inspect board namespaces |
| `workboard_notify_*` | Notification subscription management |

---

## 2. Workboard Card Fields vs SpaceStation Task Fields

### Workboard Card (full schema)

```
id: string
title: string
status: "triage" | "backlog" | "todo" | "scheduled" | "ready" | "running" | "review" | "blocked" | "done"
priority: "low" | "normal" | "high" | "urgent"
labels: string[]
position: number
createdAt: number (epoch ms)
updatedAt: number (epoch ms)
notes: string
agentId: string (optional)
sessionKey: string (optional)
runId: string (optional)
taskId: string (optional)
sourceUrl: string (optional)
execution: {
  id: string
  kind: "agent-session"
  engine: string
  mode: "autonomous" | "manual"
  status: "idle" | "running" | "completed" | "blocked" | "violated"
  model: string
  startedAt: number
  updatedAt: number
  sessionKey?: string
  runId?: string
}
startedAt: number (optional)
completedAt: number (optional)
events: CardEvent[]
metadata: {
  attempts: AttemptSummary[]
  comments: Comment[]
  links: CardLink[]
  proof: ProofEntry[]
  artifacts: Artifact[]
  attachments: Attachment[]
  workerLogs: WorkerLog[]
  workerProtocol: { state, updatedAt, detail }
  automation: AutomationConfig
  claim: ClaimInfo
  diagnostics: Diagnostic[]
  notifications: Notification[]
  templateId?: string
  archivedAt?: number
  stale?: StaleInfo
  lifecycleStatusSourceUpdatedAt?: number
  failureCount?: number
}
```

### SpaceStation Task (current)

```
id: string
title: string
assignee: string
status: "triage" | "backlog" | "in_progress" | "done" | "archived"
priority: "P1" | "P2" | "P3"
ts: string (ISO)
note: string
linkedIncidentId: string
tags: string[]
projectId: string
history: HistoryEntry[]
lastActivity: string (ISO)
currentStep: string
progress: number
stalledAt: string (ISO)
wasStalled: boolean
dispatchCount: number
dispatchFailed: boolean
dispatchFailedReason: string
rcaConfidence: number
```

### Field Mapping

| SpaceStation Task | Workboard Card | Notes |
|-------------------|----------------|-------|
| `id` | `id` | Direct |
| `title` | `title` | Direct |
| `assignee` | `agentId` | Different name |
| `status` | `status` | Different values (see below) |
| `priority` | `priority` | Different scale (P1-3 vs low/normal/high/urgent) |
| `note` | `notes` | Different name |
| `tags` | `labels` | Different name |
| `linkedIncidentId` | ❌ No equivalent | SpaceStation-specific |
| `projectId` | `metadata.automation.boardId` | Indirect |
| `history` | `metadata.comments` + `events` | Split across two arrays |
| `lastActivity` | `updatedAt` | Different format (ISO vs epoch ms) |
| `currentStep` | `metadata.workerProtocol.detail` | Indirect |
| `progress` | ❌ No equivalent | SpaceStation-specific |
| `stalledAt` | `metadata.stale` | Different structure |
| `wasStalled` | ❌ No equivalent | SpaceStation-specific |
| `dispatchCount` | `metadata.attempts.length` | Indirect |
| `rcaConfidence` | ❌ No equivalent | SpaceStation-specific |
| ❌ No equivalent | `sessionKey` | Workboard-specific |
| ❌ No equivalent | `runId` | Workboard-specific |
| ❌ No equivalent | `taskId` | Workboard-specific |
| ❌ No equivalent | `execution` | Workboard-specific |
| ❌ No equivalent | `metadata.links` | Workboard-specific |
| ❌ No equivalent | `metadata.proof` | Workboard-specific |
| ❌ No equivalent | `metadata.artifacts` | Workboard-specific |
| ❌ No equivalent | `metadata.workerLogs` | Workboard-specific |
| ❌ No equivalent | `metadata.claim` | Workboard-specific |
| ❌ No equivalent | `metadata.diagnostics` | Workboard-specific |

### Status Mapping

| SpaceStation | Workboard |
|-------------|-----------|
| `triage` | `triage` |
| `backlog` | `backlog` |
| `in_progress` | `running` |
| `done` | `done` |
| `archived` | (via `metadata.archivedAt`) |

### Priority Mapping

| SpaceStation | Workboard |
|-------------|-----------|
| `P1` | `urgent` |
| `P2` | `high` |
| `P3` | `normal` |

---

## 3. API Call: Dispatch Ready Work

**Method:** `workboard.cards.dispatch` (no params)

**What it does:**
1. Promotes dependency-ready children to `ready`
2. Blocks expired claims or timed-out worker runs
3. Records dispatch metadata on ready cards
4. Selects a small batch of unclaimed ready cards (max 3 by default)
5. Claims each selected card
6. Starts a subagent worker run with bounded card context + claim token
7. Stores worker run id, session key, task linkage, execution status, worker log on card

**Response:** JSON with `started`, `startFailures`, `promoted`, `blocked`, `reclaimed`, `orchestrated` counts.

---

## 4. API Call: New Card

**Method:** `workboard.cards.create`

**Params:**
```json
{
  "title": "string (required)",
  "notes": "string (optional)",
  "status": "string (default: todo)",
  "priority": "string (default: normal)",
  "labels": ["string"] (optional),
  "agentId": "string (optional)",
  "sessionKey": "string (optional)",
  "boardId": "string (optional, default: default)",
  "templateId": "string (optional)",
  "parentCardId": "string (optional)"
}
```

**Response:** Full card object.

---

## 5. API Call: Move Card Between Columns

**Method:** `workboard.cards.move`

**Params:**
```json
{
  "id": "string (required)",
  "status": "string (required) - target column status",
  "position": "number (optional)"
}
```

**Response:** Updated full card object.

---

## 6. Session Linking

**How it works:**
1. Card has `sessionKey` and `runId` fields
2. When a session is linked, Workboard tracks its lifecycle:
   - Active session → card status = `running`
   - Completed session → card status = `review`
   - Failed/killed/timed-out session → card status = `blocked`
3. Manual review states win — if operator moves card to `review`/`blocked`/`done`, auto-sync stops
4. Stale detection: if linked session stops reporting activity, card is marked stale
5. Sessions can be created from the card (starts agent run) or captured from existing sessions ("Add to Workboard")

**Session key format:** `agent:<agentId>:subagent:workboard-<boardId>-<cardId>` for assigned cards, `subagent:workboard-<boardId>-<cardId>` for unassigned.

---

## 7. Key Differences Summary

| Aspect | SpaceStation | Workboard |
|--------|-------------|-----------|
| **Storage** | JSON file (`tasks.json`) | SQLite (plugin state) |
| **API** | REST (`/api/tasks`) | WebSocket RPC (`workboard.cards.*`) |
| **Auth** | None | Gateway token with `operator.read`/`operator.write` |
| **Columns** | 5 (triage/backlog/in_progress/done/archived) | 9 (triage/backlog/todo/scheduled/ready/running/review/blocked/done) |
| **Priorities** | P1/P2/P3 | low/normal/high/urgent |
| **Session linking** | ❌ | ✅ sessionKey + runId + auto-sync |
| **Dispatch** | ❌ | ✅ `workboard.cards.dispatch` |
| **Dependencies** | ❌ | ✅ parent/child/blocks links |
| **Comments** | ❌ | ✅ `workboard.cards.comment` |
| **Worker logs** | ❌ | ✅ `metadata.workerLogs` |
| **Proof/Artifacts** | ❌ | ✅ `metadata.proof` / `metadata.artifacts` |
| **Real-time** | 30s polling | WebSocket push |
| **Multi-agent** | ❌ | ✅ claim/heartbeat protocol |
| **Incident linking** | ✅ `linkedIncidentId` | ❌ |
| **Project grouping** | ✅ `projectId` | ❌ (but has `boardId`) |
| **Stall detection** | ✅ Built-in | ✅ Via stale detection |
