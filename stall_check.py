#!/usr/bin/env python3
import json
import os
from datetime import datetime, timezone, timedelta
import sys

TASKS_FILE = '/Users/spacemonkey/.openclaw/workspace/data/tasks.json'

def parse_iso(timestamp_str):
    """Parse ISO timestamp string, return datetime or None."""
    if not timestamp_str or timestamp_str.strip() == '' or timestamp_str.lower() == 'just now':
        return None
    try:
        # Remove trailing Z and convert to timezone-aware
        if timestamp_str.endswith('Z'):
            timestamp_str = timestamp_str[:-1] + '+00:00'
        return datetime.fromisoformat(timestamp_str)
    except Exception:
        return None

def get_task_timestamp(task):
    """Get the best timestamp for a task."""
    # 1. lastActivity
    last_activity = task.get('lastActivity')
    dt = parse_iso(last_activity)
    if dt:
        return dt, 'lastActivity'
    
    # 2. ts
    ts = task.get('ts')
    dt = parse_iso(ts)
    if dt and dt.year > 2020:  # reasonable year
        return dt, 'ts'
    
    # 3. most recent history entry
    history = task.get('history', [])
    if history:
        # Sort by ts descending
        valid_dates = []
        for h in history:
            h_ts = h.get('ts')
            dt = parse_iso(h_ts)
            if dt:
                valid_dates.append(dt)
        if valid_dates:
            latest = max(valid_dates)
            return latest, 'history'
    
    # No valid timestamp
    return None, None

def main():
    with open(TASKS_FILE, 'r') as f:
        tasks = json.load(f)
    
    now = datetime.now(timezone.utc)
    updated = False
    
    for task in tasks:
        if task.get('status') != 'in_progress':
            continue
        
        task_id = task.get('id')
        timestamp, source = get_task_timestamp(task)
        
        # If no valid timestamp, treat as stalled (hard rule)
        if timestamp is None:
            print(f"Task {task_id}: No valid timestamp found, treating as stalled.")
            # Reset to backlog
            task['status'] = 'backlog'
            task['stalledAt'] = now.isoformat()
            # Add history entry
            task.setdefault('history', []).append({
                'ts': now.isoformat(),
                'action': 'stalled_reset',
                'actor': 'heartbeat-stall-check',
                'details': 'No valid timestamp found for in_progress task'
            })
            updated = True
            continue
        
        # Calculate staleness
        staleness = now - timestamp
        staleness_minutes = staleness.total_seconds() / 60
        
        # Check for ghost dispatch fast-path: currentStep is null or "Agent starting…" and lastActivity >60s old
        current_step = task.get('currentStep')
        last_activity = task.get('lastActivity')
        last_activity_dt = parse_iso(last_activity)
        ghost_fast_path = False
        if (current_step is None or current_step == "Agent starting…") and last_activity_dt:
            if (now - last_activity_dt).total_seconds() > 60:
                ghost_fast_path = True
        
        # Hard rule: if lastActivity is null/empty and in_progress for >30 minutes, reset immediately
        last_activity_empty = not last_activity or last_activity.strip() == ''
        if last_activity_empty and staleness_minutes > 30:
            print(f"Task {task_id}: lastActivity empty and stale for {staleness_minutes:.1f} minutes > 30, resetting.")
            task['status'] = 'backlog'
            task['stalledAt'] = now.isoformat()
            task.setdefault('history', []).append({
                'ts': now.isoformat(),
                'action': 'stalled_reset',
                'actor': 'heartbeat-stall-check',
                'details': f'lastActivity empty and stale for {staleness_minutes:.1f} minutes > 30'
            })
            updated = True
            continue
        
        # Ghost dispatch fast-path
        if ghost_fast_path:
            print(f"Task {task_id}: Ghost dispatch fast-path (currentStep: {current_step}, lastActivity >60s old), resetting.")
            task['status'] = 'backlog'
            task['stalledAt'] = now.isoformat()
            task.setdefault('history', []).append({
                'ts': now.isoformat(),
                'action': 'stalled_reset',
                'actor': 'heartbeat-stall-check',
                'details': f'Ghost dispatch fast-path: currentStep={current_step}, lastActivity >60s old'
            })
            updated = True
            continue
        
        # If staleness > 2 hours, reset to backlog
        if staleness_minutes > 120:
            print(f"Task {task_id}: Stale for {staleness_minutes:.1f} minutes > 120, resetting to backlog.")
            task['status'] = 'backlog'
            task['stalledAt'] = now.isoformat()
            task.setdefault('history', []).append({
                'ts': now.isoformat(),
                'action': 'stalled_reset',
                'actor': 'heartbeat-stall-check',
                'details': f'Stale for {staleness_minutes:.1f} minutes > 120'
            })
            updated = True
            continue
        
        # If staleness > 30 minutes but < 2 hours, log warning and check currentStep
        if staleness_minutes > 30:
            print(f"Task {task_id}: Stale for {staleness_minutes:.1f} minutes (30-120), checking currentStep.")
            if current_step is None or current_step == "Agent starting…":
                print(f"Task {task_id}: currentStep is {current_step}, resetting due to stall.")
                task['status'] = 'backlog'
                task['stalledAt'] = now.isoformat()
                task.setdefault('history', []).append({
                    'ts': now.isoformat(),
                    'action': 'stalled_reset',
                    'actor': 'heartbeat-stall-check',
                    'details': f'Stale for {staleness_minutes:.1f} minutes with currentStep={current_step}'
                })
                updated = True
            else:
                print(f"Task {task_id}: currentStep is '{current_step}', no reset.")
    
    if updated:
        print(f"Updating {TASKS_FILE}")
        with open(TASKS_FILE, 'w') as f:
            json.dump(tasks, f, indent=2)
    else:
        print("No stalled tasks found.")

if __name__ == '__main__':
    main()