#!/bin/bash
# error-spike-watchdog.sh — Monitor gateway.log for error spikes every 15 min
# If error count > 20 in the last 15 minutes, write alert to alerts.json
# Shell-only, no AI tokens burned

GATEWAY_LOG="/Users/spacemonkey/.openclaw/logs/gateway.log"
ALERTS_FILE="/Users/spacemonkey/.openclaw/workspace/data/alerts.json"
LOG_FILE="/Users/spacemonkey/.openclaw/workspace/logs/error-spike-watchdog.log"
ERROR_THRESHOLD=20           # alert if >20 errors in 15-minute window
WINDOW_MIN=15

# Calculate the cutoff timestamp: now - 15 minutes in ISO 8601
# On macOS: date -v -15M
CUTOFF=$(date -v -${WINDOW_MIN}M '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)
if [ -z "$CUTOFF" ]; then
    # Fallback for non-macOS: try GNU date or perl
    CUTOFF=$(perl -e 'use POSIX qw(strftime); print strftime("%Y-%m-%dT%H:%M:%S", localtime(time()-(${WINDOW_MIN}*60)))')
fi

log() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z'): $1" >> "$LOG_FILE"
}

# Check if gateway log exists
if [ ! -f "$GATEWAY_LOG" ]; then
    log "WARNING: Gateway log not found at $GATEWAY_LOG"
    exit 0
fi

# Efficient approach: use awk to count error lines in the time window.
# Gateway log lines start with ISO 8601: 2026-05-20T21:44:52.208+01:00
# Error indicators: [warn], res ✗, ⚠️, errorCode=, errorMessage=
#
# awk compares the timestamp prefix lexicographically against the cutoff string.
# Since both are ISO 8601, string comparison works correctly.

ERROR_COUNT=$(awk -v cutoff="$CUTOFF" '
{
    # Extract timestamp: first 19 chars should be like 2026-05-20T21:44:52
    ts = substr($0, 1, 19)
    if (ts >= cutoff) {
        if (/\[warn\]/ || /res ✗/ || /⚠️/ || /errorCode=/ || /errorMessage=/) {
            count++
        }
    }
}
END { print count+0 }
' "$GATEWAY_LOG")

log "Error count in last ${WINDOW_MIN}min: $ERROR_COUNT (threshold: $ERROR_THRESHOLD)"

# Check threshold and write alert
if (( ERROR_COUNT > ERROR_THRESHOLD )); then
    msg="Gateway error spike: $ERROR_COUNT errors in ${WINDOW_MIN}min window (threshold: $ERROR_THRESHOLD)"
    log "ALERT: $msg"

    # Read existing alerts
    EXISTING="[]"
    if [ -f "$ALERTS_FILE" ]; then
        EXISTING=$(cat "$ALERTS_FILE")
    fi

    # Append new alert and cap at 100
    echo "$EXISTING" | python3 -c "
import json, sys
from datetime import datetime, timezone
alerts = json.load(sys.stdin)
alerts.append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'severity': 'critical',
    'metric': 'gateway-error-spike',
    'message': sys.argv[1],
    'value': int(sys.argv[2]),
    'threshold': int(sys.argv[3])
})
if len(alerts) > 100:
    alerts = alerts[-100:]
print(json.dumps(alerts, indent=2))
" "$msg" "$ERROR_COUNT" "$ERROR_THRESHOLD" > "$ALERTS_FILE"

    log "Wrote error spike alert to $ALERTS_FILE"
fi

exit 0
