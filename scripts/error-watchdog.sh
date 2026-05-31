#!/bin/bash
# error-watchdog.sh – Detect error spikes of identical messages within 10 min
# If >=5 occurrences, write alert to mount-alert.txt (Telegram monitors this file)

LOG_FILE="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
ALERT_FILE="${HOME}/.openclaw/workspace/mount-alert.txt"
THRESHOLD=5
WINDOW=$((10*60)) # 10 minutes in seconds
NOW=$(date +%s)

# Function to parse ISO8601 to epoch (macOS compatible)
iso_to_epoch() {
  local iso="${1%%+*}"   # drop +01:00 part
  local base="${iso%%.*}" # drop milliseconds
  date -j -f "%Y-%m-%dT%H:%M:%S" "$base" +%s 2>/dev/null
}

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
  [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
  exit 0
fi

# Gather recent error messages and count with sort | uniq -c
# (macOS bash 3.x compatible — no associative arrays)
RECENT=$(while IFS= read -r line; do
  ts=$(echo "$line" | sed -n 's/.*"date":"\([^"]*\)".*/\1/p')
  [ -z "$ts" ] && continue
  epoch=$(iso_to_epoch "$ts")
  [ -z "$epoch" ] && continue
  if (( epoch >= NOW - WINDOW )); then
    msg=$(echo "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
    [ -n "$msg" ] && echo "$msg"
  fi
done < <(grep '\[ERROR\]' "$LOG_FILE") | sort | uniq -c | sort -rn)

# Check if any message exceeds threshold
ALERTED=0
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  count=$(echo "$entry" | awk '{print $1}')
  msg=$(echo "$entry" | awk '{$1=""; print substr($0,2)}')
  if (( count >= THRESHOLD )); then
    echo "$(date): ALERT – $count occurrences of error: $msg" > "$ALERT_FILE"
    ALERTED=1
    break
  fi
done <<< "$RECENT"

# Clean up stale alert if no trigger
if (( ALERTED == 0 )); then
  [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
fi

exit 0
