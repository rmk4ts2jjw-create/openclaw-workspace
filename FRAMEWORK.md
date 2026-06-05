# FRAMEWORK.md — Development Authority & Index

**Purpose:** Ensure every agent uses the right framework, the right repo, and the right workflow.

**Repository Authority:** `SOURCES.md` is the single source of truth for canonical documentation URLs. See also `docs/sources.md`.

---

## Documentation Index

Detailed rules live in `docs/`:
- `docs/framework.md` — Framework selection guide, build tool rules, anti-patterns, gotchas
- `docs/roles.md` — Agent roles, operations engine, security rules, component rules
- `docs/routes.md` — Routes manifest + testing procedure
- `docs/stack.md` — Active project stack, dependencies
- `docs/workflow.md` — Dev→Prod workflow, git rules, merge checklist
- `docs/sources.md` — External documentation references

---

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

## Related Files

- **SOURCES.md** — Canonical documentation URLs, compatibility matrix, agent rules
- **AGENTS.md** — Agent work rules (includes source selection rules)
- **docs/framework.md** — Framework selection guide, anti-patterns, build tool rules
- **docs/workflow.md** — Development workflow, git rules, merge procedure
