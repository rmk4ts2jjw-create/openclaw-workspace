---
name: "mac-proxy-manage"
description: "Mac proxy (nginx) management on Docker host. Start/stop/restart, config updates, port mapping changes. Keeps MC accessible from iPad."
---

# Mac Proxy Management Skill

## Purpose
Manages the nginx reverse proxy on the Docker host (192.168.68.50) that makes Mission Control accessible from iPad and other devices on the network.

## Why It Should Exist
- The mac-proxy container broke this week when its config mount pointed to a deleted path (`/home/oreo/...`)
- Proxy setup requires recreating the container with correct volume mounts — a non-obvious procedure
- Port mappings (13000→3000, 18889→3001) are easy to forget
- When the proxy breaks, iPad access to MC is lost entirely

## Expected Frequency
Low — the proxy is stable once set up, but when it breaks, recovery is urgent and currently requires debugging from scratch.

## Current State
- Container: `mac-proxy` on Docker host (192.168.68.50)
- Image: `nginx:alpine`
- Ports: 13000→MC prod (3000), 18889→MC dev (3001)
- Config: `/home/openclaw/docker/mac-proxy/`

## In Scope
- Container lifecycle: start, stop, restart, recreate
- nginx config: adding/removing server blocks, port mapping changes
- Health check: verify proxy forwards requests correctly to MC prod and dev
- Log inspection: nginx error/access logs via `docker logs`
- Volume mount recovery: fix broken config mounts (as happened this week)

## Out of Scope
- MC application changes (port numbers, routes) — handled by mc-dashboard-deploy skill
- Docker host SSH key management — infrastructure concern
- Wekan or other host-port-80 services that conflict with proxy bind
- TLS/SSL termination — proxy is plain HTTP on local network

## Overlap with Existing Skills
None.

## Implementation
New skill. Documents container creation command, nginx config structure, port mapping reference, health check commands, troubleshooting for bind failures and config errors.

## Acceptance Criteria
1. **Proxy recovery is complete**: Given a stopped or broken mac-proxy container, the skill's recovery procedure results in both port 13000 and 18889 forwarding to their respective MC targets, verified by HTTP 200 on both ports.
2. **Config changes are reloadable**: After modifying nginx config in `/home/openclaw/docker/mac-proxy/conf.d/`, the skill's reload command (`docker exec mac-proxy nginx -s reload`) applies changes without container restart, verified by hitting the proxied endpoint.
3. **Port conflicts are detected**: When the skill's health check receives HTTP 000 (connection refused) on a proxied port, the diagnostic steps identify whether the issue is (a) MC app not running, (b) proxy not running, or (c) port conflict on the Docker host.
