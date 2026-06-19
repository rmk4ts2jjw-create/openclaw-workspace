# Skills Inventory – OpenClaw Workspace

**Date:** 2026-06-18

The audit examined all custom skill definitions under `/Users/spacemonkey/.openclaw/workspace/skills/`. 7 SKILL.md files were found.

## Summary Table

| Skill | Purpose (excerpt) | Created | Last Used* | Overlaps with | Still Relevant? | Classification |
|-------|-------------------|---------|------------|---------------|-----------------|----------------|
| **free‑ride** | Manages free AI models from OpenRouter, updates `openclaw.json` with fallbacks. | 2026-05-14 (git log) | 2026-06-18 (referenced in fallback chain & recent ops) | none | ✅ Yes – essential for cost-effective AI routing. | **KEEP** |
| **incident‑manage** | Incident lifecycle: auto-detect, create, link to tasks, resolve, cleanup. | (untracked – no commit) | not recorded (no log entries) | *task-system-maint* (both touch incidents) | ⚠️ Useful but currently unused; may be redundant with automation. | **KEEP** |
| **mac-proxy-manage** | Manages the nginx reverse-proxy Docker container for MC access from iPad. | (untracked) | not recorded | none | ✅ Required for iPad access; proxy broke this week. | **KEEP** |
| **mc-dashboard-deploy** | Build, verify, and deploy Mission Control Dashboard to production (port 3000). | 2026-06-15 (git log) | 2026-06-18 (deploy activity) | none | ✅ High-frequency workflow; saves 5-10 min per deploy. | **KEEP** |
| **night-shift** | Autonomous task processing 01:00-07:00 BST, review loop, morning Telegram report. | (untracked) | **never succeeded** – dispatched 0/3 nights | *task-system-maint* (task state machine) | ❌ Dispatch architecture is broken; no tasks are dispatchable. | **DELETE** |
| **task-system-maint** | Task system maintenance: stall detection, ghost dispatch prevention, archive. | (untracked) | 2026-06-18 (referenced in HEARTBEAT.md & recent ops) | *night-shift* (shared task state machine) | ✅ Core infrastructure; actively maintained. | **KEEP** |
| **vite-tanstack-debug** | Troubleshoots Vite/TanStack Start issues: 504 deps, cache corruption, route errors. | 2026-06-15 (git log) | not recorded | none | ⚠️ Low frequency; Andre uses it occasionally. | **MERGE** → into a general “debug” skill or keep as niche tool |

\* Last used = last commit or explicit reference in logs. Skills with no git history were created but never explicitly invoked.

---

## Detailed Analysis

### 1. free-ride
- **Purpose**: Configures OpenClaw to use free OpenRouter models with automatic fallback ranking.
- **Status**: HEALTHY. Referenced in current config (`openclaw.json`). Active in recent dispatch chains.
- **Action**: **KEEP** – critical for reducing AI costs.

### 2. incident-manage
- **Purpose**: Standardizes incident creation, task linking, deduplication, and resolution workflow.
- **Status**: UNTRACKED (no git commits). No usage logs found.
- **Overlap**: *task-system-maint* also handles incident-related task maintenance.
- **Action**: **KEEP** – stores valuable gubernance documentation. Consider adding git history.

### 3. mac-proxy-manage
- **Purpose**: Manages the nginx reverse-proxy container on the Docker host for iPad access.
- **Status**: UNTRACKED. No usage logs, but proxy broke this week (Jun 14).
- **Action**: **KEEP** – essential for network accessibility.

### 4. mc-dashboard-deploy
- **Purpose**: Automates the 6-step deploy workflow (cache clear → build → verify → restart → health check → rollback).
- **Status**: Recently added (Jun 15). Actively used.
- **Action**: **KEEP** – high-value, frequent use.

### 5. night-shift
- **Purpose**: Autonomous task dispatch 01:00-07:00 BST with morning report.
- **Status**: **BROKEN**. Dispatched 0/3 nights due to exclusion tags + no dispatchable tasks.
- **Overlap**: Shares task state machine logic with *task-system-maint*.
- **Decision**: **DELETE**. The underlying problem (dispatch architecture) is unsolved. Re-add when/if dispatch is fixed.

### 6. task-system-maint
- **Purpose**: Stall detection, ghost dispatch prevention, duplicate cleanup, archiving.
- **Status**: Actively maintained. Recent fixes in Jun 18.
- **Action**: **KEEP** – core infrastructure.

### 7. vite-tanstack-debug
- **Purpose**: Diagnoses and fixes common Vite/TanStack Start issues.
- **Status**: Low frequency. Andre used it during recent debugging.
- **Decision**: **MERGE** – consider folding into a general “debug” skill with other troubleshooting helpers.

---

## Recommendations

1. **Delete `night-shift`** – it never worked in practice. The dispatch architecture needs fundamental redesign first.
2. **Keep `free-ride`, `incident-manage`, `mac-proxy-manage`, `mc-dashboard-deploy`, `task-system-maint`** – all provide clear value.
3. **Merge or archive `vite-tanstack-debug`** – either integrate into a general debug skill or keep as a niche reference.

---

## Minimal Skill Set (Post-Cleanup)

| Skill | Reason |
|-------|--------|
| `free-ride` | Cost-effective AI routing |
| `incident-manage` | Incident governance |
| `mac-proxy-manage` | Network accessibility |
| `mc-dashboard-deploy` | Deployment automation |
| `task-system-maint` | Core task infrastructure |

**Total: 5 skills** (down from 7).