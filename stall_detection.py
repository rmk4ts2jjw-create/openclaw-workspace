#!/usr/bin/env python3
import json
import os
from datetime import datetime, timezone, timedelta

# Path to tasks.json
TASKS_PATH = '/Users/spacemonkey/.openclaw/workspace/data/tasks.json'

def parse_iso(timestamp_str):
    """Parse ISO timestamp string, return None if invalid or 'just now'."""
    if not timestamp_str or timestamp_str.lower() == 'just now':
        return None
    try:
        # Remove trailing Z and parse
        if timestamp_str.endswith('Z'):
            timestamp_str = timestamp_str[:-1] + '+00:00'
        return datetime.fromisoformat(timestamp_str)
    except Exception:
        return None

def get_timestamp_for_task(task):
    """Get the best available timestamp for a task."""
    # 1. lastActivity if valid
    last_activity = parse_iso(task.get('lastActivity'))
    if last_activity:
        return last_activity
    
    # 2. ts field if valid
    ts = parse_iso(task.get('ts'))
    if ts:
        return ts
    
    # 3. most recent history entry
    history = task.get('history', [])
    if history:
        # Sort history by ts descending and take the first valid one
        valid_histories = []
        for h in history:
            ts = parse_iso(h.get('ts'))
            if ts:
                valid_histories.append(ts)
        if valid_histories:
            return max(valid_histories)
    
    # No valid timestamp
    return None

def main():
    # Read tasks
    with open(TASKS_PATH, 'r') as f:
        tasks = json.load(f)
    
    now = datetime.now(timezone.utc)
    updated = False
    
    for task in tasks:
        if task.get('status') != 'in_progress':
            continue
        
        # Get the best timestamp for this task
        last_timestamp = get_timestamp_for_task(task)
        
        # Calculate staleness
        if last_timestamp is None:
            # No valid timestamp -> treat as stalled
            staleness = timedelta(hours=2)  # Consider it stale enough to reset
            reason = 'no valid timestamp'
        else:
            staleness = now - last_timestamp
            reason = f'last timestamp {last_timestamp.isoformat()}'
        
        # Check for ghost dispatch fast-path: currentStep is null or "Agent starting…" and lastActivity >60s old
        current_step = task.get('currentStep')
        last_activity = task.get('lastActivity')
        last_activity_valid = parse_iso(last_activity) if last_activity else None
        ghost_fast_path = (
            (current_step is None or current_step == "Agent starting…") and
            last_activity_valid is not None and
            (now - last_activity_valid) > timedelta(seconds=60)
        )
        
        # HARD RULE: if lastActivity is null/empty and in_progress for >30 min -> reset immediately
        if not last_activity or not last_activity_valid:
            if staleness > timedelta(minutes=30):
                print(f"HARD RULE: Task {task['id']} has no lastActivity and stale for {staleness}. Resetting.")
                task['status'] = 'backlog'
                task['stalledAt'] = now.isoformat() + 'Z'
                if 'history' not in task:
                    task['history'] = []
                task['history'].append({
                    'ts': now.isoformat() + 'Z',
                    'action': 'stalled_reset',
                    'actor': 'heartbeat',
                    'details': f'HARD RULE: no lastActivity for {staleness}'
                })
                # Reset currentStep and progress? According to HEARTBEAT.md, we don't set currentStep to "Agent starting…"
                task['currentStep'] = None
                task['progress'] = 0
                updated = True
                continue  # Skip further checks for this task
        
        # Check staleness > 2 hours -> reset
        if staleness > timedelta(hours=2):
            print(f"Task {task['id']} stale for {staleness} (>2h). Resetting to backlog.")
            task['status'] = 'backlog'
            task['stalledAt'] = now.isoformat() + 'Z'
            if 'history' not in task:
                task['history'] = []
            task['history'].append({
                'ts': now.isoformat() + 'Z',
                'action': 'stalled_reset',
                'actor': 'heartbeat',
                'details': f'Stale for {staleness}'
            })
            task['currentStep'] = None
            task['progress'] = 0
            updated = True
            continue
        
        # Check staleness > 30 minutes but < 2 hours -> warning and possible reset
        if staleness > timedelta(minutes=30):
            print(f"Task {task['id']} stale for {staleness} (>30m, <2h). Checking for ghost dispatch.")
            if current_step is None or current_step == "Agent starting…":
                print(f"  -> currentStep is {current_step}, resetting immediately.")
                task['status'] = 'backlog'
                task['stalledAt'] = now.isoformat() + 'Z'
                if 'history' not in task:
                    task['history'] = []
                task['history'].append({
                    'ts': now.isoformat() + 'Z',
                    'action': 'stalled_reset',
                    'actor': 'heartbeat',
                    'details': f'Ghost dispatch: currentStep={current_step} for {staleness}'
                })
                task['currentStep'] = None
                task['progress'] = 0
                updated = True
                continue
            else:
                print(f"  -> currentStep is '{current_step}', logging warning only.")
                # We could log a warning, but we don't have a logger. We'll just print.
                # In a real implementation, we might add a warning to the task or a log file.
                pass
    
    # Write back if updated
    if updated:
        with open(TASKS_PATH, 'w') as f:
            json.dump(tasks, f, indent=2)
        print("Tasks updated.")
    else:
        print("No tasks needed updates.")

if __name__ == '__main__':
    main()