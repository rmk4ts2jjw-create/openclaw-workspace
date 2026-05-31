#!/bin/bash
# OpenClaw Quick Backup — Config only, runs fast
# Backs up just the essential config and workspace files

set -euo pipefail

SOURCE_DIR="$HOME/.openclaw"
BACKUP_BASE="/Volumes/Public/openclaw-agent-backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Check backup target is mounted
if [ ! -d "/Volumes/Public" ]; then
    echo "ERROR: Backup target /Volumes/Public is not mounted"
    echo "MOUNT_ALERT: Backup failed — /Volumes/Public not mounted at $(date)" > "$HOME/.openclaw/workspace/data/mount-alert.txt"
    exit 1
fi

mkdir -p "$BACKUP_BASE/backups/quick" "$BACKUP_BASE/logs"

BACKUP_FILE="$BACKUP_BASE/backups/quick/openclaw-quick_$TIMESTAMP.tar.gz"

tar -czf "$BACKUP_FILE" \
    -C "$HOME" \
    .openclaw/openclaw.json \
    .openclaw/agents/ \
    .openclaw/workspace/ \
    .openclaw/memory/ \
    .openclaw/identity/ \
    .openclaw/plugins/ \
    .openclaw/plugin-skills/ 2>/dev/null || true

echo "Quick backup: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Keep only last 5 quick backups
cd "$BACKUP_BASE/backups/quick" && ls -t openclaw-quick_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
