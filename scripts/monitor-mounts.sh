#!/bin/bash
# monitor-mounts.sh — Mount + Disk monitor
# Called by cron every 15 minutes
# Pure shell — zero model calls

WORKSPACE="$HOME/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/monitor-mounts.log"
INCIDENTS_FILE="$WORKSPACE/data/incidents.json"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

echo "[$(timestamp)] [MONITOR] Running mount + disk check..." >> "$LOG_FILE"

# ── 1. Check WD MyCloud mount ───────────────────────────────────────────────
MOUNT_OK=true
if ! mount | grep -q "/Volumes/Public" && ! mount | grep -q "/Volumes/OpenClaw-WD"; then
    MOUNT_OK=false
    echo "[$(timestamp)] [MONITOR] WD MyCloud mount missing" >> "$LOG_FILE"

    # Check if there's already an open incident for this
    HAS_OPEN=$(python3 -c "
import json, os
if not os.path.exists('$INCIDENTS_FILE'): print('false')
else:
    incidents = json.load(open('$INCIDENTS_FILE'))
    for i in incidents:
        if i.get('status') != 'RESOLVED' and 'wd-mycloud' in i.get('tags', []) and 'mount' in i.get('tags', []):
            print('true')
            exit()
    print('false')
" 2>/dev/null || echo "false")

    if [ "$HAS_OPEN" = "false" ]; then
        echo "[$(timestamp)] [MONITOR] No open mount incident — triggering auto-detect" >> "$LOG_FILE"
        # Trigger the auto-detect script which will create the incident
        bash "$WORKSPACE/scripts/auto-detect-incidents.sh" >> "$LOG_FILE" 2>&1 || true
    else
        echo "[$(timestamp)] [MONITOR] Open mount incident already exists — skipping" >> "$LOG_FILE"
    fi
else
    echo "[$(timestamp)] [MONITOR] Mount OK" >> "$LOG_FILE"
fi

# ── 2. Check disk space ─────────────────────────────────────────────────────
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 85 ]; then
    echo "[$(timestamp)] [MONITOR] Disk critical: ${DISK_PCT}%" >> "$LOG_FILE"

    HAS_OPEN=$(python3 -c "
import json, os
if not os.path.exists('$INCIDENTS_FILE'): print('false')
else:
    incidents = json.load(open('$INCIDENTS_FILE'))
    for i in incidents:
        if i.get('status') != 'RESOLVED' and 'disk' in i.get('tags', []):
            print('true')
            exit()
    print('false')
" 2>/dev/null || echo "false")

    if [ "$HAS_OPEN" = "false" ]; then
        echo "[$(timestamp)] [MONITOR] No open disk incident — triggering auto-detect" >> "$LOG_FILE"
        bash "$WORKSPACE/scripts/auto-detect-incidents.sh" >> "$LOG_FILE" 2>&1 || true
    else
        echo "[$(timestamp)] [MONITOR] Open disk incident already exists — skipping" >> "$LOG_FILE"
    fi
else
    echo "[$(timestamp)] [MONITOR] Disk OK: ${DISK_PCT}%" >> "$LOG_FILE"
fi

echo "[$(timestamp)] [MONITOR] Complete" >> "$LOG_FILE"
