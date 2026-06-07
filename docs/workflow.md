# Development Workflow

## Four-Repository Structure

```
GitHub (rmk4ts2jjw-create)
├── mc-prod        ← Production (port 3000) — stable, tested code
├── mc-dev         ← Development (port 3001) — prototype integration + testing
├── mc-lovable     ← Lovable prototypes — auto-synced from Lovable (DO NOT TOUCH)
└── mc-replit      ← Replit prototypes — auto-synced from Replit (LEAVE EMPTY)
```

### Workflow
```
Lovable/Replit → mc-lovable / mc-replit (auto-sync)
        ↓
   Andre reviews prototype
        ↓
   Export ZIP → WD MyCloud
        ↓
   Space Monkey pulls into mc-dev (port 3001)
        ↓
   Test features, wire data, verify
        ↓
   Andre approves
        ↓
   Systems Engineer merges to mc-prod (port 3000)
        ↓
   All routes verified 200
```

### Local Directory Mapping
| Local Directory | GitHub Remote | Port | Purpose |
|---|---|---|---|
| `mission-control-dashboard/` | `git@github.com-rmk:rmk4ts2jjw-create/mc-prod.git` | 3000 | Production |
| `mission-control-dashboard-dev/` | `git@github.com-rmk:rmk4ts2jjw-create/mc-dev.git` | 3001 | Development |

### SSH Configuration
- `github.com` → `~/.ssh/id_ed25519_spacemonkey` (spacemonkey-home account)
- `github.com-rmk` → `~/.ssh/id_ed25519_rmk` (rmk4ts2jjw-create account)
- Always use `git@github.com-rmk:` prefix for mc-* repos

### Rules
- **NEVER** push to mc-lovable or mc-replit — Lovable/Replit manage those
- **NEVER** push directly to mc-prod without Andre's approval
- All experiments go to mc-dev (port 3001) first
- Production (port 3000) is the live system — treat it with care

---

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
