# SpaceStation Gap Analysis — vs. Old Mission Control

**Date:** 2026-06-22
**Analyst:** Station Architect (subagent)
**Scope:** SpaceStation `spacestation/src/` vs. old Mission Control (`mission-control-dashboard/` + `mc-v2` reference)
**Reference Documents:** `phase5-framework-evaluation.md`, `v2-migration-priority-matrix.md`, `v2-feature-inventory.md`, `v2-developer-guide.md`

---

## Executive Summary

SpaceStation is a **from-scratch Next.js 14 App Router** application that reuses the old MC's data layer (JSON files, SQLite) but has its own UI. It covers the core MC feature set (dashboard, tasks, incidents, memory, cron, activity, sessions, costs, analytics, agents, skills, system monitor) but **misses several high-value features** from mc-v2 that were identified as "Must-Migrate" in the migration matrix. It also introduces **new capabilities** (3D office, weather, file browser, terminal, media browser) that didn't exist before.

**Bottom line:** SpaceStation is ~75% feature-parity with the old MC + mc-v2 combined. The gaps are concentrated in: (1) backend API architecture, (2) incident management, (3) automation/night-shift, (4) approval workflows, (5) webhook integrations, (6) organization/RBAC, (7) skills marketplace. Several gaps are **High** impact and should be addressed before considering SpaceStation "complete."

---

## 1. Features MISSING from SpaceStation (Existed in Old MC / mc-v2)

### 1.1 — Incident Management System
- **Impact:** 🔴 HIGH
- **Old MC:** Full incident lifecycle (P1-P4 severity, auto-dedup, auto-resolve, timeline, linked tasks, runbook, RCA confidence)
- **mc-v2:** Classified as "Must-Migrate P0" — core differentiator
- **SpaceStation:** `/incidents` page exists but is a **thin client** — it renders a list from `/api/incidents` but lacks:
  - Incident creation form (manual or auto-detect)
  - Timeline view with event sequence
  - Auto-dedup logic (duplicate detection)
  - Auto-resolve / RCA confidence scoring
  - Runbook integration
  - P1-P4 severity classification
  - Linked task dispatch from incident
  - Real-time incident SSE stream
- **Recommendation:** **ADD** — Port from old MC's `incidents.json` logic or rebuild on mc-v2's RQ worker pattern. This is a core MC differentiator.

---

### 1.2 — Automation Layer (Night Shift, Review Loop, Heartbeat Manager)
- **Impact:** 🔴 HIGH
- **Old MC:** Night Shift (autonomous overnight feature implementation), Review Loop (AI code review via OpenCode), heartbeat manager (agent health polling), circuit breaker, quota management
- **mc-v2:** Classified as "Must-Migrate P0"
- **SpaceStation:** No equivalent. The `cron` page manages scheduled jobs but there is:
  - No autonomous overnight execution engine
  - No code review loop
  - No agent heartbeat monitoring
  - No circuit breaker for failing agents
  - No quota management
- **Recommendation:** **ADD** — This is the "soul" of Mission Control. Port Night Shift + Review Loop as background workers.

---

### 1.3 — Approval Workflow
- **Impact:** 🟡 MEDIUM
- **mc-v2:** Full approval system — board-level + global approvals, confidence scoring, approve/reject workflow, SSE streams
- **SpaceStation:** No approval system exists. No API routes, no UI.
- **Recommendation:** **ADD** — Port from mc-v2 (`/api/v1/boards/{id}/approvals`, `/api/v1/approvals`). New capability, not in old MC either.

---

### 1.4 — Webhook System
- **Impact:** 🟡 MEDIUM
- **mc-v2:** Full webhook CRUD, payload history, inbound ingestion, typed delivery
- **SpaceStation:** No webhook management. No API routes.
- **Recommendation:** **ADD** — Port from mc-v2. Enables external integrations (GitHub, CI, etc.).

---

### 1.5 — Organization Management & RBAC
- **Impact:** 🟡 MEDIUM
- **mc-v2:** Organizations, members, invites, board access control, role-based access
- **SpaceStation:** No organization concept. Settings page shows system info but no user/role management.
- **Recommendation:** **ADD** — Port from mc-v2. Required for multi-user/team scenarios.

---

### 1.6 — Skills Marketplace
- **Impact:** 🟡 MEDIUM
- **mc-v2:** Marketplace with search, filter, install/uninstall, version picker, skill packs (git sync)
- **SpaceStation:** Skills page exists (`/skills`) but is a **local skill viewer** — reads from filesystem, shows file lists. No marketplace, no install/uninstall, no version management, no git sync.
- **Recommendation:** **ADD** — Layer mc-v2 marketplace API on top of existing local skills. The local skill viewer is a good base; add marketplace search/install on top.

---

### 1.7 — Board Groups
- **Impact:** 🟢 LOW
- **mc-v2:** Group boards together, cross-board snapshots, group memory, group heartbeat
- **SpaceStation:** No board grouping concept.
- **Recommendation:** **ADD** (post-cutover) — Useful for multi-board setups but not blocking.

---

### 1.8 — Custom Fields
- **Impact:** 🟢 LOW
- **mc-v2:** Per-org custom field definitions, typed values, per-board field mapping
- **SpaceStation:** No custom fields. Tasks have fixed schema.
- **Recommendation:** **ADD** (post-cutover) — Nice-to-have for power users.

---

### 1.9 — Tags System
- **Impact:** 🟢 LOW
- **mc-v2:** Org-scoped tags, tag assignments, CRUD
- **SpaceStation:** Tasks have a `tags` string array but no tag management UI/API.
- **Recommendation:** **ADD** — Simple CRUD, low effort.

---

### 1.10 — Task Dependencies
- **Impact:** 🟢 LOW
- **mc-v2:** Task dependency links, dependency validation, visual banners
- **SpaceStation:** No dependency management.
- **Recommendation:** **ADD** — Useful for complex project tracking.

---

### 1.11 — Board Onboarding Wizard
- **Impact:** 🟢 LOW
- **mc-v2:** Chat-based board setup wizard (name, goal, config)
- **SpaceStation:** No onboarding flow.
- **Recommendation:** **KEEP AS-IS** (skip for now) — Low priority, can be added later.

---

### 1.12 — Real-time SSE Streaming
- **Impact:** 🔴 HIGH
- **Old MC:** Polling-based (30s intervals)
- **mc-v2:** SSE streams for tasks, activity, approvals, board memory — real-time updates
- **SpaceStation:** All pages use **client-side polling** (`useEffect` + `setInterval`). No SSE anywhere.
  - Activities page: fetches on mount, no live updates
  - Tasks page: fetches on mount, no live updates
  - Incidents page: fetches on mount, no live updates
- **Recommendation:** **FIX** — Add SSE streaming for at least: activities, tasks, incidents. This is a major UX regression from mc-v2's architecture.

---

### 1.13 — Backend API Architecture
- **Impact:** 🔴 HIGH
- **mc-v2:** 75+ RESTful endpoints, FastAPI + SQLModel + Alembic + PostgreSQL, typed OpenAPI client, auth system
- **SpaceStation:** ~40 Next.js API routes, no database (JSON file-based), no auth, no migrations, no typed client
- **Recommendation:** **FIX** (architectural) — SpaceStation's API routes are thin wrappers over JSON files. This is fine for single-user but won't scale. Consider migrating to mc-v2's backend for production use.

---

### 1.14 — Auth System
- **Impact:** 🟡 MEDIUM
- **mc-v2:** Clerk SSO + local token mode, multi-user, role-based
- **SpaceStation:** `/api/auth/login` and `/api/auth/logout` exist but no middleware protection, no user management, no RBAC
- **Recommendation:** **FIX** — Add auth middleware to protect all API routes. Port mc-v2's dual-mode auth if multi-user is needed.

---

### 1.15 — Agent Office (Animated Pixel Sprites)
- **Impact:** 🟡 MEDIUM
- **Old MC:** Framer Motion animated office with agent sprites, rooms, door animations, station ambience
- **mc-v2:** Classified as "Must-Migrate P1" — port Agent Office visuals
- **SpaceStation:** Has `Office3D/` and `MissionControl/` component directories — **3D office exists** but may not have the same pixel art charm
- **Recommendation:** **FIX** — Review Office3D quality vs. old MC's Agent Office. If it's a downgrade, port the pixel art version.

---

### 1.16 — Decision Records Wiki
- **Impact:** 🟢 LOW
- **Old MC:** Wiki-backed decision records in `wiki/decisions/`
- **mc-v2:** Classified as "Must-Migrate P2"
- **SpaceStation:** Memory page exists but no decision records structure.
- **Recommendation:** **KEEP AS-IS** — Can be added as a section in the Memory page later.

---

### 1.17 — Task Archive
- **Impact:** 🟢 LOW
- **Old MC:** `tasks-archive.json` (2576 lines), dedicated archive UI
- **SpaceStation:** Tasks page has an "Archive" column in the kanban but no dedicated archive view/history.
- **Recommendation:** **FIX** — Add a dedicated archive page with search and restore.

---

### 1.18 — Health Monitoring (Advanced)
- **Impact:** 🟡 MEDIUM
- **Old MC:** Disk alerts, swap usage, prediction checks, auto-heal audit
- **SpaceStation:** System Monitor page exists with CPU/RAM/Disk/Network gauges + service management. **Missing:** predictive alerts, auto-heal, swap monitoring.
- **Recommendation:** **FIX** — Add predictive disk alerts and auto-heal scripts. The base monitoring is solid.

---

### 1.19 — Telegram Delivery
- **Impact:** 🟢 LOW
- **Old MC:** Cron report delivery to Telegram
- **mc-v2:** Classified as "Must-Migrate P1"
- **SpaceStation:** No Telegram integration.
- **Recommendation:** **KEEP AS-IS** — Can be added as a notification channel later. Not blocking.

---

### 1.20 — Memory System (Full)
- **Impact:** 🟡 MEDIUM
- **Old MC:** Daily logs, MEMORY.md, Station Memory SQLite, Wiki bridge, memory suggestions API
- **SpaceStation:** Memory page exists (`/memory`) with search. **Missing:** memory suggestions API, wiki bridge auto-import, daily log auto-capture.
- **Recommendation:** **FIX** — Add memory suggestions endpoint and wiki bridge sync.

---

## 2. Features in SpaceStation that are NEW (Didn't Exist Before)

### 2.1 — 3D Office / Mission Control Visual
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** `Office3D/` component directory with Three.js-based 3D office visualization. `MissionControl/` component set.
- **Assessment:** Ambitious upgrade from old MC's 2D Framer Motion office. Quality depends on execution.
- **Recommendation:** **KEEP AS-IS** — This is a differentiating feature. Polish it.

---

### 2.2 — Weather Widget
- **Impact:** 🟢 LOW (positive)
- **Description:** `/api/weather` route + `WeatherWidget.tsx` component. Shows current conditions.
- **Assessment:** Nice touch for a personal dashboard. Didn't exist in old MC.
- **Recommendation:** **KEEP AS-IS** — Low cost, adds personality.

---

### 2.3 — File Browser
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** Full file browser with `/api/files` (upload, download, mkdir, write, delete, workspaces). `FileBrowser.tsx`, `FileTree.tsx`, `FilePreview.tsx`.
- **Assessment:** Old MC had file management via agent tools but no visual file browser. This is a genuine new capability.
- **Recommendation:** **KEEP AS-IS** — Useful addition.

---

### 2.4 — Web Terminal
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** `/api/terminal` route — server-side terminal access from the browser.
- **Assessment:** Didn't exist in old MC. Powerful for remote management.
- **Recommendation:** **KEEP AS-IS** — Ensure auth is enforced on this endpoint.

---

### 2.5 — Media Browser
- **Impact:** 🟢 LOW (positive)
- **Description:** `/api/media/[...path]` route — serves media files from the workspace.
- **Assessment:** Convenient for viewing downloaded images/videos.
- **Recommendation:** **KEEP AS-IS**

---

### 2.6 — Global Search
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** `GlobalSearch.tsx` component + `/api/search` route. Full-text search across activities, tasks, documents.
- **Assessment:** Old MC had no unified search. This is a significant UX improvement.
- **Recommendation:** **KEEP AS-IS** — Consider expanding to include memory wiki and skills.

---

### 2.7 — Costs & Analytics with Charts
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** Full cost tracking with Recharts (daily trends, by-agent, by-model pie charts, token usage). Budget tracking with projections.
- **Assessment:** Old MC had basic cost display but no charts or budget projections. Significant upgrade.
- **Recommendation:** **KEEP AS-IS** — Well implemented.

---

### 2.8 — Session History with Detail Panel
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** Full session list with filtering (main/cron/subagent/direct), search, token tracking, context usage bars, and a slide-in detail panel with message transcripts.
- **Assessment:** Old MC had session logs but no visual browser with transcripts. Major improvement.
- **Recommendation:** **KEEP AS-IS**

---

### 2.9 — Workflows Page
- **Impact:** 🟡 MEDIUM (positive)
- **Description:** Static page documenting 10 workflows (Social Radar, AI News, Trend Monitor, LinkedIn, Newsletter, Email Triage, Weekly Roundup, Advisory Board, Git Backup, Nightly Evolution).
- **Assessment:** Documentation-only page. The workflows themselves are OpenClaw cron jobs, not SpaceStation features. But the documentation is valuable.
- **Recommendation:** **KEEP AS-IS** — Consider linking to actual cron job configs.

---

### 2.10 — Agent Organigrama
- **Impact:** 🟢 LOW (positive)
- **Description:** `AgentOrganigrama.tsx` — visual hierarchy of agent communication allowances.
- **Assessment:** Didn't exist in old MC. Nice visualization of agent relationships.
- **Recommendation:** **KEEP AS-IS**

---

### 2.11 — Cron Weekly Timeline
- **Impact:** 🟢 LOW (positive)
- **Description:** `CronWeeklyTimeline.tsx` — visual weekly view of cron job schedules.
- **Assessment:** Old MC had a cron list but no timeline view.
- **Recommendation:** **KEEP AS-IS**

---

### 2.12 — Notepad
- **Impact:** 🟢 LOW (positive)
- **Description:** `Notepad.tsx` — quick scratchpad in the dashboard.
- **Assessment:** Simple but useful. Didn't exist in old MC.
- **Recommendation:** **KEEP AS-IS**

---

### 2.13 — Browse Page
- **Impact:** 🟢 LOW (positive)
- **Description:** `/browse` route — seems to be a simple web browsing interface.
- **Assessment:** New capability.
- **Recommendation:** **KEEP AS-IS**

---

## 3. Features WORSE Than Old MC

### 3.1 — No Real-time Updates (SSE → Polling)
- **Impact:** 🔴 HIGH
- **Old MC:** Polling (acceptable)
- **mc-v2:** SSE streaming (superior)
- **SpaceStation:** Polling with no live updates — **same as old MC, regression from mc-v2**
- **Recommendation:** **FIX** — Implement SSE for activities, tasks, incidents.

---

### 3.2 — No Incident Management Depth
- **Impact:** 🔴 HIGH
- **Old MC:** Full incident lifecycle with auto-dedup, timeline, RCA
- **SpaceStation:** Basic list view only
- **Recommendation:** **FIX** — Port full incident system.

---

### 3.3 — No Automation Engine
- **Impact:** 🔴 HIGH
- **Old MC:** Night Shift, Review Loop, heartbeat manager
- **SpaceStation:** None
- **Recommendation:** **FIX** — Port automation layer.

---

### 3.4 — No Auth / RBAC
- **Impact:** 🟡 MEDIUM
- **Old MC:** No auth (single-user, acceptable)
- **mc-v2:** Full auth system
- **SpaceStation:** Login/logout endpoints exist but no route protection
- **Recommendation:** **FIX** — Add middleware protection.

---

### 3.5 — Skills Page is Local-Only
- **Impact:** 🟡 MEDIUM
- **Old MC:** Skills page with file viewer (same)
- **mc-v2:** Full marketplace with install/uninstall
- **SpaceStation:** Same as old MC — no marketplace layer
- **Recommendation:** **FIX** — Add marketplace capabilities.

---

### 3.6 — No Predictive Health Alerts
- **Impact:** 🟡 MEDIUM
- **Old MC:** Disk alerts, swap monitoring, auto-heal
- **SpaceStation:** Basic gauges only
- **Recommendation:** **FIX** — Add predictive alerts.

---

### 3.7 — Memory System Less Structured
- **Impact:** 🟡 MEDIUM
- **Old MC:** Daily logs + MEMORY.md + Station Memory + Wiki bridge
- **SpaceStation:** Search page only, no auto-capture, no wiki bridge
- **Recommendation:** **FIX** — Add memory suggestions and wiki bridge.

---

## 4. Features BETTER Than Old MC

### 4.1 — Modern Stack (Next.js 14 + React 19)
- **Impact:** 🔴 HIGH
- **Old MC:** Next.js 12 + React 18 + Pages Router
- **SpaceStation:** Next.js 14 App Router + React 19 + TypeScript strict
- **Recommendation:** **KEEP AS-IS** — This is the foundation. Don't regress.

---

### 4.2 — Dashboard with Real Charts
- **Impact:** 🟡 MEDIUM
- **Old MC:** Basic metrics cards
- **SpaceStation:** Recharts-powered analytics with line charts, bar charts, pie charts, heatmaps
- **Recommendation:** **KEEP AS-IS**

---

### 4.3 — Session Browser with Transcripts
- **Impact:** 🟡 MEDIUM
- **Old MC:** JSON log files
- **SpaceStation:** Visual session list with filter, search, and slide-in transcript panel
- **Recommendation:** **KEEP AS-IS**

---

### 4.4 — 3D Office Visualization
- **Impact:** 🟡 MEDIUM
- **Old MC:** 2D Framer Motion sprites
- **SpaceStation:** Three.js 3D office
- **Recommendation:** **KEEP AS-IS** (if quality is good)

---

### 4.5 — File Browser
- **Impact:** 🟡 MEDIUM
- **Old MC:** No visual file browser
- **SpaceStation:** Full file tree, upload, download, mkdir, write, delete
- **Recommendation:** **KEEP AS-IS**

---

### 4.6 — Web Terminal
- **Impact:** 🟡 MEDIUM
- **Old MC:** No terminal in browser
- **SpaceStation:** `/api/terminal` for browser-based terminal access
- **Recommendation:** **KEEP AS-IS** (ensure auth!)

---

### 4.7 — Global Search
- **Impact:** 🟡 MEDIUM
- **Old MC:** No unified search
- **SpaceStation:** Full-text search across activities, tasks, documents
- **Recommendation:** **KEEP AS-IS**

---

### 4.8 — Costs Dashboard
- **Impact:** 🟡 MEDIUM
- **Old MC:** Basic cost display
- **SpaceStation:** Full cost analytics with budget tracking, projections, model pricing table
- **Recommendation:** **KEEP AS-IS**

---

### 4.9 — System Monitor with Service Management
- **Impact:** 🟡 MEDIUM
- **Old MC:** Basic health check
- **SpaceStation:** CPU/RAM/Disk/Network gauges, service table with restart/stop/logs, Tailscale VPN, firewall rules
- **Recommendation:** **KEEP AS-IS**

---

### 4.10 — Component Architecture
- **Impact:** 🟡 MEDIUM
- **Old MC:** Flat components in `src/components/`
- **SpaceStation:** Organized components with `charts/`, `office/`, `MissionControl/`, `TenacitOS/` subdirectories
- **Recommendation:** **KEEP AS-IS**

---

## 5. Priority Summary

### 🔴 HIGH — Must Fix Before "Complete"

| # | Gap | Recommendation | Effort |
|---|-----|---------------|--------|
| 1 | No real-time SSE streaming | **FIX** — Add SSE for activities, tasks, incidents | Medium |
| 2 | No incident management depth | **ADD** — Port full incident lifecycle | High |
| 3 | No automation engine | **ADD** — Port Night Shift + Review Loop | High |
| 4 | No auth / RBAC | **FIX** — Add middleware protection | Medium |
| 5 | Backend API architecture | **FIX** — Migrate from JSON files to proper DB | High |

### 🟡 MEDIUM — Should Fix

| # | Gap | Recommendation | Effort |
|---|-----|---------------|--------|
| 6 | No approval workflow | **ADD** — Port from mc-v2 | Medium |
| 7 | No webhook system | **ADD** — Port from mc-v2 | Medium |
| 8 | No organization management | **ADD** — Port from mc-v2 | Medium |
| 9 | Skills marketplace | **ADD** — Layer on top of existing local skills | Medium |
| 10 | No predictive health alerts | **FIX** — Add disk alerts + auto-heal | Low |
| 11 | Memory system incomplete | **FIX** — Add suggestions + wiki bridge | Medium |
| 12 | Agent Office quality | **FIX** — Review vs. old MC pixel art | Low |

### 🟢 LOW — Can Add Post-Cutover

| # | Gap | Recommendation | Effort |
|---|-----|---------------|--------|
| 13 | Board groups | **ADD** | Medium |
| 14 | Custom fields | **ADD** | Low |
| 15 | Tags system | **ADD** | Low |
| 16 | Task dependencies | **ADD** | Low |
| 17 | Task archive view | **FIX** | Low |
| 18 | Decision records wiki | **ADD** | Low |
| 19 | Telegram delivery | **ADD** | Low |
| 20 | Board onboarding wizard | **KEEP AS-IS** | — |

---

## 6. New Features to Protect

These are SpaceStation innovations that should NOT be lost:

| Feature | Recommendation |
|---------|---------------|
| 3D Office / Mission Control visual | **KEEP AS-IS** — Polish it |
| Weather Widget | **KEEP AS-IS** |
| File Browser | **KEEP AS-IS** |
| Web Terminal | **KEEP AS-IS** — Add auth |
| Media Browser | **KEEP AS-IS** |
| Global Search | **KEEP AS-IS** — Expand scope |
| Costs Dashboard with Charts | **KEEP AS-IS** |
| Session History with Transcripts | **KEEP AS-IS** |
| Agent Organigrama | **KEEP AS-IS** |
| Cron Weekly Timeline | **KEEP AS-IS** |
| Notepad | **KEEP AS-IS** |
| Browse Page | **KEEP AS-IS** |

---

## 7. Overall Assessment

| Dimension | Old MC | SpaceStation | Delta |
|-----------|--------|-------------|-------|
| **Core Dashboard** | ✅ | ✅ | = |
| **Task Management** | ✅ | ✅ | = (kanban is good) |
| **Incidents** | ✅✅ | ⚠️ | **Regression** |
| **Automation** | ✅✅ | ❌ | **Missing** |
| **Memory** | ✅✅ | ⚠️ | **Regression** |
| **Cron** | ✅ | ✅ | = |
| **Activity** | ✅ | ✅ | = |
| **Sessions** | ✅ | ✅✅ | **Better** |
| **Costs** | ⚠️ | ✅✅ | **Better** |
| **Analytics** | ⚠️ | ✅✅ | **Better** |
| **System Monitor** | ⚠️ | ✅✅ | **Better** |
| **Agents** | ✅ | ✅ | = |
| **Skills** | ⚠️ | ⚠️ | = (both lack marketplace) |
| **Approvals** | ❌ | ❌ | = (neither had it) |
| **Webhooks** | ❌ | ❌ | = (neither had it) |
| **Auth/RBAC** | ❌ | ⚠️ | **Slight regression** |
| **Real-time** | ⚠️ | ⚠️ | = (both poll) |
| **File Browser** | ❌ | ✅✅ | **New** |
| **Terminal** | ❌ | ✅✅ | **New** |
| **3D Office** | ❌ | ✅ | **New** |
| **Global Search** | ❌ | ✅✅ | **New** |
| **Weather** | ❌ | ✅ | **New** |

**Score:** SpaceStation covers ~75% of the combined old MC + mc-v2 feature set. The missing 25% is mostly high-value features that were identified as "Must-Migrate" in the migration matrix. The new features (3D office, file browser, terminal, global search, costs dashboard) are genuine improvements.

**Verdict:** SpaceStation is a solid foundation with better UX than old MC in many areas, but it's not yet a full replacement. The 5 High-priority gaps (incidents, automation, SSE, auth, backend) need to be addressed before it can be considered "Mission Control v2."
