#!/bin/bash
# gateway-self-heal.sh — Detect and auto-recover from gateway crash loops
#
# Trigger: EmbeddedAttemptSessionTakeoverError detected 3+ times in 10 minutes
# Action: Restart gateway via launchctl kickstart, log, create resolved incident
#
# Called by cron every 5 minutes
# Pure shell + Python — zero model calls

WORKSPACE="$HOME/.openclaw/workspace"
INCIDENTS_FILE="$WORKSPACE/data/incidents.json"
LOG_FILE="$WORKSPACE/logs/gateway-self-heal.log"
STATE_FILE="$WORKSPACE/data/gateway-heal-state.json"
GATEWAY_LOG_DIR="/tmp/openclaw"
SESSION_DIR="$HOME/.openclaw/agents/main/sessions"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

mkdir -p "$WORKSPACE/logs" "$WORKSPACE/data"

echo "$(timestamp) [GW-HEAL] Checking for gateway crash loop..." >> "$LOG_FILE"

# ── Count EmbeddedAttemptSessionTakeoverError in last 10 minutes ─────────────
ERROR_COUNT=$(python3 << 'PYEOF'
import json, os, glob, re
from datetime import datetime, timezone, timedelta

session_dir = os.path.expanduser('~/.openclaw/agents/main/sessions')
now = datetime.now(timezone.utc)
cutoff = now - timedelta(minutes=10)
count = 0

# Check session JSONL files modified in last 10 min
for f in glob.glob(os.path.join(session_dir, '*.jsonl')):
    try:
        mtime = os.path.getmtime(f)
        if mtime < cutoff.timestamp():
            continue
        with open(f) as fh:
            content = fh.read()
        if 'EmbeddedAttemptSessionTakeoverError' in content or 'session file changed' in content:
            count += 1
    except:
        continue

# Also check gateway logs
log_dir = '/tmp/openclaw'
for log_file in glob.glob(os.path.join(log_dir, 'openclaw-*.log')):
    try:
        mtime = os.path.getmtime(log_file)
        if mtime < cutoff.timestamp():
            continue
        with open(log_file) as fh:
            content = fh.read()
        # Count distinct error lines (not total occurrences)
        lines = [l for l in content.splitlines() if 'EmbeddedAttemptSessionTakeoverError' in l]
        if lines:
            count += 1  # Count the log file as one source
    except:
        continue

print(count)
PYEOF
)

echo "$(timestamp) [GW-HEAL] Found $ERROR_COUNT error source(s) in last 10 min" >> "$LOG_FILE"

# ── Gate: Need 3+ errors to trigger ─────────────────────────────────────────
if [ "$ERROR_COUNT" -lt 3 ]; then
    echo "$(timestamp) [GW-HEAL] Below threshold (3) — no action" >> "$LOG_FILE"
    exit 0
fi

echo "$(timestamp) [GW-HEAL] THRESHOLD EXCEEDED — initiating gateway restart" >> "$LOG_FILE"

# ── Circuit breaker: Don't restart more than once per 15 minutes ─────────────
if [ -f "$STATE_FILE" ]; then
    LAST_RESTART=$(python3 -c "
import json, os
try:
    s = json.load(open('$STATE_FILE'))
    print(s.get('lastRestart', ''))
except:
    print('')
" 2>/dev/null)
    if [ -n "$LAST_RESTART" ]; then
        SECONDS_SINCE=$(python3 -c "
from datetime import datetime, timezone
try:
    t = datetime.fromisoformat('$LAST_RESTART'.replace('Z','+00:00'))
    delta = datetime.now(timezone.utc) - t
    print(int(delta.total_seconds()))
except:
    print(0)
" 2>/dev/null)
        if [ "$SECONDS_SINCE" -lt 900 ]; then
            echo "$(timestamp) [GW-HEAL] Circuit breaker: last restart ${SECONDS_SINCE}s ago — skipping" >> "$LOG_FILE"
            exit 0
        fi
    fi
fi

# ── Restart gateway ──────────────────────────────────────────────────────────
echo "$(timestamp) [GW-HEAL] Restarting gateway via launchctl..." >> "$LOG_FILE"

RESTART_OK=false

# Try launchctl kickstart first (cleanest)
if launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway 2>/dev/null; then
    RESTART_OK=true
    echo "$(timestamp) [GW-HEAL] launchctl kickstart (gui) succeeded" >> "$LOG_FILE"
elif launchctl kickstart -k system/ai.openclaw.gateway 2>/dev/null; then
    RESTART_OK=true
    echo "$(timestamp) [GW-HEAL] launchctl kickstart (system) succeeded" >> "$LOG_FILE"
else
    # Fallback: openclaw CLI
    if /opt/homebrew/bin/openclaw gateway restart >> "$LOG_FILE" 2>&1; then
        RESTART_OK=true
        echo "$(timestamp) [GW-HEAL] openclaw gateway restart succeeded" >> "$LOG_FILE"
    else
        echo "$(timestamp) [GW-HEAL] ALL RESTART METHODS FAILED" >> "$LOG_FILE"
    fi
fi

# ── Wait and verify ─────────────────────────────────────────────────────────
sleep 10

HEALTHY=false
for attempt in 1 2 3; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:18789/ 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        HEALTHY=true
        break
    fi
    echo "$(timestamp) [GW-HEAL] Health check attempt $attempt: HTTP $HTTP_CODE" >> "$LOG_FILE"
    sleep 5
done

# ── Update state ─────────────────────────────────────────────────────────────
python3 << PYEOF
import json, os, shutil, tempfile
from datetime import datetime, timezone

state_file = "$STATE_FILE"
now = datetime.now(timezone.utc).isoformat()

state = {}
if os.path.exists(state_file):
    try:
        state = json.load(open(state_file))
    except:
        pass

state['lastRestart'] = now
state['restartCount'] = state.get('restartCount', 0) + 1
state['lastErrorCount'] = $ERROR_COUNT
state['lastRestartOk'] = $HEALTHY

# Append to history (keep last 20)
history = state.get('history', [])
history.append({
    'ts': now,
    'errorCount': $ERROR_COUNT,
    'restartOk': $HEALTHY,
    'method': 'launchctl-kickstart' if $RESTART_OK else 'failed'
})
state['history'] = history[-20:]

# Atomic write
try:
    if os.path.exists(state_file):
        shutil.copy2(state_file, state_file + '.bak')
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(state_file), suffix='.tmp')
    with os.fdopen(fd, 'w') as f:
        json.dump(state, f, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.rename(tmp, state_file)
except:
    pass

# ── Create resolved incident ─────────────────────────────────────────────────
incidents_file = "$INCIDENTS_FILE"
incidents = []
if os.path.exists(incidents_file):
    try:
        incidents = json.load(open(incidents_file))
    except:
        pass

nums = []
for i in incidents:
    m = i['id'].split('-')
    if len(m) == 2 and m[1].isdigit():
        nums.append(int(m[1]))
next_id = f"INC-{str(max(nums) + 1 if nums else 1).zfill(3)}"

status_str = "RESTARTED_OK" if $HEALTHY else "RESTART_FAILED"
inc = {
    "id": next_id,
    "title": f"Gateway auto-healed — {status_str}",
    "severity": "P1",
    "status": "RESOLVED",
    "owner": "lifesupport",
    "acknowledged": True,
    "escalated": False,
    "opened": now,
    "lastActivity": now,
    "resolved": now,
    "summary": (
        f"Gateway self-heal triggered: {ERROR_COUNT} EmbeddedAttemptSessionTakeoverError sources in 10 min. "
        f"Restart {'succeeded' if $HEALTHY else 'FAILED'}. "
        f"Health check: {'HTTP 200' if $HEALTHY else 'unhealthy'}."
    ),
    "tags": ["gateway", "auto-heal", "self-heal", "session-takeover"],
    "timeline": [
        {"ts": now, "message": f"Auto-heal triggered: {ERROR_COUNT} error sources detected", "actor": "system"},
        {"ts": now, "message": f"Gateway restart {'succeeded' if $RESTART_OK else 'FAILED'}", "actor": "system"},
        {"ts": now, "message": f"Health check: {'HTTP 200 — healthy' if $HEALTHY else 'UNHEALTHY — needs human'}", "actor": "system"},
        {"ts": now, "message": "Auto-resolved by gateway-self-heal.sh", "actor": "system"},
    ],
    "autoHealed": True,
    "_recurrence": 1
}
incidents.insert(0, inc)

try:
    if os.path.exists(incidents_file):
        shutil.copy2(incidents_file, incidents_file + '.bak')
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(incidents_file), suffix='.tmp')
    with os.fdopen(fd, 'w') as f:
        json.dump(incidents, f, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.rename(tmp, incidents_file)
except:
    pass

print(f"{next_id}")
PYEOF

if $HEALTHY; then
    echo "$(timestamp) [GW-HEAL] ✅ Gateway healthy after restart" >> "$LOG_FILE"
else
    echo "$(timestamp) [GW-HEAL] ❌ Gateway still unhealthy after restart — needs human" >> "$LOG_FILE"
fi

echo "$(timestamp) [GW-HEAL] Complete" >> "$LOG_FILE"
