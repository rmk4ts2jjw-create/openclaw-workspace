#!/bin/bash
# stall-detector.sh — Shell-only stall detection for in_progress tasks
# Runs every 15 minutes via OpenClaw cron. Zero AI tokens.
#
# Rule: Any in_progress task with no lastActivity update for >30 minutes
# gets reset to backlog immediately.
#
# This is a safety net that does NOT depend on heartbeat timing,
# dispatcher state, or agent behavior. It is purely time-based.

set -euo pipefail

WORKSPACE="/Users/spacemonkey/.openclaw/workspace"
TASKS_FILE="$WORKSPACE/data/tasks.json"
LOG="$WORKSPACE/logs/stall-detector.log"
THRESHOLD_MIN=30

mkdir -p "$(dirname "$LOG")"
DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

python3 - "$TASKS_FILE" "$THRESHOLD_MIN" "$DATE" "$LOG" << 'PYEOF'
import json, sys, os, tempfile, shutil
from datetime import datetime, timezone

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
        print(f"safe_write error: {e}", file=sys.stderr)

tasks_file = sys.argv[1]
threshold_min = int(sys.argv[2])
date_str = sys.argv[3]
log_file = sys.argv[4]
now = datetime.now(timezone.utc)
log_lines = []

with open(tasks_file) as f:
    tasks = json.load(f)

reset_count = 0
cleared_count = 0

for t in tasks:
    # PHASE 0: Instant reset for "Agent starting…" that never progressed
    # If currentStep is "Agent starting…" (or null) and lastActivity is >60s ago,
    # the sub-agent never actually started. Reset immediately.
    if t.get('status') == 'in_progress':
        step = t.get('currentStep', None)
        last = t.get('lastActivity') or t.get('ts')
        if step in ('Agent starting…', 'Agent starting...', None) and last:
            try:
                last_ts = datetime.fromisoformat(last.replace('Z', '+00:00'))
                age_sec = (now - last_ts).total_seconds()
                if age_sec > 60:
                    t['status'] = 'backlog'
                    t['currentStep'] = None
                    t['progress'] = 0
                    t['stalledAt'] = now.isoformat()
                    t['lastActivity'] = now.isoformat()
                    t['dispatchCount'] = t.get('dispatchCount', 0) + 1
                    t['wasStalled'] = True
                    t['ghostDispatch'] = True
                    entry = {
                        'ts': now.isoformat(),
                        'action': 'ghost_dispatch_reset',
                        'actor': 'stall-detector',
                        'details': f'Ghost dispatch reset — Agent starting for {age_sec:.0f}s with no progress'
                    }
                    if 'history' not in t:
                        t['history'] = []
                    t['history'].append(entry)
                    log_lines.append(f"  GHOST_RESET {t['id']}: {t['title'][:60]} — Agent starting for {age_sec:.0f}s")
                    reset_count += 1
                    continue
            except (ValueError, TypeError):
                pass

    # PHASE 1: Reset stale in_progress tasks to backlog
    if t.get('status') != 'in_progress':
        continue

    last_ts = None
    la = t.get('lastActivity')
    if la:
        try:
            last_ts = datetime.fromisoformat(la.replace('Z', '+00:00'))
        except:
            pass
    if not last_ts:
        ts = t.get('ts')
        if ts and ts != 'just now':
            try:
                last_ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
            except:
                pass
    if not last_ts:
        for h in reversed(t.get('history', [])):
            try:
                last_ts = datetime.fromisoformat(h['ts'].replace('Z', '+00:00'))
                break
            except:
                continue

    stale_min = 99999 if not last_ts else (now - last_ts).total_seconds() / 60

    if stale_min > threshold_min:
        old_step = t.get('currentStep', None)
        t['status'] = 'backlog'
        t['currentStep'] = None
        t['progress'] = 0
        t['stalledAt'] = now.isoformat()
        t['lastActivity'] = now.isoformat()
        t['dispatchCount'] = t.get('dispatchCount', 0) + 1
        t['wasStalled'] = True
        entry = {
            'ts': now.isoformat(),
            'action': 'stalled_reset',
            'actor': 'stall-detector',
            'details': f'Auto-reset by stall detector — in_progress for {stale_min:.0f} min with no activity (threshold: {threshold_min} min). Was: {old_step}'
        }
        if 'history' not in t:
            t['history'] = []
        t['history'].append(entry)
        log_lines.append(f"  RESET {t['id']}: {t['title'][:60]} — stale {stale_min:.0f} min")
        reset_count += 1

    continue

# PHASE 2: Clear stalledAt on backlog tasks that have been stalled long enough
# This prevents permanent deadlock where stalled tasks can never be re-dispatched
# Cooldown: 30 minutes in backlog after stall reset
for t in tasks:
    if t.get('status') != 'backlog' or not t.get('stalledAt'):
        continue
    try:
        stalled_time = datetime.fromisoformat(t['stalledAt'].replace('Z', '+00:00'))
        in_backlog_min = (now - stalled_time).total_seconds() / 60
    except:
        continue
    # Clear stalledAt after 2 hours in backlog (prevents rapid dispatch→reset loops)
    # wasStalled persists for 3 hours to give manual review time
    # dispatchFailed is NEVER cleared by the stall detector — only manual intervention
    if in_backlog_min > 120:
        t['stalledAt'] = None
    if in_backlog_min > 180:
        t.pop('wasStalled', None)
        entry = {
            'ts': now.isoformat(),
            'action': 'stalled_cleared',
            'actor': 'stall-detector',
            'details': f'stalledAt cleared after {in_backlog_min:.0f} min in backlog — task eligible for re-dispatch'
        }
        if 'history' not in t:
            t['history'] = []
        t['history'].append(entry)
        log_lines.append(f"  CLEARED {t['id']}: stalledAt removed after {in_backlog_min:.0f} min in backlog (wasStalled remains for 3h)")
        cleared_count += 1

if reset_count > 0 or cleared_count > 0:
    safe_write(tasks_file, tasks)
    parts = []
    if reset_count > 0:
        parts.append(f"reset {reset_count}")
    if cleared_count > 0:
        parts.append(f"cleared {cleared_count}")
    log_lines.insert(0, f"[{date_str}] Stall detector: {', '.join(parts)} task(s)")
else:
    log_lines.append(f"[{date_str}] Stall detector: OK — no stale tasks")

with open(log_file, "a") as f:
    for line in log_lines:
        f.write(line + "\n")

print(f"Reset {reset_count} tasks" if reset_count > 0 else "No stale tasks")
PYEOF
