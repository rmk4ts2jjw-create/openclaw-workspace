import json
import os
import subprocess
from datetime import datetime, timezone

workspace_path = '/Users/spacemonkey/.openclaw/workspace'
tasks_file = os.path.join(workspace_path, 'data', 'tasks.json')

def is_valid_iso(timestamp):
    if not timestamp or timestamp == "just now":
        return False
    try:
        # Handle ISO format with Z or without timezone
        if timestamp.endswith('Z'):
            timestamp = timestamp[:-1] + '+00:00'
        datetime.fromisoformat(timestamp)
        return True
    except Exception:
        return False

def main():
    # Read tasks.json
    try:
        with open(tasks_file, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading tasks.json: {e}")
        return 0

    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    reset_count = 0
    reset_reasons = []

    for task in data:
        if task.get('status') != 'in_progress':
            continue

        # Determine the timestamp to use for staleness calculation
        last_activity = task.get('lastActivity')
        ts = task.get('ts')
        history = task.get('history', [])

        base_time = None
        base_source = None

        # 1. lastActivity if valid
        if last_activity and is_valid_iso(last_activity):
            try:
                if last_activity.endswith('Z'):
                    last_activity = last_activity[:-1] + '+00:00'
                base_time = datetime.fromisoformat(last_activity)
                base_source = 'lastActivity'
            except Exception:
                pass

        # 2. ts if valid and base_time not set
        if base_time is None and ts and is_valid_iso(ts):
            try:
                if ts.endswith('Z'):
                    ts = ts[:-1] + '+00:00'
                base_time = datetime.fromisoformat(ts)
                base_source = 'ts'
            except Exception:
                pass

        # 3. most recent history[].ts if base_time not set
        if base_time is None:
            valid_history_times = []
            for h in history:
                h_ts = h.get('ts')
                if h_ts and is_valid_iso(h_ts):
                    try:
                        if h_ts.endswith('Z'):
                            h_ts = h_ts[:-1] + '+00:00'
                        valid_history_times.append(datetime.fromisoformat(h_ts))
                    except Exception:
                        pass
            if valid_history_times:
                base_time = max(valid_history_times)
                base_source = 'history'

        # If no valid timestamp found, treat as stalled
        if base_time is None:
            stalled = True
            staleness = None
            reset_reason = "No valid timestamp found (broken data)"
        else:
            staleness = now - base_time
            stalled = False
            reset_reason = None

        # Apply reset rules
        current_step = task.get('currentStep')

        # Rule a: HARD RULE: If lastActivity is null/empty AND the task has been in_progress for >30 minutes, RESET IMMEDIATELY.
        if not last_activity or last_activity == "":
            if staleness and staleness.total_seconds() > 30 * 60:  # >30 minutes
                reset_reason = f"No lastActivity for >30 minutes (staleness: {staleness})"
                stalled = True

        # Rule d: Ghost dispatch fast-path: If currentStep is "Agent starting…" (or null) AND lastActivity is >60 seconds old, reset IMMEDIATELY.
        if (current_step is None or current_step == "Agent starting…") and last_activity and is_valid_iso(last_activity):
            try:
                if last_activity.endswith('Z'):
                    last_activity = last_activity[:-1] + '+00:00'
                last_activity_time = datetime.fromisoformat(last_activity)
                if (now - last_activity_time).total_seconds() > 60:
                    reset_reason = f"Ghost dispatch: currentStep is {current_step} and lastActivity >60s old"
                    stalled = True
            except Exception:
                pass

        # Rule b: If staleness > 2 hours: reset to backlog, set stalledAt to current ISO timestamp, add history entry.
        if staleness and staleness.total_seconds() > 2 * 60 * 60:  # >2 hours
            reset_reason = f"Staleness >2 hours: {staleness}"
            stalled = True

        # Rule c: If staleness > 30 minutes but < 2 hours: log a warning. If currentStep is still "Agent starting…" or null, reset immediately.
        if staleness and staleness.total_seconds() > 30 * 60 and staleness.total_seconds() <= 2 * 60 * 60:
            # We are in the 30 minutes to 2 hours window
            if current_step is None or current_step == "Agent starting…":
                reset_reason = f"Staleness between 30min and 2hrs ({staleness}) and currentStep is {current_step}"
                stalled = True

        if stalled and reset_reason:
            # Reset the task
            task['status'] = 'backlog'
            task['stalledAt'] = now_iso  # set stalledAt to now
            # Add history entry
            if 'history' not in task:
                task['history'] = []
            task['history'].append({
                'ts': now_iso,
                'action': 'stalled_reset',
                'actor': 'heartbeat',
                'details': reset_reason
            })
            # Reset currentStep and progress? We'll set currentStep to null and progress to 0 as per typical backlog state.
            task['currentStep'] = None
            task['progress'] = 0
            # Note: We do not clear 'wasStalled' or 'dispatchCount' here; the HEARTBEAT.md doesn't specify.
            # The dispatchCount is incremented elsewhere? Actually, the HEARTBEAT.md says under stall detection:
            #   "ALSO increment dispatchCount by 1 (set to at least 1 if not present)."
            # We'll increment dispatchCount.
            if 'dispatchCount' not in task:
                task['dispatchCount'] = 0
            task['dispatchCount'] += 1
            reset_count += 1
            reset_reasons.append(f"Task {task.get('id')}: {reset_reason}")

    # Write back if any changes
    if reset_count > 0:
        try:
            with open(tasks_file, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Reset {reset_count} stalled tasks.")
            for reason in reset_reasons:
                print(f"  - {reason}")
            # Git commit and push
            try:
                subprocess.run(['git', 'add', 'data/tasks.json'], check=True, cwd=workspace_path)
                subprocess.run(['git', 'commit', '-m', f'Heartbeat: reset {reset_count} stalled tasks'], check=True, cwd=workspace_path)
                subprocess.run(['git', 'push'], check=True, cwd=workspace_path)
                print("Git commit and push successful.")
            except subprocess.CalledProcessError as e:
                print(f"Git error: {e}")
        except Exception as e:
            print(f"Error writing tasks.json: {e}")
    else:
        print("No stalled tasks found.")

    return reset_count

if __name__ == '__main__':
    main()