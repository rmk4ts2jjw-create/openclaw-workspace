---
name: "task-system-maint"
description: "Task system maintenance: stall detection, ghost dispatch prevention, duplicate cleanup, archive. Covers maintenance.sh steps and HEARTBEAT.md task logic."
---

# Task System Maintenance Skill

## Purpose
Consolidates all task system maintenance operations: stall detection, ghost dispatch prevention, duplicate cleanup, archiving, and the task state machine.

## Why It Should Exist
- Task maintenance logic is the most complex and frequently-modified part of the system
- Changes this week alone: ghost dispatch fix, extended cooldowns, dispatchFailed protection, predict-prevent disable, duplicate cleanup
- Logic is spread across: `stall-detector.sh`, `maintenance.sh` (steps 5-7), `HEARTBEAT.md` (200+ lines), `predict-prevent.py`, `save-tasks.tsx`
- The state machine (backlog → in_progress → done, with stalled/dispatchFailed/ghost states) is not documented in one place

## Expected Frequency
Medium — task system issues arise 1-2 times per week, each requiring changes to multiple files.

## Current State
- Stall detector: shell script, 30-min threshold, Phase 0/1/2 cooldowns
- Ghost dispatch: 60s timeout, wasStalled management
- Predict-prevent: DISABLED (was creating duplicates)
- Archive: 30-day done tasks → `data/tasks-archive.json`

## Overlap with Existing Skills
None.

## Implementation
New skill. Single reference for:
- Task state machine diagram
- Stall detection rules and cooldowns
- Ghost dispatch prevention
- Duplicate detection and cleanup
- Archive procedure
- EXCLUDED_TAGS list and rationale

## Acceptance Criteria
1. **Stall detection is deterministic**: Given a task that has been in_progress with no lastActivity update for >30 minutes, following the skill's procedure resets it to backlog and sets stalledAt, verified by inspecting tasks.json.
2. **Duplicate prevention tasks are detectable**: The skill provides a query that identifies all duplicate prevention tasks (same pattern, multiple active), and a procedure that removes all but the oldest without affecting non-prevention tasks.
3. **Archive procedure is safe**: Running the archive procedure moves all done tasks older than 30 days from tasks.json to tasks-archive.json, and the count of tasks removed matches the count added to the archive file.
