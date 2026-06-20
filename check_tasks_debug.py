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
        return False, f"Not backlog (status: {task.get('status')})"
    
    if task.get('stalledAt') is not None:
        return False, f"Has stalledAt: {task.get('stalledAt')}"
    
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
    ineligible = []
    
    for task in tasks:
        eligible_flag, reason = is_eligible_for_night_shift(task)
        if eligible_flag:
            eligible.append((task, reason))
        else:
            ineligible.append((task.get('id', 'unknown'), task.get('title', 'no title'), reason))
    
    print(f"Total tasks: {len(tasks)}")
    print(f"Eligible for Night Shift: {len(eligible)}")
    print(f"Ineligible for Night Shift: {len(ineligible)}")
    
    if len(ineligible) > 0:
        print("\nIneligible tasks (first 10):")
        for i, (task_id, title, reason) in enumerate(ineligible[:10]):
            print(f"{i+1}. {task_id}: {title}")
            print(f"   Reason: {reason}")
            print()

if __name__ == '__main__':
    main()