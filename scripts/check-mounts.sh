#!/bin/bash
# ── WD MyCloud Mount Check & Auto-Reconnect ─────────────────────────────────
# Verifies /Volumes/Public exists and is writable.
# If mount is dead, attempts to remount via SMB.
# Returns 0 if OK, 1 if unavailable after remount attempt.
#
# CONFIG:
#   MYCLOUD_HOST  — NetBIOS name or IP of the WD MyCloud
#   MYCLOUD_SHARE — Share name to mount (NOT the TimeMachine slice)
#   MOUNT_POINT   — Local mount path

MYCLOUD_HOST="${MYCLOUD_HOST:-MyCloud-1E4N74}"
MYCLOUD_SHARE="${MYCLOUD_SHARE:-Public}"
MOUNT_POINT="/Volumes/Public"
LOG_FILE="$HOME/.openclaw/workspace/logs/mount-check.log"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"

mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check if mount exists and is writable
check_mount() {
  if [ ! -d "$MOUNT_POINT" ]; then
    return 1
  fi
  if [ ! -w "$MOUNT_POINT" ]; then
    return 1
  fi
  # Try a quick write test to catch stale mounts
  if ! touch "$MOUNT_POINT/.mount-test-$$" 2>/dev/null; then
    return 1
  fi
  rm -f "$MOUNT_POINT/.mount-test-$$" 2>/dev/null
  return 0
}

if check_mount; then
  echo "[$TIMESTAMP] OK: $MOUNT_POINT exists and writable" >> "$LOG_FILE"
  [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
  exit 0
fi

# Mount is dead or stale — log and attempt remount
echo "[$TIMESTAMP] WARN: $MOUNT_POINT unavailable, attempting remount..." >> "$LOG_FILE"

# First check if the MyCloud host is reachable
if ! ping -c 1 -t 3 "$MYCLOUD_HOST" >/dev/null 2>&1; then
  echo "[$TIMESTAMP] ERROR: $MYCLOUD_HOST not responding to ping" >> "$LOG_FILE"
  echo "HOST_DOWN: $MYCLOUD_HOST unreachable at $TIMESTAMP" > "$ALERT_FILE"
  exit 1
fi

# Unmount stale mount first
if mount | grep -q "$MOUNT_POINT"; then
  umount -f "$MOUNT_POINT" 2>/dev/null || diskutil unmount force "$MOUNT_POINT" 2>/dev/null
  sleep 2
fi

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"

# Mount via SMB using guest auth
# Format: //guest@HOST/SHARE  (no password needed for public shares)
MOUNT_URL="//guest@${MYCLOUD_HOST}/${MYCLOUD_SHARE}"
if mount -t smbfs "$MOUNT_URL" "$MOUNT_POINT" 2>/dev/null; then
  sleep 2
  if check_mount; then
    echo "[$TIMESTAMP] OK: Remounted $MOUNT_POINT from ${MYCLOUD_HOST}/${MYCLOUD_SHARE}" >> "$LOG_FILE"
    [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
    exit 0
  fi
fi

# Remount failed
echo "[$TIMESTAMP] ERROR: Failed to remount $MOUNT_POINT from ${MOUNT_URL}" >> "$LOG_FILE"
echo "MOUNT_FAILED: $MOUNT_POINT unavailable at $TIMESTAMP (host: ${MYCLOUD_HOST})" > "$ALERT_FILE"
exit 1
