#!/usr/bin/env python3

import json
from datetime import datetime, timezone
import sys

def load_tasks():
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
        return json.load(f)

def main():
    tasks = load_tasks()
    backlog_tasks = [t for t in tasks if t.get('status') == 'backlog']
    
    print(f"Found {len(backlog_tasks)} backlog tasks:")
    
    for i, task in enumerate(backlog_tasks):
        print(f"\n{i+1}. ID: {task.get('id')}")
        print(f"   Title: {task.get('title')}")
        print(f"   Priority: {task.get('priority')}")
        print(f"   Tags: {task.get('tags', [])}")
        print(f"   Dispatch Count: {task.get('dispatchCount', 0)}")
        print(f"   Stalled At: {task.get('stalledAt')}")
        print(f"   Was Stalled: {task.get('wasStalled')}")
        print(f"   TS: {task.get('ts')}")

if __name__ == '__main__':
    main()