#!/bin/bash
# ── Safe Backup Script ──────────────────────────────────────────────────────
# Checks mount availability before backing up. Skips if mount is unavailable.

set -euo pipefail

MOUNT_POINT="/Volumes/Public-1"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"
LOG_FILE="$HOME/.openclaw/workspace/logs/backup.log"
SOURCE_DIR="$HOME/.openclaw/workspace"
BACKUP_DIR="$MOUNT_POINT/OpenClawData"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE_STAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Check for previous mount alert
if [ -f "$ALERT_FILE" ]; then
  echo "[$TIMESTAMP] WARNING: Mount alert file exists — skipping backup" >> "$LOG_FILE"
  echo "SKIPPED: Mount alert detected at $TIMESTAMP"
  exit 1
fi

# Verify mount exists and is writable
if [ ! -d "$MOUNT_POINT" ] || [ ! -w "$MOUNT_POINT" ]; then
  echo "[$TIMESTAMP] ERROR: $MOUNT_POINT not available — backup skipped" >> "$LOG_FILE"
  echo "MOUNT_MISSING: $MOUNT_POINT unavailable at $TIMESTAMP" > "$ALERT_FILE"
  echo "SKIPPED: Mount unavailable at $TIMESTAMP"
  exit 1
fi

# Create backup
BACKUP_NAME="openclaw-backup-${DATE_STAMP}.tar.gz"
echo "[$TIMESTAMP] Starting backup: $BACKUP_NAME" >> "$LOG_FILE"

cd "$SOURCE_DIR"
tar -czf "/tmp/$BACKUP_NAME" \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='dist' \
  --exclude='tmp' \
  --exclude='*.log' \
  data/ \
  scripts/ \
  AGENTS.md \
  SOUL.md \
  USER.md \
  MEMORY.md \
  TOOLS.md \
  IDENTITY.md \
  2>/dev/null

# Move to backup directory
mv "/tmp/$BACKUP_NAME" "$BACKUP_DIR/$BACKUP_NAME"

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)

# Clean old backups (keep last 30)
cd "$BACKUP_DIR"
ls -t openclaw-backup-*.tar.gz 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true

echo "[$TIMESTAMP] Backup complete: $BACKUP_NAME ($BACKUP_SIZE)" >> "$LOG_FILE"
echo "OK: $BACKUP_NAME ($BACKUP_SIZE)"
exit 0
