#!/bin/bash
# incident-dedup.sh — Consolidate duplicate open incidents
#
# Finds open incidents with matching fingerprints and merges them:
# - Keeps the oldest (primary) incident
# - Closes duplicates as "DUPLICATE" with reference to primary
# - Merges timelines and tags
#
# Called by maintenance.sh or cron
# Pure Python — zero model calls

WORKSPACE="$HOME/.openclaw/workspace"
INCIDENTS_FILE="$WORKSPACE/data/incidents.json"
LOG_FILE="$WORKSPACE/logs/incident-dedup.log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

mkdir -p "$WORKSPACE/logs"

echo "$(timestamp) [DEDUP] Running incident deduplication..." >> "$LOG_FILE"

python3 << 'PYEOF'
import json, os, shutil, tempfile
from datetime import datetime, timezone, timedelta

incidents_file = os.environ.get("INCIDENTS_FILE", "/Users/spacemonkey/.openclaw/workspace/data/incidents.json")
log_file = os.environ.get("LOG_FILE", "/Users/spacemonkey/.openclaw/workspace/logs/incident-dedup.log")

def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, "a") as f:
        f.write(f"[{ts}] [DEDUP] {msg}\n")
    print(msg)

def safe_write(path, data):
    try:
        if os.path.exists(path):
            shutil.copy2(path, path + ".bak")
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', suffix='.tmp')
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.rename(tmp, path)
    except Exception as e:
        log(f"safe_write error: {e}")

def compute_fingerprint(title, tags):
    import hashlib, re
    normalized = title.lower().strip()
    normalized = re.sub(r'\b\d+\b', 'N', normalized)
    normalized = re.sub(r'\s*—\s*', ' ', normalized)
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    tag_str = ','.join(sorted(t.lower() for t in tags))
    return hashlib.md5(f"{normalized}|{tag_str}".encode()).hexdigest()[:12]

# Load incidents
if not os.path.exists(incidents_file):
    log("No incidents file found")
    exit(0)

with open(incidents_file) as f:
    incidents = json.load(f)

now = datetime.now(timezone.utc).isoformat()

# Step 1: Backfill fingerprints on incidents that don't have them
backfilled = 0
for inc in incidents:
    if not inc.get("_fingerprint") and inc.get("status") != "RESOLVED":
        tags = inc.get("tags", [])
        inc["_fingerprint"] = compute_fingerprint(inc.get("title", ""), tags)
        backfilled += 1

if backfilled:
    log(f"Backfilled {backfilled} fingerprints")

# Step 2: Find duplicate groups among non-RESOLVED incidents
from collections import defaultdict

# Group by fingerprint
fp_groups = defaultdict(list)
for inc in incidents:
    if inc.get("status") == "RESOLVED":
        continue
    fp = inc.get("_fingerprint", "")
    if fp:
        fp_groups[fp].append(inc)

# Also group by exact title (for incidents without fingerprints)
title_groups = defaultdict(list)
for inc in incidents:
    if inc.get("status") == "RESOLVED":
        continue
    if not inc.get("_fingerprint"):
        title_groups[inc.get("title", "")].append(inc)

merged_count = 0

# Process fingerprint groups
for fp, group in fp_groups.items():
    if len(group) <= 1:
        continue
    
    # Sort by opened date — oldest is primary
    group.sort(key=lambda x: x.get("opened", ""))
    primary = group[0]
    duplicates = group[1:]
    
    for dup in duplicates:
        # Only merge if duplicate is within 24h of primary
        try:
            primary_opened = datetime.fromisoformat(primary.get("opened", "").replace("Z", "+00:00"))
            dup_opened = datetime.fromisoformat(dup.get("opened", "").replace("Z", "+00:00"))
            if (dup_opened - primary_opened) > timedelta(hours=24):
                continue
        except:
            continue
        
        log(f"Merging {dup['id']} → {primary['id']} (fingerprint: {fp})")
        
        # Merge timeline from duplicate into primary
        for event in dup.get("timeline", []):
            event["message"] = f"[From {dup['id']}] {event.get('message', '')}"
            primary["timeline"].append(event)
        
        # Merge tags (union)
        primary_tags = set(primary.get("tags", []))
        dup_tags = set(dup.get("tags", []))
        primary["tags"] = sorted(primary_tags | dup_tags)
        
        # Update primary summary
        recurrence = primary.get("_recurrence", 1) + 1
        primary["_recurrence"] = recurrence
        primary["lastActivity"] = now
        primary["timeline"].append({
            "ts": now,
            "message": f"Consolidated duplicate {dup['id']} (recurrence #{recurrence})",
            "actor": "system"
        })
        
        # Close duplicate
        dup["status"] = "RESOLVED"
        dup["resolved"] = now
        dup["lastActivity"] = now
        dup["summary"] = f"DUPLICATE of {primary['id']}: {dup.get('summary', '')}"
        dup["timeline"].append({
            "ts": now,
            "message": f"Auto-closed as duplicate of {primary['id']} by incident-dedup.sh",
            "actor": "system"
        })
        dup["_duplicateOf"] = primary["id"]
        
        merged_count += 1

# Process title-only groups (for incidents without fingerprints)
for title, group in title_groups.items():
    if len(group) <= 1:
        continue
    if not title:
        continue
    
    group.sort(key=lambda x: x.get("opened", ""))
    primary = group[0]
    duplicates = group[1:]
    
    for dup in duplicates:
        try:
            primary_opened = datetime.fromisoformat(primary.get("opened", "").replace("Z", "+00:00"))
            dup_opened = datetime.fromisoformat(dup.get("opened", "").replace("Z", "+00:00"))
            if (dup_opened - primary_opened) > timedelta(hours=24):
                continue
        except:
            continue
        
        log(f"Merging {dup['id']} → {primary['id']} (title match)")
        
        for event in dup.get("timeline", []):
            event["message"] = f"[From {dup['id']}] {event.get('message', '')}"
            primary["timeline"].append(event)
        
        primary_tags = set(primary.get("tags", []))
        dup_tags = set(dup.get("tags", []))
        primary["tags"] = sorted(primary_tags | dup_tags)
        
        recurrence = primary.get("_recurrence", 1) + 1
        primary["_recurrence"] = recurrence
        primary["lastActivity"] = now
        
        dup["status"] = "RESOLVED"
        dup["resolved"] = now
        dup["lastActivity"] = now
        dup["summary"] = f"DUPLICATE of {primary['id']}: {dup.get('summary', '')}"
        dup["timeline"].append({
            "ts": now,
            "message": f"Auto-closed as duplicate of {primary['id']} by incident-dedup.sh",
            "actor": "system"
        })
        dup["_duplicateOf"] = primary["id"]
        
        merged_count += 1

if merged_count > 0:
    safe_write(incidents_file, incidents)
    log(f"Merged {merged_count} duplicate incidents")
else:
    log("No duplicates found")

# Stats
open_count = sum(1 for i in incidents if i.get("status") != "RESOLVED")
resolved_count = sum(1 for i in incidents if i.get("status") == "RESOLVED")
log(f"Stats: {open_count} open, {resolved_count} resolved, {len(incidents)} total")
PYEOF

echo "$(timestamp) [DEDUP] Complete" >> "$LOG_FILE"
