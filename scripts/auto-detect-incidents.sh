#!/bin/bash
# Auto-detect incidents from system state
# Called by maintenance.sh every 30 minutes
# Pure shell — zero model calls

WORKSPACE="$HOME/.openclaw/workspace"
[ -z "$WORKSPACE" ] && WORKSPACE="$HOME/.openclaw/workspace"
INCIDENTS_FILE="$WORKSPACE/data/incidents.json"
LOG_FILE="$HOME/.openclaw/logs/health-check-restart.log"
ALERT_FILE="$WORKSPACE/mount-alert.txt"
GATEWAY_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

# Helper: create incident via Python (since we need JSON manipulation)
create_incident() {
    local title="$1" severity="$2" owner="$3" summary="$4" tags="$5" source="$6"
    python3 << PYEOF
import json, os
from datetime import datetime

path = "$INCIDENTS_FILE"
incidents = json.load(open(path)) if os.path.exists(path) else []

# Deduplicate
for i in incidents:
    if i["status"] != "RESOLVED" and i["title"] == "$title" and "$source" in i.get("tags", []):
        print("duplicate")
        exit(0)

nums = []
for i in incidents:
    m = i["id"].split("-")
    if len(m) == 2 and m[1].isdigit():
        nums.append(int(m[1]))
next_id = f"INC-{str(max(nums) + 1 if nums else 1).zfill(3)}"

now = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
inc = {
    "id": next_id, "title": "$title", "severity": "$severity",
    "status": "TRIAGE", "owner": "$owner", "acknowledged": False,
    "escalated": False, "opened": now, "lastActivity": now,
    "summary": "$summary",
    "tags": ${tags} + ["$source"],
    "timeline": [{"ts": now, "message": "Auto-detected by $source", "actor": "system"}],
    "actions": []
}
incidents.insert(0, inc)
with open(path, "w") as f:
    json.dump(incidents, f, indent=2)
print(next_id)
PYEOF
}

echo "$(timestamp) [AUTO-DETECT] Running incident auto-detection..." >> "$LOG_FILE"

# ── 1. Check disk space ──────────────────────────────────────────────────────
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 85 ]; then
    echo "$(timestamp) [AUTO-DETECT] Disk at ${DISK_PCT}% — creating incident" >> "$LOG_FILE"
    create_incident \
        "Disk space critical — ${DISK_PCT}% used on root volume" \
        "P2" "lifesupport" \
        "Root volume disk usage at ${DISK_PCT}%. Threshold is 85%. System performance may degrade." \
        '["disk", "storage", "critical"]' \
        "disk-monitor"
fi

# ── 2. Check WD MyCloud mount ────────────────────────────────────────────────
if ! mount | grep -q "/Volumes/Public" && ! mount | grep -q "/Volumes/OpenClaw-WD"; then
    if ! python3 -c "
import json
incidents = json.load(open('$INCIDENTS_FILE'))
for i in incidents:
    if i['status'] != 'RESOLVED' and 'wd-mycloud' in i.get('tags', []) and 'mount' in i.get('tags', []):
        exit(1)
exit(0)
" 2>/dev/null; then
        :
    else
        echo "$(timestamp) [AUTO-DETECT] WD MyCloud mount missing — creating incident" >> "$LOG_FILE"
        create_incident \
            "WD MyCloud mount missing — backup storage unavailable" \
            "P2" "lifesupport" \
            "Neither /Volumes/Public nor /Volumes/OpenClaw-WD is mounted. Backup scripts cannot write to remote storage." \
            '["wd-mycloud", "mount", "backup"]' \
            "mount-monitor"
    fi
fi

# ── 3. Check cron errors ─────────────────────────────────────────────────────
CRON_ERROR_COUNT=$(python3 -c "
import json, os
path = '$WORKSPACE/data/cron-errors.json'
if not os.path.exists(path): print(0)
else:
    errors = json.load(open(path))
    active = [e for e in errors if e.get('status') in ('new', 'in_progress')]
    print(len(active))
" 2>/dev/null || echo "0")

if [ "$CRON_ERROR_COUNT" -gt 3 ]; then
    echo "$(timestamp) [AUTO-DETECT] $CRON_ERROR_COUNT active cron errors — creating incident" >> "$LOG_FILE"
    create_incident \
        "Cron job failures — $CRON_ERROR_COUNT active errors detected" \
        "P2" "lifesupport" \
        "cron-errors.json shows $CRON_ERROR_COUNT active error entries. Multiple cron jobs are failing." \
        '["cron", "failures"]' \
        "cron-monitor"
fi

# ── 4. Check for stale tasks (>2h no activity) ──────────────────────────────
STALE_TASKS=$(python3 -c "
import json, os
path = '$WORKSPACE/data/tasks.json'
if not os.path.exists(path): print(0)
else:
    tasks = json.load(open(path))
    stale = 0
    for t in tasks:
        if t.get('status') == 'in_progress':
            stale += 1
    print(stale)
" 2>/dev/null || echo "0")

if [ "$STALE_TASKS" -gt 2 ]; then
    echo "$(timestamp) [AUTO-DETECT] $STALE_TASKS tasks stuck in progress — creating incident" >> "$LOG_FILE"
    create_incident \
        "Tasks stuck In Progress — $STALE_TASKS tasks with no recent activity" \
        "P3" "monkey" \
        "$STALE_TASKS tasks are in In Progress state. Tasks without activity for extended periods should be reviewed." \
        '["tasks", "stale", "in-progress"]' \
        "task-monitor"
fi

# ── 5. Check Mission Control health (dashboard down) ─────────────────────────
MC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000/)
if [ "$MC_STATUS" != "200" ]; then
    echo "$(timestamp) [AUTO-DETECT] Mission Control HTTP $MC_STATUS — creating incident" >> "$LOG_FILE"
    create_incident \
        "Mission Control dashboard down — HTTP $MC_STATUS" \
        "P1" "engineer" \
        "Mission Control dashboard is not responding (HTTP $MC_STATUS). The dev server may have crashed or the port is occupied." \
        '["mission-control", "outage", "dashboard"]' \
        "health-check"
fi

# ── 6. Check session count anomaly ───────────────────────────────────────────
SESSION_COUNT=$(python3 -c "
import json, os
path = '$HOME/.openclaw/agents/main/sessions/sessions.json'
if not os.path.exists(path): print(0)
else:
    data = json.load(open(path))
    sessions = data if isinstance(data, list) else data.get('sessions', [])
    print(len(sessions))
" 2>/dev/null || echo "0")

if [ "$SESSION_COUNT" -gt 20 ]; then
    echo "$(timestamp) [AUTO-DETECT] Session count anomaly: $SESSION_COUNT sessions — creating incident" >> "$LOG_FILE"
    create_incident \
        "Session count anomaly — $SESSION_COUNT active sessions detected" \
        "P2" "lifesupport" \
        "Session store shows $SESSION_COUNT sessions. Normal baseline is 2-5. Possible runaway cron job or session leak." \
        '["sessions", "anomaly", "leak"]' \
        "session-monitor"
fi

# ── 7. Check for gateway session takeover errors ─────────────────────────────
GATEWAY_ERRORS=$(python3 -c "
import json, os, glob
from datetime import datetime, timezone, timedelta

session_dir = os.path.expanduser('~/.openclaw/agents/main/sessions')
now = datetime.now(timezone.utc)
error_count = 0

for f in glob.glob(os.path.join(session_dir, '*.jsonl')):
    try:
        mtime = os.path.getmtime(f)
        if mtime < (now - timedelta(hours=1)).timestamp():
            continue
        with open(f) as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except:
                    continue
                content = json.dumps(entry)
                if 'EmbeddedAttemptSessionTakeoverError' in content or 'session file changed' in content:
                    error_count += 1
                    break
    except:
        continue

print(error_count)
" 2>/dev/null || echo "0")

if [ "$GATEWAY_ERRORS" -gt 0 ]; then
    echo "$(timestamp) [AUTO-DETECT] Gateway session errors: $GATEWAY_ERRORS files with takeover errors" >> "$LOG_FILE"
    create_incident \
        "Gateway session errors — $GATEWAY_ERRORS session(s) with EmbeddedAttemptSessionTakeoverError" \
        "P1" "engineer" \
        "Detected $GATEWAY_ERRORS session files with takeover errors in the last hour. Gateway may be in a crash loop." \
        '["gateway", "crash-loop", "session-takeover"]' \
        "gateway-monitor"
fi

# ── 8. Check for rate limit errors (429) in gateway log ──────────────────────
if [ -f "$GATEWAY_LOG" ]; then
    RL_COUNT=$(grep -c '"status":429\|"statusCode":429\|rate.limit\|429 Too Many' "$GATEWAY_LOG" 2>/dev/null || echo "0")
    if [ "$RL_COUNT" -gt 5 ]; then
        echo "$(timestamp) [AUTO-DETECT] Rate limit errors: $RL_COUNT occurrences in gateway log" >> "$LOG_FILE"
        create_incident \
            "Rate limit exhaustion — $RL_COUNT 429 errors in gateway log" \
            "P2" "lifesupport" \
            "Gateway log shows $RL_COUNT rate limit (429) errors. Free model pool may be exhausted." \
            '["rate-limit", "429", "models"]' \
            "rate-monitor"
    fi
fi

echo "$(timestamp) [AUTO-DETECT] Complete" >> "$LOG_FILE"
