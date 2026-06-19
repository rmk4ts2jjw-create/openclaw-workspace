import json
from datetime import datetime, timezone

# Load tasks
with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
    tasks = json.load(f)

# List of stalled task IDs to reset
stalled_task_ids = [
    "rev-phase-2",
    "rev-phase-3", 
    "rev-phase-4",
    "rev-phase-5",
    "rev-phase-6",
    "cd28ab90-cffe-4fa0-9bee-c144f3038a27"
]

# Current time for history entry
now = datetime.now(timezone.utc).isoformat()

# Reset each stalled task
for task in tasks:
    if task['id'] in stalled_task_ids:
        print(f"Resetting task {task['id']}")
        # Change status from in_progress to backlog
        task['status'] = 'backlog'
        # Increment dispatchCount
        task['dispatchCount'] = task.get('dispatchCount', 0) + 1
        # Add history entry
        task['history'].append({
            'ts': now,
            'action': 'stalled',
            'actor': 'stall-detector',
            'details': 'Task stalled due to no lastActivity update for >30 minutes'
        })
        # Clear currentStep and progress (optional, but good practice)
        task['currentStep'] = None
        task['progress'] = 0
        # Note: we keep lastActivity as-is for stall detection logic

# Save back
with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'w') as f:
    json.dump(tasks, f, indent=2)

print(f"Reset {len(stalled_task_ids)} stalled tasks")