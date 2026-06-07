#!/usr/bin/env python3
"""
Auto-Healer — automated incident recovery for Mission Control.

For each RCA signature, defines:
- recovery_command: shell command to fix the issue
- rollback_command: shell command to undo if recovery fails
- verify_command: shell command to confirm recovery worked
- risk_level: low / medium / high (controls auto-execute vs manual approval)

Called by fix-validator.py when a Fix task moves to Done.
State: data/auto-heal-state.json
Audit: data/auto-heal-audit.json
Lock: /tmp/auto-healer.lock (flock)

Usage:
  python3 auto-healer.py --dry-run          # Log what would be done
  python3 auto-healer.py --task-id TASK_ID  # Auto-heal for specific task
  python3 auto-healer.py --status           # Show last 10 actions
  python3 auto-healer.py --enable low       # Enable auto-heal for low risk
  python3 auto-healer.py --enable medium    # Enable low+medium
  python3 auto-healer.py --enable all       # Enable all risk levels
"""

import json
import os
import subprocess
import sys
import fcntl
import tempfile
import shutil
from datetime import datetime, timezone

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
STATE_FILE = os.path.join(WORKSPACE, "data/auto-heal-state.json")
AUDIT_FILE = os.path.join(WORKSPACE, "data/auto-heal-audit.json")
LOCK_FILE = "/tmp/auto-healer.lock"
LOG_FILE = os.path.join(WORKSPACE, "logs/auto-heal.log")
TIMEOUT = 30  # seconds per recovery command

# ── Recovery Knowledge Base ─────────────────────────────────────────────────
# Each entry maps an RCA pattern to recovery actions.
# risk_level: low = safe to auto-execute, medium = needs confirmation, high = manual only
RECOVERY_MAP = {
    "mount": {
        "label": "WD MyCloud SMB mount recovery",
        "risk_level": "low",
        "recovery_command": "bash /Users/spacemonkey/.openclaw/workspace/scripts/mount-wd-mycloud.sh 2>&1 || true",
        "rollback_command": "umount /Volumes/Public /Volumes/OpenClaw-WD 2>/dev/null; true",
        "verify_command": "mount | grep -q '/Volumes/Public\\|/Volumes/OpenClaw-WD' && echo MOUNT_OK || echo MOUNT_FAIL",
        "description": "Remount WD MyCloud SMB shares"
    },
    "cron_latency": {
        "label": "Cron job optimization",
        "risk_level": "medium",
        "recovery_command": "openclaw cron list --json 2>/dev/null | python3 -c \"import json,sys; data=json.load(sys.stdin); [print(f'  {c[\\\"name\\\"]}: {c.get(\\\"lastRun\\\",{}).get(\\\"durationMs\\\",0)/1000:.0f}s') for c in data if c.get('lastRun',{}).get('durationMs',0)>30000]\" 2>/dev/null || true",
        "rollback_command": "true",  # Read-only, no rollback needed
        "verify_command": "openclaw cron list 2>/dev/null | grep -cE 'error|failed' | xargs -I{} sh -c 'if [ {} -gt 0 ]; then echo CRON_ERRORS; else echo CRON_OK; fi'",
        "description": "Identify slow cron jobs for optimization"
    },
    "memory_trend": {
        "label": "Memory pressure relief",
        "risk_level": "medium",
        "recovery_command": "sync && sudo purge 2>/dev/null; echo 'Memory purge attempted'",
        "rollback_command": "true",  # Can't un-purge, but it's safe
        "verify_command": "vm_stat | grep 'Pages free' | awk '{print $3}' | head -1 | xargs -I{} sh -c 'if [ {} -gt 100000 ]; then echo MEM_OK; else echo MEM_LOW; fi'",
        "description": "Purge inactive memory pages"
    },
    "task_stall": {
        "label": "Stalled task reset",
        "risk_level": "low",
        "recovery_command": "python3 /Users/spacemonkey/.openclaw/workspace/scripts/stall-detector.sh 2>&1 || true",
        "rollback_command": "true",  # Stall detector is read-only + safe resets
        "verify_command": "python3 -c \"import json; tasks=json.load(open('/Users/spacemonkey/.openclaw/workspace/data/tasks.json')); stuck=[t for t in tasks if t.get('status')=='in_progress']; print('STALLED:'+str(len(stuck)))\" 2>/dev/null || echo STALL_CHECK_FAIL",
        "description": "Run stall detector to reset stuck tasks"
    },
    "smb_retries": {
        "label": "SMB connection recovery",
        "risk_level": "low",
        "recovery_command": "bash /Users/spacemonkey/.openclaw/workspace/scripts/mount-wd-mycloud.sh 2>&1 || true",
        "rollback_command": "umount /Volumes/Public /Volumes/OpenClaw-WD 2>/dev/null; true",
        "verify_command": "mount | grep -q '/Volumes/Public\\|/Volumes/OpenClaw-WD' && echo MOUNT_OK || echo MOUNT_FAIL",
        "description": "Remount SMB shares to clear retry state"
    },
    "rate_limit": {
        "label": "Rate limit cooldown",
        "risk_level": "low",
        "recovery_command": "echo 'Rate limit: waiting 60s for cooldown' && sleep 60 && echo 'Cooldown complete'",
        "rollback_command": "true",
        "verify_command": "tail -50 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null | grep -c '429' | xargs -I{} sh -c 'if [ {} -lt 3 ]; then echo RATE_OK; else echo RATE_HIGH; fi'",
        "description": "Wait for rate limit cooldown period"
    },
    "session_takeover": {
        "label": "Session file cleanup",
        "risk_level": "high",
        "recovery_command": "openclaw sessions cleanup 2>&1 || true",
        "rollback_command": "true",
        "verify_command": "python3 -c \"import glob,os,time; files=glob.glob(os.path.expanduser('~/.openclaw/agents/main/sessions/*.jsonl')); recent=[f for f in files if os.path.getmtime(f)>time.time()-3600]; errors=[f for f in recent if 'EmbeddedAttemptSessionTakeover' in open(f).read()]; print('TAKEOVER:'+str(len(errors)))\" 2>/dev/null || echo TAKEOVER_CHECK_FAIL",
        "description": "Clean up stale session files"
    },
    "disk": {
        "label": "Disk space cleanup",
        "risk_level": "medium",
        "recovery_command": "find /tmp/openclaw/logs -name '*.log' -mtime +7 -delete 2>/dev/null; find /Users/spacemonkey/.openclaw/workspace/logs -name '*.log' -mtime +7 -delete 2>/dev/null; echo 'Old logs cleaned'",
        "rollback_command": "true",  # Logs are disposable
        "verify_command": "df / | tail -1 | awk '{if ($5+0<85) print \"DISK_OK\"; else print \"DISK_LOW\"}'",
        "description": "Clean old log files to free disk space"
    },
    "dashboard_down": {
        "label": "Mission Control restart",
        "risk_level": "medium",
        "recovery_command": "lsof -ti:3000 2>/dev/null | xargs kill -9 2>/dev/null; cd /Users/spacemonkey/.openclaw/workspace/mission-control-dashboard && bun run dev --host --port 3000 &>/dev/null & echo 'MC restart initiated'",
        "rollback_command": "true",
        "verify_command": "sleep 5 && curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://localhost:3000/ 2>/dev/null | grep -q '200' && echo MC_OK || echo MC_DOWN",
        "description": "Kill and restart Vite dev server on port 3000"
    },
    "existsSync": {
        "label": "Client-side leak fix",
        "risk_level": "high",
        "recovery_command": "echo 'existsSync leak requires code fix — cannot auto-heal. Create a task instead.'",
        "rollback_command": "true",
        "verify_command": "grep -r 'existsSync' /Users/spacemonkey/.openclaw/workspace/mission-control-dashboard/src/ 2>/dev/null | grep -v node_modules | wc -l | xargs -I{} sh -c 'if [ {} -gt 0 ]; then echo EXISTSYNC_LEAK; else echo EXISTSYNC_OK; fi'",
        "description": "existsSync leak requires manual code fix"
    },
}


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")
    print(msg)


def load_json(path, default):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return default


def save_json(path, data):
    try:
        if os.path.exists(path):
            shutil.copy2(path, path + ".bak")
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', suffix='.tmp')
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(data, f, indent=2)
                f.flush()
                os.fsync(f.fileno())
            os.rename(tmp, path)
        except:
            if os.path.exists(tmp):
                os.remove(tmp)
            raise
    except Exception as e:
        log(f"save_json error: {e}")


def run_cmd(cmd, timeout=TIMEOUT):
    """Run a shell command with timeout. Returns (stdout, stderr, returncode)."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", "TIMEOUT", -1
    except Exception as e:
        return "", str(e), -1


def acquire_lock():
    """Acquire exclusive lock. Returns file handle or None."""
    try:
        fh = open(LOCK_FILE, "w")
        fcntl.flock(fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fh
    except:
        return None


def release_lock(fh):
    if fh:
        fcntl.flock(fh.fileno(), fcntl.LOCK_UN)
        fh.close()


def get_enabled_risks(state):
    """Get set of enabled risk levels from state."""
    level = state.get("auto_heal_level", "none")
    if level == "all":
        return {"low", "medium", "high"}
    elif level == "medium":
        return {"low", "medium"}
    elif level == "low":
        return {"low"}
    return set()


def match_recovery(task_tags, task_title, task_note):
    """Match a task to recovery patterns. Returns list of matching pattern keys."""
    text = f"{task_title} {task_note} {' '.join(task_tags)}".lower()
    matches = []
    for key, recovery in RECOVERY_MAP.items():
        # Match by tag
        if key in [t.lower() for t in task_tags]:
            matches.append(key)
            continue
        # Match by keyword in title/note
        keywords = recovery["label"].lower().split()
        if any(kw in text for kw in keywords if len(kw) > 3):
            matches.append(key)
    return matches


def execute_recovery(pattern_key, dry_run=False):
    """Execute recovery for a pattern. Returns result dict."""
    recovery = RECOVERY_MAP[pattern_key]
    result = {
        "pattern": pattern_key,
        "label": recovery["label"],
        "risk_level": recovery["risk_level"],
        "dry_run": dry_run,
        "ts": datetime.now(timezone.utc).isoformat(),
    }

    if dry_run:
        result["status"] = "dry_run"
        result["would_execute"] = recovery["recovery_command"]
        return result

    # Execute recovery
    log(f"  Executing: {recovery['label']}")
    stdout, stderr, rc = run_cmd(recovery["recovery_command"])
    result["recovery_output"] = stdout[:500]
    result["recovery_stderr"] = stderr[:200] if stderr else ""
    result["recovery_rc"] = rc

    if rc == -1 and "TIMEOUT" in stderr:
        result["status"] = "timeout"
        log(f"  TIMEOUT: {recovery['label']}")
        return result

    # Verify
    vout, _, vrc = run_cmd(recovery["verify_command"])
    result["verify_output"] = vout
    result["verify_rc"] = vrc

    if vrc == 0 and ("OK" in vout or "0" in vout):
        result["status"] = "success"
        log(f"  SUCCESS: {recovery['label']} — {vout}")
    else:
        # Try rollback
        log(f"  VERIFY FAILED: {vout} — attempting rollback")
        rout, _, rrc = run_cmd(recovery["rollback_command"])
        result["rollback_output"] = rout[:200]
        result["rollback_rc"] = rrc
        result["status"] = "rollback"
        log(f"  ROLLBACK: {recovery['label']}")

    return result


def auto_heal_task(task_id, dry_run=False):
    """Auto-heal for a specific task."""
    state = load_json(STATE_FILE, {"auto_heal_level": "none", "total_heals": 0, "success_count": 0, "fail_count": 0})
    audit = load_json(AUDIT_FILE, [])
    enabled_risks = get_enabled_risks(state)

    # Load task
    tasks_file = os.path.join(WORKSPACE, "data/tasks.json")
    with open(tasks_file) as f:
        tasks = json.load(f)

    task = None
    for t in tasks:
        if t["id"] == task_id:
            task = t
            break

    if not task:
        log(f"Task {task_id} not found")
        return None

    # Match recovery patterns
    tags = task.get("tags", [])
    title = task.get("title", "")
    note = task.get("note", "")
    matches = match_recovery(tags, title, note)

    if not matches:
        log(f"No recovery patterns matched for {task_id}")
        return None

    # Acquire lock
    lock = acquire_lock()
    if not lock:
        log("Another auto-heal is running — skipping")
        return None

    results = []
    try:
        for pattern in matches:
            recovery = RECOVERY_MAP[pattern]
            risk = recovery["risk_level"]

            if risk not in enabled_risks:
                log(f"  SKIP [{pattern}]: risk={risk} not enabled (current: {state.get('auto_heal_level', 'none')})")
                results.append({
                    "pattern": pattern, "status": "skipped",
                    "reason": f"risk={risk} not enabled"
                })
                continue

            result = execute_recovery(pattern, dry_run)
            results.append(result)

            # Update counters
            state["total_heals"] = state.get("total_heals", 0) + 1
            if result["status"] == "success":
                state["success_count"] = state.get("success_count", 0) + 1
            elif result["status"] in ("rollback", "timeout"):
                state["fail_count"] = state.get("fail_count", 0) + 1

        # Audit entry
        audit_entry = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "task_id": task_id,
            "task_title": title[:80],
            "dry_run": dry_run,
            "results": results
        }
        audit.append(audit_entry)
        audit = audit[-200:]  # Keep last 200

        save_json(STATE_FILE, state)
        save_json(AUDIT_FILE, audit)

    finally:
        release_lock(lock)

    return results


def show_status():
    """Show auto-heal status."""
    state = load_json(STATE_FILE, {"auto_heal_level": "none", "total_heals": 0, "success_count": 0, "fail_count": 0})
    audit = load_json(AUDIT_FILE, [])

    print(f"Auto-Heal Status")
    print(f"  Level: {state.get('auto_heal_level', 'none')}")
    print(f"  Total heals: {state.get('total_heals', 0)}")
    print(f"  Success: {state.get('success_count', 0)}")
    print(f"  Failed: {state.get('fail_count', 0)}")
    print(f"  Audit entries: {len(audit)}")
    print()

    if audit:
        print("Last 10 actions:")
        for entry in audit[-10:]:
            ts = entry["ts"][:19]
            task = entry["task_id"][:30]
            dry = " [DRY]" if entry.get("dry_run") else ""
            results = ", ".join(f"{r['pattern']}={r['status']}" for r in entry.get("results", []))
            print(f"  {ts} | {task}{dry} | {results}")

    print()
    print("Recovery patterns:")
    for key, rec in RECOVERY_MAP.items():
        print(f"  [{rec['risk_level']:6s}] {key:20s} — {rec['label']}")


def set_level(level):
    """Set auto-heal risk level."""
    state = load_json(STATE_FILE, {})
    state["auto_heal_level"] = level
    save_json(STATE_FILE, state)
    enabled = get_enabled_risks(state)
    print(f"Auto-heal level set to: {level}")
    print(f"Enabled risk levels: {', '.join(sorted(enabled)) if enabled else 'none'}")


def main():
    args = sys.argv[1:]

    if not args:
        show_status()
        return

    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    if not args or args[0] == "--status":
        show_status()
    elif args[0] == "--task-id":
        task_id = args[1] if len(args) > 1 else None
        if task_id:
            auto_heal_task(task_id, dry_run=dry_run)
        else:
            print("Usage: auto-healer.py --task-id TASK_ID [--dry-run]")
    elif args[0] == "--enable":
        level = args[1] if len(args) > 1 else "low"
        set_level(level)
    else:
        print("Usage:")
        print("  auto-healer.py --status")
        print("  auto-healer.py --task-id TASK_ID [--dry-run]")
        print("  auto-healer.py --enable [low|medium|all]")


if __name__ == "__main__":
    main()
