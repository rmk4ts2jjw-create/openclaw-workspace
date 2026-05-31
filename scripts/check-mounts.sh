#!/bin/bash
# ── WD MyCloud Mount Check & Auto-Reconnect ─────────────────────────────────
# Verifies /Volumes/Public exists and is writable.
# If mount is dead, attempts to remount via SMB.
# Returns 0 if OK, 1 if unavailable after remount attempt.

MOUNT_POINT="/Volumes/Public"
SMB_URL="smb://MyCloud-1E4N74/Public"
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
  [ -f "$ALERT_FILE" ] && rm "$ALERT_FILE"
  exit 0
fi

# Mount is dead or stale — attempt remount
echo "[$TIMESTAMP] WARN: $MOUNT_POINT unavailable, attempting remount..." >> "$LOG_FILE"

# Unmount stale mount first
if mount | grep -q "$MOUNT_POINT"; then
  umount "$MOUNT_POINT" 2>/dev/null || diskutil unmount "$MOUNT_POINT" 2>/dev/null
  sleep 2
fi

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"

# Mount via SMB (guest auth, no password)
if mount -t smbfs "//$SMB_URL" "$MOUNT_POINT" 2>/dev/null; then
  sleep 2
  if check_mount; then
    echo "[$TIMESTAMP] OK: Remounted $MOUNT_POINT successfully" >> "$LOG_FILE"
    [ -f "$ALERT_FILE" ] && rm "$ALERT_FILE"
    exit 0
  fi
fi

# Remount failed
echo "[$TIMESTAMP] ERROR: Failed to remount $MOUNT_POINT" >> "$LOG_FILE"
echo "MOUNT_FAILED: $MOUNT_POINT unavailable at $TIMESTAMP" > "$ALERT_FILE"
exit 1
