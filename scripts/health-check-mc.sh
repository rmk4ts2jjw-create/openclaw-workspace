#!/bin/bash
# Mission Control Health Check — shell-only, zero model calls
# Checks if MC is responding on port 3000, restarts if not.
# Runs every 15 minutes via cron.

LOG_FILE="$HOME/.openclaw/logs/health-check-restart.log"
MC_DIR="$HOME/.openclaw/workspace/mission-control-dashboard"
ALERT_FILE="$HOME/.openclaw/workspace/mount-alert.txt"
MAX_RESTARTS_PER_HOUR=3

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Check if Mission Control is responding
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000/)

if [ "$STATUS" = "200" ]; then
    # All good — log only if previous check failed (we track state)
    if [ -f "$HOME/.openclaw/logs/.mc-health-bad" ]; then
        echo "$(timestamp) [OK] Mission Control recovered (HTTP $STATUS)" >> "$LOG_FILE"
        rm -f "$HOME/.openclaw/logs/.mc-health-bad"
    fi
    # Auto-detect incidents even when MC is healthy
    "$HOME/.openclaw/workspace/scripts/auto-detect-incidents.sh" 2>/dev/null
    exit 0
fi

# Not responding — mark as bad
touch "$HOME/.openclaw/logs/.mc-health-bad"
echo "$(timestamp) [DOWN] Mission Control returned HTTP $STATUS — attempting restart" >> "$LOG_FILE"

# Count restarts in the last hour
ONE_HOUR_AGO=$(date -v-1H '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')
RESTART_COUNT=$(awk -v since="$ONE_HOUR_AGO" '$0 >= since' "$LOG_FILE" 2>/dev/null | grep -c '\[DOWN\]' || echo "0")

if [ "$RESTART_COUNT" -ge "$MAX_RESTARTS_PER_HOUR" ]; then
    echo "$(timestamp) [ALERT] Mission Control restarted $RESTART_COUNT times in the last hour — manual intervention needed" >> "$LOG_FILE"
    echo "Mission Control is down and auto-restart has failed $RESTART_COUNT times in the last hour. Please check immediately." > "$ALERT_FILE"
    exit 1
fi

# Kill any stale processes on port 3000
PIDS=$(lsof -ti :3000 2>/dev/null)
if [ -n "$PIDS" ]; then
    echo "$(timestamp) [RESTART] Killing stale processes on port 3000: $PIDS" >> "$LOG_FILE"
    kill $PIDS 2>/dev/null
    sleep 2
    # Force kill if still running
    PIDS2=$(lsof -ti :3000 2>/dev/null)
    if [ -n "$PIDS2" ]; then
        kill -9 $PIDS2 2>/dev/null
        sleep 1
    fi
fi

# Start Mission Control
echo "$(timestamp) [RESTART] Starting Mission Control via bun run dev" >> "$LOG_FILE"
cd "$MC_DIR" && nohup bun run dev --host --port 3000 > /dev/null 2>&1 &
sleep 5

# Verify it came back
NEW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000/)
if [ "$NEW_STATUS" = "200" ]; then
    echo "$(timestamp) [RESTART OK] Mission Control is back (HTTP $NEW_STATUS)" >> "$LOG_FILE"
    rm -f "$HOME/.openclaw/logs/.mc-health-bad"
else
    echo "$(timestamp) [RESTART FAIL] Mission Control still not responding (HTTP $NEW_STATUS)" >> "$LOG_FILE"
    echo "Mission Control health check restart failed at $(timestamp). HTTP status: $NEW_STATUS" > "$ALERT_FILE"
    exit 1
fi

# Auto-detect incidents on every run
"$HOME/.openclaw/workspace/scripts/auto-detect-incidents.sh" 2>/dev/null
