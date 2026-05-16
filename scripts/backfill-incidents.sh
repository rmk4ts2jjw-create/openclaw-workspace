#!/bin/bash
# Backfill incidents from the past 3 days
# Directly writes to incidents.json since the createIncident server fn needs a running server

WORKSPACE="/Users/spacemonkey/.openclaw/workspace"
INCIDENTS_FILE="$WORKSPACE/data/incidents.json"

echo "=== Backfilling incidents ==="

python3 << 'PYEOF'
import json, os
from datetime import datetime

workspace = os.environ.get("WORKSPACE", "/Users/spacemonkey/.openclaw/workspace")
incidents_path = os.path.join(workspace, "data", "incidents.json")

# Read existing
if os.path.exists(incidents_path):
    with open(incidents_path) as f:
        incidents = json.load(f)
else:
    incidents = []

def next_id(incs):
    nums = []
    for i in incs:
        m = i["id"].split("-")
        if len(m) == 2 and m[1].isdigit():
            nums.append(int(m[1]))
    return f"INC-{str(max(nums) + 1 if nums else 1).zfill(3)}"

def is_dup(incs, title, source):
    return any(i["status"] != "RESOLVED" and i["title"] == title and source in i.get("tags", []) for i in incs)

def make_incident(incidents, title, severity, owner, summary, tags, source):
    if is_dup(incidents, title, source):
        print(f"  SKIP (dup): {title[:60]}")
        return None
    now = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
    inc = {
        "id": next_id(incidents),
        "title": title,
        "severity": severity,
        "status": "TRIAGE",
        "owner": owner,
        "acknowledged": False,
        "escalated": False,
        "opened": now,
        "lastActivity": now,
        "summary": summary,
        "tags": list(tags) + [source],
        "timeline": [{"ts": now, "message": f"Backfilled from logs by {source}", "actor": "system"}],
        "actions": []
    }
    print(f"  CREATE: {inc['id']} [{severity}] {title[:60]}")
    return inc

new_incidents = []

# INC-005: Mission Control outage
inc = make_incident(incidents,
    "Mission Control down — LaunchAgent pointing to deleted Wrangler binary",
    "P1", "engineer",
    "The LaunchAgent com.openclaw.mission-control was pointing to a Wrangler binary in ~/Downloads/agent-control-station-main which no longer exists. Exit code 78 (EX_CONFIG) accumulated 9,473 restart attempts. The current Vite process was an unmanaged orphan.",
    {"mission-control", "launchagent", "outage", "wrangler"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-006: Rate limit exhaustion
inc = make_incident(incidents,
    "Rate limit exhaustion — all models returned 429 starting May 15 19:42",
    "P1", "lifesupport",
    "Starting 2026-05-15 19:42, owl-alpha began failing with all_keys_exhausted errors. The watcher log shows continuous rotation failures every ~16 minutes through 2026-05-16 00:49 (17+ failures). All API keys were exhausted, leaving the agent unable to process requests for several hours.",
    {"rate-limit", "models", "429", "all-keys-exhausted"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-007: Cron job failures
inc = make_incident(incidents,
    "Cron job failures — Git Auto-Commit timeout and Activity Summary failing",
    "P2", "lifesupport",
    "Multiple cron jobs have been failing: Git Auto-Commit timeout, Activity Summary fail. The cron-errors.json shows 6 active error entries. Daily station check at 23:00 has been impacted.",
    {"cron", "failures", "git", "activity-summary"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-008: WD MyCloud mount issues
inc = make_incident(incidents,
    "WD MyCloud mount failing — /Volumes/Public-1 not found (persistent since May 16 06:18)",
    "P2", "lifesupport",
    "The mount-check.log shows continuous /Volumes/Public-1 not found errors every 30 minutes since at least 2026-05-16 06:18 (20+ errors). Backup scripts depending on this mount path are failing silently.",
    {"wd-mycloud", "mount", "backup", "storage"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-009: Tasks stuck In Progress
inc = make_incident(incidents,
    "Tasks stuck In Progress — 3 tasks with no assignee or recent activity",
    "P3", "monkey",
    "Three tasks (Error Feed behaviour review, Task Completion summary, Agent Office Overall) have been in In Progress state with no assigned owner. No activity updates visible. Tasks may be orphaned from agent assignments.",
    {"tasks", "stale", "in-progress", "orphaned"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-010: Build error — AnimatePresence SSR failure
inc = make_incident(incidents,
    "Build error — AnimatePresence SSR failure in Dashboard component",
    "P2", "engineer",
    "ReferenceError: AnimatePresence is not defined at StationChatter in Dashboard.tsx. The awaitingReviewCount variable was defined inside QuickActionsPanel but referenced in the parent Dashboard component — a scoping bug causing SSR crash on the /visual page.",
    {"build", "ssr", "dashboard", "animation"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-011: Port conflict
inc = make_incident(incidents,
    "Port conflict — Mission Control dev server jumping between 3000 and 3001",
    "P3", "engineer",
    "When the LaunchAgent restarts the dev server, it sometimes finds port 3000 still occupied by the previous process and falls back to 3001. This causes confusion about which port is serving the live app and can result in stale builds being served.",
    {"port", "conflict", "dev-server", "launchagent"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# INC-012: Disk space warning
inc = make_incident(incidents,
    "Disk space warning — Data volume at 85% (175 Gi / 228 Gi)",
    "P3", "lifesupport",
    "Health log from 2026-05-15 12:03 shows /System/Volumes/Data at 85% usage (175 Gi / 228 Gi). Swap/compressor usage notable at ~21.9 GB. Approaching threshold where system performance may degrade.",
    {"disk", "storage", "warning", "swap"}, "backfill-2026-05-16")
if inc: new_incidents.append(inc)

# Prepend new incidents
incidents = new_incidents + incidents

with open(incidents_path, "w") as f:
    json.dump(incidents, f, indent=2)

print(f"\n=== Done: {len(new_incidents)} new incidents created ===")
print(f"Total incidents: {len(incidents)}")
for i in incidents:
    print(f"  {i['id']} [{i['severity']}] ({i['status']}) {i['title'][:70]}")
PYEOF