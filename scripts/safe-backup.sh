#!/bin/bash
# ── Safe Backup Script ──────────────────────────────────────────────────────
# Backs up workspace + MC dashboard to WD MyCloud.
# Checks mount availability before backing up. Skips if mount is unavailable.
#
# Target: /Volumes/Public/openclaw-agent-backup/

set -euo pipefail

MOUNT_POINT="/Volumes/Public"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"
LOG_FILE="$HOME/.openclaw/workspace/logs/backup.log"
SOURCE_DIR="$HOME/.openclaw/workspace"
BACKUP_DIR="$MOUNT_POINT/openclaw-agent-backup/backups"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_STAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p "$(dirname "$LOG_FILE")"

# ── 1. Check mount ─────────────────────────────────────────────────────────

if [ -f "$ALERT_FILE" ]; then
  echo "[$TIMESTAMP] WARNING: Mount alert file exists — skipping backup" >> "$LOG_FILE"
  echo "SKIPPED: Mount alert detected at $TIMESTAMP"
  exit 1
fi

if [ ! -d "$MOUNT_POINT" ] || [ ! -w "$MOUNT_POINT" ]; then
  echo "[$TIMESTAMP] ERROR: $MOUNT_POINT not available — backup skipped" >> "$LOG_FILE"
  echo "MOUNT_MISSING: $MOUNT_POINT unavailable at $TIMESTAMP" > "$ALERT_FILE"
  echo "SKIPPED: Mount unavailable at $TIMESTAMP"
  exit 1
fi

# Write test to catch stale mounts
if ! touch "$MOUNT_POINT/.backup-test-$$" 2>/dev/null; then
  echo "[$TIMESTAMP] ERROR: $MOUNT_POINT not writable — backup skipped" >> "$LOG_FILE"
  echo "MOUNT_READONLY: $MOUNT_POINT not writable at $TIMESTAMP" > "$ALERT_FILE"
  echo "SKIPPED: Mount not writable at $TIMESTAMP"
  exit 1
fi
rm -f "$MOUNT_POINT/.backup-test-$$" 2>/dev/null

# ── 2. Create backup ───────────────────────────────────────────────────────

mkdir -p "$BACKUP_DIR"

BACKUP_NAME="openclaw-backup-${DATE_STAMP}.tar.gz"
BACKUP_SIZE="N/A"

echo "[$TIMESTAMP] Starting backup: $BACKUP_NAME" >> "$LOG_FILE"

cd "$SOURCE_DIR"

tar -czf "/tmp/$BACKUP_NAME" \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='dist' \
  --exclude='tmp' \
  --exclude='*.log' \
  --exclude='logs/*' \
  --exclude='raw/sources/*' \
  --exclude='mission-control-dashboard/node_modules' \
  --exclude='mission-control-dashboard/.git' \
  --exclude='mission-control-dashboard/dist' \
  --exclude='mission-control-dashboard-dev/node_modules' \
  --exclude='mission-control-dashboard-dev/.git' \
  --exclude='mission-control-dashboard-dev/dist' \
  data/ \
  scripts/ \
  logs/ \
  memory/ \
  AGENTS.md \
  SOUL.md \
  USER.md \
  MEMORY.md \
  TOOLS.md \
  IDENTITY.md \
  NIGHT_SHIFT.md \
  2>/dev/null

mv "/tmp/$BACKUP_NAME" "$BACKUP_DIR/$BACKUP_NAME"
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)

# ── 3. Clean old backups (keep last 30) ────────────────────────────────────

cd "$BACKUP_DIR"
ls -t openclaw-backup-*.tar.gz 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true

# ── 4. Save backup state ──────────────────────────────────────────────────

STATE_FILE="$MOUNT_POINT/openclaw-agent-backup/backup-state.json"
cat > "$STATE_FILE" << EOF
{
  "last_backup": "$TIMESTAMP",
  "last_backup_file": "$BACKUP_NAME",
  "last_backup_size": "$BACKUP_SIZE",
  "source_size": "$(du -sh "$SOURCE_DIR" | cut -f1)",
  "disk_free": "$(df -h / | tail -1 | awk '{print $4}')",
  "backup_disk_free": "$(df -h "$MOUNT_POINT" 2>/dev/null | tail -1 | awk '{print $4}' || echo 'N/A')"
}
EOF

echo "[$TIMESTAMP] Backup complete: $BACKUP_NAME ($BACKUP_SIZE)" >> "$LOG_FILE"
echo "OK: $BACKUP_NAME ($BACKUP_SIZE)"
exit 0
