#!/bin/bash
# OpenClaw Restore Script
# Restores OpenClaw from a backup archive
# Usage: ./openclaw-restore.sh [backup-file.tar.gz]
# If no file specified, uses the latest backup

set -euo pipefail

BACKUP_BASE="/Volumes/Public-1/openclaw-agent-backup"
RESTORE_DIR="$HOME/.openclaw"

# === Find backup file ===
if [ -n "${1:-}" ]; then
    BACKUP_FILE="$1"
else
    # Find the latest full backup
    BACKUP_FILE=$(ls -t "$BACKUP_BASE/backups/daily"/openclaw-full_*.tar.gz 2>/dev/null | head -1)
    if [ -z "$BACKUP_FILE" ]; then
        # Fall back to weekly
        BACKUP_FILE=$(ls -t "$BACKUP_BASE/backups/weekly"/openclaw-weekly_*.tar.gz 2>/dev/null | head -1)
    fi
    if [ -z "$BACKUP_FILE" ]; then
        # Fall back to quick
        BACKUP_FILE=$(ls -t "$BACKUP_BASE/backups/quick"/openclaw-config_*.tar.gz 2>/dev/null | head -1)
    fi
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: No backup file found."
    echo "Usage: $0 [backup-file.tar.gz]"
    echo ""
    echo "Available backups:"
    find "$BACKUP_BASE/backups" -name "*.tar.gz" -type f 2>/dev/null | sort -r | head -10
    exit 1
fi

echo "=== OpenClaw Restore ==="
echo "Backup file: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Restore target: $RESTORE_DIR"
echo ""

# === Safety: backup current state ===
if [ -d "$RESTORE_DIR" ]; then
    SAFETY_BACKUP="$RESTORE_DIR.pre-restore.$(date +%Y%m%d_%H%M%S)"
    echo "Creating safety backup of current state: $SAFETY_BACKUP"
    cp -a "$RESTORE_DIR" "$SAFETY_BACKUP"
    echo "Safety backup created."
fi

# === Stop OpenClaw if running ===
echo "Stopping OpenClaw gateway..."
openclaw gateway stop 2>/dev/null || true
sleep 2

# === Extract backup ===
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$HOME"
echo "Restore complete!"

# === Verify ===
echo ""
echo "=== Verification ==="
echo "openclaw.json: $([ -f "$RESTORE_DIR/openclaw.json" ] && echo 'OK' || echo 'MISSING')"
echo "workspace: $([ -d "$RESTORE_DIR/workspace" ] && echo 'OK' || echo 'MISSING')"
echo "agents: $([ -d "$RESTORE_DIR/agents" ] && echo 'OK' || echo 'MISSING')"
echo "memory: $([ -d "$RESTORE_DIR/memory" ] && echo 'OK' || echo 'MISSING')"
echo ""

# === Restart ===
echo "Starting OpenClaw gateway..."
openclaw gateway start 2>/dev/null || echo "Start OpenClaw manually: openclaw gateway start"
echo ""
echo "Done! OpenClaw should be running with restored configuration."
