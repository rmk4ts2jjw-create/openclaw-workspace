#!/usr/bin/env python3

import json
from datetime import datetime, timezone
import sys

def load_tasks():
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
        return json.load(f)

def is_eligible_for_night_shift(task):
    # Basic checks
    if task.get('status') != 'backlog':
        return False, "Not backlog"
    
    if task.get('stalledAt') is not None:
        return False, "Has stalledAt"
    
    if task.get('wasStalled') is True:
        return False, "wasStalled is True"
    
    dispatch_count = task.get('dispatchCount', 0)
    if dispatch_count >= 3:
        return False, f"dispatchCount >= 3 ({dispatch_count})"
    
    # Priority check - only P2 and P3 for Night Shift
    priority = task.get('priority', '')
    if priority not in ['P2', 'P3']:
        return False, f"Priority {priority} not P2/P3"
    
    # Exclusion tags
    exclusion_tags = {'needs-human-input', 'planning', 'design', 'roadmap', 'prevention', 'predictive'}
    tags = set(task.get('tags', []))
    if exclusion_tags & tags:
        return False, f"Has exclusion tags: {exclusion_tags & tags}"
    
    return True, "Eligible"

def main():
    tasks = load_tasks()
    eligible = []
    
    for task in tasks:
        eligible_flag, reason = is_eligible_for_night_shift(task)
        if eligible_flag:
            eligible.append((task, reason))
        else:
            # Uncomment to see why tasks are ineligible
            # print(f"Task {task.get('id', 'unknown')}: {reason}")
            pass
    
    # Sort by priority (P2 before P3), then by age (oldest first)
    def sort_key(item):
        task = item[0]
        priority = task.get('priority', '')
        # P2 comes before P3
        priority_order = 0 if priority == 'P2' else 1
        # Older tasks first (using ts field)
        ts_str = task.get('ts', '9999-12-31')
        try:
            # Handle "just now" or other non-ISO formats
            if ts_str == 'just now':
                ts = datetime.now(timezone.utc)
            else:
                ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        except:
            ts = datetime.max.replace(tzinfo=timezone.utc)
        return (priority_order, ts)
    
    eligible.sort(key=sort_key)
    
    print(f"Found {len(eligible)} eligible tasks for Night Shift:")
    for i, (task, reason) in enumerate(eligible[:5]):  # Show first 5
        print(f"{i+1}. ID: {task.get('id')}")
        print(f"   Title: {task.get('title')}")
        print(f"   Priority: {task.get('priority')}")
        print(f"   Tags: {task.get('tags', [])}")
        print(f"   Dispatch Count: {task.get('dispatchCount', 0)}")
        print(f"   TS: {task.get('ts')}")
        print()
    
    if len(eligible) > 0:
        print(f"\nTop {min(2, len(eligible))} tasks that would be dispatched (max 2 per night):")
        for i, (task, reason) in enumerate(eligible[:2]):
            print(f"{i+1}. {task.get('id')} - {task.get('title')}")

if __name__ == '__main__':
    main()