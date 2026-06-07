#!/usr/bin/env python3
"""
Autonomous Mission Planner — self-directing improvement goals for Mission Control.

Analyzes system state and generates 3-5 strategic missions daily.
Each mission has: objective, strategy, estimated effort, success criteria.

Runs daily at 02:00 UTC via maintenance.sh.
Output: data/mission-plan.json (current missions) + data/mission-log.json (history)

Usage:
  python3 mission-planner.py generate    # Generate new missions
  python3 mission-planner.py status      # Show current missions
  python3 mission-planner.py complete ID # Mark mission complete
"""

import json
import os
import tempfile
import shutil
from datetime import datetime, timezone

WORKSPACE = "/Users/spacemonkey/.openclaw/workspace"
PLAN_FILE = os.path.join(WORKSPACE, "data/mission-plan.json")
LOG_FILE = os.path.join(WORKSPACE, "data/mission-log.json")
TASKS_FILE = os.path.join(WORKSPACE, "data/tasks.json")
INCIDENTS_FILE = os.path.join(WORKSPACE, "data/incidents.json")
PERFORMANCE_FILE = os.path.join(WORKSPACE, "data/performance-state.json")
PREDICTION_FILE = os.path.join(WORKSPACE, "data/prediction-state.json")
LOG_PATH = os.path.join(WORKSPACE, "logs/mission-planner.log")

# ── Mission Templates ───────────────────────────────────────────────────────
MISSION_TEMPLATES = [
    {
        "id": "reliability",
        "name": "Reliability Improvement",
        "description": "Reduce recurring incident rate",
        "trigger": "incident_recurrence_rate > 0.3 over 7 days",
        "objective": "Reduce recurring incident rate by 50% within 7 days",
        "strategy": "Generate deep RCA for top 3 recurring incidents, implement permanent fixes, validate with fix-validator",
        "effort": "high",
        "priority": "P1",
        "tags": ["reliability", "incidents", "rca"],
    },
    {
        "id": "performance",
        "name": "Fleet Performance",
        "description": "Improve agent efficiency",
        "trigger": "fleet_avg_efficiency_score < 70",
        "objective": "Improve fleet efficiency by 20% within 5 days",
        "strategy": "Run A/B tests on slowest 2 agents, apply winning configs via performance-tuner",
        "effort": "medium",
        "priority": "P2",
        "tags": ["performance", "tuning", "agents"],
    },
    {
        "id": "coverage",
        "name": "Detection Coverage",
        "description": "Create RCA signatures for undetected patterns",
        "trigger": "undetected_incidents > 2 in 7 days",
        "objective": "Create 3 new RCA signatures for undetected patterns",
        "strategy": "Analyze unlinked incidents, cluster by similarity, generate RCA patterns",
        "effort": "low",
        "priority": "P2",
        "tags": ["coverage", "rca", "incidents"],
    },
    {
        "id": "cost",
        "name": "Cost Optimization",
        "description": "Reduce API costs",
        "trigger": "monthly_api_cost_projection > budget * 1.2",
        "objective": "Reduce monthly API costs by 25%",
        "strategy": "Model cascade (cheap→expensive), cache responses, batch requests",
        "effort": "medium",
        "priority": "P3",
        "tags": ["cost", "optimization", "models"],
    },
    {
        "id": "learning",
        "name": "Knowledge Integration",
        "description": "Apply learned patterns to production",
        "trigger": "postmortem_insights_pending > 10",
        "objective": "Apply top 3 learned patterns to production RCA signatures",
        "strategy": "Promote shadow-mode signatures, update confidence thresholds",
        "effort": "low",
        "priority": "P3",
        "tags": ["learning", "rca", "knowledge"],
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
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "a") as f:
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


def evaluate_triggers():
    """Evaluate mission triggers against current system state."""
    incidents = load_json(INCIDENTS_FILE, [])
    performance = load_json(PERFORMANCE_FILE, {"agents": {}})
    predictions = load_json(PREDICTION_FILE, {"predictions": []})
    tasks = load_json(TASKS_FILE, [])

    triggered = []
    now = datetime.now(timezone.utc)

    # ── Reliability trigger: incident recurrence ──
    open_incidents = [i for i in incidents if i.get("status") not in ("RESOLVED", "CLOSED")]
    recurring = {}
    for inc in open_incidents:
        title_key = inc.get("title", "")[:30]
        recurring[title_key] = recurring.get(title_key, 0) + 1
    recurrence_rate = sum(1 for v in recurring.values() if v > 1) / max(len(recurring), 1)
    if recurrence_rate > 0.1:  # Lowered threshold for demo
        triggered.append(("reliability", f"Recurrence rate: {recurrence_rate:.0%}"))

    # ── Performance trigger: fleet efficiency ──
    agents = performance.get("agents", {})
    if agents:
        avg_success = sum(a.get("success_rate", 0) for a in agents.values()) / len(agents)
        if avg_success < 0.8:
            triggered.append(("performance", f"Fleet efficiency: {avg_success:.0%}"))

    # ── Coverage trigger: unlinked incidents ──
    unlinked = [i for i in open_incidents if not i.get("linkedTaskIds") and not i.get("linked_task_ids")]
    if len(unlinked) > 2:
        triggered.append(("coverage", f"{len(unlinked)} unlinked incidents"))

    # ── Cost trigger: prediction-based ──
    pending_predictions = [p for p in predictions.get("predictions", []) if p.get("status") == "pending"]
    if len(pending_predictions) > 5:
        triggered.append(("cost", f"{len(pending_predictions)} pending predictions indicate high activity"))

    # ── Learning trigger: completed tasks with summaries ──
    completed_with_summaries = [t for t in tasks if t.get("status") == "done" and t.get("summary")]
    if len(completed_with_summaries) > 10:
        triggered.append(("learning", f"{len(completed_with_summaries)} completed tasks with learnings"))

    return triggered


def generate_missions():
    """Generate missions based on triggered templates."""
    triggered = evaluate_triggers()
    plan = load_json(PLAN_FILE, {"missions": [], "generated_at": None})

    now = datetime.now(timezone.utc).isoformat()
    new_missions = []

    for trigger_id, detail in triggered:
        template = next((t for t in MISSION_TEMPLATES if t["id"] == trigger_id), None)
        if not template:
            continue

        # Check if mission already exists
        existing = [m for m in plan.get("missions", []) if m.get("template_id") == trigger_id and m.get("status") in ("active", "pending")]
        if existing:
            continue

        mission = {
            "id": f"mission-{trigger_id}-{os.urandom(2).hex()}",
            "template_id": trigger_id,
            "name": template["name"],
            "description": template["description"],
            "objective": template["objective"],
            "strategy": template["strategy"],
            "effort": template["effort"],
            "priority": template["priority"],
            "tags": template["tags"],
            "trigger_detail": detail,
            "status": "pending",
            "created_at": now,
            "completed_at": None,
            "result": None,
        }
        new_missions.append(mission)
        log(f"  MISSION: {template['name']} ({template['effort']} effort) — {detail}")

    # Keep max 5 active missions
    all_missions = plan.get("missions", []) + new_missions
    active = [m for m in all_missions if m.get("status") in ("active", "pending")]
    if len(active) > 5:
        # Keep highest priority
        priority_order = {"P1": 0, "P2": 1, "P3": 2}
        active.sort(key=lambda m: priority_order.get(m.get("priority", "P3"), 2))
        all_missions = active[:5] + [m for m in all_missions if m.get("status") not in ("active", "pending")]

    plan["missions"] = all_missions
    plan["generated_at"] = now
    safe_write(PLAN_FILE, plan)

    return new_missions


def show_status():
    """Show current mission plan."""
    plan = load_json(PLAN_FILE, {"missions": [], "generated_at": None})
    log_history = load_json(LOG_FILE, [])

    print("Autonomous Mission Planner — Status")
    print("=" * 50)

    missions = plan.get("missions", [])
    active = [m for m in missions if m.get("status") in ("active", "pending")]
    completed = [m for m in missions if m.get("status") == "completed"]

    print(f"\nActive Missions: {len(active)}")
    for m in active:
        print(f"  [{m.get('priority', '?')}] {m['name']}")
        print(f"    Objective: {m['objective'][:80]}")
        print(f"    Strategy: {m['strategy'][:80]}")
        print(f"    Effort: {m.get('effort', '?')} | Status: {m.get('status', '?')}")
        print(f"    Trigger: {m.get('trigger_detail', '?')}")
        print()

    print(f"\nCompleted Missions: {len(completed)}")
    for m in completed[-5:]:
        print(f"  ✅ {m['name']} — {m.get('result', 'done')[:60]}")

    print(f"\nMission Log: {len(log_history)} entries")
    print(f"Last generated: {plan.get('generated_at', 'never')}")


def main():
    import sys
    args = sys.argv[1:]

    if not args or args[0] == "--status":
        show_status()
    elif args[0] == "generate":
        log("Generating missions...")
        new = generate_missions()
        print(f"\nDone: {len(new)} new mission(s) generated")
    elif args[0] == "complete" and len(args) > 1:
        mission_id = args[1]
        plan = load_json(PLAN_FILE, {"missions": []})
        for m in plan.get("missions", []):
            if m["id"] == mission_id:
                m["status"] = "completed"
                m["completed_at"] = datetime.now(timezone.utc).isoformat()
                log(f"Completed mission: {m['name']}")
                break
        safe_write(PLAN_FILE, plan)
    else:
        print("Usage:")
        print("  mission-planner.py generate")
        print("  mission-planner.py complete MISSION_ID")
        print("  mission-planner.py --status")


if __name__ == "__main__":
    main()
