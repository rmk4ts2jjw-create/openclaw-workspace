import json
import datetime
import os

with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
    tasks = json.load(f)

with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'w') as f:
    for task in tasks:
        if task.get('id') == 'task-inc-130-d4c3':
            task['dispatchCount'] = 1
            task['stalledAt'] = null
            task['lastActivity'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
            if 'history' not in task:
                task['history'] = []
            task['history'].append({
                'ts': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'action': 'dispatch_reset',
                'actor': 'heartbeat',
                'details': 'Reset dispatch count and stalledAt to allow re-dispatch'
            })
            print(f"Reset task-inc-130-d4c3: dispatchCount={task['dispatchCount']}, stalledAt={task.get('stalledAt')}")
    json.dump(tasks, f, indent=2)
