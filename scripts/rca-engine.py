#!/usr/bin/env python3
"""
RCA Engine — Root Cause Analysis for Mission Control incidents.
Maps error signatures to root causes, suggested fixes, and confidence scores.

Called by auto-detect-incidents.sh via create_incident() to enrich
auto-generated tasks with actionable RCA data.
"""

import json
import os
import re
from datetime import datetime, timezone

# ── Knowledge Base: Error Signatures → Root Causes ──────────────────────────
# Each entry: (pattern, root_cause, suggested_file, proposed_fix, agent, confidence)
RCA_SIGNATURES = [
    # SMB / WD mount failures
    {
        "patterns": ["mount", "/Volumes/Public", "/Volumes/OpenClaw-WD", "smb", "WD MyCloud"],
        "root_cause": "WD MyCloud SMB mount dropped — guest session timeout or NAS sleep",
        "suggested_file": "scripts/mount-wd-mycloud.sh",
        "proposed_fix": "Add keepalive cron: `bash scripts/mount-wd-mycloud.sh` every 10 min. Check NAS sleep settings. Consider dedicated SMB user instead of guest.",
        "agent": "lifesupport",
        "confidence": 85,
        "tags": ["mount", "wd-mycloud", "smb"]
    },
    # Cron job timeouts
    {
        "patterns": ["cron.*timeout", "job execution timed out", "timed out.*cron"],
        "root_cause": "Cron job exceeded model-call timeout — model may be slow or gateway overloaded",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Increase timeoutSeconds for affected cron job. Check gateway log for 429/rate-limit patterns that indicate model pool exhaustion.",
        "agent": "lifesupport",
        "confidence": 80,
        "tags": ["cron", "timeout", "performance"]
    },
    # JSON write conflicts / data corruption
    {
        "patterns": ["JSON write", "atomic write", "tasks.json", "data corruption", "write conflict"],
        "root_cause": "Concurrent writes to JSON state files without proper locking — data loss risk",
        "suggested_file": "scripts/maintenance.sh",
        "proposed_fix": "Ensure all write paths use safe_write() (temp file + fsync + rename). Add file locking for concurrent access patterns.",
        "agent": "engineer",
        "confidence": 75,
        "tags": ["data-integrity", "json", "atomic-write"]
    },
    # Browser automation stalls
    {
        "patterns": ["browser.*stall", "browser automation", "snapshot failed", "element not found"],
        "root_cause": "Browser automation element ref became stale between snapshot and interaction",
        "suggested_file": "wiki/browser-automation-findings.md",
        "proposed_fix": "Add retry logic with fresh snapshot before each interaction. Increase default timeout. Use aria-label selectors instead of numeric refs where possible.",
        "agent": "engineer",
        "confidence": 70,
        "tags": ["browser-automation", "selenium", "playwright"]
    },
    # Rate limit / 429 errors
    {
        "patterns": ["429", "rate limit", "rate-limit", "Too Many Requests", "model pool"],
        "root_cause": "OpenRouter free model pool exhausted — too many requests in short window",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Enable FreeRide auto-switching for fallback models. Add exponential backoff to cron jobs. Reduce concurrent agent sessions.",
        "agent": "lifesupport",
        "confidence": 90,
        "tags": ["rate-limit", "429", "models"]
    },
    # Session takeover errors
    {
        "patterns": ["session file changed", "EmbeddedAttemptSessionTakeover", "takeover"],
        "root_cause": "Gateway session lock conflict — embedded prompt released while session file was modified",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Update OpenClaw to latest version (session lock fix in 2026.6.x). Reduce concurrent cron jobs that access session files.",
        "agent": "engineer",
        "confidence": 80,
        "tags": ["gateway", "session", "takeover"]
    },
    # Disk space critical
    {
        "patterns": ["disk", "storage", "low disk", "disk space", "root volume"],
        "root_cause": "Root volume disk usage exceeded threshold — logs, node_modules, or backups consuming space",
        "suggested_file": "scripts/disk-monitor.sh",
        "proposed_fix": "Run `ncdu /` to identify large directories. Clean old logs (>7d): `find /tmp/openclaw -mtime +7 -delete`. Prune node_modules in unused repos.",
        "agent": "lifesupport",
        "confidence": 85,
        "tags": ["disk", "storage", "cleanup"]
    },
    # Mission Control dashboard down
    {
        "patterns": ["dashboard down", "HTTP 000", "mission control", "port 3000", "dev server"],
        "root_cause": "Vite dev server crashed or port 3000 is occupied by stale process",
        "suggested_file": "scripts/maintenance.sh",
        "proposed_fix": "Step 3 in maintenance.sh handles this automatically. Manual: `lsof -ti :3000 | xargs kill -9 && cd mission-control-dashboard && bun run dev --host --port 3000 &`",
        "agent": "engineer",
        "confidence": 95,
        "tags": ["mission-control", "outage", "vite"]
    },
    # Stalled tasks
    {
        "patterns": ["stale task", "stuck in progress", "no recent activity", "stalled"],
        "root_cause": "Tasks dispatched but not picked up by agents — ghost dispatch or agent timeout",
        "suggested_file": "scripts/stall-detector.sh",
        "proposed_fix": "Verify stall detector is running (maintenance.sh step 5). Check sub-agent timeout settings. Reset dispatchCount on repeatedly stalled tasks.",
        "agent": "monkey",
        "confidence": 80,
        "tags": ["tasks", "stalled", "dispatch"]
    },
    # existsSync leak (Timeline page)
    {
        "patterns": ["existsSync", "client-side leak", "timeline"],
        "root_cause": "Node.js fs.existsSync called in browser context — server-side API leaking into client bundle",
        "suggested_file": "mission-control-dashboard/src/routes/timeline.tsx",
        "proposed_fix": "Move all fs calls to server-only loader functions. Add 'use server' directive. Use API endpoints instead of direct fs access from components.",
        "agent": "engineer",
        "confidence": 85,
        "tags": ["timeline", "existsSync", "client-leak"]
    },
]


def analyze(title: str, summary: str, tags: list) -> dict:
    """Match incident against known signatures. Returns RCA data or None."""
    text = f"{title} {summary} {' '.join(tags)}".lower()
    
    best_match = None
    best_score = 0
    
    for sig in RCA_SIGNATURES:
        score = 0
        for pattern in sig["patterns"]:
            if pattern.lower() in text:
                score += 1
        if score > best_score:
            best_score = score
            best_match = sig
    
    if best_match and best_score >= 1:
        return {
            "root_cause": best_match["root_cause"],
            "suggested_file": best_match["suggested_file"],
            "proposed_fix": best_match["proposed_fix"],
            "suggested_agent": best_match["agent"],
            "confidence": best_match["confidence"],
            "matched_tags": best_match["tags"]
        }
    return None


def format_rca_note(rca: dict, inc_id: str, inc_summary: str) -> str:
    """Format RCA data into a task note."""
    confidence = rca["confidence"]
    sla = "2-hour SLA" if confidence >= 80 else "4-hour SLA"
    return (
        f"Auto-created from incident {inc_id}: {inc_summary}\n\n"
        f"── RCA Analysis ──\n"
        f"Root cause: {rca['root_cause']}\n"
        f"Confidence: {confidence}% ({sla})\n"
        f"Suggested file: {rca['suggested_file']}\n"
        f"Suggested agent: {rca['suggested_agent']}\n\n"
        f"Proposed fix:\n{rca['proposed_fix']}"
    )


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        # Quick test
        result = analyze(
            "WD MyCloud mount missing — backup storage unavailable",
            "Neither /Volumes/Public nor /Volumes/OpenClaw-WD is mounted.",
            ["wd-mycloud", "mount", "backup"]
        )
        print(json.dumps(result, indent=2))
    elif len(sys.argv) > 3 and sys.argv[1] == "analyze":
        # CLI: rca-engine.py analyze "title" "summary" '["tag1","tag2"]'
        title = sys.argv[2]
        summary = sys.argv[3]
        tags = json.loads(sys.argv[4]) if len(sys.argv) > 4 else []
        result = analyze(title, summary, tags)
        print(json.dumps(result) if result else "null")
    else:
        print("Usage: python3 rca-engine.py test | analyze <title> <summary> <tags_json>")
