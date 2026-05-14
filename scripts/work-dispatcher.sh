#!/bin/bash
# ~/.openclaw/workspace/scripts/work-dispatcher.sh
# Checks if any tasks are in_progress. If none, picks a backlog item and logs it.
# Designed to be called by cron every 15 minutes.

TASKS_FILE="/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
LOG_FILE="/Users/spacemonkey/.openclaw/workspace/memory/dispatcher-log.md"

# Check if any tasks are in_progress
IN_PROGRESS=$(python3 -c "
import json
with open('$TASKS_FILE') as f:
    tasks = json.load(f)
in_progress = [t for t in tasks if t['status'] == 'in_progress']
print(len(in_progress))
")

if [ "$IN_PROGRESS" -gt 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') — $IN_PROGRESS task(s) in progress. Skipping." >> "$LOG_FILE"
    exit 0
fi

# No tasks in progress — pick a backlog item
BACKLOG_COUNT=$(python3 -c "
import json
with open('$TASKS_FILE') as f:
    tasks = json.load(f)
backlog = [t for t in tasks if t['status'] == 'backlog']
print(len(backlog))
")

if [ "$BACKLOG_COUNT" -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') — No backlog items. Nothing to do." >> "$LOG_FILE"
    exit 0
fi

# Pick the first backlog item and mark it as in_progress
python3 << 'PYEOF'
import json
from datetime import datetime

tasks_file = "/Users/spacemonkey/.openclaw/workspace/data/tasks.json"
log_file = "/Users/spacemonkey/.openclaw/workspace/memory/dispatcher-log.md"

with open(tasks_file) as f:
    tasks = json.load(f)

# Find first backlog item
backlog = [t for t in tasks if t['status'] == 'backlog']
if not backlog:
    exit(0)

# Sort by id to get oldest first
backlog.sort(key=lambda t: t['id'])
picked = backlog[0]

# Mark as in_progress
for t in tasks:
    if t['id'] == picked['id']:
        t['status'] = 'in_progress'
        t['ts'] = 'just now'
        if 'note' not in t:
            t['note'] = ''
        t['note'] += f" [auto-dispatched {datetime.now().strftime('%Y-%m-%d %H:%M')}]"
        break

with open(tasks_file, 'w') as f:
    json.dump(tasks, f, indent=2)

# Log
with open(log_file, 'a') as f:
    f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} — DISPATCHED\n")
    f.write(f"- **{picked['id']}**: {picked['title']}\n")
    f.write(f"- Assignee: {picked['assignee']}\n")
    f.write(f"- Status: backlog → in_progress\n")

print(f"Dispatched {picked['id']}: {picked['title']}")
PYEOF
