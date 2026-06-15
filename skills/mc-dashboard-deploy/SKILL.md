---
name: "mc-dashboard-deploy"
description: "Build, verify, and deploy Mission Control Dashboard to production (port 3000). Handles cache clear, build, LaunchAgent restart, health checks."
---

# MC Dashboard Deploy Skill

## Purpose
Standardizes the build-and-deploy workflow for Mission Control Dashboard (port 3000). Eliminates the ad-hoc 5-6 step sequence currently done manually each time.

## Why It Should Exist
- MC deploys have been repeated 15+ times in the past week alone, each requiring: clear Vite cache → bun install → bun build → verify → restart LaunchAgent → health check
- Failure modes: forgetting cache clear (stale deps), forgetting LaunchAgent restart (old code), port conflicts, deploying without verifying
- Time saved: ~5-10 min per deploy, reduced error rate (currently 15-30 min with debugging)

## Expected Frequency
High — 3-10 times per week during active development.

## Dependencies
- `bun`, `launchctl`, `curl`
- `~/.openclaw/workspace/mission-control-dashboard/`
- `~/Library/LaunchAgents/com.openclaw.mc.dashboard.plist`

## Workflow
1. Pre-check: curl localhost:3000 → verify running
2. Clear cache: `rm -rf node_modules/.vite .vite`
3. Build: `bun run build` → verify "✓ built"
4. Restart: `launchctl unload` → wait → `launchctl load`
5. Verify: HTTP 200 + HTML content check
6. Rollback on failure: restore from `mission-control-dashboard-backup-*`

## Overlap with Existing Skills
None.

## Implementation
New skill. Shell script wrapper (`scripts/deploy-mc.sh`) with pre/post health checks, auto-rollback, optional `--dev` flag for port 3001.

## Acceptance Criteria
1. **Deploy completes without manual intervention**: Given a clean `main` branch, executing the deploy skill results in prod (port 3000) serving latest code within 3 minutes, verified by HTTP 200 and expected HTML title.
2. **Cache corruption handled automatically**: When node_modules/.vite contains stale bundles, the deploy skill clears them and produces a working build without operator diagnosis.
3. **Failed build triggers rollback**: When bun run build exits non-zero, the skill restores the previous production build from the most recent backup directory and restarts LaunchAgent, leaving prod in a working state.
4. **LaunchAgent restart verified**: After launchctl load, the skill confirms the new process listens on port 3000 within 10 seconds. Retries once before reporting failure.
