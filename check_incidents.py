#!/usr/bin/env python3

import json

def load_incidents():
    with open('/Users/spacemonkey/.openclaw/workspace/data/incidents.json', 'r') as f:
        return json.load(f)

def main():
    incidents = load_incidents()
    
    # Count by status
    status_counts = {}
    open_incidents = []
    
    for incident in incidents:
        status = incident.get('status', 'UNKNOWN')
        status_counts[status] = status_counts.get(status, 0) + 1
        
        if status != 'RESOLVED':
            open_incidents.append(incident)
    
    print("Incident status counts:")
    for status, count in sorted(status_counts.items()):
        print(f"  {status}: {count}")
    
    print(f"\nTotal incidents: {len(incidents)}")
    print(f"Open incidents (non-RESOLVED): {len(open_incidents)}")
    
    if len(open_incidents) > 0:
        print("\nOpen incidents:")
        for incident in open_incidents:
            print(f"  {incident.get('id')}: {incident.get('title')} ({incident.get('status')})")

if __name__ == '__main__':
    main()