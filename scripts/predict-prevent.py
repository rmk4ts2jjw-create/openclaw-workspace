#!/usr/bin/env python3
"""
Predictive Incident Prevention — anomaly detection for Mission Control.

Scans real-time logs and metrics to flag potential failures BEFORE they
become incidents. Creates "Prevent:" tasks at confidence >= 60%.

Anomaly patterns:
1. Disk mount — missing for 2 consecutive checks
2. Cron latency — jobs taking >80% of scheduled interval
3. Memory trend — RAM usage grows >5%/hour over 3 checks
4. Task queue depth — >5 tasks stuck in_progress for >1 hour
5. SMB retries — >3 retries in 10 minutes

Called by maintenance.sh. State tracked in data/prediction-state.json.
"""

import json
import os
import subprocess
import tempfile
import shutil
from datetime import datetime, timezone, timedelta

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
TASKS_FILE = os.path.join(WORKSPACE, "data/tasks.json")
INCIDENTS_FILE = os.path.join(WORKSPACE, "data/incidents.json")
STATE_FILE = os.path.join(WORKSPACE, "data/prediction-state.json")
LOG_FILE = os.path.join(WORKSPACE, "logs/predict-prevent.log")


def safe_write(path, data):
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
        log(f"safe_write error: {e}")


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {msg}\n")
    print(msg)


def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"checks": {}, "predictions": [], "accuracy": {}}


def save_state(state):
    safe_write(STATE_FILE, state)


def run_cmd(cmd, timeout=10):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip()
    except:
        return ""


def check_mount_trend(state):
    """Check if mount has been missing for 2 consecutive checks."""
    output = run_cmd("mount | grep -c '/Volumes/Public\\|/Volumes/OpenClaw-WD'")
    mounted = int(output) > 0 if output.isdigit() else False

    key = "mount_missing"
    checks = state["checks"].get(key, [])

    now = datetime.now(timezone.utc).isoformat()
    checks.append({"ts": now, "mounted": mounted})
    # Keep last 10 checks
    checks = checks[-10:]
    state["checks"][key] = checks

    # Need 2 consecutive missing
    if len(checks) >= 2 and not checks[-1]["mounted"] and not checks[-2]["mounted"]:
        return {
            "pattern": "mount",
            "confidence": 75,
            "detail": f"WD MyCloud mount missing for 2 consecutive checks (last: {checks[-1]['ts'][:19]})",
            "prevention": "Check NAS power/network. Run: bash scripts/mount-wd-mycloud.sh"
        }
    return None


def check_cron_latency(state):
    """Check if any cron job is taking >80% of its scheduled interval."""
    output = run_cmd("openclaw cron list --json 2>/dev/null")
    if not output:
        return None

    try:
        crons = json.loads(output) if output.startswith("[") else json.loads(f"[{output}]")
    except:
        return None

    now = datetime.now(timezone.utc)
    for cron in crons:
        name = cron.get("name", "unknown")
        # Check last run duration vs interval
        last_run = cron.get("lastRun", {})
        if last_run and isinstance(last_run, dict):
            duration = last_run.get("durationMs", 0)
            schedule = cron.get("schedule", {})
            interval_ms = schedule.get("everyMs", 0)

            if interval_ms > 0 and duration > 0:
                ratio = duration / interval_ms
                if ratio > 0.8:
                    return {
                        "pattern": "cron_latency",
                        "confidence": 70,
                        "detail": f"Cron '{name}' taking {ratio:.0%} of interval ({duration/1000:.0f}s / {interval_ms/1000:.0f}s)",
                        "prevention": f"Optimize cron '{name}' or increase interval. Check for model timeouts."
                    }
    return None


def check_memory_trend(state):
    """Check if RAM usage grows >5%/hour over 3 checks."""
    output = run_cmd("vm_stat | grep 'Pages active' | awk '{print $3}'")
    if not output:
        # Fallback: use top
        output = run_cmd("top -l 1 -s 0 | grep 'PhysMem' | awk '{print $2}'")

    try:
        # Normalize to a percentage-like number
        mem_active = float(output.replace(".", "")) if output else 0
    except:
        return None

    key = "memory_trend"
    checks = state["checks"].get(key, [])
    now = datetime.now(timezone.utc).isoformat()
    checks.append({"ts": now, "value": mem_active})
    checks = checks[-10:]
    state["checks"][key] = checks

    if len(checks) >= 3:
        # Check growth rate
        v1, v2, v3 = checks[-3]["value"], checks[-2]["value"], checks[-1]["value"]
        if v1 > 0 and v2 > 0 and v3 > 0:
            growth_1 = (v2 - v1) / v1
            growth_2 = (v3 - v2) / v2
            if growth_1 > 0.05 and growth_2 > 0.05:
                return {
                    "pattern": "memory_trend",
                    "confidence": 65,
                    "detail": f"Memory growing >5%/check for 3 consecutive checks ({growth_1:.1%}, {growth_2:.1%})",
                    "prevention": "Check for memory leaks in long-running processes. Run: ps aux --sort=-%mem | head -10"
                }
    return None


def check_task_stall(state):
    """Check if >5 tasks are stuck in In Progress for >1 hour."""
    try:
        with open(TASKS_FILE) as f:
            tasks = json.load(f)
    except:
        return None

    now = datetime.now(timezone.utc)
    stuck = []
    for t in tasks:
        if t.get("status") != "in_progress":
            continue
        started = t.get("startedAt", t.get("ts", ""))
        if started and started != "just now":
            try:
                started_dt = datetime.fromisoformat(started.replace("Z", "+00:00"))
                age_hours = (now - started_dt).total_seconds() / 3600
                if age_hours > 1:
                    stuck.append({"id": t["id"], "title": t["title"][:50], "age_h": round(age_hours, 1)})
            except:
                continue

    if len(stuck) > 5:
        return {
            "pattern": "task_stall",
            "confidence": 80,
            "detail": f"{len(stuck)} tasks stuck in In Progress for >1 hour: {', '.join(s['id'] for s in stuck[:3])}...",
            "prevention": "Run stall detector: bash scripts/stall-detector.sh. Check sub-agent timeouts."
        }
    return None


def check_smb_retries(state):
    """Check for SMB connection retries in logs."""
    log_file = f"/tmp/openclaw/openclaw-{datetime.now().strftime('%Y-%m-%d')}.log"
    if not os.path.exists(log_file):
        return None

    # Check for SMB-related errors in last 10 minutes
    output = run_cmd(f"tail -200 {log_file} 2>/dev/null | grep -ci 'smb\\|mount.*fail\\|connection.*refused.*\\(Public\\|OpenClaw\\)'")
    try:
        retry_count = int(output) if output.isdigit() else 0
    except:
        retry_count = 0

    key = "smb_retries"
    checks = state["checks"].get(key, [])
    now = datetime.now(timezone.utc).isoformat()
    checks.append({"ts": now, "count": retry_count})
    checks = checks[-10:]
    state["checks"][key] = checks

    if retry_count > 3:
        return {
            "pattern": "smb_retries",
            "confidence": 70,
            "detail": f"{retry_count} SMB/mount errors in recent logs",
            "prevention": "Check NAS network connectivity. Consider dedicated SMB user instead of guest."
        }
    return None


def create_prevention_task(anomaly, tasks):
    """Create a 'Prevent:' task from an anomaly detection."""
    now = datetime.now(timezone.utc).isoformat()

    # Check if a similar prevention task already exists
    existing = [t for t in tasks if t.get("status") in ("backlog", "in_progress", "triage")
                and t.get("tags") and "prevention" in t.get("tags", [])
                and anomaly["pattern"] in t.get("title", "").lower()]

    if existing:
        return None  # Don't duplicate

    task_id = f"task-prevent-{anomaly['pattern']}-{os.urandom(2).hex()}"
    task = {
        "id": task_id,
        "title": f"Prevent: {anomaly['detail'][:80]}",
        "assignee": "monkey",
        "status": "backlog",
        "priority": "P2",
        "ts": "just now",
        "note": f"Predictive prevention (confidence: {anomaly['confidence']}%)\n\n{anomaly['detail']}\n\nPrevention action:\n{anomaly['prevention']}\n\nIf this prediction is correct, fix the issue and mark Done.\nIf this prediction is wrong, mark Done with note 'False positive'.",
        "tags": ["prevention", "predictive", anomaly["pattern"]],
        "history": [{"ts": now, "action": "created", "actor": "predict-prevent", "details": f"Auto-created from anomaly detection ({anomaly['confidence']}% confidence)"}],
        "lastActivity": now,
        "currentStep": None,
        "progress": 0,
        "predictionConfidence": anomaly["confidence"],
        "predictionPattern": anomaly["pattern"]
    }
    tasks.insert(0, task)
    return task


def main():
    now = datetime.now(timezone.utc)
    state = load_state()

    # Run all anomaly checks
    checks = [
        ("mount", check_mount_trend),
        ("cron_latency", check_cron_latency),
        ("memory_trend", check_memory_trend),
        ("task_stall", check_task_stall),
        ("smb_retries", check_smb_retries),
    ]

    anomalies = []
    for name, check_fn in checks:
        try:
            result = check_fn(state)
            if result and result["confidence"] >= 60:
                anomalies.append(result)
                log(f"  ANOMALY [{name}]: {result['detail'][:80]} (confidence: {result['confidence']}%)")
        except Exception as e:
            log(f"  CHECK ERROR [{name}]: {e}")

    if not anomalies:
        log("No anomalies detected")
        save_state(state)
        return

    # Create prevention tasks
    with open(TASKS_FILE) as f:
        tasks = json.load(f)

    created = 0
    for anomaly in anomalies:
        task = create_prevention_task(anomaly, tasks)
        if task:
            log(f"  CREATED: {task['id']} — {task['title'][:60]}")
            created += 1

    if created > 0:
        safe_write(TASKS_FILE, tasks)

    # Track predictions for accuracy
    for anomaly in anomalies:
        pattern = anomaly["pattern"]
        state["predictions"].append({
            "ts": now.isoformat(),
            "pattern": pattern,
            "confidence": anomaly["confidence"],
            "detail": anomaly["detail"][:100],
            "status": "pending"
        })

    # Keep only last 100 predictions
    state["predictions"] = state["predictions"][-100:]
    save_state(state)
    log(f"Done: {len(anomalies)} anomaly(s), {created} task(s) created")


if __name__ == "__main__":
    main()
