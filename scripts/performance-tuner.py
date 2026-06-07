#!/usr/bin/env python3
"""
Performance Tuning Engine — agent efficiency optimization for Mission Control.

Analyzes agent performance (speed, success rate, cost) and generates
"Tune:" tasks when agents are underperforms.

Usage:
  python3 performance-tuner.py analyze          # Analyze all agents
  python3 performance-tuner.py suggest          # Generate Tune: tasks
  python3 performance-tuner.py --status         # Show last tuning actions
  python3 performance-tuner.py --apply TASK_ID  # Apply a tuning (with approval)
"""

import json
import os
import subprocess
import tempfile
import shutil
from datetime import datetime, timezone

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
STATE_FILE = os.path.join(WORKSPACE, "data/performance-state.json")
TUNE_LOG = os.path.join(WORKSPACE, "data/auto-tune-log.json")
TASKS_FILE = os.path.join(WORKSPACE, "data/tasks.json")
LOG_FILE = os.path.join(WORKSPACE, "logs/performance-tuner.log")

# Performance rules: condition → suggestion
TUNING_RULES = [
    {
        "id": "slow_agent",
        "label": "Slow Agent Model",
        "description": "Agent has high average task duration",
        "condition": lambda stats: stats.get("avg_task_minutes", 0) > 30,
        "suggestion": "Consider switching model to a faster alternative (e.g., deepseek-reasoner → deepseek-chat for simple tasks)",
        "config_tune": {"model_override": "deepseek/deepseek-chat"},
        "confidence": 80,
        "risk": "medium",
    },
    {
        "id": "high_failure_rate",
        "label": "High Task Failure Rate",
        "description": "Agent has >20% task failure/retry rate",
        "condition": lambda stats: stats.get("failure_rate", 0) > 0.2,
        "suggestion": "Review agent's task assignments and model capability match. Consider model upgrade or task re-assignment.",
        "config_tune": None,
        "confidence": 75,
        "risk": "high",
    },
    {
        "id": "inefficient_cron",
        "label": "Inefficient Cron Schedule",
        "description": "Cron job runs at suboptimal time causing delays",
        "condition": lambda stats: stats.get("cron_failure_rate", 0) > 0.15,
        "suggestion": "Reschedule cron to align with system idle periods (:00 or :30)",
        "config_tune": {"schedule_offset": 0},
        "confidence": 65,
        "risk": "low",
    },
    {
        "id": "low_memory",
        "label": "Low Agent Memory Allocation",
        "description": "Agent context window is nearly full",
        "condition": lambda stats: stats.get("context_utilization", 0) > 0.85,
        "suggestion": "Increase memory allocation or reduce session history",
        "config_tune": {"context_window": "increase"},
        "confidence": 70,
        "risk": "low",
    },
    {
        "id": "overprovisioned",
        "label": "Over-provisioned Model",
        "description": "Expensive model used for simple tasks with high success rate",
        "condition": lambda stats: stats.get("cost_per_task", 0) > 0.05 and stats.get("success_rate", 1.0) > 0.95,
        "suggestion": "Switch to cheaper model (e.g., claude-3-haiku) for cost savings without quality loss",
        "config_tune": {"model_override": "anthropic/claude-3-haiku-20240307"},
        "confidence": 85,
        "risk": "medium",
    },
]


def safe_write(path, data):
    try:
        if os.path.exists(path):
            shutil.copy2(path, path + ".bak")
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", suffix=".tmp")
        try:
            with os.fdopen(fd, "w") as f:
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


def load_json(path, default):
    try:
        if os.path.exists(path):
            with open(path) as f:
                return json.load(f)
    except:
        pass
    return default


def analyze_agents():
    """Analyze agent performance from task history."""
    tasks = load_json(TASKS_FILE, [])
    state = load_json(STATE_FILE, {"agents": {}, "tune_tasks": [], "applied_tunes": []})

    # Group tasks by agent
    agent_tasks = {}
    for t in tasks:
        agent = t.get("assignee", "unknown")
        if agent not in agent_tasks:
            agent_tasks[agent] = []
        agent_tasks[agent].append(t)

    now = datetime.now(timezone.utc)
    analysis = {}

    for agent, agent_task_list in agent_tasks.items():
        # Filter to recent tasks (last 30 days)
        recent = []
        for t in agent_task_list:
            try:
                ts = t.get("ts", "")
                if ts and ts != "just now":
                    task_time = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                    age_days = (now - task_time).total_seconds() / 86400
                    if age_days < 30:
                        recent.append(t)
            except:
                continue

        total = len(recent)
        done = len([t for t in recent if t.get("status") == "done"])
        failed = len([t for t in recent if t.get("status") in ("triaged", "cancelled")])
        in_progress = len([t for t in recent if t.get("status") == "in_progress"])

        # Calculate avg task age for completed tasks
        durations = []
        for t in recent:
            if t.get("status") == "done":
                started = t.get("startedAt", t.get("ts", ""))
                completed = t.get("completedAt", "")
                if started and completed and started != "just now":
                    try:
                        s = datetime.fromisoformat(started.replace("Z", "+00:00"))
                        c = datetime.fromisoformat(completed.replace("Z", "+00:00"))
                        dur_hours = (c - s).total_seconds() / 3600
                        if dur_hours > 0 and dur_hours < 72:  # Filter outliers
                            durations.append(dur_hours)
                    except:
                        continue

        avg_hours = sum(durations) / len(durations) if durations else 0
        failure_rate = failed / total if total > 0 else 0
        success_rate = done / total if total > 0 else 0

        analysis[agent] = {
            "total_tasks": total,
            "done": done,
            "failed": failed,
            "in_progress": in_progress,
            "avg_task_hours": round(avg_hours, 1),
            "failure_rate": round(failure_rate, 3),
            "success_rate": round(success_rate, 3),
            "analyzed_at": now.isoformat(),
        }

    state["agents"] = analysis
    safe_write(STATE_FILE, state)
    return analysis


def generate_suggestions(analysis):
    """Analyze agents and generate Tune: tasks where applicable."""
    state = load_json(STATE_FILE, {"agents": {}, "tune_tasks": [], "applied_tunes": []})
    tasks = load_json(TASKS_FILE, [])
    suggestions = []

    for agent, stats in analysis.items():
        for rule in TUNING_RULES:
            try:
                if rule["condition"](stats):
                    # Check if a similar tune task already exists
                    existing = [t for t in tasks if t.get("status") in ("backlog", "triage", "in_progress")
                                and t.get("tags") and "tuning" in t.get("tags", [])
                                and rule["id"] in t.get("title", "").lower()]

                    if existing:
                        continue

                    suggestion = {
                        "agent": agent,
                        "rule_id": rule["id"],
                        "label": rule["label"],
                        "description": rule["description"],
                        "suggestion": rule["suggestion"],
                        "confidence": rule["confidence"],
                        "risk": rule["risk"],
                        "config_tune": rule["config_tune"],
                        "stats": {
                            "avg_task_hours": stats.get("avg_task_hours", 0),
                            "failure_rate": stats.get("failure_rate", 0),
                            "success_rate": stats.get("success_rate", 0),
                        },
                        "generated_at": datetime.now(timezone.utc).isoformat(),
                        "status": "pending",
                    }
                    suggestions.append(suggestion)
                    log(f"  SUGGESTION: {agent} — {rule['label']} ({rule['confidence']}%)")

            except Exception as e:
                log(f"  RULE ERROR [{rule['id']}]: {e}")

    state["tune_tasks"] = state.get("tune_tasks", []) + suggestions
    safe_write(STATE_FILE, state)
    return suggestions


def create_tune_task(suggestion):
    """Create a Tune: task in tasks.json from a suggestion."""
    tasks = load_json(TASKS_FILE, [])
    now = datetime.now(timezone.utc).isoformat()

    # Check for existing
    existing = [t for t in tasks if t.get("status") in ("backlog", "triage")
                and suggestion["rule_id"] in t.get("title", "").lower()]
    if existing:
        return None

    task = {
        "id": f"tune-{suggestion['rule_id']}-{suggestion['agent']}-{os.urandom(2).hex()}",
        "title": f"Tune: {suggestion['label']} — {suggestion['agent']}",
        "assignee": "monkey",
        "status": "triage",
        "priority": "P2",
        "ts": now,
        "note": (
            f"Auto-generated tuning suggestion (confidence: {suggestion['confidence']}%)\n\n"
            f"Agent: {suggestion['agent']}\n"
            f"Issue: {suggestion['description']}\n\n"
            f"Stats:\n"
            f"- Avg task duration: {suggestion['stats'].get('avg_task_hours', 0)}h\n"
            f"- Failure rate: {suggestion['stats'].get('failure_rate', 0):.1%}\n"
            f"- Success rate: {suggestion['stats'].get('success_rate', 0):.1%}\n\n"
            f"Suggestion: {suggestion['suggestion']}\n"
            f"Risk: {suggestion['risk']}\n"
        ),
        "tags": ["tuning", "performance", suggestion["rule_id"], suggestion["agent"]],
        "history": [{"ts": now, "action": "created", "actor": "performance-tuner", "details": f"Auto-generated from {suggestion['rule_id']} rule"}],
        "lastActivity": now,
        "tuning_confidence": suggestion["confidence"],
        "tuning_risk": suggestion["risk"],
    }
    tasks.insert(0, task)
    safe_write(TASKS_FILE, tasks)
    return task


def show_status():
    """Show performance tuning status."""
    state = load_json(STATE_FILE, {"agents": {}, "tune_tasks": [], "applied_tunes": []})
    tasks = load_json(TASKS_FILE, [])

    print("Performance Tuning Engine — Status")
    print("=" * 50)

    print("\nAgent Performance:")
    for agent, stats in state.get("agents", {}).items():
        print(f"  {agent}:")
        print(f"    Tasks: {stats.get('done', 0)} done / {stats.get('total_tasks', 0)} total")
        print(f"    Avg duration: {stats.get('avg_task_hours', 0)}h")
        print(f"    Success rate: {stats.get('success_rate', 0):.1%}")
        print(f"    Failure rate: {stats.get('failure_rate', 0):.1%}")

    print("\nTuning Suggestions:")
    pending = [t for t in state.get("tune_tasks", []) if t.get("status") == "pending"]
    print(f"  Total: {len(state.get('tune_tasks', []))}")
    print(f"  Pending: {len(pending)}")

    print("\nApplied Tunes:")
    print(f"  Total: {len(state.get('applied_tunes', []))}")

    print("\nTuning Rules:")
    for rule in TUNING_RULES:
        print(f"  [{rule['confidence']}%] {rule['id']}: {rule['label']} ({rule['risk']} risk)")


def main():
    import sys
    args = sys.argv[1:]

    if not args or args[0] == "--status":
        show_status()
    elif args[0] == "analyze":
        log("Analyzing agent performance...")
        analysis = analyze_agents()
        for agent, stats in analysis.items():
            print(f"  {agent}: {stats.get('done', 0)} done, {stats.get('avg_task_hours', 0)}h avg, {stats.get('success_rate', 0):.1%} success")
    elif args[0] == "suggest":
        log("Generating tuning suggestions...")
        analysis = analyze_agents()
        suggestions = generate_suggestions(analysis)
        created = 0
        for s in suggestions:
            task = create_tune_task(s)
            if task:
                log(f"  CREATED: {task['id']}")
                created += 1
        print(f"\nDone: {len(suggestions)} suggestions, {created} tasks created")
    else:
        print("Usage:")
        print("  performance-tuner.py analyze")
        print("  performance-tuner.py suggest")
        print("  performance-tuner.py --status")


if __name__ == "__main__":
    main()
