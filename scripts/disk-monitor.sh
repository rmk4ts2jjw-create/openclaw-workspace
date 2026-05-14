#!/bin/bash
# ── Disk Space Monitor ───────────────────────────────────────────────────────
# Checks local disk space and sends alert if below threshold.
# Run via cron every 6 hours.

set -euo pipefail

LOCAL_WORKSPACE="$HOME/.openclaw/workspace"
ALERT_FILE="$LOCAL_WORKSPACE/disk-alert.txt"
LOG_FILE="$LOCAL_WORKSPACE/logs/disk-monitor.log"
THRESHOLD_GB=20

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p "$(dirname "$LOG_FILE")"

# Get local free space in GB
LOCAL_FREE=$(df -g "$LOCAL_WORKSPACE" | tail -1 | awk '{print $4}')

echo "[$TIMESTAMP] Local free: ${LOCAL_FREE}GB" >> "$LOG_FILE"

if [ "$LOCAL_FREE" -lt "$THRESHOLD_GB" ]; then
  MSG="LOW DISK: ${LOCAL_FREE}GB free (threshold: ${THRESHOLD_GB}GB) at $TIMESTAMP"
  echo "$MSG" > "$ALERT_FILE"
  echo "[$TIMESTAMP] WARNING: $MSG" >> "$LOG_FILE"
  echo "ALERT: $MSG"
  exit 1
else
  # Clear alert if it exists
  [ -f "$ALERT_FILE" ] && rm "$ALERT_FILE"
  echo "[$TIMESTAMP] OK: ${LOCAL_FREE}GB free" >> "$LOG_FILE"
  echo "OK: ${LOCAL_FREE}GB free"
  exit 0
fi
