# Development Workflow

## Two-Instance Strategy

```
Lovable / Replit prototypes
        ↓
mission-control-dashboard-dev/  (port 3001, manual start)
        ↓ test & approve
        ↓ merge features manually (copy files or cherry-pick commits)
        ↓
mission-control-dashboard/      (port 3000, auto-start via LaunchAgent)
```

---

## Production (`mission-control-dashboard/`)

- **Port:** 3000
- **LaunchAgent:** `com.openclaw.mc.dashboard` (auto-starts on boot)
- **Branch:** `main` — single source of truth
- **Node modules:** 660MB (full dependencies)
- **Log:** `~/.openclaw/workspace/logs/mc-dashboard.log`
- **Error log:** `~/.openclaw/workspace/logs/mc-dashboard-error.log`
- **Never** run experimental changes here
- **Always** verify all routes return 200 after any change

---

## Development (`mission-control-dashboard-dev/`)

- **Port:** 3001
- **Start manually:** `cd mission-control-dashboard-dev && bun run dev --host --port 3001`
- **Or via script:** `./scripts/start-dev.sh`
- **Purpose:** Test Lovable/Replit prototypes, experiment with new features
- **Can be wiped/re-cloned** without affecting production
- **Not** auto-started on boot

---

## Shared Resources (workspace level)

- `data/tasks.json` — Both instances read/write the same task data
- `data/incidents.json` — Shared incident data
- `assets/` — Shared sprites, icons, images
- `scripts/` — Backup scripts, health checks, maintenance
- `logs/` — Centralized logs for both instances

---

## Git Rules

- MC Production and MC Dev are **separate git repos** (same GitHub remote, different local dirs)
- Workspace repo is **separate** from both
- Never commit `node_modules/` or `.vite/` — already in .gitignore
- After any meaningful change: `git status` → commit → push
- **Never force-push** to shared remotes without explicit approval

---

## Merging Dev → Production

1. Test thoroughly on dev (port 3001)
2. Verify all routes return 200
3. Copy changed files to production (or cherry-pick commits)
4. Restart production server
5. Verify all routes return 200 on production
6. Commit and push
