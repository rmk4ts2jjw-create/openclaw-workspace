#!/usr/bin/env python3
import json
from datetime import datetime, timezone

STATE_PATH = '/Users/spacemonkey/.openclaw/workspace/memory/heartbeat-state.json'

def main():
    # Read current state
    with open(STATE_PATH, 'r') as f:
        state = json.load(f)
    
    # Get current time in ISO format with milliseconds and Z
    now = datetime.now(timezone.utc)
    # Format: 2026-06-22T11:14:00.123Z
    iso_time = now.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
    
    # Update the checks we performed
    state['lastChecks']['stallDetection'] = iso_time
    state['lastChecks']['circuitBreaker'] = iso_time
    state['lastChecks']['incidents'] = iso_time
    state['lastChecks']['email'] = iso_time
    
    # Also update the heartbeat timestamp? The HEARTBEAT.md doesn't specify, but we can update the heartbeat time.
    state['heartbeat'] = iso_time
    state['lastHeartbeat'] = int(now.timestamp())
    
    # Write back
    with open(STATE_PATH, 'w') as f:
        json.dump(state, f, indent=2)
    
    print(f"Updated heartbeat state to {iso_time}")

if __name__ == '__main__':
    main()