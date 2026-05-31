#!/bin/bash
# ── SMB Mount Keepalive ─────────────────────────────────────────────────────
# Pings the WD MyCloud mount every 5 minutes to prevent SMB timeout.
# Lightweight — just touches a temp file and removes it.

MOUNT_POINT="/Volumes/Public"

if [ -d "$MOUNT_POINT" ] && [ -w "$MOUNT_POINT" ]; then
  touch "$MOUNT_POINT/.keepalive" 2>/dev/null && rm -f "$MOUNT_POINT/.keepalive" 2>/dev/null
fi
