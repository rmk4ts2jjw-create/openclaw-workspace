#!/usr/bin/env python3
import json

def main():
    with open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json', 'r') as f:
        data = json.load(f)
    
    backlog = [task for task in data if task.get('status') == 'backlog']
    print(f"Found {len(backlog)} backlog tasks")
    for task in backlog:
        tid = task.get('id', 'NO ID')
        prio = task.get('priority', 'NO PRIO')
        tags = task.get('tags', [])
        stalledAt = task.get('stalledAt')
        dispatchCount = task.get('dispatchCount', 0)
        wasStalled = task.get('wasStalled')
        currentStep = task.get('currentStep')
        ts = task.get('ts', 'NO TS')
        print("ID: " + tid)
        print("  Priority: " + prio + ", Tags: " + str(tags))
        print("  stalledAt: " + str(stalledAt) + ", dispatchCount: " + str(dispatchCount) + ", wasStalled: " + str(wasStalled) + ", currentStep: " + str(currentStep) + ", ts: " + ts)
        print("---")

if __name__ == '__main__':
    main()