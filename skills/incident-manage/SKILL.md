---
name: "incident-manage"
description: "Incident lifecycle management: auto-detect, create, link to tasks, resolve, and cleanup. Covers maintenance.sh incident logic and UI."
---

# Incident Management Skill

## Purpose
Standardizes the incident lifecycle: detection, creation, task linking, resolution, and cleanup. Covers both automated maintenance.sh incident detection and MC UI incident management.

## Why It Should Exist
- Incident logic is scattered: `auto-detect-incidents.sh`, `maintenance.sh` (step 6), `incidents.json` schema, MC UI incident panel
- Duplicate incidents are created because detection runs every 30 min without dedup
- Incident→Task linking is manual and error-prone
- Auto-resolve logic (open > 10) is buried in HEARTBEAT.md
- No clear procedure for incident severity classification

## Expected Frequency
Low — incidents are infrequent but when they occur, the workflow is complex and error-prone.

## Current State
- Detection: `auto-detect-incidents.sh` via maintenance.sh every 30 min
- Storage: `data/incidents.json`
- Auto-resolve: heartbeat check if open > 10
- UI: MC Dashboard incidents panel

## In Scope
- Incident creation: from automated detection and manual creation
- Incident→Task linking: creating linked tasks, bidirectional references
- Severity classification: P1 (critical), P2 (warning), P3 (info) — criteria for each
- Resolution workflow: marking incidents resolved, verifying linked tasks are done
- Auto-resolve: criteria for automatic resolution (linked task done, age threshold)
- Dedup: preventing duplicate incidents for the same root cause

## Out of Scope
- Root cause analysis — this is a human investigation activity
- Incident response execution — the skill documents the workflow but doesn't perform remediation
- External notification (Telegram, email) — handled by cron jobs and delivery config
- Post-incident review / postmortem — separate governance process

## Overlap with Existing Skills
None.

## Implementation
New skill. Documents the full incident lifecycle with detection rules, dedup logic, severity classification, task linking procedure, auto-resolve thresholds, and manual resolution workflow.

## Acceptance Criteria
1. **Duplicate detection works**: Given an existing open incident with title "WD MyCloud mount missing", the skill's dedup logic prevents creation of a second incident with the same title within a 24-hour window.
2. **Incident→Task linking is bidirectional**: When an incident is created with a linked task, the task record contains the incident ID and the incident record contains the task ID. Resolving the incident verifies the linked task is done.
3. **Auto-resolve fires at threshold**: When open incidents exceed 10, the skill's auto-resolve procedure resolves incidents whose linked tasks are done and closes orphan incidents older than 5 days, reducing the open count below 10.
4. **Severity classification is consistent**: Given a set of 5 incident scenarios (gateway down, disk full, memory high, task stall, mount missing), the skill's classification criteria assign the same severity regardless of who creates the incident.
