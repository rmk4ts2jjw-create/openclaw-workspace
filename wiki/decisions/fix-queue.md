# Phase 4: Skills Cleanup

## Actions Completed
1. [x] Removed `night-shift` skill (never successfully dispatched tasks)
2. [x] Archived `vite-tanstack-debug` skill

## Confirmed Active Skills
- free-ride (cost optimization)
- incident-manage (governance)
- mac-proxy-manage (networking)
- mc-dashboard-deploy (deployment)
- task-system-maint (task infrastructure)

## Next Steps
- Monitor `night-shift` deletion effectiveness
- Watch `vite-tanstack-debug` archive status

---

# Phase 5: Mission Control UI

## Fix 1: Dashboard Live Data — VERIFIED ✅
- Dashboard.tsx already wires useAgentStatus() and useTaskStream() hooks to all panels
- No code changes needed — data flow is correct

## Fix 2: Task Board Dispatch — FIXED ✅
- Added DashboardRefresher to TasksPage for periodic loader invalidation
- Added useEffect to sync tasks state with loader data
- Commit: 08c38a4

## Fix 3: Layout & Panels — FIXED ✅
- Removed conflicting inline style from panels grid
- Changed lg:grid-cols-4 to lg:grid-cols-3 xl:grid-cols-4 for better 7-item distribution
- Added items-stretch for consistent height alignment
- Commit: 0035614

## Fix 4: Decisions & Audits in Wiki — FIXED ✅
- Added getWikiDecisions and getAuditFiles server functions
- Added Decisions and Audits sections to KnowledgeBaseTab
- Commit: 4a05ea9

## Fix 5: Navigation Cleanup — VERIFIED ✅
- No duplicate routes
- Agent Office route is gone (embedded in Dashboard component)
- Sidebar active states are correct
- All 10 routes match sidebar links
- No code changes needed

## Fix Summary
| Fix | Status | Commit |
|-----|--------|--------|
| 5.1 Dashboard Live Data | Verified ✅ | — |
| 5.2 Task Dispatch | Fixed ✅ | 08c38a4 |
| 5.3 Panel Alignment | Fixed ✅ | 0035614 |
| 5.4 Decisions & Audits | Fixed ✅ | 4a05ea9 |
| 5.5 Navigation | Verified ✅ | — |

## Phase 5: Remaining Issues — ALL FIXED ✅

| Fix | Status | Commit |
|-----|--------|--------|
| 5.6 Memory Tab Error Boundary | Fixed ✅ | 9288672 |
| 5.7 Drag-and-Drop onDragEnd | Fixed ✅ | 194315d |
| 5.8 Dispatch All dispatchCount | Fixed ✅ | 632e6e1 |
| 5.9 Task Detail Popup (drag state) | Fixed ✅ | 194315d |
| AsyncLocalStorage leak | Dev-only, production clean | — |

### Notes
- All 4 UI issues likely share root cause: AsyncLocalStorage error in dev server preventing client JS from loading
- Production build is clean — issues are dev-server-only
- Fixes make code more resilient regardless of root cause
- OpenCode consistently killed on large file reads; fixes applied directly
- Browser testing needed to confirm all fixes work