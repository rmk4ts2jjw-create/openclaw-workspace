#!/usr/bin/env python3
"""
RCA Engine — Root Cause Analysis for Mission Control incidents.
Maps error signatures to root causes, suggested fixes, confidence scores,
and validation commands.

Called by auto-detect-incidents.sh via create_incident() to enrich
auto-generated tasks with actionable RCA data.
"""

import json
import os
import re
from datetime import datetime, timezone

# ── Knowledge Base: Error Signatures → Root Causes ──────────────────────────
RCA_SIGNATURES = [
    # SMB / WD mount failures
    {
        "patterns": ["mount", "/Volumes/Public", "/Volumes/OpenClaw-WD", "smb", "WD MyCloud"],
        "root_cause": "WD MyCloud SMB mount dropped — guest session timeout or NAS sleep",
        "suggested_file": "scripts/mount-wd-mycloud.sh",
        "proposed_fix": "Add keepalive cron: bash scripts/mount-wd-mycloud.sh every 10 min. Check NAS sleep settings. Consider dedicated SMB user instead of guest.",
        "agent": "lifesupport",
        "confidence": 85,
        "tags": ["mount", "wd-mycloud", "smb"],
        "validation_command": "mount | grep -q '/Volumes/Public\\|/Volumes/OpenClaw-WD' && echo MOUNT_OK || echo MOUNT_FAIL"
    },
    # Cron job timeouts
    {
        "patterns": ["cron.*timeout", "job execution timed out", "timed out.*cron"],
        "root_cause": "Cron job exceeded model-call timeout — model may be slow or gateway overloaded",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Increase timeoutSeconds for affected cron job. Check gateway log for 429/rate-limit patterns.",
        "agent": "lifesupport",
        "confidence": 80,
        "tags": ["cron", "timeout", "performance"],
        "validation_command": "openclaw cron list 2>/dev/null | grep -cE 'error|failed' | xargs -I{} sh -c 'if [ {} -gt 0 ]; then echo CRON_ERRORS; else echo CRON_OK; fi'"
    },
    # JSON write conflicts / data corruption
    {
        "patterns": ["JSON write", "atomic write", "tasks.json", "data corruption", "write conflict"],
        "root_cause": "Concurrent writes to JSON state files without proper locking — data loss risk",
        "suggested_file": "scripts/maintenance.sh",
        "proposed_fix": "Ensure all write paths use safe_write() (temp file + fsync + rename). Add file locking.",
        "agent": "engineer",
        "confidence": 75,
        "tags": ["data-integrity", "json", "atomic-write"],
        "validation_command": "python3 -c \"import json; json.load(open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json')); print('JSON_OK')\" 2>/dev/null || echo JSON_FAIL"
    },
    # Browser automation stalls
    {
        "patterns": ["browser.*stall", "browser automation", "snapshot failed", "element not found"],
        "root_cause": "Browser automation element ref became stale between snapshot and interaction",
        "suggested_file": "wiki/browser-automation-findings.md",
        "proposed_fix": "Add retry logic with fresh snapshot before each interaction. Increase default timeout.",
        "agent": "engineer",
        "confidence": 70,
        "tags": ["browser-automation", "selenium", "playwright"],
        "validation_command": "openclaw browser status 2>/dev/null | grep -q 'running' && echo BROWSER_OK || echo BROWSER_FAIL"
    },
    # Rate limit / 429 errors
    {
        "patterns": ["429", "rate limit", "rate-limit", "Too Many Requests", "model pool"],
        "root_cause": "OpenRouter free model pool exhausted — too many requests in short window",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Enable FreeRide auto-switching for fallback models. Add exponential backoff to cron jobs.",
        "agent": "lifesupport",
        "confidence": 90,
        "tags": ["rate-limit", "429", "models"],
        "validation_command": "tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -c '429' | xargs -I{} sh -c 'if [ {} -gt 5 ]; then echo RATE_LIMITED; else echo RATE_OK; fi'"
    },
    # Session takeover errors
    {
        "patterns": ["session file changed", "EmbeddedAttemptSessionTakeover", "takeover"],
        "root_cause": "Gateway session lock conflict — embedded prompt released while session file was modified",
        "suggested_file": "openclaw.json",
        "proposed_fix": "Update OpenClaw to latest version. Reduce concurrent cron jobs that access session files.",
        "agent": "engineer",
        "confidence": 80,
        "tags": ["gateway", "session", "takeover"],
        "validation_command": "python3 -c \"import glob,os,time; files=glob.glob(os.path.expanduser('~/.openclaw/agents/main/sessions/*.jsonl')); recent=[f for f in files if os.path.getmtime(f)>time.time()-3600]; errors=[f for f in recent if 'EmbeddedAttemptSessionTakeover' in open(f).read()]; print('TAKEOVER_ERRORS:'+str(len(errors)))\" 2>/dev/null || echo TAKEOVER_CHECK_FAIL"
    },
    # Disk space critical
    {
        "patterns": ["disk", "storage", "low disk", "disk space", "root volume"],
        "root_cause": "Root volume disk usage exceeded threshold — logs, node_modules, or backups consuming space",
        "suggested_file": "scripts/disk-monitor.sh",
        "proposed_fix": "Run ncdu / to identify large directories. Clean old logs (>7d). Prune node_modules in unused repos.",
        "agent": "lifesupport",
        "confidence": 85,
        "tags": ["disk", "storage", "cleanup"],
        "validation_command": "df / | tail -1 | awk '{if ($5+0>85) print \"DISK_LOW\"; else print \"DISK_OK\"}'"
    },
    # Mission Control dashboard down
    {
        "patterns": ["dashboard down", "HTTP 000", "mission control", "port 3000", "dev server"],
        "root_cause": "Vite dev server crashed or port 3000 is occupied by stale process",
        "suggested_file": "scripts/maintenance.sh",
        "proposed_fix": "Step 3 in maintenance.sh handles this automatically. Manual: kill stale process on port 3000 and restart.",
        "agent": "engineer",
        "confidence": 95,
        "tags": ["mission-control", "outage", "vite"],
        "validation_command": "curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost:3000/ 2>/dev/null | grep -q '200' && echo MC_OK || echo MC_DOWN"
    },
    # Stalled tasks
    {
        "patterns": ["stale task", "stuck in progress", "no recent activity", "stalled"],
        "root_cause": "Tasks dispatched but not picked up by agents — ghost dispatch or agent timeout",
        "suggested_file": "scripts/stall-detector.sh",
        "proposed_fix": "Verify stall detector is running (maintenance.sh step 5). Check sub-agent timeout settings.",
        "agent": "monkey",
        "confidence": 80,
        "tags": ["tasks", "stalled", "dispatch"],
        "validation_command": "python3 -c \"import json; tasks=json.load(open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json')); stale=[t for t in tasks if t.get('status')=='in_progress']; print('STALLED:'+str(len(stale)))\" 2>/dev/null || echo STALL_CHECK_FAIL"
    },
    # existsSync leak (Timeline page)
    {
        "patterns": ["existsSync", "client-side leak", "timeline"],
        "root_cause": "Node.js fs.existsSync called in browser context — server-side API leaking into client bundle",
        "suggested_file": "mission-control-dashboard/src/routes/timeline.tsx",
        "proposed_fix": "Move all fs calls to server-only loader functions. Add 'use server' directive.",
        "agent": "engineer",
        "confidence": 85,
        "tags": ["timeline", "existsSync", "client-leak"],
        "validation_command": "grep -r 'existsSync' /Users/spacemonkey/.openclaw/workspace/mission-control-dashboard/src/ 2>/dev/null | grep -v node_modules | wc -l | xargs -I{} sh -c 'if [ {} -gt 0 ]; then echo EXISTSYNC_LEAK; else echo EXISTSYNC_OK; fi'"
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
        result = {
            "root_cause": best_match["root_cause"],
            "suggested_file": best_match["suggested_file"],
            "proposed_fix": best_match["proposed_fix"],
            "suggested_agent": best_match["agent"],
            "confidence": best_match["confidence"],
            "matched_tags": best_match["tags"]
        }
        if "validation_command" in best_match:
            result["validation_command"] = best_match["validation_command"]
        return result
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
        result = analyze(
            "WD MyCloud mount missing — backup storage unavailable",
            "Neither /Volumes/Public nor /Volumes/OpenClaw-WD is mounted.",
            ["wd-mycloud", "mount", "backup"]
        )
        print(json.dumps(result, indent=2))
    elif len(sys.argv) > 3 and sys.argv[1] == "analyze":
        title = sys.argv[2]
        summary = sys.argv[3]
        tags = json.loads(sys.argv[4]) if len(sys.argv) > 4 else []
        result = analyze(title, summary, tags)
        print(json.dumps(result) if result else "null")
    else:
        print("Usage: python3 rca-engine.py test | analyze <title> <summary> <tags_json>")
