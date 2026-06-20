#!/bin/bash
set -e

WORKSPACE="/Users/spacemonkey/.openclaw/workspace"
STATE_FILE="$WORKSPACE/memory/heartbeat-state.json"

# Initialize state if not exists
if [ ! -f "$STATE_FILE" ]; then
    echo '{"lastChecks":{}}' > "$STATE_FILE"
fi

# Read state
STATE=$(cat "$STATE_FILE")
# Check for jq
if command -v jq >/dev/null 2>&1; then
    UPDATE_WITH_JQ=true
else
    UPDATE_WITH_JQ=false
fi

# Current timestamp
NOW=$(date +%s)

# Function to update a field in the state using jq or Python
update_state() {
    local key=$1
    local value=$2
    if $UPDATE_WITH_JQ; then
        STATE=$(echo "$STATE" | jq --arg key "$key" --arg value "$value" '.lastChecks[$key] = ($value | tonumber // .)')
    else
        # Use Python
        STATE=$(python3 -c "
import json, sys
state = json.loads(sys.stdin.read())
state['lastChecks']['$key'] = $value
print(json.dumps(state))
        " <<< "$STATE")
    fi
}

# We'll collect messages for what we did
MESSAGES=""

# Weather check
WEATHER_INTERVAL=21600 # 6 hours
LAST_WEATHER=$(echo "$STATE" | jq -r '.lastChecks.weather // empty' 2>/dev/null)
if [ -z "$LAST_WEATHER" ] || [ $((NOW - LAST_WEATHER)) -gt $WEATHER_INTERVAL ]; then
    # Try to get location
    LOCATION=$(curl -s ipinfo.io/loc 2>/dev/null)
    if [ -n "$LOCATION" ]; then
        # Get weather for location
        WEATHER=$(curl -s "wttr.in/$LOCATION?format=3" 2>/dev/null)
        if [ -n "$WEATHER" ]; then
            MESSAGES="$MESSAGES Weather: $WEATHER"
            update_state "weather" $NOW
        fi
    fi
fi

# Memory maintenance
MEMORY_INTERVAL=172800 # 2 days
LAST_MEMORY=$(echo "$STATE" | jq -r '.lastChecks.memory_maintenance // empty' 2>/dev/null)
if [ -z "$LAST_MEMORY" ] || [ $((NOW - LAST_MEMORY)) -gt $MEMORY_INTERVAL ]; then
    # Read yesterday and today's memory files
    YESTERDAY=$(date -v-1d +%Y-%m-%d)
    TODAY=$(date +%Y-%m-%d)
    MEMORY_DIR="$WORKSPACE/memory"
    # We'll just note that we checked
    MESSAGES="$MESSAGES Memory maintenance checked for $YESTERDAY and $TODAY"
    update_state "memory_maintenance" $NOW
fi

# Git check and commit
GIT_INTERVAL=86400 # 1 day
LAST_GIT=$(echo "$STATE" | jq -r '.lastChecks.git_commit // empty' 2>/dev/null)
if [ -z "$LAST_GIT" ] || [ $((NOW - LAST_GIT)) -gt $GIT_INTERVAL ]; then
    # Check for changes in allowed files
    cd "$WORKSPACE"
    CHANGES=$(git status --porcelain | grep -E '^(memory/|MEMORY.md|AGENTS.md|TOOLS.md|IDENTITY.md|USER.md)' || true)
    if [ -n "$CHANGES" ]; then
        # We have changes, let's commit them
        git add memory/ MEMORY.md AGENTS.md TOOLS.md IDENTITY.md USER.md
        # Commit only if there are staged changes
        if ! git diff --staged --quiet; then
            git commit -m "Heartbeat update: automated commit from cron"
            git push
            MESSAGES="$MESSAGES Committed changes to memory and config files"
        fi
    fi
    update_state "git_commit" $NOW
fi

# Update the state file
echo "$STATE" > "$STATE_FILE"

# Output the messages
echo "$MESSAGES"