#!/bin/bash
# session-cleanup.sh — Archive session files with "takeover" errors older than 24h
# Runs every 6 hours via cron
# Shell-only, no AI tokens burned

SESSION_DIR="/Users/spacemonkey/.openclaw/agents/main/sessions"
ARCHIVE_DIR="/Users/spacemonkey/.openclaw/workspace/logs/session-archive"
ALERTS_FILE="/Users/spacemonkey/.openclaw/workspace/data/alerts.json"
LOG_FILE="/Users/spacemonkey/.openclaw/workspace/logs/session-cleanup.log"
THRESHOLD=$((24 * 60 * 60))   # 24 hours in seconds
NOW=$(date +%s)
TAKEOVER_LIMIT=5               # alert if >5 takeover errors in any single hour
TMPDIR_CLEANUP=$(mktemp -d /tmp/session-cleanup.XXXXXX)

# Ensure dirs exist
mkdir -p "$ARCHIVE_DIR"

log() {
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z'): $1" >> "$LOG_FILE"
}

log "=== Session cleanup started ==="

# Track archived count via temp file (subshell-safe)
echo "0" > "$TMPDIR_CLEANUP/archived"
echo "0" > "$TMPDIR_CLEANUP/skipped"

# Build list of candidate files (older than 24h, contain takeover, not trajectory)
CANDIDATES="$TMPDIR_CLEANUP/candidates"
: > "$CANDIDATES"

for f in "$SESSION_DIR"/*.jsonl "$SESSION_DIR"/*.reset.*; do
    [ -f "$f" ] || continue

    # Skip trajectory files — they are companions to main session files
    case "$f" in
        *.trajectory.jsonl) continue ;;
    esac

    mtime=$(stat -f %m "$f" 2>/dev/null) || continue
    age=$(( NOW - mtime ))

    if (( age > THRESHOLD )); then
        if grep -q "takeover" "$f" 2>/dev/null; then
            echo "$f" >> "$CANDIDATES"
        else
            echo $(( $(cat "$TMPDIR_CLEANUP/skipped") + 1 )) > "$TMPDIR_CLEANUP/skipped"
        fi
    fi
done

# Archive candidate files
if [ -s "$CANDIDATES" ]; then
    while IFS= read -r f; do
        [ -f "$f" ] || continue
        fname=$(basename "$f")
        dest="$ARCHIVE_DIR/$fname"

        # Avoid overwriting
        if [ -f "$dest" ]; then
            dest="$ARCHIVE_DIR/${fname}.$(date +%s)"
        fi

        cp "$f" "$dest" && rm -f "$f"

        # Also archive matching trajectory file if it exists
        traj="${f%.jsonl}.trajectory.jsonl"
        if [ -f "$traj" ]; then
            traj_name=$(basename "$traj")
            traj_dest="$ARCHIVE_DIR/$traj_name"
            [ -f "$traj_dest" ] && traj_dest="$ARCHIVE_DIR/${traj_name}.$(date +%s)"
            cp "$traj" "$traj_dest" && rm -f "$traj"
            log "ARCHIVED (trajectory): $traj_name"
        fi

        mtime=$(stat -f %m "$dest" 2>/dev/null) || mtime=$NOW
        age_h=$(( (NOW - mtime) / 3600 ))
        log "ARCHIVED: $fname (age: ${age_h}h, takeover errors found) -> $dest"
        echo $(( $(cat "$TMPDIR_CLEANUP/archived") + 1 )) > "$TMPDIR_CLEANUP/archived"
    done < "$CANDIDATES"
fi

archived=$(cat "$TMPDIR_CLEANUP/archived")
skipped=$(cat "$TMPDIR_CLEANUP/skipped")
log "Archived: $archived files, Skipped (no takeover): $skipped files"

# --- Check takeover error spikes (>5 in any single hour across ALL session files) ---
: > "$TMPDIR_CLEANUP/takeover_hours"

for f in "$SESSION_DIR"/*.jsonl "$SESSION_DIR"/*.reset.* "$SESSION_DIR"/*.trajectory.jsonl; do
    [ -f "$f" ] || continue
    grep -h "takeover" "$f" 2>/dev/null | while IFS= read -r line; do
        # Extract ISO 8601 date: "date":"2026-06-04T12:34:56.789+01:00"
        ts=$(echo "$line" | sed -n 's/.*"date"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        if [ -n "$ts" ]; then
            hour_key="${ts:0:13}"  # e.g. "2026-06-04T12"
            echo "$hour_key" >> "$TMPDIR_CLEANUP/takeover_hours"
        fi
    done
done

if [ -s "$TMPDIR_CLEANUP/takeover_hours" ]; then
    SPIKE_HOURS=$(sort "$TMPDIR_CLEANUP/takeover_hours" | uniq -c | sort -rn | awk -v limit="$TAKEOVER_LIMIT" '$1 > limit {print $1, $2}')

    if [ -n "$SPIKE_HOURS" ]; then
        # Build new alert entries
        EXISTING="[]"
        if [ -f "$ALERTS_FILE" ]; then
            EXISTING=$(cat "$ALERTS_FILE")
        fi

        NEW_ALERTS="[]"
        while IFS= read -r spike; do
            [ -z "$spike" ] && continue
            count=$(echo "$spike" | awk '{print $1}')
            hour=$(echo "$spike" | awk '{print $2}')
            msg="Takeover error spike: $count occurrences in hour $hour (threshold: $TAKEOVER_LIMIT)"

            log "ALERT: $msg"

            NEW_ALERTS=$(echo "$NEW_ALERTS" | python3 -c "
import json, sys
from datetime import datetime, timezone
alerts = json.load(sys.stdin)
alerts.append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'severity': 'critical',
    'metric': 'session-takeover-spike',
    'message': sys.argv[1],
    'value': int(sys.argv[2]),
    'threshold': int(sys.argv[3])
})
print(json.dumps(alerts))
" "$msg" "$count" "$TAKEOVER_LIMIT")
        done <<< "$SPIKE_HOURS"

        # Merge and cap at 100 alerts
        echo "$EXISTING" | python3 -c "
import json, sys
existing = json.load(sys.argv[1])
new = json.loads(sys.argv[2])
merged = existing + new
if len(merged) > 100:
    merged = merged[-100:]
print(json.dumps(merged, indent=2))
" "$EXISTING" "$NEW_ALERTS" > "$ALERTS_FILE"

        log "Wrote takeover spike alerts to $ALERTS_FILE"
    else
        log "No takeover error spikes detected (threshold: $TAKEOVER_LIMIT/hour)"
    fi
else
    log "No takeover errors found in any session files"
fi

# Cleanup temp
rm -rf "$TMPDIR_CLEANUP"

log "=== Session cleanup complete ==="
exit 0
