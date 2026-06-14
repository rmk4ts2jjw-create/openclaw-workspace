# Skill Lifecycle Management — Backlog Item

## Status: Proposed
## Priority: P2
## Created: 2026-06-14

## Purpose
Define governance processes for the full skill lifecycle: creation, activation, monitoring, deprecation, and archive. Currently no formal process exists — skills are proposed via Skill Workshop but there's no mechanism for ongoing health checks or retirement.

## Motivation
- 7 skills are currently pending activation with no defined path to activation or deprecation
- Without lifecycle management, skills can become stale (outdated assumptions, changed architecture, obsolete dependencies) without detection
- No metrics exist to determine whether a skill is actually being used or providing value

## Cross-References

When reviewing retrieval-related skills (search, recall, memory, knowledge), always cross-reference the AGENTS.md Recall Engine procedure to avoid duplication. The Recall Engine is the authoritative retrieval workflow. A new skill should improve upon it, not replace it.

## Scope

### Skill Health
How to determine whether an activated skill is still functioning correctly:
- **Invocation tracking**: Each skill should log when it was last invoked and by which session
- **Success/failure tracking**: Record whether the skill's procedure completed successfully or required manual intervention
- **Dependency validation**: Periodically verify that the skill's dependencies (tools, paths, credentials) still exist and are valid
- **Assumption checking**: Verify that the skill's assumptions about project structure, file locations, and system state remain true

### Skill Metrics
Where metrics should live and what should be tracked:
- **Storage location**: `~/.openclaw/workspace/data/skill-metrics.json` — centralized metrics file
- **Invocation count**: Total times the skill was invoked, per skill, per week
- **Success rate**: Percentage of invocations that completed without manual intervention
- **Failure rate**: Percentage of invocations that required fallback or manual correction
- **Manual override count**: Times the operator bypassed the skill's procedure
- **Average execution time**: Time from skill invocation to completion
- **Stale usage**: Days since last invocation (skills not used in 30+ days flagged as stale)

### Skill Rot Detection
How to detect degraded skills:
- **Outdated assumptions**: Skill references file paths, component names, or API endpoints that no longer exist
- **Changed architecture**: The skill's workflow assumes a system structure that has been refactored
- **Obsolete dependencies**: Tools or packages the skill depends on have been removed or replaced
- **Persistent failures**: Skill fails in 3+ consecutive invocations
- **Superseded workflows**: A newer skill or built-in tool covers the same use case more effectively

### Deprecation Workflow
Lifecycle stages: **Draft → Pending Review → Activated → Monitored → Deprecated → Archived**

| Stage | Trigger | Action |
|-------|---------|--------|
| Draft | Skill proposal created | Available for review, not usable |
| Pending Review | Submitted to Skill Workshop | Under evaluation |
| Reviewed | Acceptance criteria verified | Ready for activation |
| Activated | Explicitly approved by owner | Usable by agents |
| Monitored | Active usage | Metrics collected, health checks run |
| Deprecated | Rot detected or owner decision | No longer usable, marked obsolete |
| Archived | 30 days after deprecation | Moved to archive, retained for reference |

### Suggested Deprecation Triggers
- Zero invocations in 30 days (stale)
- Success rate below 50% over 10+ invocations
- Critical dependency no longer available
- Superseded by a newer skill or built-in capability
- Owner explicitly requests deprecation

## Dependencies
- Skill Workshop (already exists)
- OpenClaw cron system (for periodic health checks)
- Metrics storage (`data/skill-metrics.json`)

## Out of Scope
- Skill creation process (handled by Skill Workshop)
- Skill content authoring (handled by skill-creator skill)
- Automated skill testing (future capability)

## Acceptance Criteria
1. **Metrics are collected**: After activation, each skill invocation is recorded in `data/skill-metrics.json` with timestamp, session ID, success/failure status, and execution time.
2. **Health checks run periodically**: A weekly cron job checks all activated skills for dependency validity and assumption correctness, reporting any issues.
3. **Deprecation is actionable**: When a skill is deprecated, agents receive a clear message directing them to the alternative (newer skill, built-in tool, or manual procedure).
4. **Archive is retained**: Deprecated skills are moved to `~/.openclaw/workspace/skills/archive/` with their full history, not deleted.
