#!/bin/bash
# ── Quota Budget Enforcer ────────────────────────────────────────────────────
# Tracks and enforces daily model call budget.
# Called by maintenance.sh every 30 minutes.
#
# Budget allocation (based on ~100 free model calls/day):
#   60% interactive (chat, tasks, building) = ~60 calls
#   30% essential automation = ~30 calls
#   10% buffer = ~10 calls
#
# If automation exceeds its budget, automated processes are disabled.

GATEWAY_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
BUDGET_FILE="$HOME/.openclaw/workspace/data/quota-budget-state.json"
LOG_FILE="$HOME/.openclaw/workspace/logs/quota-budget.log"

# Budget limits (adjust based on your actual free tier)
TOTAL_BUDGET=100          # total model calls per day
AUTOMATION_BUDGET=30      # 30% for automation
INTERACTIVE_RESERVE=60    # 60% reserved for interactive use
BUFFER=10                 # 10% buffer

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Count today's model calls from gateway log
if [ -f "$GATEWAY_LOG" ]; then
    TOTAL_CALLS=$(grep -c "model-call-started" "$GATEWAY_LOG" 2>/dev/null || echo "0")
else
    TOTAL_CALLS=0
fi

# Count automation calls (from cron jobs, not main session)
# Heuristic: calls NOT from the main interactive session
AUTO_CALLS=$(grep "model-call-started" "$GATEWAY_LOG" 2>/dev/null | grep -v "agent:main:main" | wc -l | tr -d ' ')

# Initialize or read budget state
if [ ! -f "$BUDGET_FILE" ]; then
    echo '{"date":"'$(date +%Y-%m-%d)'","total_calls":0,"auto_calls":0,"automation_disabled":false,"last_check":""}' > "$BUDGET_FILE"
fi

# Reset counter if it's a new day
STORED_DATE=$(python3 -c "import json; d=json.load(open('$BUDGET_FILE')); print(d.get('date',''))" 2>/dev/null || echo "")
if [ "$STORED_DATE" != "$(date +%Y-%m-%d)" ]; then
    echo '{"date":"'$(date +%Y-%m-%d)'","total_calls":'$TOTAL_CALLS',"auto_calls":'$AUTO_CALLS',"automation_disabled":false,"last_check":"'$TIMESTAMP'"}' > "$BUDGET_FILE"
    echo "[$TIMESTAMP] [QUOTA] New day — counters reset. Total: $TOTAL_CALLS, Auto: $AUTO_CALLS" >> "$LOG_FILE"
    exit 0
fi

# Update state
python3 << PYEOF
import json

budget_file = "$BUDGET_FILE"
with open(budget_file) as f:
    state = json.load(f)

state["total_calls"] = $TOTAL_CALLS
state["auto_calls"] = $AUTO_CALLS
state["last_check"] = "$TIMESTAMP"

# Check if automation exceeded budget
if state["auto_calls"] > $AUTOMATION_BUDGET and not state.get("automation_disabled", False):
    state["automation_disabled"] = True
    state["automation_disabled_at"] = "$TIMESTAMP"
    # Write state first, then disable automation
    with open(budget_file, "w") as f:
        json.dump(state, f, indent=2)
    
    # Disable the Daily Station Check cron
    import subprocess
    result = subprocess.run(
        ["openclaw", "cron", "disable", "dae7406b-ec78-4752-ba93-91bc62541f7d"],
        capture_output=True, text=True
    )
    with open("$LOG_FILE", "a") as log:
        log.write(f"[$TIMESTAMP] [QUOTA] AUTOMATION BUDGET EXCEEDED — Auto calls: {state['auto_calls']}/{30}\n")
        log.write(f"[$TIMESTAMP] [QUOTA] Daily Station Check disabled. Interactive budget protected.\n")
else:
    with open(budget_file, "w") as f:
        json.dump(state, f, indent=2)
PYEOF

echo "[$TIMESTAMP] [QUOTA] Total: $TOTAL_CALLS/$TOTAL_BUDGET, Auto: $AUTO_CALLS/$AUTOMATION_BUDGET" >> "$LOG_FILE"
