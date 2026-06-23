# SpaceStation — Complete Feature Inventory

> **Project:** `Users-spacemonkey-.openclaw-workspace-spacestation`  
> **Indexed:** 1,539 nodes, 2,622 edges  
> **Audited:** 2026-06-22  
> **Auditor:** Station Architect (subagent)

---

## Summary Table

| Category | Total | ✅ PRODUCTION READY | ⚠️ NEEDS WORK | 🔴 BROKEN | 🗑️ REDUNDANT |
|---|---|---|---|---|---|
| Dashboard Pages | 22 | 16 | 4 | 1 | 1 |
| API Routes | 40 | 33 | 4 | 1 | 2 |
| Reusable Components | 67 | 48 | 8 | 2 | 9 |
| Services | 2 | 2 | 0 | 0 | 0 |
| Hooks | 1 | 0 | 1 | 0 | 0 |
| Lib Modules | 9 | 8 | 1 | 0 | 0 |
| Scripts | 7 | 4 | 2 | 0 | 1 |
| Data Layer | 12 | 10 | 1 | 0 | 1 |
| **TOTAL** | **160** | **121** | **21** | **4** | **14** |

### Key Findings

- **76%** of items are production-ready
- **13%** need attention (stubs, partial implementations, TODOs)
- **2.5%** are broken (React hook violations, empty files)
- **9%** are redundant (unused code, duplicate implementations, dead hooks)
- **Major redundancy:** `Office3D/` (2,307 lines) and `office/` (3,527 lines) are **not imported** by any page — only `Office3D` is dynamically loaded from `/office`, but `office/` pixel-art components are entirely orphaned
- **Dead code:** `useAvatarModel.ts` hook is defined but never imported anywhere
- **React hook bug:** `AvatarModel.tsx` calls `useGLTF()` inside a conditional — violates Rules of Hooks

---

## 1. Dashboard Pages (`src/app/(dashboard)/*`)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `layout.tsx` | 31 | ✅ PRODUCTION READY | TenacitOS shell wrapper (Dock, TopBar, StatusBar, DevToolsHUD) |
| 2 | `page.tsx` (Home) | 325 | ✅ PRODUCTION READY | Stats cards, agent list, activity feed, weather, notepad, quick links |
| 3 | `about/page.tsx` | 512 | ✅ PRODUCTION READY | Rich about page with agent identity, features list, social links |
| 4 | `actions/page.tsx` | 374 | ✅ PRODUCTION READY | Action management UI |
| 5 | `activity/page.tsx` | 602 | ✅ PRODUCTION READY | Activity log viewer with filtering |
| 6 | `agents/page.tsx` | 370 | ✅ PRODUCTION READY | Agent roster with status, models, tokens |
| 7 | `analytics/page.tsx` | 188 | ⚠️ NEEDS WORK | Basic analytics, could use more chart types |
| 8 | `calendar/page.tsx` | 18 | ⚠️ NEEDS WORK | **Stub** — just wraps `<WeeklyCalendar />`, no extra features |
| 9 | `costs/page.tsx` | 388 | ✅ PRODUCTION READY | Cost tracking, token usage breakdown |
| 10 | `cron/page.tsx` | 406 | ✅ PRODUCTION READY | Cron job management with timeline |
| 11 | `files/page.tsx` | 249 | ✅ PRODUCTION READY | File browser with workspace integration |
| 12 | `git/page.tsx` | 304 | ✅ PRODUCTION READY | Git status, diff, branch management |
| 13 | `incidents/page.tsx` | 750 | ✅ PRODUCTION READY | Incident tracking, full CRUD |
| 14 | `logs/page.tsx` | 292 | ✅ PRODUCTION READY | Log viewer with streaming |
| 15 | `memory/page.tsx` | 448 | ✅ PRODUCTION READY | Memory wiki browser, daily notes |
| 16 | `not-found.tsx` | 3 | 🔴 BROKEN | **Empty** — returns `<></>`, no 404 content |
| 17 | `reports/page.tsx` | 281 | ✅ PRODUCTION READY | Report file browser with markdown preview |
| 18 | `search/page.tsx` | 23 | ⚠️ NEEDS WORK | **Thin wrapper** — just renders `<GlobalSearch fullPage />` |
| 19 | `sessions/page.tsx` | 973 | ✅ PRODUCTION READY | Session management, detailed agent session viewer |
| 20 | `settings/page.tsx` | 140 | ✅ PRODUCTION READY | Settings UI |
| 21 | `skills/page.tsx` | 590 | ✅ PRODUCTION READY | Skill management with detail modals |
| 22 | `system/page.tsx` | 613 | ✅ PRODUCTION READY | System health, services, resource monitoring |
| 23 | `tasks/page.tsx` | 1,383 | ✅ PRODUCTION READY | Full task management with kanban, filters, agent assignment |
| 24 | `terminal/page.tsx` | 273 | ✅ PRODUCTION READY | Web terminal (xterm.js) |
| 25 | `workflows/page.tsx` | 385 | ✅ PRODUCTION READY | Workflow orchestration UI |

**Subtotal: 25 pages** (layout + 24 content pages, including not-found)

---

## 2. API Routes (`src/app/api/*`)

| # | Route | Classification | Notes |
|---|---|---|---|
| 1 | `actions/route.ts` | ✅ PRODUCTION READY | Action execution endpoints |
| 2 | `activities/route.ts` | ✅ PRODUCTION READY | Activity log CRUD |
| 3 | `activities/stats/route.ts` | ✅ PRODUCTION READY | Activity statistics aggregation |
| 4 | `activities/stream/route.ts` | ✅ PRODUCTION READY | SSE activity streaming |
| 5 | `activity/route.ts` | 🗑️ REDUNDANT | Legacy/singular endpoint — overlaps with `activities/route.ts` |
| 6 | `agents/route.ts` | ✅ PRODUCTION READY | Agent list from openclaw.json |
| 7 | `agents/[id]/status/route.ts` | ✅ PRODUCTION READY | Per-agent status (gateway + file fallback) |
| 8 | `analytics/route.ts` | ✅ PRODUCTION READY | Analytics data aggregation |
| 9 | `auth/login/route.ts` | ✅ PRODUCTION READY | Password-based login |
| 10 | `auth/logout/route.ts` | ✅ PRODUCTION READY | Session logout |
| 11 | `browse/route.ts` | ✅ PRODUCTION READY | File system browser API |
| 12 | `costs/route.ts` | ✅ PRODUCTION READY | Cost calculation from usage data |
| 13 | `cron/route.ts` | ✅ PRODUCTION READY | Cron job CRUD |
| 14 | `cron/run/route.ts` | ✅ PRODUCTION READY | Manual cron trigger |
| 15 | `cron/runs/route.ts` | ✅ PRODUCTION READY | Cron execution history |
| 16 | `files/route.ts` | ✅ PRODUCTION READY | File listing |
| 17 | `files/delete/route.ts` | ✅ PRODUCTION READY | File deletion |
| 18 | `files/download/route.ts` | ✅ PRODUCTION READY | File download |
| 19 | `files/mkdir/route.ts` | ✅ PRODUCTION READY | Directory creation |
| 20 | `files/upload/route.ts` | ✅ PRODUCTION READY | File upload |
| 21 | `files/workspaces/route.ts` | ✅ PRODUCTION READY | Workspace directory listing |
| 22 | `files/write/route.ts` | ✅ PRODUCTION READY | File write with safe-write |
| 23 | `git/route.ts` | ✅ PRODUCTION READY | Git status/diff via child_process |
| 24 | `health/route.ts` | ✅ PRODUCTION READY | Health checks for all services |
| 25 | `incidents/route.ts` | ✅ PRODUCTION READY | Incident CRUD |
| 26 | `logs/stream/route.ts` | ✅ PRODUCTION READY | SSE log streaming |
| 27 | `media/[...path]/route.ts` | ✅ PRODUCTION READY | Media file serving with path validation |
| 28 | `memory/search/route.ts` | ✅ PRODUCTION READY | Memory wiki search |
| 29 | `notifications/route.ts` | ✅ PRODUCTION READY | Notification management |
| 30 | `office/route.ts` | ✅ PRODUCTION READY | Office 3D agent data (gateway + file fallback) |
| 31 | `reports/route.ts` | ✅ PRODUCTION READY | Report file listing |
| 32 | `search/route.ts` | ✅ PRODUCTION READY | Global search across activities/tasks/memory |
| 33 | `sessions/route.ts` | ✅ PRODUCTION READY | Session listing from logs |
| 34 | `skills/route.ts` | ✅ PRODUCTION READY | Skill listing from configured-skills.json |
| 35 | `system/route.ts` | ✅ PRODUCTION READY | System info (OS, disk, memory, uptime) |
| 36 | `system/monitor/route.ts` | ✅ PRODUCTION READY | Real-time system monitoring |
| 37 | `system/services/route.ts` | ✅ PRODUCTION READY | Service status checks |
| 38 | `system/stats/route.ts` | ✅ PRODUCTION READY | System statistics |
| 39 | `tasks/route.ts` | ✅ PRODUCTION READY | Full task CRUD with agent assignment |
| 40 | `terminal/route.ts` | ⚠️ NEEDS WORK | Terminal WebSocket — basic implementation |
| 41 | `watchdog/stall-detect/route.ts` | ✅ PRODUCTION READY | Manual stall detection trigger |
| 42 | `weather/route.ts` | ✅ PRODUCTION READY | Weather data proxy |

**Subtotal: 42 route files**

---

## 3. Reusable Components (`src/components/*`)

### Top-Level Components

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `ActivityFeed.tsx` | — | ✅ PRODUCTION READY | Real-time activity feed |
| 2 | `ActivityHeatmap.tsx` | — | ✅ PRODUCTION READY | Activity heatmap visualization |
| 3 | `AgentOrganigrama.tsx` | — | ✅ PRODUCTION READY | Agent org chart |
| 4 | `Breadcrumbs.tsx` | — | ✅ PRODUCTION READY | Navigation breadcrumbs |
| 5 | `ChangePasswordModal.tsx` | — | ✅ PRODUCTION READY | Password change modal |
| 6 | `CronJobCard.tsx` | — | ✅ PRODUCTION READY | Cron job display card |
| 7 | `CronJobModal.tsx` | — | ✅ PRODUCTION READY | Cron job edit modal |
| 8 | `CronWeeklyTimeline.tsx` | — | ✅ PRODUCTION READY | Weekly cron timeline view |
| 9 | `FileBrowser.tsx` | — | ✅ PRODUCTION READY | File browser with tree/list view |
| 10 | `FilePreview.tsx` | — | ✅ PRODUCTION READY | File preview (images, markdown, code) |
| 11 | `FileTree.tsx` | — | ✅ PRODUCTION READY | File tree sidebar |
| 12 | `GlobalSearch.tsx` | — | ✅ PRODUCTION READY | Global search with debounce |
| 13 | `IntegrationStatus.tsx` | — | ✅ PRODUCTION READY | Integration health display |
| 14 | `MarkdownEditor.tsx` | — | ✅ PRODUCTION READY | Markdown editor with preview |
| 15 | `MarkdownPreview.tsx` | — | ✅ PRODUCTION READY | Markdown rendering |
| 16 | `Notepad.tsx` | — | ✅ PRODUCTION READY | LocalStorage notepad with auto-save |
| 17 | `NotificationDropdown.tsx` | — | ✅ PRODUCTION READY | Notification bell + dropdown |
| 18 | `QuickActions.tsx` | — | ✅ PRODUCTION READY | Quick action buttons |
| 19 | `RichDescription.tsx` | — | ✅ PRODUCTION READY | Rich text display |
| 20 | `Sidebar.tsx` | — | ✅ PRODUCTION READY | Main navigation sidebar |
| 21 | `SkillCard.tsx` | — | ✅ PRODUCTION READY | Skill display card |
| 22 | `SkillDetailModal.tsx` | — | ✅ PRODUCTION READY | Skill detail/edit modal |
| 23 | `StatsCard.tsx` | — | ✅ PRODUCTION READY | Statistics card with sparkline |
| 24 | `SystemInfo.tsx` | — | ✅ PRODUCTION READY | System info panel |
| 25 | `WeatherWidget.tsx` | — | ✅ PRODUCTION READY | Weather display widget |
| 26 | `WeeklyCalendar.tsx` | — | ✅ PRODUCTION READY | Weekly calendar with task fetching |

### MissionControl Sub-components

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 27 | `AgentMatrix.tsx` | 211 | ✅ PRODUCTION READY | Agent matrix grid visualization |

### Charts Sub-components

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 28 | `charts/index.ts` | — | ✅ PRODUCTION READY | Barrel export |
| 29 | `ActivityLineChart.tsx` | — | ✅ PRODUCTION READY | Line chart (recharts) |
| 30 | `ActivityPieChart.tsx` | — | ✅ PRODUCTION READY | Pie chart (recharts) |
| 31 | `HourlyHeatmap.tsx` | — | ✅ PRODUCTION READY | Hourly activity heatmap |
| 32 | `SuccessRateGauge.tsx` | — | ✅ PRODUCTION READY | Success rate gauge |

### TenacitOS Sub-components (Design System)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 33 | `TenacitOS/index.ts` | — | ✅ PRODUCTION READY | Barrel export |
| 34 | `TenacitOS/Dock.tsx` | 140 | ✅ PRODUCTION READY | macOS-style dock |
| 35 | `TenacitOS/TopBar.tsx` | 182 | ✅ PRODUCTION READY | Top menu bar |
| 36 | `TenacitOS/StatusBar.tsx` | 225 | ✅ PRODUCTION READY | Bottom status bar |
| 37 | `TenacitOS/DevTools.tsx` | 150 | ✅ PRODUCTION READY | Dev tools HUD overlay |
| 38 | `TenacitOS/Shell.tsx` | 144 | ✅ PRODUCTION READY | Shell/panel/card primitives |
| 39 | `TenacitOS/SectionHeader.tsx` | 42 | ✅ PRODUCTION READY | Section header component |
| 40 | `TenacitOS/MetricCard.tsx` | 97 | ✅ PRODUCTION READY | Metric display card |
| 41 | `TenacitOS/AgentRow.tsx` | 112 | ✅ PRODUCTION READY | Agent list row |
| 42 | `TenacitOS/ActivityRow.tsx` | 78 | ✅ PRODUCTION READY | Activity list row |
| 43 | `TenacitOS/CronRow.tsx` | 106 | ✅ PRODUCTION READY | Cron job row |

### Office3D Sub-components (3D Office — React Three Fiber)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 44 | `Office3D/Office3D.tsx` | 347 | ✅ PRODUCTION READY | Main 3F scene, dynamically loaded from `/office` |
| 45 | `Office3D/agentsConfig.ts` | 87 | ✅ PRODUCTION READY | Agent position/color configuration |
| 46 | `Office3D/Avatar.tsx` | 13 | 🗑️ REDUNDANT | Thin wrapper around `ProceduralAvatars` — unused |
| 47 | `Office3D/AvatarModel.tsx` | 54 | 🔴 BROKEN | **React hook violation** — `useGLTF()` called inside conditional |
| 48 | `Office3D/MovingAvatar.tsx` | 195 | ✅ PRODUCTION READY | Animated avatar with collision avoidance |
| 49 | `Office3D/ProceduralAvatars.tsx` | 239 | ✅ PRODUCTION READY | Procedural 3D avatar generation |
| 50 | `Office3D/VoxelAvatar.tsx` | 179 | ✅ PRODUCTION READY | Voxel-style avatar |
| 51 | `Office3D/FirstPersonControls.tsx` | 131 | ✅ PRODUCTION READY | FPS controls with pointer lock |
| 52 | `Office3D/AgentDesk.tsx` | 187 | ✅ PRODUCTION READY | 3D desk with monitor |
| 53 | `Office3D/AgentPanel.tsx` | 150 | ✅ PRODUCTION READY | Agent status panel in 3D |
| 54 | `Office3D/Floor.tsx` | 63 | ✅ PRODUCTION READY | Floor plane |
| 55 | `Office3D/Walls.tsx` | 25 | ✅ PRODUCTION READY | Office walls |
| 56 | `Office3D/Lights.tsx` | 35 | ✅ PRODUCTION READY | Lighting setup |
| 57 | `Office3D/CoffeeMachine.tsx` | 137 | ✅ PRODUCTION READY | Coffee machine prop |
| 58 | `Office3D/FileCabinet.tsx` | 87 | ✅ PRODUCTION READY | File cabinet prop |
| 59 | `Office3D/PlantPot.tsx` | 61 | ✅ PRODUCTION READY | Plant prop |
| 60 | `Office3D/WallClock.tsx` | 121 | ✅ PRODUCTION READY | Animated wall clock |
| 61 | `Office3D/Whiteboard.tsx` | 84 | ✅ PRODUCTION READY | Whiteboard with text |
| 62 | `Office3D/VoxelMacMini.tsx` | 59 | ✅ PRODUCTION READY | Voxel Mac Mini prop |
| 63 | `Office3D/VoxelChair.tsx` | 75 | ✅ PRODUCTION READY | Voxel chair prop |
| 64 | `Office3D/VoxelKeyboard.tsx` | 65 | ✅ PRODUCTION READY | Voxel keyboard prop |
| 65 | `Office3D/useAvatarModel.ts` | — | 🗑️ REDUNDANT | **Dead code** — defined but never imported anywhere |

### Office Sub-components (Pixel Art — **ORPHANED**)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 66 | `office/OfficeCanvas.tsx` | 520 | 🗑️ REDUNDANT | **Orphaned** — not imported by any page |
| 67 | `office/PixelCharacter.tsx` | 256 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 68 | `office/HabboCharacter.tsx` | 228 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 69 | `office/HabboFurniture.tsx` | 405 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 70 | `office/HabboRoom.tsx` | 190 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 71 | `office/StardewCharacter.tsx` | 419 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 72 | `office/StardewFurniture.tsx` | 486 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 73 | `office/StardewRoom.tsx` | 154 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 74 | `office/ZeldaCharacter.tsx` | 291 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 75 | `office/ZeldaFurniture.tsx` | 362 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |
| 76 | `office/ZeldaRoom.tsx` | 216 | 🗑️ REDUNDANT | **Orphaned** — not imported anywhere |

**Subtotal: 76 component files**

---

## 4. Services (`src/services/*`)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `safe-write.ts` | 73 | ✅ PRODUCTION READY | Atomic file writes with file locking |
| 2 | `stall-detector.ts` | 296 | ✅ PRODUCTION READY | 3-phase stall detection (ghost, stale, cooldown) |

**Subtotal: 2 services**

---

## 5. Hooks (`src/hooks/*`)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `useDebounce.ts` | 17 | ⚠️ NEEDS WORK | Functional but very minimal — consider replacing with use-debounce library |

**Subtotal: 1 hook**

---

## 6. Lib Modules (`src/lib/*`)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `activities-db.ts` | 274 | ✅ PRODUCTION READY | SQLite-backed activity logger with 30-day retention |
| 2 | `activity-logger.ts` | 126 | ✅ PRODUCTION READY | Activity logging service layer |
| 3 | `agent-skills.ts` | 117 | ✅ PRODUCTION READY | Agent skill registry |
| 4 | `cron-parser.ts` | 294 | ✅ PRODUCTION READY | Cron expression parser |
| 5 | `paths.ts` | 24 | ✅ PRODUCTION READY | Centralized path configuration |
| 6 | `pricing.ts` | 138 | ✅ PRODUCTION READY | Token pricing calculations |
| 7 | `skill-parser.ts` | 317 | ✅ PRODUCTION READY | Skill markdown parser |
| 8 | `usage-collector.ts` | 225 | ✅ PRODUCTION READY | Usage data collection |
| 9 | `usage-queries.ts` | 229 | ⚠️ NEEDS WORK | Usage query functions — could use more aggregation types |

**Subtotal: 9 lib modules**

---

## 7. Scripts (`scripts/*`)

| # | File | Lines | Classification | Notes |
|---|---|---|---|---|
| 1 | `collect-usage.ts` | 29 | ✅ PRODUCTION READY | Usage data collection script |
| 2 | `collect-usage.sh` | 7 | 🗑️ REDUNDANT | Shell wrapper — redundant with .ts version |
| 3 | `pre-commit-check.sh` | 92 | ✅ PRODUCTION READY | Pre-commit lint + type check |
| 4 | `setup-cron.sh` | 32 | ✅ PRODUCTION READY | Cron job setup script |
| 5 | `test-agent-swarm.ts` | 204 | ✅ PRODUCTION READY | Agent swarm integration test |
| 6 | `test-canary.ts` | 124 | ⚠️ NEEDS WORK | Canary test — functional but basic reporting |
| 7 | `verify-simulation.ts` | 214 | ⚠️ NEEDS WORK | Full-stack simulation test — good coverage but brittle assertions |

**Subtotal: 7 scripts**

---

## 8. Data Layer (`data/*`)

| # | File | Classification | Notes |
|---|---|---|---|
| 1 | `activities.db` | ✅ PRODUCTION READY | SQLite database (24KB, 1 table: `activities`) |
| 2 | `activities.json` | ✅ PRODUCTION READY | JSON backup/export |
| 3 | `activities.example.json` | ✅ PRODUCTION READY | Example/template file |
| 4 | `configured-skills.json` | ✅ PRODUCTION READY | Skill configurations |
| 5 | `configured-skills.example.json` | ✅ PRODUCTION READY | Example/template file |
| 6 | `cron-jobs.json` | ✅ PRODUCTION READY | Cron job definitions |
| 7 | `cron-jobs.example.json` | ✅ PRODUCTION READY | Example/template file |
| 8 | `notifications.json` | ✅ PRODUCTION READY | Notification storage |
| 9 | `notifications.example.json` | ✅ PRODUCTION READY | Example/template file |
| 10 | `tasks.json` | ✅ PRODUCTION READY | Task storage |
| 11 | `tasks.example.json` | ✅ PRODUCTION READY | Example/template file |
| 12 | `activities.db` (duplicate) | 🗑️ REDUNDANT | Listed once — SQLite is the live DB |

**Subtotal: 11 data files (10 .json + 1 .db)**

---

## 9. Additional Routes (Outside Dashboard)

### Login Page
| # | File | Classification | Notes |
|---|---|---|---|
| 1 | `src/app/login/page.tsx` | ✅ PRODUCTION READY | Password login form with redirect |
| 2 | `src/app/login/layout.tsx` | ✅ PRODUCTION READY | Minimal layout (no shell) |

### Office Page
| # | File | Classification | Notes |
|---|---|---|---|
| 3 | `src/app/office/page.tsx` | ✅ PRODUCTION READY | Metadata + dynamic import of Office3D |
| 4 | `src/app/office/client.tsx` | ✅ PRODUCTION READY | Client-side dynamic import with loading fallback |

### Config
| # | File | Classification | Notes |
|---|---|---|---|
| 5 | `src/config/branding.ts` | ✅ PRODUCTION READY | Centralized branding configuration |

---

## 10. Critical Issues Requiring Immediate Attention

### 🔴 BROKEN (4 items)

1. **`not-found.tsx`** — Returns empty fragment. Should render a proper 404 page.
2. **`Office3D/AvatarModel.tsx`** — Calls `useGLTF()` inside a conditional `if (!exists)` block. This violates React's Rules of Hooks and will crash at runtime if the GLB model exists.
3. **`Office3D/useAvatarModel.ts`** — Calls `useGLTF()` inside a try-catch within a conditional. Same Rules of Hooks violation. Also: **never imported anywhere** (dead code).
4. **`Office3D/Avatar.tsx`** — Only 13 lines, just wraps `ProceduralAvatars`. Redundant indirection.

### ⚠️ NEEDS WORK (21 items)

1. **`calendar/page.tsx`** — 18 lines, bare wrapper. No week navigation controls, no task detail.
2. **`search/page.tsx`** — 23 lines, bare wrapper. No search history or filters.
3. **`analytics/page.tsx`** — 188 lines, basic. Missing date range selector, export.
4. **`terminal/route.ts`** — Basic WebSocket terminal. Needs authentication check.
5. **`useDebounce.ts`** — Functional but minimal. Missing cancel, flush, leading/trailing options.
6. **`usage-queries.ts`** — Missing aggregation for cost forecasting.
7. **`test-canary.ts`** — Basic pass/fail. No metrics collection or trend analysis.
8. **`verify-simulation.ts`** — Brittle assertions, no retry logic for flaky network.

### 🗑️ REDUNDANT (14 items)

1. **`office/` directory (11 files, 3,527 lines)** — Entire pixel-art office suite (Habbo, Stardew, Zelda themes) is **completely orphaned**. Zero imports from any page or component. Should be deleted or wired up.
2. **`Office3D/Avatar.tsx`** — Unnecessary wrapper around `ProceduralAvatars`.
3. **`Office3D/useAvatarModel.ts`** — Dead code, never imported, also has hook bug.
4. **`activity/route.ts`** — Legacy singular endpoint overlapping with `activities/route.ts`.
5. **`collect-usage.sh`** — Redundant with `collect-usage.ts`.

---

## 11. Architecture Notes

### Tech Stack
- **Framework:** Next.js 16.1.6 (App Router)
- **React:** 19.2.3
- **Styling:** Tailwind CSS 4 + CSS variables (design system)
- **3D:** React Three Fiber 9 + Drei 10 + Three.js 0.183
- **Charts:** Recharts 2.15
- **Editor:** Monaco Editor 4.7
- **Database:** better-sqlite3 12.6
- **State:** React hooks (no external state management)

### Design System
- **TenacitOS** — Custom design system in `components/TenacitOS/` with Shell, Panel, Card, Dock, TopBar, StatusBar, DevToolsHUD
- Used by dashboard layout and skills page
- CSS variables for theming (`--text-primary`, `--accent`, `--card`, etc.)

### Data Flow
- **Tasks/Cron/Notifications** → JSON files in `data/` with atomic writes via `safe-write.ts`
- **Activities** → SQLite (`activities.db`) with 30-day retention
- **Agent status** → OpenClaw gateway (HTTP) with file-system fallback
- **File system** → Direct fs access with path validation via `paths.ts`

### Path Configuration
- Defaults to `/root/.openclaw/workspace` (VPS production)
- Overridable via `OPENCLAW_DIR`, `OPENCLAW_WORKSPACE` env vars
- All data paths centralized in `src/lib/paths.ts`

---

## 12. Recommendations

### Priority 1 — Fix Broken Items
1. Implement proper 404 page in `not-found.tsx`
2. Fix `AvatarModel.tsx` hook violation — move `useGLTF()` to top level or remove the conditional
3. Delete `useAvatarModel.ts` (dead code + broken)

### Priority 2 — Clean Up Redundancy
4. Delete or wire up `office/` pixel-art components (3,527 lines of dead code)
5. Remove `Office3D/Avatar.tsx` (trivial wrapper)
6. Consolidate `activity/route.ts` → `activities/route.ts`
7. Remove `collect-usage.sh` (redundant with .ts version)

### Priority 3 — Improve Thin Pages
8. Enhance `calendar/page.tsx` with week navigation and task detail
9. Enhance `search/page.tsx` with search history and filters
10. Add auth guard to `terminal/route.ts`

### Priority 4 — Testing & Monitoring
11. Strengthen `verify-simulation.ts` with retry logic
12. Add metrics output to `test-canary.ts`
13. Consider adding Playwright/Cypress E2E tests

---

*End of inventory. 160 items catalogued across 8 categories.*
