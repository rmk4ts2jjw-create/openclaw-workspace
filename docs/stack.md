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

## Infrastructure Access

### Docker Host (`docker-host`)
- SSH access configured and tested
- **Rules:**
  1. Never delete production containers without Andre's approval
  2. `docker compose down` / `docker compose up` requires confirmation before execution
  3. All container changes (start, stop, restart, create, delete) must be logged to incidents
  4. `docker ps` and `docker logs` are safe to run freely

### Containers (as of 2026-06-13)
| Container | Image | Status | Purpose |
|---|---|---|---|
| mac-proxy | nginx:alpine | Up 9 days | Proxy service (ports 13000, 18889) |
| open-webui | ghcr.io/open-webui/open-webui:main | Up 11 days (healthy) | Web UI (port 3000) |
| portainer | portainer/portainer-ce:latest | Up 11 days | Container management (port 9443) |
| sonarr | linuxserver/sonarr:latest | Up 11 days | TV automation (port 8989) |
| lidarr | linuxserver/lidarr:latest | Up 11 days | Music automation (port 8686) |
| radarr | linuxserver/radarr:latest | Up 11 days | Movie automation (port 7878) |
| pihole | pihole/pihole:latest | Up 11 days (healthy) | DNS ad-blocking (port 8085) |
| rdt-client | rogerfar/rdt-client | Up 11 days (healthy) | Real-Debrid client (port 6500) |
| prowlarr | linuxserver/prowlarr:latest | Up 11 days | Indexer automation (port 9696) |

---

## SSH Configuration

| Host | SSH Key | Account / Purpose |
|---|---|---|
| `github.com` | `~/.ssh/id_ed25519_spacemonkey` | spacemonkey-home account (workspace repo) |
| `github.com-rmk` | `~/.ssh/id_ed25519_rmk` | rmk4ts2jjw-create account (mc-* repos) |

- Always use `git@github.com-rmk:` prefix for mc-* repos (mc-prod, mc-dev, mc-lovable, mc-replit)
- See `docs/workflow.md` for the full four-repository structure and rules
