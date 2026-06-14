# FRAMEWORK.md — Development Authority & Index

**Purpose:** Ensure every agent uses the right framework, the right repo, and the right workflow.

**Repository Authority:** `SOURCES.md` is the single source of truth for canonical documentation URLs. See also `docs/sources.md`.

---

## Documentation Index

Detailed rules live in `docs/`:
- `docs/framework.md` — Framework selection guide, build tool rules, anti-patterns, gotchas
- `docs/roles.md` — Agent roles, operations engine, security rules, component rules
- `docs/routes.md` — Routes manifest + testing procedure
- `docs/stack.md` — Tech stack, dependencies, SSH configuration
- `docs/workflow.md` — Dev→Prod workflow, git rules, merge checklist, four-repository structure
- `docs/sources.md` — External documentation references, compatibility matrix, agent rules

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

## Related Files

- **`SOURCES.md`** — Canonical documentation URLs (workspace root, full version)
- **`AGENTS.md`** — Agent work rules (includes source selection rules summary)
