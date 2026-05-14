#!/bin/bash
# ── Combined Maintenance Script ──────────────────────────────────────────────
# Runs mount check, disk monitor, and safe backup in sequence.
# Called by cron/LaunchAgent.

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/maintenance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"

echo "[$TIMESTAMP] === Maintenance run started ===" >> "$LOG_FILE"

# 1. Mount check
echo "[$TIMESTAMP] Running mount check..." >> "$LOG_FILE"
if bash "$WORKSPACE/scripts/check-mounts.sh" >> "$LOG_FILE" 2>&1; then
  echo "[$TIMESTAMP] Mount check: OK" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] Mount check: FAILED — skipping backup" >> "$LOG_FILE"
  exit 1
fi

# 2. Disk monitor
echo "[$TIMESTAMP] Running disk monitor..." >> "$LOG_FILE"
bash "$WORKSPACE/scripts/disk-monitor.sh" >> "$LOG_FILE" 2>&1 || true

# 3. Safe backup (only on certain days to avoid excessive writes)
DAY_OF_WEEK=$(date '+%u')  # 1=Mon, 7=Sun
if [ "$DAY_OF_WEEK" -eq 7 ] || [ "$DAY_OF_WEEK" -eq 1 ]; then
  echo "[$TIMESTAMP] Running safe backup (weekly)..." >> "$LOG_FILE"
  bash "$WORKSPACE/scripts/safe-backup.sh" >> "$LOG_FILE" 2>&1 || true
fi

# 4. Migration (monthly)
DAY_OF_MONTH=$(date '+%d')
if [ "$DAY_OF_MONTH" = "01" ]; then
  echo "[$TIMESTAMP] Running storage migration (monthly)..." >> "$LOG_FILE"
  bash "$WORKSPACE/scripts/migrate-storage.sh" >> "$LOG_FILE" 2>&1 || true
fi

echo "[$TIMESTAMP] === Maintenance run complete ===" >> "$LOG_FILE"
