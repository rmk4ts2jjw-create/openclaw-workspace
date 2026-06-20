# Migration Priority Matrix

**Generated:** 2026-06-20
**Sources:**
- `data/audits/v2-feature-inventory.md` — per-item classification (KEEP AS-IS, KEEP BUT RESTYLE, MERGE, REPLACE)
- `data/audits/v2-duplicate-analysis.md` — per-domain verdicts (USE THEIRS, USE OURS, MERGE BOTH)

---

## Matrix Structure

| List | Criteria | Sources |
|------|----------|---------|
| **High-Value Adopt** | Framework features superior to ours — adopt as-is with minimal effort | `KEEP AS-IS` + `USE THEIRS` |
| **Must-Migrate** | Our features absent from framework — must be ported before cutover | `USE OURS` + `REPLACE` (our version better) |
| **Merge/Restyle** | Overlapping features needing blend of framework architecture + our business logic/visuals | `MERGE` + `KEEP BUT RESTYLE` + `MERGE BOTH` |

---

## 1. High-Value Adopt — Use Framework As-Is

These items require no porting effort — adopt the framework version directly.

### Priority: P0 (Prerequisites — required before anything works)

| Item | Source | Rationale |
|------|--------|-----------|
| Auth system (Clerk + local tokens) | Feature 1.1, Dup §8 | Prerequisite for all authenticated routes |
| API Architecture (FastAPI + OpenAPI + Orval) | Dup §10 | All frontend calls depend on typed API client |
| Database layer (Alembic + SQLModel + PostgreSQL) | Dup §11 | Foundation for all data persistence |
| Backend endpoints (all 75+) | Feature §3 | Every API listed as KEEP AS-IS — production-ready CRUD |
| Data models (all 28) | Feature §4 | All SQLModel models adoptable as-is |
| Services (all 20) | Feature §5 | Business logic layer — production-ready |
| Backend core utilities (auth, config, logging, rate-limit) | Feature §6.2 | Drop-in replacements for ad-hoc server.ts |
| Health endpoints (`/health`, `/healthz`, `/readyz`) | Feature §3.20, Dup §21 | Standards-compliant probes |

### Priority: P1 (New Capabilities — adopt in any order)

| Item | Source | Rationale |
|------|--------|-----------|
| **Board Groups** (CRUD + detail + snapshots) | Feature 1.6 | Entirely new capability, no existing overlap |
| **Skills Marketplace** (search, filter, install/uninstall, packs) | Feature 1.7, Dup §4 | Full productized system — adopt over ad-hoc skills/ |
| **SSE Infrastructure** (Redis-backed streaming) | Dup §9 | Replace all polling with real-time streams |
| **Approvals System** (board + global) | Feature 1.4/1.8, Dup §7 | New capability — approval workflow + confidence scoring |
| **Organization Management** (members, roles, invites, RBAC) | Feature §1.8, Dup §8 | Full multi-tenancy ready for team use |
| **Webhook System** (CRUD, payload history, ingestion) | Feature 1.4, Dup §15 | New capability — typed webhook delivery |
| **Custom Fields** (per-org definitions, typed values) | Feature §1.8, Dup §16 | Structured replacement for ad-hoc JSON fields |
| **Tags** (CRUD, org-scoped, assignments) | Feature §1.8, Dup §17 | Structured tag management |
| **Activity SSE Streams** (live activity, task comments) | Dup §6 | Replace polling with real-time |
| **Cypress E2E + GitHub Actions CI** | Feature §7, Dup §12 | Full testing pyramid |
| **Docker Compose deployment** | Feature §7, Dup §13 | Production-ready multi-service deployment |
| **Documentation** (19 files: arch, deployment, API refs) | Feature §7, Dup §25 | Comprehensive docs adopt as-is |
| **Gateway Connection Testing + Device Pairing** | Feature 1.5 | Form has built-in validation and connection test |

---

## 2. Must-Migrate — Port Our Custom Features

These are absent from the framework and must be rebuilt on top of it before cutover is possible.

### Priority: P0 (Core Differentiators — define what MC is)

| Item | Source | Porting Approach | Effort |
|------|--------|------------------|--------|
| **Incident Management** (P1-P4, timelines, auto-dedup, auto-resolve, linked tasks, runbook) | Dup §18 | New Incident + IncidentTimeline models; new FastAPI endpoints; RQ worker for auto-dedup/auto-resolve; migrate `incidents.json` (9260 lines) → PostgreSQL | **High** |
| **Automation Layer** (Night Shift, Review Loop, heartbeat manager, cron management, circuit breaker, quota) | Dup §19 | New AutomationState + CronJob models; RQ workers; new FastAPI endpoints; migrate 15 `*.state.json` files | **High** |
| **OpenClaw Integration** (sub-agent spawn via CLI, gateway identity in openclaw.json) | Dup §20 | Extend GatewayDispatchService with local process spawn; new API endpoint for sub-agent dispatch | **High** |
| **Agent Office** (animated pixel sprites, rooms, door animations, station ambience) | Feature 1.2/1.3, Dup §2 | React component port; embed in framework dashboard/agent layouts | **Medium** |

### Priority: P1 (Essential — needed for full cutover)

| Item | Source | Porting Approach | Effort |
|------|--------|------------------|--------|
| **Memory System** (daily logs, MEMORY.md, Station Memory SQLite, Wiki bridge, memory suggestions API) | Dup §5 | New MemoryEntry + StationMemory models; FastAPI endpoints wrapping file/DB reads; bridge as background sync worker | **Medium** |
| **Health Monitoring** (disk alerts, swap usage, prediction checks, auto-heal audit) | Dup §21 | New MonitoringMetric model; extend metrics API; RQ worker for periodic checks | **Medium** |
| **Telegram Delivery** (cron report delivery) | Dup §23 | New TelegramNotification service + worker; add as delivery channel | **Low** |
| **Decision Records Wiki** (wiki/decisions/ markdown) | Dup §24 | New Decision model + API; migrate markdown files to DB with rendered output | **Low** |

### Priority: P2 (Nice-to-have — can ship post-cutover)

| Item | Source | Porting Approach | Effort |
|------|--------|------------------|--------|
| **Task Archive** (`tasks-archive.json`, 2576 lines) | Dup §1 | New ArchivedTask model; migrate JSON → PostgreSQL | **Medium** |
| **Task Dedup Logic** (custom detection in POST /api/tasks/add) | Dup §1 | Replace with TaskFingerprint model integration | **Low** |
| **UI Kit Components** (button, input, select, dialog, badge — our themed versions) | Feature 2.9, Dup §14 | Drop-in replacements for framework's shadcn-style components | **Low** |
| **Landing Page** (our existing dashboard home) | Feature 1.1, Dup §14 | Keep our page at `/`; drop framework's landing shell | **Low** |

---

## 3. Merge/Restyle — Blend Framework Architecture + Our Business Logic

These require combining framework's implementation with our custom data, visual identity, or workflows.

### Priority: P0 (Core UX — must be right for cutover)

| Item | Source | Blend Strategy | Effort |
|------|--------|----------------|--------|
| **Dashboard Home** (`/dashboard`) | Feature 1.2, Dup §14 | Framework's metrics API + data layer + navigation; embed our Agent Office (pixel sprites, rooms, ambience) as a panel; keep our dark theme | **High** |
| **Task Management** (kanban + dispatch + status workflow) | Feature 1.4, Dup §1 | Framework's kanban + SSE streaming + drag-and-drop; our triage→backlog→in_progress→done workflow; our dispatch button (spawn sub-agent); restyle cards to match pixel aesthetic; archive integration | **High** |
| **Agent Detail** (`/agents/[id]`) | Feature 1.3, Dup §2 | Framework's data display (health, activity, events); embed Agent Office room view with sprite for that agent; restyle to dark theme | **Medium** |
| **Agent Management** (overall CRUD + visualization) | Dup §2 | Framework's CRUD API + model; extend model with OpenClaw fields (dispatchCount, stalledAt); Agent Office as visual layer | **Medium** |

### Priority: P1 (Important — needed for feature parity)

| Item | Source | Blend Strategy | Effort |
|------|--------|----------------|--------|
| **Board Detail** (kanban + live feed + chat + approvals) | Feature 1.4 | Framework's TaskBoard (drag-and-drop, SSE); restyle cards to our pixel aesthetic; keep framework's LiveFeedCard, BoardChatComposer, approvals panel | **Medium** |
| **Activity Feed** (SSE + visual style) | Feature 2.6, Dup §6 | Framework's SSE data pipeline + ActivityFeed component; restyle with our event visual treatment (speech bubbles, agent flash, pixel icons) | **Low** |
| **Skills System** (marketplace + packs + MC's proposals) | Dup §4 | Framework's marketplace + packs workflow; migrate MC's skills/ proposals into packs; bridge install → OpenClaw gateway loading | **Medium** |
| **Deployment** (Docker + LaunchAgent dual-mode) | Dup §13 | Framework's Docker Compose for production; keep MC's LaunchAgent + Vite for dev/single-operator; `install.sh` detects mode | **Medium** |
| **Agent Detail Edit** (`/agents/[id]/edit`) | Feature 1.3 | Framework's edit form; extend with OpenClaw-specific fields | **Low** |

### Priority: P2 (Cosmetic — theme alignment, non-functional)

| Item | Source | Blend Strategy | Effort |
|------|--------|----------------|--------|
| All Tables (Agents, Boards, Gateways, BoardGroups, Tags, CustomFields, Skills, Members, Access) | Feature 2.4 | Framework's table components; restyle to dark theme | **Low per table** |
| All Forms (Gateway, Tag, CustomField, SkillInstall) | Feature 2.5 | Framework's form components; restyle | **Low per form** |
| Templates (DashboardShell, DashboardPageLayout) | Feature 2.1 | Framework's layout components; restyle sidebar, headers | **Low** |
| Atoms (StatusPill, StatusDot) | Feature 2.7 | Restyle to pixel aesthetic | **Low** |
| Auth Components (SignedOutPanel) | Feature 2.8 | Restyle | **Low** |
| Onboarding Page | Feature 1.1 | Framework's flow; restyle to our theme | **Low** |
| Settings, Tags, Custom Fields pages | Feature 1.8 | Framework's pages; restyle | **Low per page** |
| Utility libraries (formatters, utils) | Feature 6.1 | Merge our helpers into theirs | **Low** |
| Formatters, `cn` utility merge | Feature 6.1 | De-duplicate shared utilities | **Low** |

---

## Execution Order Recommendation

```
Phase 0 (Prerequisites) ───── High-Value Adopt P0
    │
    ▼
Phase 1 (Foundation) ──────── Merge/Restyle P0 + Must-Migrate P0
    │                         (Dashboard merge, Task merge, Incident port, Automation port)
    ▼
Phase 2 (Capabilities) ────── High-Value Adopt P1 + Must-Migrate P1
    │                         (Board Groups, Skills Marketplace, Memory port, Health port)
    ▼
Phase 3 (Polish) ──────────── Merge/Restyle P1 + P2 + Must-Migrate P2
                              (Tables, Forms, Templates restyle; archive migration; UI kit)
```

### Phase 0 — Prerequisites
Set up framework's backend (FastAPI + PostgreSQL + Redis), auth, API client, SSE infra.
**No MC code touches this phase** — pure framework bootstrap.

### Phase 1 — Foundation (highest risk, highest value)
Merge the dashboard (metrics + Agent Office), merge task management (kanban + dispatch), port incidents and automation. This is where the two codebases actually fuse.

### Phase 2 — Capabilities
Adopt new framework features (board groups, skills, approvals, orgs) while porting MC's unique systems (memory, health monitoring, Telegram).

### Phase 3 — Polish
Restyle everything to match our dark/pixel theme. Migrate archived data. De-duplicate utilities.

---

## Effort Estimates

| Phase | Items | Estimated Dev Days |
|-------|-------|-------------------|
| Phase 0 | 8 items (all adopt) | 3-5 days |
| Phase 1 | 6 items (4 merge + 4 must-migrate) | 15-25 days |
| Phase 2 | 10+ items (adopt + port) | 10-15 days |
| Phase 3 | 20+ items (restyle + low-effort) | 5-10 days |
| **Total** | **45+ items** | **33-55 days** |

---

## Data Migration Path

| Source | Target | Phase |
|--------|--------|-------|
| `incidents.json` (9260 lines) | Incident + IncidentTimeline models | Phase 1 |
| `tasks-archive.json` (2576 lines) | ArchivedTask model | Phase 2 |
| `data/*.state.json` (15 files) | State models + RQ worker state | Phase 1 |
| `memory/` daily logs (30 files) | MemoryEntry / BoardMemory extensions | Phase 2 |
| `station-memory.db` (FTS5) | Wiki bridge + souls directory | Phase 2 |
| `tasks.json` (Workboard) | Board/Task via API | Phase 1 |
| `wiki/decisions/` markdown | Decision model + API | Phase 2 |
