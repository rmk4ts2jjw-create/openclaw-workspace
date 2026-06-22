#!/bin/bash
# ── WD MyCloud Mount Script for Public and OpenClaw-WD Shares ─────────────────────
# Ensures both /Volumes/Public and /Volumes/OpenClaw-WD are mounted and writable.
# Intended to be run via cron every 10 minutes to prevent SMB timeout.
#
# NOTE: This script uses sudo for mkdir and mount operations. The user must have
#       passwordless sudo for these commands, or the script will fail.
#       To set up passwordless sudo for the specific commands, add the following
#       to /etc/sorsders.d/wd-mycloud (using visudo):
#       spacemonkey ALL=(ROOT) NOPASSWD: /bin/mkdir -p /Volumes/Public, /bin/mkdir -p /Volumes/OpenClaw-WD, /sbin/mount -t smbfs //guest@*/Public /Volumes/Public, /sbin/mount -t smbfs //guest@*/OpenClaw-WD /Volumes/OpenClaw-WD
#
# CONFIG:
#   MYCLOUD_HOST  — NetBIOS name or IP of the WD MyCloud (default: MyCloud-1E4N74)
#   MYCLOUD_PUBLIC_SHARE — Share name for Public (default: Public)
#   MYCLOUD_OPENCLAW_SHARE — Share name for OpenClaw-WD (default: OpenClaw-WD)
#   LOG_FILE — Where to log output

MYCLOUD_HOST="${MYCLOUD_HOST:-MyCloud-1E4N74}"
MYCLOUD_PUBLIC_SHARE="${MYCLOUD_PUBLIC_SHARE:-Public}"
MYCLOUD_OPENCLAW_SHARE="${MYCLOUD_OPENCLAW_SHARE:-OpenClaw-WD}"
LOG_FILE="$HOME/.openclaw/workspace/logs/wd-mycloud-mount.log"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to check if a mount point is valid (exists, writable, and can touch a file)
check_mount() {
  local MOUNT_POINT="$1"
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

# Function to mount a share given mount point, host, and share name
mount_share() {
  local MOUNT_POINT="$1"
  local SHARE_NAME="$2"
  local MOUNT_URL="//guest@${MYCLOUD_HOST}/${SHARE_NAME}"

  echo "[$TIMESTAMP] Attempting to mount $SHARE_NAME at $MOUNT_POINT" >> "$LOG_FILE"

  # Unmount stale mount first if it exists but is not valid
  if mount | grep -q "$MOUNT_POINT"; then
    if ! check_mount "$MOUNT_POINT"; then
      echo "[$TIMESTAMP] Stale mount detected at $MOUNT_POINT, forcing unmount" >> "$LOG_FILE"
      sudo umount -f "$MOUNT_POINT" 2>/dev/null || sudo diskutil unmount force "$MOUNT_POINT" 2>/dev/null
      sleep 2
    else
      # Already mounted and valid
      return 0
    fi
  fi

  # Ensure mount point exists (requires sudo)
  if ! sudo mkdir -p "$MOUNT_POINT"; then
    echo "[$TIMESTAMP] Failed to create mount point $MOUNT_POINT" >> "$LOG_FILE"
    return 1
  fi

  # Mount via SMB using guest auth (requires sudo)
  if sudo mount -t smbfs "$MOUNT_URL" "$MOUNT_POINT" 2>/dev/null; then
    sleep 2
    if check_mount "$MOUNT_POINT"; then
      echo "[$TIMESTAMP] Successfully mounted $MOUNT_POINT from ${MYCLOUD_HOST}/${SHARE_NAME}" >> "$LOG_FILE"
      [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
      return 0
    else
      echo "[$TIMESTAMP] Mount succeeded but validation failed for $MOUNT_POINT" >> "$LOG_FILE"
      return 1
    fi
  else
    echo "[$TIMESTAMP] Failed to mount $MOUNT_POINT from ${MOUNT_URL}" >> "$LOG_FILE"
    echo "MOUNT_FAILED: $MOUNT_POINT unavailable at $TIMESTAMP (host: ${MYCLOUD_HOST})" > "$ALERT_FILE"
    return 1
  fi
}

# Main logic
echo "[$TIMESTAMP] ===== WD MyCloud Mount Script Started =====" >> "$LOG_FILE"

# Check and mount Public share
if check_mount "/Volumes/Public"; then
  echo "[$TIMESTAMP] OK: /Volumes/Public is already mounted and writable" >> "$LOG_FILE"
else
  mount_share "/Volumes/Public" "$MYCLOUD_PUBLIC_SHARE"
fi

# Check and mount OpenClaw-WD share
if check_mount "/Volumes/OpenClaw-WD"; then
  echo "[$TIMESTAMP] OK: /Volumes/OpenClaw-WD is already mounted and writable" >> "$LOG_FILE"
else
  mount_share "/Volumes/OpenClaw-WD" "$MYCLOUD_OPENCLAW_SHARE"
fi

echo "[$TIMESTAMP] ===== WD MyCloud Mount Script Completed =====" >> "$LOG_FILE"
exit 0