#!/usr/bin/env python3
import json
import sys
from datetime import datetime, timezone

def is_eligible(task):
    # Check status
    if task.get('status') != 'backlog':
        return False
    # Check stalledAt
    if task.get('stalledAt') is not None:
        return False
    # Check dispatchCount
    if task.get('dispatchCount', 0) >= 3:
        return False
    # Check wasStalled
    if task.get('wasStalled') is True:
        return False
    # Check tags for exclusions
    excluded_tags = {"needs-human-input", "planning", "design", "roadmap", 
                     "phase-2-dependent", "phase-3-dependent", "large-change",
                     "prevention", "predictive"}
    tags = set(task.get('tags', []))
    if excluded_tags & tags:
        return False
    # Check currentStep (should be null for backlog, but just in case)
    if task.get('currentStep') is not None:
        return False
    return True

def task_priority(task):
    # Return a tuple for sorting: priority order P1 < P2 < P3 (so P1 comes first)
    prio = task.get('priority', 'P3')
    # Convert to number: P1 -> 0, P2 -> 1, P3 -> 2
    prio_map = {'P1': 0, 'P2': 1, 'P3': 2}
    return prio_map.get(prio, 99)

def task_age(task):
    # Older tasks have smaller ts (earlier time)
    ts_str = task.get('ts', '')
    try:
        # Parse the timestamp string to datetime for comparison
        # Handle ISO format and "just now"
        if ts_str == 'just now':
            return datetime.now(timezone.utc)
        # Remove timezone info for simplicity, but we want to compare
        # We'll assume it's ISO format with or without timezone
        # If it has timezone, we'll strip it and treat as UTC? Not perfect but okay for ordering
        # We'll just use the string lexicographically for now because the format is consistent
        return ts_str
    except:
        return ts_str

def main():
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
        data = json.load(f)
    
    eligible = [task for task in data if is_eligible(task)]
    if not eligible:
        print("No eligible tasks found")
        sys.exit(1)
    
    # Sort by priority (P1 first), then by age (oldest first)
    eligible.sort(key=lambda t: (task_priority(t), task_age(t)))
    
    selected = eligible[0]
    print(selected['id'])

if __name__ == '__main__':
    main()