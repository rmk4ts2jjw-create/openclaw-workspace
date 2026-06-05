#!/bin/bash
# circuit-breaker.sh — Error tracking and automated processing halt
# 
# Usage:
#   circuit-breaker.sh check <error_type>    → returns 0 if OK, 1 if tripped
#   circuit-breaker.sh trip <error_type>     → manually trip the breaker
#   circuit-breaker.sh reset                → reset all breakers
#   circuit-breaker.sh status               → show current breaker state
#
# Rules:
#   5 identical errors within 10 minutes = circuit opens
#   Circuit stays open for 30 minutes (no automated processing)
#   After 30 min, circuit half-allows (one retry). If it trips again, 30 more minutes.
#
# This prevents the cascade: gateway crash → incident flood → data corruption

STATE_FILE="/Users/spacemonkey/.openclaw/workspace/data/circuit-breaker-state.json"
LOG="/Users/spacemonkey/.openclaw/workspace/logs/circuit-breaker.log"
THRESHOLD_COUNT=5
THRESHOLD_WINDOW=600   # 10 minutes in seconds
TRIP_DURATION=1800     # 30 minutes in seconds

mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$LOG")"
DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo '{"errors":{},"tripped":{},"trip_count":{}}'
    fi
}

save_state() {
    echo "$1" | python3 -c "import json,sys; json.dump(json.load(sys.stdin), open('$STATE_FILE','w'), indent=2)"
}

case "${1:-status}" in
    check)
        ERROR_TYPE="${2:-unknown}"
        STATE=$(get_state)
        NOW=$(date +%s)
        
        # Check if circuit is tripped for this error type
        TRIPPED_UNTIL=$(echo "$STATE" | python3 -c "
import json, sys
s = json.load(sys.stdin)
tripped = s.get('tripped', {})
print(tripped.get('$ERROR_TYPE', 0))
" 2>/dev/null || echo "0")
        
        if [ "$TRIPPED_UNTIL" -gt "$NOW" ] 2>/dev/null; then
            REMAINING=$((TRIPPED_UNTIL - NOW))
            echo "[$DATE] CIRCUIT OPEN for '$ERROR_TYPE' — ${REMAINING}s remaining" >> "$LOG"
            echo "TRIPPED:$REMAINING"
            exit 1
        fi
        
        # Record this error
        STATE=$(echo "$STATE" | python3 -c "
import json, sys
from datetime import datetime, timezone
s = json.load(sys.stdin)
now = int(datetime.now(timezone.utc).timestamp())
errors = s.get('errors', {})
if '$ERROR_TYPE' not in errors:
    errors['$ERROR_TYPE'] = []
# Add this error timestamp
errors['$ERROR_TYPE'].append(now)
# Prune old errors outside the window
errors['$ERROR_TYPE'] = [t for t in errors['$ERROR_TYPE'] if now - t < $THRESHOLD_WINDOW]
s['errors'] = errors
print(json.dumps(s))
")
        save_state "$STATE"
        
        # Check if threshold exceeded
        ERROR_COUNT=$(echo "$STATE" | python3 -c "
import json, sys
s = json.load(sys.stdin)
print(len(s.get('errors', {}).get('$ERROR_TYPE', [])))
" 2>/dev/null || echo "0")
        
        if [ "$ERROR_COUNT" -ge "$THRESHOLD_COUNT" ] 2>/dev/null; then
            # Trip the circuit
            TRIP_COUNT=$(echo "$STATE" | python3 -c "
import json, sys
s = json.load(sys.stdin)
tc = s.get('trip_count', {})
print(tc.get('$ERROR_TYPE', 0))
" 2>/dev/null || echo "0")
            TRIP_COUNT=$((TRIP_COUNT + 1))
            
            STATE=$(echo "$STATE" | python3 -c "
import json, sys
from datetime import datetime, timezone
s = json.load(sys.stdin)
now = int(datetime.now(timezone.utc).timestamp())
tripped = s.get('tripped', {})
tripped['$ERROR_TYPE'] = now + $TRIP_DURATION
s['tripped'] = tripped
tc = s.get('trip_count', {})
tc['$ERROR_TYPE'] = $TRIP_COUNT
s['trip_count'] = tc
print(json.dumps(s))
" "$TRIP_COUNT")
            save_state "$STATE"
            
            echo "[$DATE] CIRCUIT TRIPPED for '$ERROR_TYPE' — $THRESHOLD_COUNT errors in ${THRESHOLD_WINDOW}s. Halt for ${TRIP_DURATION}s. (trip #$TRIP_COUNT)" >> "$LOG"
            echo "TRIPPED:$TRIP_DURATION"
            exit 1
        fi
        
        echo "OK:$ERROR_COUNT"
        exit 0
        ;;
    
    trip)
        ERROR_TYPE="${2:-manual}"
        STATE=$(get_state)
        NOW=$(date +%s)
        STATE=$(echo "$STATE" | python3 -c "
import json, sys
from datetime import datetime, timezone
s = json.load(sys.stdin)
now = int(datetime.now(timezone.utc).timestamp())
tripped = s.get('tripped', {})
tripped['$ERROR_TYPE'] = now + $TRIP_DURATION
s['tripped'] = tripped
print(json.dumps(s))
")
        save_state "$STATE"
        echo "[$DATE] MANUAL TRIP for '$ERROR_TYPE' — halt for ${TRIP_DURATION}s" >> "$LOG"
        echo "TRIPPED:$TRIP_DURATION"
        ;;
    
    reset)
        echo '{"errors":{},"tripped":{},"trip_count":{}}' | python3 -c "import json,sys; json.dump(json.load(sys.stdin), open('$STATE_FILE','w'), indent=2)"
        echo "[$DATE] Circuit breaker RESET" >> "$LOG"
        echo "RESET"
        ;;
    
    status)
        STATE=$(get_state)
        NOW=$(date +%s)
        echo "$STATE" | python3 -c "
import json, sys
from datetime import datetime, timezone
s = json.load(sys.stdin)
now = int(datetime.now(timezone.utc).timestamp())
tripped = s.get('tripped', {})
errors = s.get('errors', {})
tc = s.get('trip_count', {})

print('=== Circuit Breaker Status ===')
active = False
for et, until in tripped.items():
    remaining = until - now
    if remaining > 0:
        active = True
        print(f'  🔴 {et}: OPEN — {remaining}s remaining (trip #{tc.get(et, 1)})')
    else:
        print(f'  🟢 {et}: closed (was tripped #{tc.get(et, 1)}x)')

if not active:
    print('  All circuits closed')

print()
print('Recent errors (10min window):')
for et, timestamps in errors.items():
    recent = [t for t in timestamps if now - t < 600]
    if recent:
        print(f'  {et}: {len(recent)} errors')
"
        ;;
esac
