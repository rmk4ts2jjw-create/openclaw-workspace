# Framework vs MC — Duplicate Feature Analysis

**Date:** 2026-06-20
**Sources:**
- Framework candidate: `data/audits/phase5-framework-evaluation.md` + `data/audits/v2-feature-inventory.md`
- MC current: `data/audits/api-endpoints.md`, source exploration, `data/*.json` schemas

---

## Classification Key

| Label | Meaning |
|-------|---------|
| **USE THEIRS** | Framework version is superior — adopt it, drop ours |
| **USE OURS** | Our version is better — keep ours, skip framework's |
| **MERGE BOTH** | Both have value — combine the best of each |

---

## Overlaps by Feature Domain

### 1. Task Management

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Board UI** | Kanban board with drag-and-drop, columns (Inbox, In Progress, Review, Done) | Tabular/text-based task stream, polling every 5s |
| **Task CRUD** | Full REST API: create, read, update, delete, comments, dependencies | JSON-file-backed with `POST /api/save-tasks` (merge-based), `POST /api/tasks/add` |
| **Real-time** | SSE stream (`/tasks/stream`) | Polling only |
| **Status workflow** | Inbox → In Progress → Review → Done | Triage → Backlog → In Progress → Done |
| **Dispatch** | Agent assignment only | `POST /api/dispatch` — spawns OpenClaw sub-agents |
| **Archive** | No explicit archive | `tasks-archive.json` (2576 lines) |
| **Deduplication** | TaskFingerprint model | Duplicate detection in `POST /api/tasks/add` |

**Verdict: MERGE BOTH**

- **Use framework's** kanban board UI, SSE streaming, task CRUD API, comments, dependencies
- **Keep MC's** task dispatch workflow (triage→backlog→in_progress→done fits OpenClaw), archive system, dedup logic
- **Migrate** `tasks.json`/`tasks-archive.json` → PostgreSQL Task model

---

### 2. Agent Management

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Agent CRUD** | Full: create, read, update, delete, health, activity events, heartbeat endpoint, nudge, command | None via API — agents are OpenClaw sub-processes |
| **Agent model** | Name, emoji, heartbeat config, identity profile, board assignment | OpenClaw agent metadata in Workboard |
| **Monitoring** | Agent detail page with health/activity/events table | `useAgentStatus` polling every 10s, `useAgentNetwork` every 15s |
| **Agent Office** | None | Animated pixel art office with sprites, rooms, door animations |
| **Sub-agent spawn** | None | Core feature — `dispatch` creates OpenClaw sub-agent tasks |

**Verdict: MERGE BOTH**

- **Use framework's** agent CRUD API, model, health monitoring, heartbeat endpoint
- **Use MC's** sub-agent spawn logic (framework has no equivalent), Agent Office visual
- **Extend framework** Agent model with OpenClaw-specific fields (dispatchCount, currentStep, stalledAt)

---

### 3. Gateway Management

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Gateway CRUD** | Full: create, read, update, delete, connection testing, device pairing, template sync, soul sync | None — MC IS a gateway, doesn't manage others |
| **Gateway model** | URL, token, workspace root, TLS, sessions | OpenClaw gateway config in `openclaw.json` |

**Verdict: USE THEIRS**

- Framework treats MC as a managed gateway. Adopt framework's gateway management to self-manage MC.
- Keep `openclaw.json` as the source of truth for MC's own config; framework can read/write it.

---

### 4. Skills System

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Marketplace** | Skills marketplace with search, filter, sort, install/uninstall, version picker | None |
| **Skill packs** | Git-based skill packs, sync from git, delete, sync all | `skills/` directory with SKILL.md proposals |
| **Lifecycle** | Gateway-installed skills, marketplace skills, packs | `skill-lifecycle-backlog.md` — manual proposals |
| **Installation** | POST `/api/v1/skills/marketplace/{id}/install` → gateway | OpenClaw native skill loading |

**Verdict: MERGE BOTH**

- **Use framework's** marketplace, packs, install workflow — structured and productized
- **Migrate MC's** `skills/` proposals into framework's skill packs
- **Bridge** framework's skill install → OpenClaw gateway skill loading

---

### 5. Memory System

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Board memory** | `BoardMemory` + `BoardGroupMemory` models with SSE stream, chat | None per-board |
| **Daily logs** | None | `memory/YYYY-MM-DD.md` — 30 files |
| **Long-term memory** | None | `MEMORY.md` — curated wisdom |
| **Station Memory** | None | SQLite DB with FTS5, `station-memory-tool.cjs`, memory suggestions API |
| **Wiki bridge** | None | OpenClaw wiki vault at `~/.openclaw/wiki/main` |
| **Memory suggestions** | None | `GET /api/station-memory/suggest` — generates from completed items |

**Verdict: USE OURS**

- Framework's board memory is useful for per-board chat/context during collaboration
- **BUT** MC's multi-layer memory system (daily logs → MEMORY.md → Station Memory → Wiki) is the real value
- Recommend: keep framework's board memory for real-time chat; mount MC's memory layers alongside it as additional APIs

---

### 6. Activity / Event Log

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Model** | `ActivityEvent` with SSE streaming, filtering, search | Event log polled every 5s from `GET /api/events` |
| **SSE** | `/activity/stream`, `/activity/task-comments/stream` | None — polling |
| **UI** | ActivityFeed component with live updates | `RecentEventsPanel`, `EventLog` in sidebar |

**Verdict: USE THEIRS**

- Framework's SSE-based activity system is superior to polling
- Replace MC's `GET /api/events` polling with framework's SSE stream
- Keep our visual treatment of events (speech bubbles, agent flash) — restyle their ActivityFeed

---

### 7. Approvals

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Workflow** | Per-task approval with confidence scoring, SSE stream | None |
| **UI** | Board approvals panel, global approvals dashboard | None |

**Verdict: USE THEIRS**

- New capability for MC — adopt framework's approval workflow as-is
- Extend if needed with MC-specific automation triggers

---

### 8. Auth & Multi-tenancy

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Auth** | Clerk SSO + local token, role-based access | No auth (single-operator) |
| **Organizations** | Full: orgs, members, invites, board access control, RBAC | None — single-user |
| **User management** | User profiles, org membership, role assignment | None |

**Verdict: USE THEIRS**

- Auth and multi-tenancy are prerequisites for team use
- For single-operator mode, local token auth is sufficient — Clerk can be optional
- Adopt framework's org model even in single-tenant mode

---

### 9. Real-time Infrastructure

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Transport** | SSE streams for tasks, approvals, chat, memory, activity | Polling (5s, 10s, 15s) |
| **Backend** | Redis-backed SSE via FastAPI StreamingResponse | Vite dev server, polled JSON endpoints |

**Verdict: USE THEIRS**

- SSE is objectively better than polling for real-time features
- Trade-off: adds Redis dependency (MC currently has zero infrastructure)
- For single-operator mode, could fall back to polling; for production use SSE

---

### 10. API Architecture

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Spec** | Full OpenAPI 3.0 spec with auto-generated TypeScript client (Orval) | Ad-hoc fetch calls |
| **Typing** | Every endpoint typed, generated client | Manual fetch with loose typing |
| **Documentation** | Swagger UI `/docs`, OpenAPI spec | None |

**Verdict: USE THEIRS**

- No contest. Adopt framework's OpenAPI design and Orval client generation.
- MC's 14 server.ts endpoints → ported to framework's FastAPI backend.

---

### 11. Database

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Engine** | PostgreSQL (SQLite for dev) | SQLite + 34 JSON files |
| **Migrations** | Alembic with versioned migrations | None |
| **ORM** | Async SQLAlchemy + SQLModel | Raw file reads/writes |
| **Multi-tenancy** | All models tenant-scoped via `TenancyBase` mixin | None |
| **Backups** | Standard PostgreSQL backup | Manual `.bak` copies of JSON files |

**Verdict: USE THEIRS**

- No contest. Framework's database architecture is industry standard.
- All 34 JSON data files → migrate to PostgreSQL models.
- `tasks-archive.json` (2576 lines), `incidents.json` (9260 lines) are top priorities.

---

### 12. Testing Infrastructure

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Unit tests** | Vitest (frontend) + pytest (backend) | Zero |
| **E2E** | Cypress | Zero |
| **CI/CD** | GitHub Actions pipeline | None |

**Verdict: USE THEIRS**

- No contest. Framework has a full testing pyramid. Adopt everything.

---

### 13. Deployment

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Mode** | Docker Compose (5 services) + systemd + install.sh | macOS LaunchAgent + Vite dev server |
| **Portability** | Linux/macOS via Docker | macOS-only |
| **Dependencies** | PostgreSQL + Redis + RQ worker | Zero — single Vite process |
| **Simplicity** | Complex but correct | Trivially simple |

**Verdict: MERGE BOTH**

- **Adopt framework's** Docker Compose for production/team deployments
- **Keep MC's** LaunchAgent + Vite mode for single-operator/simpler setups
- Framework's `install.sh` should detect and support both modes

---

### 14. UI Component System

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Architecture** | Atoms → Molecules → Organisms → Templates hierarchy | Flat components + shadcn/ui |
| **Kit** | shadcn-style UI (button, input, select, dialog, badge) | Custom shadcn/ui components with theme |
| **Theme** | Light theme (togglable), corporate | Dark theme, pixel art, Framer Motion, personality |
| **Custom** | Generic, professional | Agent Office, pixel sprites, starfield, door animations |

**Verdict: USE OURS**

- MC's theme and personality are deliberate and distinctive
- Use framework's component hierarchy as organizational pattern
- But REPLACE all UI kit components with MC's themed versions
- Embed Agent Office as a custom organism in the framework layout

---

### 15. Webhooks

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Webhooks** | Board webhooks CRUD, payload history, ingestion API | None |

**Verdict: USE THEIRS**

- New capability. Adopt framework's webhook system as-is.

---

### 16. Custom Fields

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Custom fields** | Per-org definitions, per-board mapping, typed values | None — ad-hoc in JSON |

**Verdict: USE THEIRS**

- New capability. Framework's custom field system replaces MC's ad-hoc JSON fields.

---

### 17. Tags

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Tags** | CRUD, task-tag assignments, org-scoped | Used implicitly in tasks.json/Workboard, no structured system |

**Verdict: USE THEIRS**

- Framework's tag system is structured. Migrate existing tags into it.

---

### 18. Incident Management

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Incidents** | None | P1-P4 tracking, timeline arrays, auto-dedup, auto-resolve, linked tasks, runbook integration |
| **Prediction** | None | `prediction-state.json` — time-series checks (mount_missing, etc.) |
| **Auto-heal** | None | `auto-heal-state.json` — 28/28 successes, dry-run audit trail |
| **Alerts** | None | `alerts.json` — disk at 83%, swap usage |

**Verdict: USE OURS**

- Framework has no incident system. This is MC's core operational feature.
- **Extend framework** with Incident model, auto-dedup logic, prediction state, auto-heal
- All incident endpoints (`/api/incidents/update`, `/api/incidents/timeline`, etc.) → new FastAPI endpoints
- Migrate `incidents.json` (9260 lines) → PostgreSQL Incident model

---

### 19. Night Shift / Automation

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Night Shift** | None | Autonomous overnight processing, `night-shift-state.json`, archive |
| **Review Loop** | None | AI code review via OpenCode |
| **Heartbeat** | Agent heartbeat endpoint | Full heartbeat state manager with email/calendar/weather/stall/circuit/memory/git checks |
| **Cron** | None | Cron management: enable/disable/toggle, `cron-errors.json` tracking |
| **Quota** | None | API quota budget tracking |
| **Circuit breaker** | Rate limiter only | Error tracking per operation, circuit state |

**Verdict: USE OURS**

- Framework has zero automation. MC's automation layer is a competitive advantage.
- Port all automation to framework's backend as RQ workers and new API endpoints.
- Night Shift, Review Loop, heartbeat, cron management, circuit breaker — all unique.

---

### 20. OpenClaw Integration

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Integration** | Manages external gateways (OpenClaw-compatible) via RPC | IS an OpenClaw gateway — deeply integrated |
| **Config** | Gateway model (URL, token, etc.) | `openclaw.json` — full gateway identity |
| **Task dispatch** | Agent assignment only | Sub-process spawn via OpenClaw CLI |

**Verdict: USE OURS**

- This is MC's #1 unique value. Framework treats OpenClaw as external; MC runs OpenClaw.
- Framework's Gateway model can reference MC itself. MC's OpenClaw integrations stay.
- Extend framework's GatewayDispatchService to include local process spawn.

---

### 21. Health Monitoring

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Health** | `/health`, `/healthz`, `/readyz` | Agent health + disk alerts + gateway health |
| **Metrics** | Dashboard KPIs (throughput, WIP, pending approvals) | No formal metrics dashboard |
| **Monitoring** | Basic | Disk at 83%, swap usage, 28/28 auto-heal, prediction checks |

**Verdict: MERGE BOTH**

- **Use framework's** health endpoints and metrics API as the data layer
- **Use MC's** disk monitoring, swap alerts, auto-heal, prediction checks as additional metrics
- Combine: framework's metrics endpoint → MC's monitoring data sources

---

### 22. Deployment & Operations

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Startup** | `docker compose up` or `install.sh` + systemd | LaunchAgent + `start-mc.sh` |
| **State** | Managed in PostgreSQL | JSON files, SQLite |
| **Backups** | `BACKUP_GUIDE.md` — pg_dump | `BACKUP_GUIDE.md` — file copies |
| **Recovery** | `RECOVERY_GUIDE.md` — Docker rebuild | `RECOVERY_GUIDE.md` — file restore |

**Verdict: MERGE BOTH**

- Framework's Docker deployment is more robust for production
- Keep MC's LaunchAgent mode for development/single-operator
- Both have backup guides — unify into a single operations doc

---

### 23. Telegram Delivery

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Telegram** | None | Cron report delivery to Telegram |

**Verdict: USE OURS**

- MC's Telegram integration is unique. Add as a framework service.

---

### 24. Audit Trail / Decisions

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Activity** | ActivityEvent model with SSE | Recent events in sidebar |
| **Decisions** | None | `wiki/decisions/` — markdown-backed decision records |
| **Audit** | Event-based audit trail | No structured audit beyond events + decisions wiki |

**Verdict: MERGE BOTH**

- **Use framework's** `ActivityEvent` as the structured audit trail
- **Keep MC's** decisions wiki for human-readable, long-term decisions
- Link decisions to activity events via IDs

---

### 25. Documentation

| Aspect | Framework | Our MC |
|--------|-----------|--------|
| **Structured docs** | 19 files: arch, deployment, dev, ops, API refs, policy | Root-level READMEs, AGENTS.md, SOURCES.md, etc. |
| **API docs** | Swagger UI + OpenAPI spec | None |
| **Dev guides** | Contributing, development setup | `RECOVERY_GUIDE.md`, `BACKUP_GUIDE.md` |

**Verdict: USE THEIRS**

- Move to framework's documentation structure
- Keep MC-specific docs (AGENTS.md, SOURCES.md, HEARTBEAT.md) as supplementary
- Document ported MC features in framework's docs/

---

## Summary

### By Verdict

| Verdict | Count | Feature Areas |
|---------|-------|---------------|
| **USE THEIRS** | 11 | Auth & Multi-tenancy, Gateway Management, Real-time, API Architecture, Database, Testing, Activity/Events, Approvals, Webhooks, Custom Fields, Tags, Documentation |
| **USE OURS** | 6 | Memory System, UI Components/Theme, Incident Management, Automation, OpenClaw Integration, Telegram |
| **MERGE BOTH** | 8 | Task Management, Agent Management, Skills, Deployment, Health Monitoring, Operations, Audit Trail, Task Status Workflow |

### Key Takeaways

1. **Backend architecture** (API, DB, auth, real-time, testing) → all USE THEIRS. No contest.
2. **Core MC differentiators** (incidents, automation, OpenClaw, memory, Telegram) → all USE OURS. These must be ported.
3. **Task/agent/skills** → MERGE. Framework has the structured models; MC has the unique workflows.
4. **UI** → USE OURS. MC's theme and character are intentional and should not be sacrificed.

### Data Migration Priority

| Source | Target | Effort |
|--------|--------|--------|
| `incidents.json` (9260 lines) | Incident model | High |
| `tasks-archive.json` (2576 lines) | Archived Task model | Medium |
| `tasks.json` (0 bytes — Workboard) | Board/Task model via API | Medium |
| `data/*.state.json` files (15 files) | State models + RQ worker state | Medium |
| `memory/` daily logs | BoardMemory extensions | Low |
| `station-memory.db` → Wiki bridge | Souls directory? | Low |
