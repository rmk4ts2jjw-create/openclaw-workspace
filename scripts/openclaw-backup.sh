#!/bin/bash
# OpenClaw Full Backup Script
# Backs up the entire .openclaw directory + workspace to external storage
# Run from admin account or with write access to backup destination

set -euo pipefail

# === Configuration ===
SOURCE_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$SOURCE_DIR/workspace"
BACKUP_BASE="/Volumes/Public/openclaw-agent-backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DAY_OF_WEEK=$(date +"%u")  # 1=Mon, 7=Sun
DATE=$(date +"%Y-%m-%d")

# === Functions ===
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# === Pre-flight ===
if [ ! -d "$SOURCE_DIR" ]; then
    die "Source directory not found: $SOURCE_DIR"
fi

if [ ! -d "$BACKUP_BASE" ]; then
    die "Backup disk not mounted. Connect the external backup disk first."
fi

# Create backup directories
mkdir -p "$BACKUP_BASE"/{backups/{daily,weekly,monthly,quick},archives,logs,projects,sync}

# === Quick Config Backup (always runs) ===
log "Starting quick config backup..."
QUICK_DIR="$BACKUP_BASE/backups/quick"
CONFIG_BACKUP="$QUICK_DIR/openclaw-config_$TIMESTAMP.tar.gz"

tar -czf "$CONFIG_BACKUP" \
    -C "$HOME" \
    --exclude='.openclaw/tmp' \
    --exclude='.openclaw/logs' \
    --exclude='.openclaw/agents/*/sessions' \
    --exclude='.openclaw/media' \
    --exclude='.openclaw/.freeride-cache.json' \
    .openclaw/openclaw.json \
    .openclaw/agents/ \
    .openclaw/workspace/ \
    .openclaw/memory/ \
    .openclaw/identity/ \
    .openclaw/plugins/ \
    .openclaw/plugin-skills/ \
    .openclaw/skills/ 2>/dev/null || true

log "Quick config backup: $CONFIG_BACKUP ($(du -h "$CONFIG_BACKUP" | cut -f1))"

# Keep only last 3 quick backups
cd "$QUICK_DIR" && ls -t openclaw-config_*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

# === Full Daily Backup ===
log "Starting full daily backup..."
DAILY_DIR="$BACKUP_BASE/backups/daily"
FULL_BACKUP="$DAILY_DIR/openclaw-full_$TIMESTAMP.tar.gz"

tar -czf "$FULL_BACKUP" \
    -C "$HOME" \
    --exclude='.openclaw/tmp' \
    --exclude='.openclaw/agents/*/sessions/*.jsonl' \
    --exclude='.openclaw/agents/*/sessions/*.trajectory*' \
    --exclude='.openclaw/.freeride-cache.json' \
    --exclude='.openclaw/workspace/raw/sources' \
    .openclaw/ \
    .openclaw/workspace/ 2>/dev/null || true

log "Full daily backup: $FULL_BACKUP ($(du -h "$FULL_BACKUP" | cut -f1))"

# Keep only last 7 daily backups
cd "$DAILY_DIR" && ls -t openclaw-full_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

# === Weekly Backup (Sunday) ===
if [ "$DAY_OF_WEEK" = "7" ]; then
    log "Starting weekly backup..."
    WEEKLY_DIR="$BACKUP_BASE/backups/weekly"
    cp "$FULL_BACKUP" "$WEEKLY_DIR/openclaw-weekly_$DATE.tar.gz"
    log "Weekly backup created."
    
    # Keep only last 4 weekly backups
    cd "$WEEKLY_DIR" && ls -t openclaw-weekly_*.tar.gz 2>/dev/null | tail -n +5 | xargs rm -f 2>/dev/null || true
fi

# === Monthly Backup (1st of month) ===
DAY_OF_MONTH=$(date +"%d")
if [ "$DAY_OF_MONTH" = "01" ]; then
    log "Starting monthly backup..."
    MONTHLY_DIR="$BACKUP_BASE/backups/monthly"
    cp "$FULL_BACKUP" "$MONTHLY_DIR/openclaw-monthly_$DATE.tar.gz"
    log "Monthly backup created."
    
    # Keep last 12 monthly backups
    cd "$MONTHLY_DIR" && ls -t openclaw-monthly_*.tar.gz 2>/dev/null | tail -n +13 | xargs rm -f 2>/dev/null || true
fi

# === Sync workspace files (for real-time access) ===
log "Syncing workspace files..."
rsync -a --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    "$WORKSPACE_DIR/" "$BACKUP_BASE/sync/workspace/" 2>/dev/null || true

# === Save system state ===
log "Saving system state..."
STATE_FILE="$BACKUP_BASE/logs/backup-state_$DATE.json"
cat > "$STATE_FILE" << EOF
{
    "timestamp": "$TIMESTAMP",
    "date": "$DATE",
    "hostname": "$(hostname)",
    "macos_version": "$(sw_vers -productVersion)",
    "openclaw_version": "$(openclaw --version 2>/dev/null || echo 'unknown')",
    "backup_size": "$(du -h "$FULL_BACKUP" | cut -f1)",
    "config_size": "$(du -h "$CONFIG_BACKUP" | cut -f1)",
    "source_size": "$(du -sh "$SOURCE_DIR" | cut -f1)",
    "workspace_size": "$(du -sh "$WORKSPACE_DIR" | cut -f1)",
    "disk_free": "$(df -h / | tail -1 | awk '{print $4}')",
    "backup_disk_free": "$(df -h /Volumes/Backups\\ of\\ spacemonkey 2>/dev/null | tail -1 | awk '{print $4}' || echo 'N/A')"
}
EOF

# === Log ===
echo "[$TIMESTAMP] Backup complete. Full: $(du -h "$FULL_BACKUP" | cut -f1)" >> "$BACKUP_BASE/logs/backup.log"
log "Backup complete!"
log "Full backup: $FULL_BACKUP"
log "Config backup: $CONFIG_BACKUP"
