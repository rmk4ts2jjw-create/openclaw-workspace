#!/bin/bash
# ── Storage Migration Script ─────────────────────────────────────────────────
# Moves logs, archives, and historical data to WD MyCloud.
# Keeps symlinks in place for seamless local access.
# Run only after mount validation passes.

set -euo pipefail

MOUNT_POINT="/Volumes/Public"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"
LOG_FILE="$HOME/.openclaw/workspace/logs/migration.log"
LOCAL_WORKSPACE="$HOME/.openclaw/workspace"
CLOUD_BASE="$MOUNT_POINT/OpenClawData"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
  echo "$1"
}

# ── Pre-flight checks ────────────────────────────────────────────────────────
if [ -f "$ALERT_FILE" ]; then
  log "ERROR: Mount alert file exists — aborting migration"
  exit 1
fi

if [ ! -d "$MOUNT_POINT" ] || [ ! -w "$MOUNT_POINT" ]; then
  log "ERROR: $MOUNT_POINT not available — aborting migration"
  exit 1
fi

log "Starting storage migration..."

# ── Create cloud directory structure ─────────────────────────────────────────
mkdir -p "$CLOUD_BASE"/{logs,archives,memory,backups}

# ── Migrate logs ─────────────────────────────────────────────────────────────
# Move logs older than 7 days to cloud, keep recent logs local
if [ -d "$LOCAL_WORKSPACE/logs" ]; then
  find "$LOCAL_WORKSPACE/logs" -name "*.log" -mtime +7 -type f | while read -r logfile; do
    filename=$(basename "$logfile")
    cp "$logfile" "$CLOUD_BASE/logs/$filename"
    # Keep local copy for 30 days, then remove
    log "Migrated log: $filename"
  done
fi

# ── Migrate memory archives ──────────────────────────────────────────────────
# Move daily memory files older than 30 days to cloud
if [ -d "$LOCAL_WORKSPACE/memory" ]; then
  find "$LOCAL_WORKSPACE/memory" -name "20*.md" -mtime +30 -type f | while read -r memfile; do
    filename=$(basename "$memfile")
    cp "$memfile" "$CLOUD_BASE/memory/$filename"
    log "Migrated memory: $filename"
  done
fi

# ── Create symlinks for seamless access ──────────────────────────────────────
# Logs symlink
if [ -d "$CLOUD_BASE/logs" ] && [ ! -L "$LOCAL_WORKSPACE/logs/archive" ]; then
  ln -sf "$CLOUD_BASE/logs" "$LOCAL_WORKSPACE/logs/archive"
  log "Created symlink: logs/archive -> cloud"
fi

# Memory symlink
if [ -d "$CLOUD_BASE/memory" ] && [ ! -L "$LOCAL_WORKSPACE/memory/archive" ]; then
  ln -sf "$CLOUD_BASE/memory" "$LOCAL_WORKSPACE/memory/archive"
  log "Created symlink: memory/archive -> cloud"
fi

# ── Disk space monitoring ────────────────────────────────────────────────────
LOCAL_FREE=$(df -g "$LOCAL_WORKSPACE" | tail -1 | awk '{print $4}')
CLOUD_FREE=$(df -g "$CLOUD_BASE" | tail -1 | awk '{print $4}')

log "Local free space: ${LOCAL_FREE}GB"
log "Cloud free space: ${CLOUD_FREE}GB"

if [ "$LOCAL_FREE" -lt 20 ]; then
  log "WARNING: Local free space below 20GB (${LOCAL_FREE}GB)"
fi

# ── Write status file ────────────────────────────────────────────────────────
cat > "$LOCAL_WORKSPACE/logs/migration-status.json" << EOF
{
  "lastMigration": "$TIMESTAMP",
  "localFreeGB": $LOCAL_FREE,
  "cloudFreeGB": $CLOUD_FREE,
  "cloudPath": "$CLOUD_BASE",
  "status": "ok"
}
EOF

log "Migration complete."
exit 0
