#!/usr/bin/env python3
"""Auto-resolve stale incidents.
- Resolves incidents whose linked tasks are done
- Closes orphan incidents (no linked task) older than N days
"""
import json
import sys
from datetime import datetime, timezone, timedelta

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
INCIDENTS_FILE = f"{WORKSPACE}/data/incidents.json"
TASKS_FILE = f"{WORKSPACE}/data/tasks.json"

def main():
    close_old_days = int(sys.argv[1]) if len(sys.argv) > 1 else 5

    with open(INCIDENTS_FILE) as f:
        incidents = json.load(f)
    with open(TASKS_FILE) as f:
        tasks = json.load(f)

    task_map = {t["id"]: t for t in tasks}
    now = datetime.now(timezone.utc)
    resolved = []
    closed = []

    for inc in incidents:
        if inc.get("status") == "RESOLVED":
            continue

        linked_task_id = inc.get("linkedTaskId")
        created_ts = inc.get("ts") or inc.get("createdAt")

        if linked_task_id and linked_task_id in task_map:
            task = task_map[linked_task_id]
            if task.get("status") == "done":
                inc["status"] = "RESOLVED"
                inc["resolvedAt"] = now.isoformat()
                inc["resolution"] = f"Auto-resolved: linked task {linked_task_id} is done"
                resolved.append(inc["id"])
                continue

        # Orphan: no linked task, old enough to close
        if not linked_task_id and created_ts:
            try:
                created = datetime.fromisoformat(created_ts.replace("Z", "+00:00"))
                age_days = (now - created).days
                if age_days >= close_old_days:
                    inc["status"] = "RESOLVED"
                    inc["resolvedAt"] = now.isoformat()
                    inc["resolution"] = f"Auto-closed: orphan incident, {age_days} days old (threshold: {close_old_days})"
                    closed.append(inc["id"])
            except (ValueError, TypeError):
                pass

    with open(INCIDENTS_FILE, "w") as f:
        json.dump(incidents, f, indent=2)

    print(f"✅ Auto-resolve complete: {len(resolved)} resolved, {len(closed)} closed")
    if resolved:
        print(f"  Resolved: {', '.join(resolved)}")
    if closed:
        print(f"  Closed: {', '.join(closed)}")
    remaining = [i for i in incidents if i.get("status") != "RESOLVED"]
    print(f"  Remaining open: {len(remaining)}")

if __name__ == "__main__":
    main()
