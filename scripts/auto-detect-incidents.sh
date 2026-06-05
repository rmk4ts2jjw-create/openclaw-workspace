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

# Helper: create incident + linked task via Python
# Creates the incident record AND a linked task in tasks.json
# Task starts in "triage" status (not backlog) for incident response workflow
create_incident() {
    local title="$1" severity="$2" owner="$3" summary="$4" tags="$5" source="$6"

    # Circuit breaker check — skip if this error type is tripped
    local CB_RESULT
    CB_RESULT=$(bash /Users/spacemonkey/.openclaw/workspace/scripts/circuit-breaker.sh check "incident-create-$source" 2>/dev/null)
    if echo "$CB_RESULT" | grep -q "^TRIPPED:"; then
        echo "[$(timestamp)] [CIRCUIT-BREAKER] Skipping incident creation for '$source' — circuit open ($CB_RESULT)" >> "$LOG_FILE"
        return 0
    fi

    python3 << PYEOF
import json, os, tempfile, fcntl, shutil
from datetime import datetime, timezone, timedelta

incidents_path = "$INCIDENTS_FILE"
tasks_path = os.path.join(os.path.dirname(incidents_path), "tasks.json")

# ── Atomic write helper ──
def safe_write(path, data):
    """Atomic JSON write: temp file + rename. Keeps .bak.1 backup."""
    try:
        if os.path.exists(path):
            shutil.copy2(path, path + ".bak")
        dir_name = os.path.dirname(path) or '.'
        fd, tmp = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(data, f, indent=2)
                f.flush(); os.fsync(f.fileno())
            os.rename(tmp, path)
        except:
            if os.path.exists(tmp):
                os.remove(tmp)
            raise
    except Exception as e:
        print(f"safe_write error: {e}", file=__import__("sys").stderr)

# ── Incident dedup: same title+source within 24h → update existing ──
def find_existing_incident(incidents, title, source_tags):
    """Find a non-RESOLVED incident with matching title created within 24h."""
    now = datetime.now(timezone.utc)
    for inc in incidents:
        if inc.get("status") == "RESOLVED":
            continue
        if inc.get("title") != title:
            continue
        # Check if created within 24 hours
        opened = inc.get("opened", "")
        try:
            opened_dt = datetime.fromisoformat(opened.replace("Z", "+00:00"))
            if (now - opened_dt) < timedelta(hours=24):
                return inc
        except:
            continue
    return None

incidents = json.load(open(incidents_path)) if os.path.exists(incidents_path) else []

# Deduplicate: find existing active incident with same title within 24h
existing_inc = find_existing_incident(incidents, "$title", "$source")
inc_already_exists = existing_inc is not None

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")

if inc_already_exists:
    # Update existing incident: append to timeline, bump lastActivity, increment count
    next_id = existing_inc["id"]
    existing_inc["lastActivity"] = now
    # Track recurrence count in summary
    recurrence = existing_inc.get("_recurrence", 1) + 1
    existing_inc["_recurrence"] = recurrence
    existing_inc["summary"] = "$summary" + f" (recurrence #{recurrence})"
    existing_inc["timeline"].append({"ts": now, "message": f"Recurrence #{recurrence}: Auto-detected by $source", "actor": "system"})
    safe_write(incidents_path, incidents)
    # Still create a linked task for the recurrence (so it shows in triage)
    # But only if no open linked task already exists
    tasks_check = json.load(open(tasks_path)) if os.path.exists(tasks_path) else []
    has_open_linked = any(t.get("linkedIncidentId") == next_id and t.get("status") in ("triage", "backlog", "in_progress") for t in tasks_check)
    if has_open_linked:
        print(f"duplicate|{next_id}")
        exit(0)
else:
    # Generate next INC ID
    nums = []
    for i in incidents:
        m = i["id"].split("-")
        if len(m) == 2 and m[1].isdigit():
            nums.append(int(m[1]))
    next_id = f"INC-{str(max(nums) + 1 if nums else 1).zfill(3)}"

    # Auto-generate response actions based on severity
    import random as _rnd
    def _act_id(): return f"act-{_rnd.randrange(100000, 999999)}"
    _severity_actions = {
        "P1": [
            {"id": _act_id(), "label": "Investigate root cause", "description": "Immediately investigate the root cause of this critical incident", "status": "suggested", "assignee": "$owner"},
            {"id": _act_id(), "label": "Assess blast radius", "description": "Determine which systems and services are affected", "status": "suggested", "assignee": "lifesupport"},
            {"id": _act_id(), "label": "Implement emergency mitigation", "description": "Apply the fastest available fix to reduce impact", "status": "suggested", "assignee": "$owner"},
            {"id": _act_id(), "label": "Notify command", "description": "Escalate to human operator for awareness", "status": "suggested", "assignee": "monkey"},
        ],
        "P2": [
            {"id": _act_id(), "label": "Investigate issue", "description": "Investigate the cause of this high-severity incident", "status": "suggested", "assignee": "$owner"},
            {"id": _act_id(), "label": "Apply fix", "description": "Implement a fix for the identified issue", "status": "suggested", "assignee": "$owner"},
            {"id": _act_id(), "label": "Verify resolution", "description": "Confirm the fix resolves the incident", "status": "suggested", "assignee": "lifesupport"},
        ],
        "P3": [
            {"id": _act_id(), "label": "Review and triage", "description": "Review the incident and determine appropriate response", "status": "suggested", "assignee": "monkey"},
            {"id": _act_id(), "label": "Apply standard fix", "description": "Apply a standard fix procedure", "status": "suggested", "assignee": "$owner"},
        ],
        "P4": [
            {"id": _act_id(), "label": "Monitor and log", "description": "Monitor the situation and log for pattern analysis", "status": "suggested", "assignee": "lifesupport"},
        ],
    }
    _actions = _severity_actions.get("$severity", _severity_actions["P3"])

    inc = {
        "id": next_id, "title": "$title", "severity": "$severity",
        "status": "TRIAGE", "owner": "$owner", "acknowledged": False,
        "escalated": False, "opened": now, "lastActivity": now,
        "summary": "$summary",
        "tags": ${tags} + ["$source"],
        "timeline": [{"ts": now, "message": "Auto-detected by $source", "actor": "system"}],
        "actions": _actions,
        "actionsGenerated": True,
        "_recurrence": 1
    }
    incidents.insert(0, inc)
    safe_write(incidents_path, incidents)

# Create linked task in tasks.json
try:
    tasks = json.load(open(tasks_path)) if os.path.exists(tasks_path) else []
    task_id = f"task-{next_id.lower()}-{os.urandom(2).hex()}"
    task = {
        "id": task_id,
        "title": f"Investigate: {next_id}",
        "assignee": "$owner",
        "status": "triage",
        "priority": "$severity",
        "ts": "just now",
        "note": f"Auto-created from incident {next_id}: $summary",
        "linkedIncidentId": next_id,
        "tags": ["incident-response"] + ${tags},
        "history": [{"ts": now, "action": "created", "actor": "system", "details": f"Auto-created from incident {next_id}"}],
        "lastActivity": now
    }
    tasks.insert(0, task)
    safe_write(tasks_path, tasks)
    print(f"{next_id}|{task_id}")
except Exception as e:
    print(next_id)
    print(f"task_create_error: {e}", file=__import__("sys").stderr)
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
