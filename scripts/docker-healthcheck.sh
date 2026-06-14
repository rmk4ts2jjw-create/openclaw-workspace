#!/bin/bash
# docker-healthcheck.sh — Verify all containers on docker-host are running
# Runs every Monday at 08:30 BST via OpenClaw cron.
# Shell-only, no AI cost.

LOG="/Users/spacemonkey/.openclaw/workspace/logs/docker-healthcheck.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S %Z')

log() { echo "[$DATE] $1" >> "$LOG"; }

log "=== Docker Healthcheck ==="

# Get container status from docker-host
CONTAINERS=$(ssh -i ~/.ssh/id_ed25519_openclaw_infra docker-host "docker ps --format '{{.Names}}\t{{.Status}}'" 2>&1)

if [ $? -ne 0 ]; then
  log "ERROR: Failed to connect to docker-host"
  log "=== Healthcheck FAILED ==="
  exit 1
fi

TOTAL=0
RUNNING=0
DOWN_LIST=""

while IFS=$'\t' read -r name status; do
  [ -z "$name" ] && continue
  TOTAL=$((TOTAL + 1))
  if echo "$status" | grep -qi "^Up"; then
    RUNNING=$((RUNNING + 1))
    log "✅ $name: $status"
  else
    log "❌ $name: $status"
    DOWN_LIST="$DOWN_LIST $name"
  fi
done <<< "$CONTAINERS"

log "---"
log "Total: $TOTAL | Running: $RUNNING | Down: $((TOTAL - RUNNING))"

# Ensure stremio-server is running
if ! echo "$CONTAINERS" | grep -q "stremio-server"; then
  log "⚠️ stremio-server not found — attempting restart"
  ssh -i ~/.ssh/id_ed25519_openclaw_infra docker-host "docker start stremio-server" 2>&1
  if [ $? -eq 0 ]; then
    log "✅ stremio-server restarted"
  else
    log "❌ Failed to restart stremio-server"
    DOWN_LIST="$DOWN_LIST stremio-server"
  fi
fi

if [ -n "$DOWN_LIST" ]; then
  log "⚠️ CONTAINERS DOWN:$DOWN_LIST"
  log "=== Healthcheck WARNING ==="
else
  log "✅ All $TOTAL containers running"
  log "=== Healthcheck OK ==="
fi
