import json
from datetime import datetime, timezone

# Load tasks
with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
    tasks = json.load(f)

# Filter for backlog tasks
backlog_tasks = [t for t in tasks if t.get('status') == 'backlog']
print(f"Found {len(backlog_tasks)} backlog tasks")

# Filter for dispatchable tasks
dispatchable_tasks = []
blocking_tags = {
    'needs-human-input', 'planning', 'design', 'roadmap', 'phase-2-dependent', 
    'phase-3-dependent', 'large-change', 'prevention', 'predictive'
}

for task in backlog_tasks:
    # Check for stalledAt
    if task.get('stalledAt'):
        print(f"Skipping {task['id']}: has stalledAt")
        continue
        
    # Check dispatchCount < 3
    if task.get('dispatchCount', 0) >= 3:
        print(f"Skipping {task['id']}: dispatchCount >= 3")
        continue
        
    # Check wasStalled
    if task.get('wasStalled'):
        print(f"Skipping {task['id']}: wasStalled is true")
        continue
        
    # Check for blocking tags
    task_tags = set(task.get('tags', []))
    if task_tags & blocking_tags:
        print(f"Skipping {task['id']}: has blocking tags {task_tags & blocking_tags}")
        continue
        
    # If we get here, task is dispatchable
    dispatchable_tasks.append(task)
    print(f"Dispatchable: {task['id']} - {task['title']} (P{task.get('priority', '?')})")

print(f"\nFound {len(dispatchable_tasks)} dispatchable tasks")

# Sort by priority (P1 > P2 > P3), then by age (oldest first)
def task_sort_key(task):
    priority = task.get('priority', 'P999')
    # Convert priority to number for sorting: P1 -> 1, P2 -> 2, P3 -> 3, etc.
    priority_num = int(priority[1:]) if priority.startswith('P') and priority[1:].isdigit() else 999
    # Get timestamp for age sorting
    ts_str = task.get('ts', '')
    try:
        # Handle ISO format timestamps
        if ts_str and ts_str != 'just now':
            ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        else:
            # For 'just now', use current time (newest)
            ts = datetime.now(timezone.utc)
    except:
        ts = datetime.now(timezone.utc)
    return (priority_num, ts)

dispatchable_tasks.sort(key=task_sort_key)

print("\nDispatchable tasks in order:")
for i, task in enumerate(dispatchable_tasks):
    priority = task.get('priority', '?')
    ts_str = task.get('ts', 'unknown')
    print(f"{i+1}. {task['id']} - {task['title']} (Priority: {priority}, TS: {ts_str})")

if dispatchable_tasks:
    selected_task = dispatchable_tasks[0]
    print(f"\nSelected task for dispatch: {selected_task['id']}")
    print(f"Title: {selected_task['title']}")
    print(f"Assignee: {selected_task.get('assignee', 'unassigned')}")
    print(f"Priority: {selected_task.get('priority', '?')}")
else:
    print("\nNo dispatchable tasks found")