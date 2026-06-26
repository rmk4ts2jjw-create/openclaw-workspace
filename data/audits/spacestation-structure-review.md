# SpaceStation Codebase Structure Review

**Date:** 2026-06-25  
**Reviewer:** SpaceMonkey (automated analysis)  
**Scope:** `/Users/spacemonkey/.openclaw/workspace/spacestation/src`  
**Total LOC:** ~28,173 (154 files)

---

## 1. Executive Summary

SpaceStation is a Next.js 16 dashboard for OpenClaw, forked from TenacitOS. At 28K LOC across 154 files, it's grown organically — many pages are TenacitOS boilerplate with hardcoded data, several API routes duplicate each other, and ~15% of components/libs are dead code. The core custom functionality (tasks, workboard, incidents, cron, office, agents) works but is surrounded by vestigial code from the original project.

**Key findings:**
- **28 API routes** — 3 duplicate pairs, 4 dead endpoints, 1 inconsistent namespace
- **~10 dead components** never imported anywhere
- **3 dead lib files** and **1 dead hook**
- **4 pages** are pure TenacitOS boilerplate with no real data wiring
- **System routes** have 3 overlapping endpoints that should be 1
- **Workboard API** is well-structured but has a DB path bug

---

## 2. Project Structure Assessment

### Current Layout

```
src/
├── app/
│   ├── (dashboard)/     ← 25 page routes (20 are real, 5 are boilerplate)
│   ├── api/             ← 28 route.ts files across 26 directories
│   ├── office/          ← 3D office (custom, well-structured)
│   ├── login/           ← Auth page
│   ├── layout.tsx       ← Root layout (Inter + Sora + JetBrains Mono)
│   └── globals.css
├── components/
│   ├── TenacitOS/       ← 10 files: Shell, Dock, TopBar, StatusBar, etc.
│   ├── Office3D/        ← 18 files: 3D office scene (custom)
│   ├── charts/          ← 5 files: Recharts wrappers
│   └── *.tsx            ← ~25 standalone components
├── lib/                 ← 9 files: DB, parsers, utilities
├── services/            ← 2 files: safe-write, stall-detector
├── hooks/               ← 1 file: useDebounce (DEAD)
└── config/              ← 1 file: branding.ts
```

### Verdict: **Mostly logical, but needs pruning**

The TenacitOS/ subdirectory correctly groups legacy components. The Office3D/ directory is well-isolated. The flat `/components` directory has ~25 files that could benefit from grouping (e.g., `/components/ui/` for generic cards, modals, search).

---

## 3. API Routes — Duplicates & Dead Endpoints

### 3.1 Duplicate Pairs

| Route A | Route B | Issue |
|---------|---------|-------|
| `/api/activities` | `/api/activity` | **Different data sources** — `activities` reads SQLite (`activities-db`), `activity` reads filesystem (memory/tasks/incidents). Two UIs fetch from different endpoints for the "same" concept. |
| `/api/agents` | `/api/agents/[id]/status` | The detail route is **never fetched** by any page. The list route already returns full agent data. |
| `/api/search` | `/api/memory/search` | Both search memory files. `search` also searches tasks.json. `memory/search` is more focused. Overlapping purpose. |

### 3.2 Dead / Never-Fetched Routes

These API routes exist but **no page calls them**:

| Route | Reason |
|-------|--------|
| `/api/activities/stream` | SSE stream — never consumed. The activity page polls `/api/activities` instead. |
| `/api/costs` | Fetches from `usage-tracking.db` which doesn't exist on this host. Page renders empty state. |
| `/api/reports` | Scans `memory/` for `*-analysis-*` files that don't exist. Page renders empty list. |
| `/api/workboard/cards` | **Actually used** by tasks page ✅ |

### 3.3 Overlapping System Routes

Four routes do what one could:

| Route | What it does |
|-------|-------------|
| `/api/system` | Agent identity, uptime, integrations, memory stats |
| `/api/system/stats` | CPU, RAM, disk, VPN, firewall, systemd services |
| `/api/system/monitor` | CPU, RAM, disk, network, services, Tailscale, firewall (more detailed) |
| `/api/system/services` | Service action API (restart/stop/start/logs) |

**Recommendation:** Merge `system/stats` + `system/monitor` into one `/api/system/stats` endpoint. Keep `/api/system` for identity and `/api/services` for actions.

### 3.4 Inconsistent Naming

- `/api/activities` (plural) vs `/api/activity` (singular) — pick one convention
- `/api/cron` vs `/api/cron/run` vs `/api/cron/runs` — the sub-routes are fine, but `cron/run` uses POST while `cron/runs` uses GET; the naming doesn't make the method obvious

---

## 4. Component Organization

### 4.1 Dead Components (never imported)

| Component | LOC | Notes |
|-----------|-----|-------|
| `CronJobModal.tsx` | ~80 | Likely replaced by inline modal in cron page |
| `Sidebar.tsx` | ~60 | Replaced by TenacitOS Dock |
| `SkillCard.tsx` | ~50 | Replaced by inline card in skills page |
| `SkillDetailModal.tsx` | ~70 | Replaced by inline detail in skills page |

### 4.2 TenacitOS Components (used but generic)

These 10 files in `components/TenacitOS/` are the **design system shell**:

| File | Used by | Notes |
|------|---------|-------|
| `Shell.tsx` | Dashboard layout | Core wrapper — exports Panel, Card, GhostButton |
| `Dock.tsx` | Dashboard layout | Navigation sidebar |
| `TopBar.tsx` | Dashboard layout | Header bar |
| `StatusBar.tsx` | Dashboard layout | Footer status |
| `DevTools.tsx` | Dashboard layout | Dev overlay HUD |
| `MetricCard.tsx` | Skills page | Generic metric display |
| `SectionHeader.tsx` | Skills page | Section title |
| `AgentRow.tsx` | — | **Not imported** (agents page uses inline) |
| `ActivityRow.tsx` | — | **Not imported** (activity page uses inline) |
| `CronRow.tsx` | — | **Not imported** (cron page uses inline) |

**Recommendation:** Remove `AgentRow`, `ActivityRow`, `CronRow` — they're unused. Consider moving the rest to `components/ui/` to decouple from the TenacitOS branding.

### 4.3 Office3D — Well Isolated

18 files, ~2K LOC. Clean separation with dynamic import (SSR disabled). This is the most polished custom feature. No issues.

---

## 5. Workboard Integration Review

### `/api/workboard/cards/route.ts` — 180 lines

**Structure:** GET (list), POST (create), PATCH (update), DELETE — all four methods present.

**✅ What's good:**
- Uses `openclaw` CLI for list/create (consistent with the rest of the system)
- Uses direct SQLite for PATCH/DELETE (avoids Gateway WebSocket auth)
- SQL injection protection via `sqlEscape()`
- Proper error handling with try/catch per method
- Returns proper HTTP status codes (201, 400, 404, 500)

**⚠️ Issues:**

1. **DB Path Bug:** Uses `~/.openclaw/plugins/workboard/workboard.sqlite` but the actual Workboard plugin DB is at `~/.openclaw/workspace/data/workboard.db` (per MEMORY.md). The route will silently fail or create a new empty DB.

2. **No `board_id` filter on DELETE:** The DELETE query doesn't filter by `board_id`, which could delete cards from other boards in a multi-board setup.

3. **Labels update is destructive:** PATCH deletes all labels then re-inserts. This is fine for small label sets but loses label ordering metadata if the schema evolves.

4. **No GET-by-id:** There's a helper `getCardById()` but no endpoint to fetch a single card. The PATCH response uses it, but there's no standalone GET.

**Recommendation:** Fix the DB path. Add `board_id` to DELETE. Consider adding `GET /api/workboard/cards?id=X`.

---

## 6. Pages — Boilerplate vs Real

### 6.1 Real Pages (wired to live data)

| Page | Data Source | Status |
|------|-------------|--------|
| `home` | activities/stats, agents, tasks, incidents | ✅ Live |
| `tasks` | /api/workboard/cards, /api/incidents | ✅ Live |
| `incidents` | /api/incidents | ✅ Live |
| `cron` | /api/cron, /api/cron/run, /api/cron/runs | ✅ Live |
| `agents` | /api/agents | ✅ Live |
| `activity` | /api/activities | ✅ Live |
| `system` | /api/system/monitor, /api/system/services | ✅ Live |
| `files` | /api/files/* | ✅ Live |
| `memory` | /api/files/workspaces, /api/files | ✅ Live |
| `sessions` | /api/sessions | ✅ Live |
| `office` | /api/office | ✅ Live |
| `search` | (client-side?) | ✅ Functional |
| `terminal` | /api/terminal | ✅ Live |
| `settings` | /api/system | ✅ Live |
| `skills` | /api/skills | ✅ Live |
| `actions` | /api/actions | ✅ Live |
| `git` | /api/git | ✅ Live |
| `login` | /api/auth/login | ✅ Live |

### 6.2 Boilerplate Pages (hardcoded data, no API)

| Page | Content | Recommendation |
|------|---------|----------------|
| `about` | Fetches activities/skills/tasks but renders mostly hardcoded personality/skills | **Keep** — it's a profile card, acceptable |
| `workflows` | Entirely hardcoded array of 10 workflows, no API | **Remove or wire** — misleading, not real |
| `analytics` | Fetches `/api/analytics` which reads from `activities-db` (SQLite) | **Keep** — functional but data may be sparse |
| `reports` | Fetches `/api/reports` which scans for nonexistent files | **Remove** — always empty |
| `calendar` | Not checked — likely hardcoded | **Review** |

### 6.3 Unused Pages

| Page | Notes |
|------|-------|
| `costs` | Fetches `/api/costs` from a DB that doesn't exist. Page renders zeros. |

---

## 7. Lib Files

### Dead Lib Files

| File | Notes |
|------|-------|
| `lib/activity-logger.ts` | Not imported anywhere. Likely superseded by `activities-db.ts`. |
| `lib/agent-skills.ts` | Not imported anywhere. Skills are now handled by `skill-parser.ts`. |
| `lib/usage-collector.ts` | Not imported anywhere. Would feed the nonexistent `usage-tracking.db`. |

### Active Lib Files

| File | Used by | Purpose |
|------|---------|---------|
| `lib/activities-db.ts` | activities, activities/stats, activities/stream, actions | SQLite activity logging |
| `lib/paths.ts` | 9 files | Centralized path constants |
| `lib/cron-parser.ts` | cron page | Cron expression formatting |
| `lib/skill-parser.ts` | skills page | Scans SKILL.md files |
| `lib/pricing.ts` | costs page | Token cost calculation |
| `lib/usage-queries.ts` | costs page | SQL queries for usage DB |

---

## 8. Services & Hooks

### Services (both active)

| File | Used by | Purpose |
|------|---------|---------|
| `safe-write.ts` | tasks, files, notifications | Atomic file write (write-then-rename) |
| `stall-detector.ts` | watchdog | Task stall detection |

### Hooks (dead)

| File | Notes |
|------|-------|
| `hooks/useDebounce.ts` | Not imported anywhere |

---

## 9. Middleware

The middleware is clean and minimal:
- Public routes: `/login`
- Public API prefixes: `/api/auth/`, `/api/health`, `/api/workboard`, `/api/system`
- All other routes require `mc_auth` cookie matching `AUTH_SECRET`

**Note:** `/api/workboard` is public (no auth) by design since it uses CLI/SQLite. This is acceptable for local-only access.

---

## 10. Recommendations — Priority Order

### 🔴 P0 — Fix Bugs

1. **Fix workboard DB path** in `/api/workboard/cards/route.ts` — change from `~/.openclaw/plugins/workboard/workboard.sqlite` to `~/.openclaw/workspace/data/workboard.db`

### 🟡 P1 — Remove Dead Code

2. **Delete dead components:** `CronJobModal.tsx`, `Sidebar.tsx`, `SkillCard.tsx`, `SkillDetailModal.tsx`
3. **Delete dead lib files:** `activity-logger.ts`, `agent-skills.ts`, `usage-collector.ts`
4. **Delete dead hook:** `hooks/useDebounce.ts`
5. **Delete dead TenacitOS components:** `AgentRow.tsx`, `ActivityRow.tsx`, `CronRow.tsx`
6. **Remove dead API routes:** `/api/activities/stream`, `/api/costs`, `/api/reports`

### 🟠 P2 — Merge / Consolidate

7. **Merge system routes:** Combine `/api/system/stats` + `/api/system/monitor` into one endpoint
8. **Merge activity routes:** Pick either `/api/activities` or `/api/activity` as the canonical endpoint; redirect or remove the other
9. **Remove `/api/agents/[id]/status`** — the list route already returns full data
10. **Remove `/api/search`** — `/api/memory/search` is more focused and the search page can use it

### 🔵 P3 — Clean Up Pages

11. **Remove or wire `workflows` page** — currently entirely hardcoded
12. **Remove `reports` page** — always empty, no real reports exist
13. **Remove `costs` page** — DB doesn't exist, always shows zeros
14. **Review `calendar` page** — likely hardcoded

### ⚪ P4 — Nice to Have

15. **Move TenacitOS components to `components/ui/`** — decouple design system from origin name
16. **Group standalone components** — move cards, modals, search into `components/ui/`
17. **Add GET-by-id to workboard** — `GET /api/workboard/cards?id=X`
18. **Standardize naming** — pick singular or plural for all resource routes

---

## 11. Summary Metrics

| Metric | Value |
|--------|-------|
| Total source files | 154 |
| Total LOC | ~28,173 |
| API routes | 28 (in 26 directories) |
| Page routes | 27 (25 dashboard + office + login) |
| Components | ~35 (10 TenacitOS + 18 Office3D + 7 charts/ui) |
| Dead components | 4 confirmed |
| Dead lib files | 3 |
| Dead hook | 1 |
| Dead API routes | 3 (never fetched) |
| Overlapping API routes | 3 pairs |
| Boilerplate pages | 4 (workflows, reports, costs, calendar) |
| Estimated dead code | ~4,000-5,000 LOC (~15-18%) |

---

## 12. Estimated Impact

If all P0-P3 recommendations are applied:
- **Remove** ~4,500 LOC of dead code
- **Merge** 6 API routes into 3
- **Delete** 4 boilerplate pages
- **Net result:** ~23,500 LOC, cleaner architecture, no functional loss
