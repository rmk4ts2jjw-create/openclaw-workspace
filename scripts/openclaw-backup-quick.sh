#!/bin/bash
# OpenClaw Quick Backup — Config + workspace, runs fast
# Backs up essential config, workspace, and MC dashboard source to WD MyCloud.
#
# Target: /Volumes/Public/openclaw-agent-backup/backups/quick/

set -euo pipefail

SOURCE_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$SOURCE_DIR/workspace"
MOUNT_POINT="/Volumes/Public"
BACKUP_BASE="$MOUNT_POINT/openclaw-agent-backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

mkdir -p "$(dirname "$LOG_FILE")"

# ── 1. Check mount ─────────────────────────────────────────────────────────

if [ ! -d "$MOUNT_POINT" ]; then
  echo "ERROR: Backup target $MOUNT_POINT is not mounted"
  echo "MOUNT_ALERT: Quick backup failed — $MOUNT_POINT not mounted at $(date)" > "$WORKSPACE_DIR/data/mount-alert.txt"
  exit 1
fi

if ! touch "$MOUNT_POINT/.backup-test-$$" 2>/dev/null; then
  echo "ERROR: Backup target $MOUNT_POINT is not writable"
  echo "MOUNT_READONLY: $MOUNT_POINT not writable at $(date)" > "$WORKSPACE_DIR/data/mount-alert.txt"
  exit 1
fi
rm -f "$MOUNT_POINT/.backup-test-$$" 2>/dev/null

# ── 2. Backup ──────────────────────────────────────────────────────────────

mkdir -p "$BACKUP_BASE/backups/quick" "$BACKUP_BASE/logs"

BACKUP_FILE="$BACKUP_BASE/backups/quick/openclaw-quick_$TIMESTAMP.tar.gz"

tar -czf "$BACKUP_FILE" \
  -C "$HOME" \
  --exclude='.openclaw/tmp' \
  --exclude='.openclaw/logs' \
  --exclude='.openclaw/agents/*/sessions' \
  --exclude='.openclaw/media' \
  --exclude='.openclaw/.freeride-cache.json' \
  --exclude='.openclaw/browser' \
  --exclude='.openclaw/cron/runs' \
  --exclude='workspace/node_modules' \
  --exclude='workspace/.git' \
  --exclude='workspace/dist' \
  --exclude='workspace/tmp' \
  --exclude='workspace/raw/sources' \
  --exclude='workspace/mission-control-dashboard/node_modules' \
  --exclude='workspace/mission-control-dashboard/.git' \
  --exclude='workspace/mission-control-dashboard/dist' \
  --exclude='workspace/mission-control-dashboard-dev/node_modules' \
  --exclude='workspace/mission-control-dashboard-dev/.git' \
  --exclude='workspace/mission-control-dashboard-dev/dist' \
  .openclaw/openclaw.json \
  .openclaw/workspace/ \
  .openclaw/memory/ \
  .openclaw/identity/ \
  .openclaw/plugins/ \
  .openclaw/plugin-skills/ \
  .openclaw/skills/ \
  2>/dev/null || true

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Quick backup: $BACKUP_FILE ($BACKUP_SIZE)"

# ── 3. Keep only last 5 quick backups ─────────────────────────────────────

cd "$BACKUP_BASE/backups/quick" && ls -t openclaw-quick_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

exit 0
