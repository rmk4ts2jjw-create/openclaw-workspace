#!/bin/bash
# session-expiry.sh - Auto‑expire sessions idle >24h
# This script runs daily to refuse stale sessions.

# Grab the directory containing session JSONL files
SESSION_DIR="${HOME}/.openclaw/agents/main/sessions"
THRESHOLD=$((24*60*60))  # 24 hours in seconds
NOW=$(date +%s)

# Find sessions whose last modification time is older than threshold
OLD=$(ls -1 "$SESSION_DIR"/*.jsonl 2>/dev/null | while read -r f; do
  mtime=$(stat -f %m "$f")
  if (( mtime < NOW - THRESHOLD )); then
    echo "$f"
  fi
done)

if [ -z "$OLD" ]; then
  echo "$(date): No idle sessions older than 24h." >> "$SESSION_DIR/expiry.log"
  exit 0
fi

# Delete old sessions and log
for f in $OLD; do
  echo "$(date): Expiring stale session $(basename $f)" >> "$SESSION_DIR/expiry.log"
  rm -f "$f"
  # Also delete any associated lock files
  lock="$SESSION_DIR/$(basename $f .jsonl).lock"
  [ -f "$lock" ] && rm -f "$lock"
done

exit 0