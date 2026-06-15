---
name: "vite-tanstack-debug"
description: "Standardized Vite/TanStack Start troubleshooting. Diagnoses and fixes common issues: 504 deps, cache corruption, route errors, build failures."
---

# Vite/TanStack Start Debug Skill

## Purpose
Standardized troubleshooting for Vite + TanStack Start applications. Covers the most common issues encountered during MC dashboard development.

## Why It Should Exist
- Vite 504 errors on deps (`@tanstack/router-core`, `seroval`) have occurred 3+ times this week
- Cache corruption (`node_modules/.vite`) is a recurring issue requiring identical fix each time
- Route file warnings (missing Route export) appear after merges
- Build failures from dependency mismatches
- Each incident currently requires 10-20 min of debugging that follows the same pattern

## Expected Frequency
Medium — 2-4 times per week during active MC development.

## Common Issues & Fixes
1. **504 on deps**: `rm -rf node_modules/.vite .vite && bun install --force && bun run dev`
2. **Route warnings**: Check new route files export `createFileRoute` or `Route`
3. **Build failure**: `bun install --force` → check for type errors → rebuild
4. **Stale deps**: `bun update` → test → commit lockfile
5. **Port conflict**: `lsof -ti:3000 | xargs kill -9` → restart

## Overlap with Existing Skills
None.

## Implementation
New skill. Quick-reference diagnostic flowchart + shell commands for each failure mode.

## Acceptance Criteria
1. **504 resolution is deterministic**: Given a Vite 504 error on any dependency module, following the skill's procedure resolves the error and the dev server serves the module within 2 minutes, without requiring the operator to inspect Vite internals.
2. **Route warning diagnosis is immediate**: When a new route file triggers "does not export a Route" warnings, the skill identifies the exact file and the exact missing export within 30 seconds.
3. **Build failure root cause is identified**: When `bun run build` fails, the skill's diagnostic sequence (check types → check deps → check config) identifies the root cause category (type error / dependency mismatch / config error) without trial-and-error.
