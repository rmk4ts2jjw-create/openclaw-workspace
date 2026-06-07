# Tech Stack

## Active Project Stacks

### Mission Control Dashboard
- **Stack:** TanStack Start + React + Vite + Tailwind CSS + shadcn/ui
- **Runtime:** Bun
- **Repo:** `~/.openclaw/workspace/mission-control-dashboard/`
- **Branch strategy:** `main` is the single branch, served on port 3000. No dev branch.
- **Correct sources:** See `SOURCES.md` → "TanStack Start Project"

---

## Dependencies

Key technologies used across the project:

| Category | Technology | Notes |
|----------|-----------|-------|
| Framework | TanStack Start | Full-stack React with SSR |
| UI | React 18+ | Component library |
| Build | Vite | Bundler & dev server |
| CSS | Tailwind CSS | Utility-first styling |
| Components | shadcn/ui | Component system |
| Runtime | Bun | JS runtime & package manager |

For the full dependency list, see `mission-control-dashboard/package.json`.

---

## SSH Configuration

| Host | SSH Key | Account / Purpose |
|---|---|---|
| `github.com` | `~/.ssh/id_ed25519_spacemonkey` | spacemonkey-home account (workspace repo) |
| `github.com-rmk` | `~/.ssh/id_ed25519_rmk` | rmk4ts2jjw-create account (mc-* repos) |

- Always use `git@github.com-rmk:` prefix for mc-* repos (mc-prod, mc-dev, mc-lovable, mc-replit)
- See `docs/workflow.md` for the full four-repository structure and rules
