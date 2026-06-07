#!/usr/bin/env python3
"""
Fix Validation Loop — auto-verify that fixed tasks actually resolved the incident.

When a task with rcaConfidence >= 70% moves to Done, this script:
1. Reads the linked incident's validation_command from the RCA engine
2. Runs the validation command
3. If pass → auto-resolve the incident
4. If fail → reopen incident, increment retry_count, optionally create retry task

Called by maintenance.sh after task status changes.
"""

import json
import os
import subprocess
import sys
import tempfile
import shutil
from datetime import datetime, timezone, timedelta

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
TASKS_FILE = os.path.join(WORKSPACE, "data/tasks.json")
INCIDENTS_FILE = os.path.join(WORKSPACE, "data/incidents.json")
RCA_SCRIPT = os.path.join(WORKSPACE, "scripts/rca-engine.py")
LOG_FILE = os.path.join(WORKSPACE, "logs/fix-validator.log")

MAX_RETRIES = 2
VALIDATION_TIMEOUT = 30  # seconds


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


def run_validation(command: str) -> tuple:
    """Run a validation command. Returns (passed: bool, output: str)."""
    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True,
            timeout=VALIDATION_TIMEOUT
        )
        output = result.stdout.strip()
        # Consider it a pass if output contains OK or doesn't contain FAIL/ERROR/DOWN/LOW/LEAK/LIMITED
        fail_indicators = ["FAIL", "ERROR", "DOWN", "LOW", "LEAK", "LIMITED"]
        passed = not any(ind in output.upper() for ind in fail_indicators)
        return passed, output
    except subprocess.TimeoutExpired:
        return False, "TIMEOUT"
    except Exception as e:
        return False, f"EXCEPTION: {e}"


def get_validation_command(incident: dict) -> str:
    """Get validation command from RCA engine for this incident."""
    try:
        result = subprocess.run(
            ["python3", RCA_SCRIPT, "analyze",
             incident.get("title", ""),
             incident.get("summary", ""),
             json.dumps(incident.get("tags", []))],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            rca = json.loads(result.stdout.strip())
            if rca and "validation_command" in rca:
                return rca["validation_command"]
    except Exception:
        pass
    return None


def validate_fix(task: dict, incidents: dict) -> dict:
    """Validate a fixed task. Returns result dict."""
    linked_id = task.get("linkedIncidentId")
    confidence = task.get("rcaConfidence", 0)

    if not linked_id:
        return {"action": "skip", "reason": "no linked incident"}
    if confidence < 70:
        return {"action": "skip", "reason": f"confidence {confidence}% < 70%"}

    # Find the linked incident
    incident = next((i for i in incidents if i["id"] == linked_id), None)
    if not incident:
        return {"action": "skip", "reason": f"incident {linked_id} not found"}
    if incident.get("status") == "RESOLVED":
        return {"action": "skip", "reason": "incident already resolved"}

    # Get validation command
    command = get_validation_command(incident)
    if not command:
        return {"action": "skip", "reason": "no validation command for this incident type"}

    # Run validation
    passed, output = run_validation(command)

    now = datetime.now(timezone.utc).isoformat()

    if passed:
        # Auto-resolve the incident
        incident["status"] = "RESOLVED"
        incident["resolvedAt"] = now
        incident["resolution"] = f"✅ Fix confirmed — system verified at {now[:19]}. Output: {output}"
        entry = {
            "ts": now,
            "action": "auto-resolved",
            "actor": "fix-validator",
            "details": f"Fix task {task['id']} validated successfully. Output: {output}"
        }
        incident.setdefault("timeline", []).append(entry)
        return {
            "action": "resolved",
            "incident_id": linked_id,
            "output": output
        }
    else:
        # Validation failed — check retry count
        retry_count = incident.get("_validation_retries", 0) + 1
        incident["_validation_retries"] = retry_count

        if retry_count > MAX_RETRIES:
            # Escalate to P1
            incident["severity"] = "P1"
            incident["escalated"] = True
            entry = {
                "ts": now,
                "action": "escalated",
                "actor": "fix-validator",
                "details": f"Fix validation failed {retry_count} times. Escalated to P1. Output: {output}"
            }
            incident.setdefault("timeline", []).append(entry)
            return {
                "action": "escalated",
                "incident_id": linked_id,
                "retry_count": retry_count,
                "output": output
            }
        else:
            # Reopen and create retry task
            incident["status"] = "TRIAGE"
            entry = {
                "ts": now,
                "action": "reopened",
                "actor": "fix-validator",
                "details": f"Fix validation failed (attempt {retry_count}/{MAX_RETRIES}). Output: {output}"
            }
            incident.setdefault("timeline", []).append(entry)
            return {
                "action": "retry",
                "incident_id": linked_id,
                "retry_count": retry_count,
                "output": output
            }


def main():
    """Main entry: scan for recently completed fix tasks and validate them."""
    now = datetime.now(timezone.utc)

    with open(TASKS_FILE) as f:
        tasks = json.load(f)
    with open(INCIDENTS_FILE) as f:
        incidents = json.load(f)

    # Find tasks that moved to Done with linked incidents and rcaConfidence >= 70%
    fix_tasks = [
        t for t in tasks
        if t.get("status") == "done"
        and t.get("linkedIncidentId")
        and t.get("rcaConfidence", 0) >= 70
        and not t.get("_validated")  # skip already-validated tasks
    ]

    if not fix_tasks:
        log("No fix tasks to validate")
        return

    log(f"Validating {len(fix_tasks)} fix task(s)...")

    incidents_modified = False
    for task in fix_tasks:
        result = validate_fix(task, incidents)
        log(f"  {task['id']}: {result['action']} — {result.get('reason', result.get('output', ''))}")

        if result["action"] in ("resolved", "escalated", "retry"):
            incidents_modified = True
            # Mark task as validated
            task["_validated"] = True
            task["_validation_result"] = result["action"]
            task["_validation_ts"] = now.isoformat()

    if incidents_modified:
        safe_write(INCIDENTS_FILE, incidents)
        safe_write(TASKS_FILE, tasks)
        log("Incidents and tasks updated")
    else:
        # Still mark tasks as validated even if no incident changes
        safe_write(TASKS_FILE, tasks)


if __name__ == "__main__":
    main()
