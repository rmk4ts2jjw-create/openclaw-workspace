#!/usr/bin/env python3
import json

def main():
    with open('/Users/spacemonkey/.openclaw/workspace/data/incidents.json', 'r') as f:
        data = json.load(f)
    
    # Assuming data is a list of incidents
    open_incidents = [inc for inc in data if inc.get('status') != 'RESOLVED']
    print(f"Total incidents: {len(data)}")
    print(f"Open incidents: {len(open_incidents)}")
    if len(open_incidents) > 10:
        print("Open incidents > 10, should run auto-resolve")
    else:
        print("Open incidents <= 10, no auto-resolve needed")

if __name__ == '__main__':
    main()