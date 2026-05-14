#!/bin/bash
# ── WD MyCloud Mount Check ──────────────────────────────────────────────────
# Verifies /Volumes/Public-1 exists and is writable.
# Returns 0 if OK, 1 if unavailable.
# Timestamp all checks to log.

MOUNT_POINT="/Volumes/Public-1"
LOG_FILE="$HOME/.openclaw/workspace/logs/mount-check.log"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check if mount exists
if [ ! -d "$MOUNT_POINT" ]; then
  echo "[$TIMESTAMP] ERROR: $MOUNT_POINT not found" >> "$LOG_FILE"
  echo "MOUNT_MISSING: $MOUNT_POINT unavailable at $TIMESTAMP" > "$ALERT_FILE"
  exit 1
fi

# Check if writable
if [ ! -w "$MOUNT_POINT" ]; then
  echo "[$TIMESTAMP] ERROR: $MOUNT_POINT not writable" >> "$LOG_FILE"
  echo "MOUNT_READONLY: $MOUNT_POINT not writable at $TIMESTAMP" > "$ALERT_FILE"
  exit 1
fi

# Success
echo "[$TIMESTAMP] OK: $MOUNT_POINT exists and writable" >> "$LOG_FILE"
# Clear alert if it exists
[ -f "$ALERT_FILE" ] && rm "$ALERT_FILE"
exit 0
