#!/bin/bash
# ── Combined Maintenance Script ──────────────────────────────────────────────
# Runs ALL operational checks as pure shell — zero AI sessions, zero token burn.
# Called by LaunchAgent com.openclaw.maintenance every 30 minutes.
#
# Covers:
#   1. Mount check
#   2. Disk monitor
#   3. Mission Control health check (+ auto-restart)
#   4. Error spike watchdog
#   5. Task dispatcher (pick up backlog tasks)
#   6. Incident auto-detection
#   7. Safe backup (weekly)
#   8. Session cleanup (daily)
#   9. Storage migration (monthly)
#  10. Quota budget enforcement

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/maintenance.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$HOME/.openclaw/logs"

echo "[$TIMESTAMP] === Maintenance run started ===" >> "$LOG_FILE"

# ── 1. Mount check ───────────────────────────────────────────────────────────
echo "[$TIMESTAMP] [1/10] Mount check..." >> "$LOG_FILE"
if bash "$WORKSPACE/scripts/check-mounts.sh" >> "$LOG_FILE" 2>&1; then
  echo "[$TIMESTAMP] [1/10] Mount check: OK" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] [1/10] Mount check: FAILED" >> "$LOG_FILE"
fi

# ── 2. Disk monitor ──────────────────────────────────────────────────────────
echo "[$TIMESTAMP] [2/10] Disk monitor..." >> "$LOG_FILE"
bash "$WORKSPACE/scripts/disk-monitor.sh" >> "$LOG_FILE" 2>&1 || true
echo "[$TIMESTAMP] [2/10] Disk monitor: done" >> "$LOG_FILE"

# ── 3. Mission Control health check ─────────────────────────────────────────
echo "[$TIMESTAMP] [3/10] Mission Control health check..." >> "$LOG_FILE"
MC_DIR="$WORKSPACE/mission-control-dashboard"
MC_LOG="$HOME/.openclaw/logs/health-check-restart.log"
ALERT_FILE="$WORKSPACE/mount-alert.txt"
MAX_RESTARTS_PER_HOUR=3

MC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000/ 2>/dev/null || echo "000")

if [ "$MC_STATUS" = "200" ]; then
  if [ -f "$HOME/.openclaw/logs/.mc-health-bad" ]; then
    echo "$TIMESTAMP [OK] Mission Control recovered (HTTP $MC_STATUS)" >> "$MC_LOG"
    rm -f "$HOME/.openclaw/logs/.mc-health-bad"
  fi
  echo "[$TIMESTAMP] [3/10] Mission Control: OK (HTTP $MC_STATUS)" >> "$LOG_FILE"
else
  echo "$TIMESTAMP [DOWN] Mission Control returned HTTP $MC_STATUS — attempting restart" >> "$MC_LOG"
  echo "[$TIMESTAMP] [3/10] Mission Control: DOWN (HTTP $MC_STATUS) — restarting..." >> "$LOG_FILE"

  # Rate limit: max 3 restarts per hour
  ONE_HOUR_AGO=$(date -v-1H '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d '1 hour ago' '+%Y-%m-%d %H:%M:%S')
  RESTART_COUNT=$(awk -v since="$ONE_HOUR_AGO" '$0 >= since' "$MC_LOG" 2>/dev/null | grep -c '\[DOWN\]' || echo "0")

  if [ "$RESTART_COUNT" -ge "$MAX_RESTARTS_PER_HOUR" ]; then
    echo "$TIMESTAMP [ALERT] MC restarted $RESTART_COUNT times in last hour — manual intervention needed" >> "$MC_LOG"
    echo "Mission Control is down and auto-restart has failed $RESTART_COUNT times in the last hour." > "$ALERT_FILE"
    echo "[$TIMESTAMP] [3/10] Mission Control: RESTART LIMIT EXCEEDED" >> "$LOG_FILE"
  else
    # Kill stale processes
    PIDS=$(lsof -ti :3000 2>/dev/null)
    if [ -n "$PIDS" ]; then
      kill $PIDS 2>/dev/null; sleep 2
      PIDS2=$(lsof -ti :3000 2>/dev/null)
      [ -n "$PIDS2" ] && kill -9 $PIDS2 2>/dev/null; sleep 1
    fi
    # Start MC
    cd "$MC_DIR" && nohup bun run dev --host --port 3000 > /dev/null 2>&1 &
    sleep 5
    NEW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000/ 2>/dev/null || echo "000")
    if [ "$NEW_STATUS" = "200" ]; then
      echo "$TIMESTAMP [RESTART OK] Mission Control is back (HTTP $NEW_STATUS)" >> "$MC_LOG"
      rm -f "$HOME/.openclaw/logs/.mc-health-bad"
      echo "[$TIMESTAMP] [3/10] Mission Control: RESTARTED OK" >> "$LOG_FILE"
    else
      echo "$TIMESTAMP [RESTART FAIL] Still not responding (HTTP $NEW_STATUS)" >> "$MC_LOG"
      echo "[$TIMESTAMP] [3/10] Mission Control: RESTART FAILED" >> "$LOG_FILE"
    fi
  fi
fi

# ── 4. Error spike watchdog ─────────────────────────────────────────────────
echo "[$TIMESTAMP] [4/10] Error spike watchdog..." >> "$LOG_FILE"
GATEWAY_LOG="/tmp/openclaw/openclaw-$(date +%Y-%m-%d).log"
THRESHOLD=5
WINDOW=$((10*60))
NOW=$(date +%s)

if [ ! -f "$GATEWAY_LOG" ]; then
  [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
  echo "[$TIMESTAMP] [4/10] Error watchdog: no log file, skipping" >> "$LOG_FILE"
else
  # Parse recent errors and count occurrences
  RECENT=$(while IFS= read -r line; do
    ts=$(echo "$line" | sed -n 's/.*"date":"\([^"]*\)".*/\1/p')
    [ -z "$ts" ] && continue
    iso="${ts%%+*}"; base="${iso%%.*}"
    epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$base" +%s 2>/dev/null)
    [ -z "$epoch" ] && continue
    if (( epoch >= NOW - WINDOW )); then
      msg=$(echo "$line" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
      [ -n "$msg" ] && echo "$msg"
    fi
  done < <(grep '\[ERROR\]' "$GATEWAY_LOG") | sort | uniq -c | sort -rn)

  ALERTED=0
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    count=$(echo "$entry" | awk '{print $1}')
    if (( count >= THRESHOLD )); then
      msg=$(echo "$entry" | awk '{$1=""; print substr($0,2)}')
      echo "$TIMESTAMP ALERT – $count occurrences of error: $msg" > "$ALERT_FILE"
      echo "[$TIMESTAMP] [4/10] Error watchdog: ALERT — $count occurrences" >> "$LOG_FILE"
      ALERTED=1
      break
    fi
  done <<< "$RECENT"

  if (( ALERTED == 0 )); then
    [ -f "$ALERT_FILE" ] && rm -f "$ALERT_FILE"
    echo "[$TIMESTAMP] [4/10] Error watchdog: no spikes detected" >> "$LOG_FILE"
  fi
fi

# ── 5. Stall detection ──────────────────────────────────────────────────────
echo "[$TIMESTAMP] [5/9] Stall detection..." >> "$LOG_FILE"
bash "$WORKSPACE/scripts/stall-detector.sh" >> "$LOG_FILE" 2>&1 || true
echo "[$TIMESTAMP] [5/9] Stall detection: done" >> "$LOG_FILE"

# ── 6. Task dispatcher ──────────────────────────────────────────────────────
# NOTE: The shell dispatcher only moves tasks to in_progress as a "claim".
# The heartbeat (or night shift) is responsible for actually spawning sub-agents.
# To avoid ghost dispatches, we only move ONE task at a time and ensure
# the heartbeat will pick it up on the next cycle.
echo "[$TIMESTAMP] [6/10] Task dispatcher..." >> "$LOG_FILE"
TASKS_FILE="$WORKSPACE/data/tasks.json"
DISPATCHER_LOG="$WORKSPACE/memory/dispatcher-log.md"

if [ ! -f "$TASKS_FILE" ]; then
  echo "[$TIMESTAMP] [6/10] Task dispatcher: no tasks.json found" >> "$LOG_FILE"
else
  # Count truly dispatchable backlog tasks (not blocked by stalledAt or max dispatchCount)
  DISPATCHABLE_COUNT=$(python3 -c "
import json
with open('$TASKS_FILE') as f:
    tasks = json.load(f)
print(len([t for t in tasks if t.get('status') == 'backlog' and not t.get('stalledAt') and t.get('dispatchCount', 0) < 3]))
" 2>/dev/null || echo "0")

  if [ "$DISPATCHABLE_COUNT" -eq 0 ]; then
    echo "[$TIMESTAMP] [6/10] Task dispatcher: no dispatchable backlog tasks" >> "$LOG_FILE"
  else
    # Circuit breaker check — stop dispatch if tripped
    CB_RESULT=$(bash /Users/spacemonkey/.openclaw/workspace/scripts/circuit-breaker.sh check "task-dispatch" 2>/dev/null)
    if echo "$CB_RESULT" | grep -q "^TRIPPED:"; then
      echo "[$TIMESTAMP] [CIRCUIT-BREAKER] Task dispatch halted — circuit open ($CB_RESULT)" >> "$LOG_FILE"
    else
      DISPATCH_OUTPUT=$(python3 << 'PYEOF' 2>&1)
import json, os, tempfile, shutil
from datetime import datetime, timezone

tasks_file = "/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
log_file = "/Users/spacemonkey/.openclaw/workspace/memory/dispatcher-log.md"

def safe_write(path, data):
    try:
        if os.path.exists(path):
            shutil.copy2(path, path + ".bak")
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', suffix='.tmp')
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(data, f, indent=2)
                f.flush(); os.fsync(f.fileno())
            os.rename(tmp, path)
        except:
            if os.path.exists(tmp): os.remove(tmp)
            raise
    except Exception as e:
        print(f"safe_write error: {e}")

with open(tasks_file) as f:
    tasks = json.load(f)

# Filter: backlog, not stalled, dispatchCount < 3, not wasStalled
backlog = [t for t in tasks if t.get('status') == 'backlog' and not t.get('stalledAt') and t.get('dispatchCount', 0) < 3 and not t.get('wasStalled')]
# If no fresh tasks, try previously-stalled tasks (wasStalled=True but stalledAt cleared)
if not backlog:
    backlog = [t for t in tasks if t.get('status') == 'backlog' and not t.get('stalledAt') and t.get('dispatchCount', 0) < 3]
if not backlog:
    print("NO_DISPATCHABLE")
    exit(0)

# Sort: P1 first, then P2, then P3; then oldest first
priority_order = {'P1': 0, 'P2': 1, 'P3': 2}
backlog.sort(key=lambda t: (priority_order.get(t.get('priority', 'P3'), 2), t.get('ts', '')))
picked = backlog[0]

for t in tasks:
    if t['id'] == picked['id']:
        t['status'] = 'in_progress'
        t['ts'] = 'just now'
        t['lastActivity'] = datetime.now(timezone.utc).isoformat()
        t['startedAt'] = datetime.now(timezone.utc).isoformat()
        if 'note' not in t:
            t['note'] = ''
        t['note'] += f" [auto-dispatched {datetime.now().strftime('%Y-%m-%d %H:%M')}]"
        entry = {
            'ts': datetime.now(timezone.utc).isoformat(),
            'action': 'started',
            'actor': 'dispatcher',
            'details': f'Status changed from backlog to in_progress by maintenance dispatcher'
        }
        if 'history' not in t:
            t['history'] = []
        t['history'].append(entry)
        break

safe_write(tasks_file, tasks)

with open(log_file, 'a') as f:
    f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} — DISPATCHED\n")
    f.write(f"- **{picked['id']}**: {picked['title']}\n")
    f.write(f"- Assignee: {picked.get('assignee', 'unassigned')}\n")
    f.write(f"- Status: backlog → in_progress\n")

print(f"Dispatched {picked['id']}: {picked['title']}")
PYEOF
)
      echo "$DISPATCH_OUTPUT" >> "$LOG_FILE"
      if echo "$DISPATCH_OUTPUT" | grep -q "^Dispatched "; then
        echo "[$TIMESTAMP] [6/10] Task dispatcher: dispatched task" >> "$LOG_FILE"
      elif echo "$DISPATCH_OUTPUT" | grep -q "NO_DISPATCHABLE"; then
        echo "[$TIMESTAMP] [6/10] Task dispatcher: no dispatchable tasks" >> "$LOG_FILE"
      else
        echo "[$TIMESTAMP] [6/10] Task dispatcher: no action" >> "$LOG_FILE"
      fi
    fi
  fi
fi

# ── 6.5 Fix validation ────────────────────────────────────────────────────
echo "[$TIMESTAMP] [6.5/10] Fix validation..." >> "$LOG_FILE"
if [ -f "$WORKSPACE/scripts/fix-validator.py" ]; then
  python3 "$WORKSPACE/scripts/fix-validator.py" >> "$LOG_FILE" 2>&1 || true
  echo "[$TIMESTAMP] [6.5/10] Fix validation: done" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] [6.5/10] Fix validation: script not found, skipping" >> "$LOG_FILE"
fi

# ── 7. Incident auto-detection ──────────────────────────────────────────────
echo "[$TIMESTAMP] [7/10] Incident auto-detection..." >> "$LOG_FILE"
if [ -f "$WORKSPACE/scripts/auto-detect-incidents.sh" ]; then
  bash "$WORKSPACE/scripts/auto-detect-incidents.sh" >> "$LOG_FILE" 2>&1 || true
  echo "[$TIMESTAMP] [7/10] Incident auto-detection: done" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] [7/10] Incident auto-detection: script not found, skipping" >> "$LOG_FILE"
fi

# ── 7. Safe backup (weekly — Sun & Mon) ─────────────────────────────────────
DAY_OF_WEEK=$(date '+%u')  # 1=Mon, 7=Sun
if [ "$DAY_OF_WEEK" -eq 7 ] || [ "$DAY_OF_WEEK" -eq 1 ]; then
  echo "[$TIMESTAMP] [8/10] Safe backup (weekly)..." >> "$LOG_FILE"
  if [ -f "$WORKSPACE/scripts/safe-backup.sh" ]; then
    bash "$WORKSPACE/scripts/safe-backup.sh" >> "$LOG_FILE" 2>&1 || true
    echo "[$TIMESTAMP] [8/10] Safe backup: done" >> "$LOG_FILE"
  else
    echo "[$TIMESTAMP] [8/10] Safe backup: script not found" >> "$LOG_FILE"
  fi
else
  echo "[$TIMESTAMP] [8/10] Safe backup: not today (day $DAY_OF_WEEK)" >> "$LOG_FILE"
fi

# ── 8. Session cleanup (daily — idle >24h) ─────────────────────────────────
echo "[$TIMESTAMP] [9/10] Session cleanup..." >> "$LOG_FILE"
SESSION_DIR="$HOME/.openclaw/agents/main/sessions"
THRESHOLD=$((24*60*60))
NOW_EPOCH=$(date +%s)
CLEANED=0

for f in "$SESSION_DIR"/*.jsonl; do
  [ -f "$f" ] || continue
  mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
  if [ -n "$mtime" ] && (( mtime < NOW_EPOCH - THRESHOLD )); then
    echo "$TIMESTAMP: Expiring stale session $(basename "$f")" >> "$SESSION_DIR/expiry.log"
    rm -f "$f"
    lock="$SESSION_DIR/$(basename "$f" .jsonl).lock"
    [ -f "$lock" ] && rm -f "$lock"
    CLEANED=$((CLEANED + 1))
  fi
done
echo "[$TIMESTAMP] [9/10] Session cleanup: expired $CLEANED stale sessions" >> "$LOG_FILE"

# ── 9. Storage migration (monthly — 1st of month) ──────────────────────────
DAY_OF_MONTH=$(date '+%d')
if [ "$DAY_OF_MONTH" = "01" ]; then
  echo "[$TIMESTAMP] [10/10] Storage migration (monthly)..." >> "$LOG_FILE"
  if [ -f "$WORKSPACE/scripts/migrate-storage.sh" ]; then
    bash "$WORKSPACE/scripts/migrate-storage.sh" >> "$LOG_FILE" 2>&1 || true
    echo "[$TIMESTAMP] [10/10] Storage migration: done" >> "$LOG_FILE"
  else
    echo "[$TIMESTAMP] [10/10] Storage migration: script not found" >> "$LOG_FILE"
  fi
else
  echo "[$TIMESTAMP] [10/10] Storage migration: not today (day $DAY_OF_MONTH)" >> "$LOG_FILE"
fi

# ── 10. Quota budget check ─────────────────────────────────────────────────
echo "[$TIMESTAMP] [11/11] Quota budget check..." >> "$LOG_FILE"
if [ -f "$WORKSPACE/scripts/quota-budget.sh" ]; then
  bash "$WORKSPACE/scripts/quota-budget.sh" >> "$LOG_FILE" 2>&1 || true
  echo "[$TIMESTAMP] [11/11] Quota budget: done" >> "$LOG_FILE"
else
  echo "[$TIMESTAMP] [11/11] Quota budget: script not found" >> "$LOG_FILE"
fi

echo "[$TIMESTAMP] === Maintenance run complete ===" >> "$LOG_FILE"
