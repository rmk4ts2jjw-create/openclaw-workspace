#!/usr/bin/env bash

STATE_FILE="$HOME/.openclaw/workspace/memory/heartbeat-state.json"

# Get current time in seconds since epoch and ISO 8601 string with timezone
NOW_SECONDS=$(date +%s)
NOW_ISO_NO_TZ=$(date +"%Y-%m-%dT%H:%M:%S")
TZ_OFFSET=$(date +"%z")
TZ_SIGN=${TZ_OFFSET:0:1}
TZ_HOURS=${TZ_OFFSET:1:3}
TZ_MINUTES=${TZ_OFFSET:4:2}
TZ_FORMATTED="${TZ_SIGN}${TZ_HOURS}:${TZ_MINUTES}"
NOW_ISO="${NOW_ISO_NO_TZ}${TZ_FORMATTED}"

# Threshold: 6 hours in seconds
THRESHOLD_SECONDS=$((6 * 60 * 60))  # 21600

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" <<'EOFF'
{
  "lastChecks": {
    "email": null,
    "calendar": null,
    "mentions": null,
    "weather": null
  },
  "nextIndex": 0
}
EOFF
fi

# Read current state
STATE=$(cat "$STATE_FILE")
NEXT_INDEX=$(echo "$STATE" | jq '.nextIndex // 0')

# Define categories and their check abilities (only weather can be checked)
CATEGORIES=("email" "calendar" "mentions" "weather")
ABILITY=(false false false true)  # only weather is true

CHECKED=false
CHECKED_INDEX=-1

# Check each category in order starting from NEXT_INDEX
for OFFSET in 0 1 2 3; do
    IDX=$(( (NEXT_INDEX + OFFSET) % 4 ))
    CATEGORY=${CATEGORIES[$IDX]}
    ABLE=${ABILITY[$IDX]}
    if [ "$ABLE" = true ]; then
        # Get current value for this category (may be null or missing)
        CURRENT_VAL=$(echo "$STATE" | jq -r ".lastChecks[\"$CATEGORY\"] // empty")
        if [ -z "$CURRENT_VAL" ] || [ "$CURRENT_VAL" = "null" ]; then
            # Never checked or explicitly null -> it's due
            CHECKED=true
            CHECKED_INDEX=$IDX
            break
        else
            # Convert ISO string to seconds since epoch
            # Clean timezone: remove colon and whitespace
            TS_FOR_DATE=$(echo "$CURRENT_VAL" | sed -E 's/([+-][0-9][0-9]):([0-9][0-9])$/\1\2/')
            THEN_SECONDS=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$TS_FOR_DATE" +"%s" 2>/dev/null)
            if [ $? -ne 0 ]; then
                # If parsing fails, treat as expired so we update
                THEN_SECONDS=0
            fi
            DIFF=$((NOW_SECONDS - THEN_SECONDS))
            if [ $DIFF -gt $THRESHOLD_SECONDS ]; then
                CHECKED=true
                CHECKED_INDEX=$IDX
                break
            fi
        fi
    fi
done

if [ "$CHECKED" = true ]; then
    case "$CATEGORY" in
        weather)
            # Attempt to fetch weather for London using wttr.in
            WEATHER_URL="https://wttr.in/London?format=j1"
            if command -v curl >/dev/null 2>&1; then
                RESPONSE=$(curl -s -f "$WEATHER_URL" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
                    # Success: update last check time for weather to now
                    NEW_STATE=$(echo "$STATE" | jq --arg iso "$NOW_ISO" '.lastChecks.weather = $iso | .nextIndex = ((.nextIndex + 1) % 4)')
                    echo "$NEW_STATE" > "$STATE_FILE"
                else
                    # Failed: do not update last check time, but advance index
                    NEW_STATE=$(echo "$STATE" | jq '.nextIndex = ((.nextIndex + 1) % 4)')
                    echo "$NEW_STATE" > "$STATE_FILE"
                fi
            elif command -v wget >/dev/null 2>&1; then
                RESPONSE=$(wget -qO- "$WEATHER_URL" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
                    NEW_STATE=$(echo "$STATE" | jq --arg iso "$NOW_ISO" '.lastChecks.weather = $iso | .nextIndex = ((.nextIndex + 1) % 4)')
                    echo "$NEW_STATE" > "$STATE_FILE"
                else
                    NEW_STATE=$(echo "$STATE" | jq '.nextIndex = ((.nextIndex + 1) % 4)')
                    echo "$NEW_STATE" > "$STATE_FILE"
                fi
            else
                # No curl or wget: skip and advance index
                NEW_STATE=$(echo "$STATE" | jq '.nextIndex = ((.nextIndex + 1) % 4)')
                echo "$NEW_STATE" > "$STATE_FILE"
            fi
            ;;
        *)
            # For other categories, we cannot check, so just advance index
            # (Do not update last check time because we didn't actually check)
            NEW_STATE=$(echo "$STATE" | jq '.nextIndex = ((.nextIndex + 1) % 4)')
            echo "$NEW_STATE" > "$STATE_FILE"
            ;;
    esac
else
    # No category was due to check, just advance index
    NEW_STATE=$(echo "$STATE" | jq '.nextIndex = ((.nextIndex + 1) % 4)')
    echo "$NEW_STATE" > "$STATE_FILE"
fi
