#!/bin/bash
# ~/.openclaw/workspace/scripts/work-dispatcher.sh
# Checks if any tasks are in_progress. Resets stale tasks (>2h no activity).
# If no in_progress tasks remain, picks a backlog item and dispatches it.
# Designed to be called by cron every 15 minutes.

TASKS_FILE="/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
LOG_FILE="/Users/spacemonkey/.openclaw/workspace/memory/dispatcher-log.md"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── Step 1: Check in_progress tasks and reset stale ones ─────────────────────
IN_PROGRESS_RESULT=$(python3 << 'PYEOF'
import json, sys
from datetime import datetime, timezone

tasks_file = "/Users/spacemonkey/.openclaw/workspace/data/tasks.json"

try:
    with open(tasks_file) as f:
        tasks = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("COUNT:0")
    sys.exit(0)

now = datetime.now(timezone.utc)
in_progress = [t for t in tasks if t.get('status') == 'in_progress']

if not in_progress:
    print("COUNT:0")
    sys.exit(0)

stale_count = 0
for t in in_progress:
    # Find most recent valid timestamp across all possible fields
    ts = None
    for field in ['lastActivity', 'ts', 'startedAt']:
        val = t.get(field, '')
        if val and val != 'just now':
            try:
                ts = datetime.fromisoformat(val.replace('Z', '+00:00'))
                break
            except (ValueError, AttributeError):
                pass
    # Fall back to history entries
    if not ts and t.get('history'):
        for h in reversed(t['history']):
            try:
                ts = datetime.fromisoformat(h['ts'].replace('Z', '+00:00'))
                break
            except (ValueError, AttributeError):
                pass

    if ts:
        age_h = (now - ts).total_seconds() / 3600
        if age_h > 2:
            stale_count += 1
            t['status'] = 'backlog'
            t['lastActivity'] = now.isoformat()
            if 'history' not in t:
                t['history'] = []
            t['history'].append({
                'ts': now.isoformat(),
                'action': 'reassigned',
                'actor': 'work-dispatcher',
                'details': f'Reset from_in_progress to backlog — stalled {age_h:.1f}h with no activity'
            })
    else:
        # No valid timestamp at all — treat as stale/broken
        stale_count += 1
        t['status'] = 'backlog'
        if 'history' not in t:
            t['history'] = []
        t['history'].append({
            'ts': now.isoformat(),
            'action': 'reassigned',
            'actor': 'work-dispatcher',
            'details': 'Reset from in_progress to backlog — no valid activity timestamp found'
        })

with open(tasks_file, 'w') as f:
    json.dump(tasks, f, indent=2)

# Output remaining in_progress count after stale resets
remaining = len([t for t in tasks if t.get('status') == 'in_progress'])
print(f"COUNT:{remaining}")
print(f"STALE_RESET:{stale_count}")
PYEOF
)

REMAINING=$(echo "$IN_PROGRESS_RESULT" | grep "^COUNT:" | cut -d: -f2)
STALE_RESET=$(echo "$IN_PROGRESS_RESULT" | grep "^STALE_RESET:" | cut -d: -f2)

if [ "$STALE_RESET" -gt 0 ] 2>/dev/null; then
    echo "[$TIMESTAMP] Reset $STALE_RESET stale task(s) to backlog" >> "$LOG_FILE"
fi

if [ "$REMAINING" -gt 0 ] 2>/dev/null; then
    echo "[$TIMESTAMP] $REMAINING task(s) in progress (active). Skipping dispatch." >> "$LOG_FILE"
    exit 0
fi

# ── Step 2: No active in_progress tasks — pick a backlog item ────────────────
BACKLOG_COUNT=$(python3 -c "
import json
with open('$TASKS_FILE') as f:
    tasks = json.load(f)
backlog = [t for t in tasks if t['status'] == 'backlog']
print(len(backlog))
")

if [ "$BACKLOG_COUNT" -eq 0 ]; then
    echo "[$TIMESTAMP] No backlog items. Nothing to dispatch." >> "$LOG_FILE"
    exit 0
fi

# ── Step 3: Dispatch the oldest backlog item ─────────────────────────────────
python3 << 'PYEOF'
import json
from datetime import datetime

tasks_file = "/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
log_file = "/Users/spacemonkey/.openclaw/workspace/memory/dispatcher-log.md"

with open(tasks_file) as f:
    tasks = json.load(f)

backlog = [t for t in tasks if t.get('status') == 'backlog' and not t.get('stalledAt')]
if not backlog:
    exit(0)

# Filter out tasks that have been dispatched 3+ times without real progress
# Count [auto-dispatched in note vs progress history entries
def should_skip_dispatch(t):
    note = t.get('note', '')
    history = t.get('history', [])
    dispatch_count = note.count('[auto-dispatched')
    if dispatch_count < 3:
        return False
    # Check if there are any non-dispatch, non-reassign history entries after the last dispatch
    # If not, the task has been re-dispitched with no real work
    return True

backlog = [t for t in tasks if t.get('status') == 'backlog' and not t.get('stalledAt') and not should_skip_dispatch(t)]
if not backlog:
    print("SKIP_ALL:All backlog tasks have been dispatched multiple times with no progress")
    exit(0)

backlog.sort(key=lambda t: t['id'])
picked = backlog[0]

for t in tasks:
    if t['id'] == picked['id']:
        t['status'] = 'in_progress'
        t['ts'] = 'just now'
        t['lastActivity'] = datetime.now().isoformat()
        if 'note' not in t:
            t['note'] = ''
        t['note'] += f" [auto-dispatched {datetime.now().strftime('%Y-%m-%d %H:%M')}]"
        dispatched = t
        break

with open(tasks_file, 'w') as f:
    json.dump(tasks, f, indent=2)

with open(log_file, 'a') as f:
    f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} — DISPATCHED\n")
    f.write(f"- **{dispatched['id']}**: {dispatched['title']}\n")
    f.write(f"- Assignee: {dispatched['assignee']}\n")
    f.write(f"- Status: backlog → in_progress\n")

print(f"Dispatched {dispatched['id']}: {dispatched['title']}")
PYEOF

echo "[$TIMESTAMP] Dispatched 1 task from backlog" >> "$LOG_FILE"
