import json
from datetime import datetime, timezone

# Load tasks
with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
    tasks = json.load(f)

# Filter for backlog tasks
backlog_tasks = [t for t in tasks if t.get('status') == 'backlog']
print(f"Found {len(backlog_tasks)} backlog tasks\n")

# Check each one
blocking_tags = {
    'needs-human-input', 'planning', 'design', 'roadmap', 'phase-2-dependent', 
    'phase-3-dependent', 'large-change', 'prevention', 'predictive'
}

for task in backlog_tasks:
    print(f"Task: {task['id']}")
    print(f"  Title: {task.get('title', 'No title')}")
    print(f"  Status: {task.get('status')}")
    print(f"  Priority: {task.get('priority', '?')}")
    print(f"  Assignee: {task.get('assignee', 'unassigned')}")
    
    # Check for stalledAt
    stalled_at = task.get('stalledAt')
    if stalled_at:
        print(f"  ❌ Has stalledAt: {stalled_at}")
    else:
        print(f"  ✅ No stalledAt")
        
    # Check dispatchCount < 3
    dispatch_count = task.get('dispatchCount', 0)
    if dispatch_count >= 3:
        print(f"  ❌ dispatchCount >= 3: {dispatch_count}")
    else:
        print(f"  ✅ dispatchCount < 3: {dispatch_count}")
        
    # Check wasStalled
    was_stalled = task.get('wasStalled', False)
    if was_stalled:
        print(f"  ❌ wasStalled is true")
    else:
        print(f"  ✅ wasStalled is false: {was_stalled}")
        
    # Check for blocking tags
    task_tags = set(task.get('tags', []))
    blocking_found = task_tags & blocking_tags
    if blocking_found:
        print(f"  ❌ Has blocking tags: {blocking_found}")
    else:
        print(f"  ✅ No blocking tags")
        
    # Check if assignee is valid
    assignee = task.get('assignee')
    if not assignee or assignee.strip() == '':
        print(f"  ⚠️  No assignee")
    else:
        print(f"  ✅ Assignee: {assignee}")
        
    print()