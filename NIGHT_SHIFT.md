# NIGHT SHIFT — Design Document

_Autonomous task processing during 01:00-07:00 when Andre is asleep._

**Status:** Design only — not yet implemented
**Created:** 2026-06-03

---

## 1. Architecture

### Integration with Heartbeat

Night Shift is **not a separate cron job**. It's a mode within the existing heartbeat cycle.

**Why heartbeat, not cron:**
- The heartbeat already has the context to pick tasks, spawn sub-agents, and update task state
- A separate cron would compete with the heartbeat for tasks.json access (race conditions)
- The heartbeat already runs every ~15 min — that's the right cadence for dispatching one task at a time

**How it works:**
1. At 01:00, a cron job fires a `systemEvent` to the main session: `"Night Shift check — evaluate and activate if conditions met"`
2. The heartbeat handler checks Night Shift activation conditions
3. If active, the heartbeat enters Night Shift mode for that cycle
4. Subsequent heartbeats during 01:00-07:00 continue Night Shift until it completes or hits a stop condition
5. A `night-shift-state.json` file persists state across heartbeat cycles (current task, count, tokens used)

### Coexisting with Existing Nighttime Jobs

Current nighttime cron jobs:
- **02:00 UTC (03:00 BST)** — Sessions Cleanup (systemEvent, 12ms, lightweight)
- **04:00 UTC (05:00 BST)** — Session Auto-Expiry (shell script, 11ms, lightweight)
- **06:00 Europe/London** — Auto-update FreeRide (agentTurn, ~52s, isolated)

These are all lightweight infrastructure tasks. Night Shift is the only one that dispatches work tasks. No conflict — they operate on different concerns.

**Key timing:**
- 01:00 BST → Night Shift activation check
- 02:00 UTC (03:00 BST) → Sessions Cleanup runs (no conflict)
- 04:00 UTC (05:00 BST) → Session Auto-Expiry runs (no conflict)
- 06:00 BST → FreeRide update runs (no conflict)
- 06:30 BST → Night Shift stops starting new tasks
- 07:00 BST → Night Shift sends morning report

---

## 2. Activation Conditions

ALL must be true to enter Night Shift:

| Condition | How to check |
|-----------|-------------|
| **Time is 01:00-07:00 BST** | Current hour in Europe/London timezone |
| **Dispatchable backlog exists** | Count tasks with `status: "backlog"`, no `stalledAt`, `dispatchCount < 3`, `wasStalled: false`, AND `nightShiftEligible: true` |
| **Rate limits healthy** | No 429 errors in the last 30 min (check gateway log or error feed) |
| **Andre is away** | No messages from Andre in the last 2 hours (check session activity) |

If any condition fails → skip Night Shift this cycle, log reason.

---

## 3. Task Eligibility

Not all backlog tasks qualify. Eligibility is determined **automatically** by the system at dispatch time — no manual tagging required.

**Automatically eligible:**
- `status: "backlog"`
- `stalledAt` not set
- `dispatchCount < 3`
- `wasStalled: false`
- Priority is P2 or P3 (P1 excluded)
- No exclusion tags: `"needs-human-input"`, `"planning"`, `"design"`, `"roadmap"`

**Manual override:**
- `nightShiftEligible: false` — Andre can opt out a specific task
- This is the exception, not the rule. Most tasks never need this field.

**Sort order for pickup:**
1. Priority: P2 before P3
2. Age: oldest first (by `ts` or earliest `history[].ts`)

---

## 4. Safety Constraints

### Hard Limits
- **Max 5 tasks per night** — prevents burning through backlog
- **No new tasks after 06:30** — wrap-up window
- **Stop at 07:00 sharp** — even if a task is mid-work (move back to backlog)
- **Max 100K tokens per night** — hard stop if exceeded (~20K avg per task at 5-task limit)

### Rate Limit Protection
- Before each task dispatch, check for recent 429 errors
- If 429s detected → pause Night Shift, log reason, send alert
- Never retry a failed task more than once per night

### Forbidden Actions
- Never modify `openclaw.json`
- Never modify LaunchAgents or LaunchDaemons
- Never modify cron jobs
- Never modify the gateway config
- Never touch `work-dispatcher.sh.disabled`
- Never delete tasks — only move to Done with summary
- Never dispatch P1 tasks at night

### Sub-agent Constraints
- Each sub-agent gets a 15-minute timeout
- Sub-agent must update `currentStep` and `lastActivity` every 5 min
- Sub-agent must write a completion summary before marking done
- If a sub-agent fails, the task goes back to backlog with failure note — no retry

---

## 5. State Persistence

A `data/night-shift-state.json` file tracks Night Shift across heartbeat cycles:

```json
{
  "active": true,
  "date": "2026-06-03",
  "startedAt": "2026-06-03T01:00:00+01:00",
  "tasksCompleted": [],
  "tasksAttempted": 0,
  "tasksFailed": [],
  "tokensUsed": 0,
  "currentTask": null,
  "stoppedReason": null
}
```

This file is:
- Created when Night Shift activates
- Updated after each task completes or fails
- Read at each heartbeat during Night Shift hours
- Reset when Night Shift ends (moved to `data/night-shift-archive/`)

---

## 6. Morning Report

Sent via Telegram at 07:00 BST:

```
🌙 Night Shift Report — [date]

✅ Completed: X tasks
⏭️ Skipped: Y tasks (rate limit / time / eligibility)
❌ Failed: Z tasks
🪙 Tokens used: ~N

Completed:
• [Task title] — [one-line summary]
• [Task title] — [one-line summary]

Failed:
• [Task title] — [reason]

── Station Status ──
💾 Disk: workspace X GB / MC repo Y GB
🚨 Incidents overnight: [count + brief description, or "None"]
⏱️ Gateway uptime: Xh Ym
📊 Backlog remaining: N tasks (M night-shift eligible)
```

If zero tasks were completed:

```
🟥 Night Shift Report — [date]

No tasks completed.
Reason: [no eligible tasks / rate limits hit / etc.]

── Station Status ──
💾 Disk: workspace X GB / MC repo Y GB
🚨 Incidents overnight: [count + brief description, or "None"]
⏱️ Gateway uptime: Xh Ym
📊 Backlog: N tasks (0 night-shift eligible)
```

---

## 7. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Token exhaustion** | Run out of tokens before morning, Andre wakes to dead system | 50K token hard limit. Check token usage before each dispatch. |
| **Sub-agent runaway** | Tool-call loop burns tokens on one task | 15-min timeout per sub-agent. Max 1 retry per task. |
| **tasks.json corruption** | Rapid-fire saves from multiple heartbeats | Only ONE task transition per heartbeat. Atomic read-modify-write. |
| **Rate limit cascade** | Night Shift triggers 429s that affect morning work | Check 429s before each dispatch. Stop immediately on detection. |
| **Andre wakes up mid-shift** | Andre sends a message while Night Shift is working | Check for recent Andre activity each heartbeat. If detected, pause Night Shift gracefully. |
| **Sub-agent produces bad code** | Night Shift commits broken code | Sub-agents must verify app loads (port 3000 returns 200) before marking done. |
| **P1 task gets dispatched** | Important task worked on without Andre's awareness | P1 tasks are explicitly excluded from Night Shift eligibility. |

---

## 8. Testing Plan

### Phase 1: Dry Run (no actual dispatch)
- Manually trigger Night Shift logic at a non-night hour
- Log what it WOULD do without spawning sub-agents
- Verify eligibility filtering works correctly
- Verify activation conditions evaluate correctly

### Phase 2: Single Task Test
- At a convenient hour, manually trigger Night Shift with a limit of 1 task
- Use a small, well-defined task (like the "Move Incident ShortCut" test)
- Verify: dispatch → work → completion → summary → state file update
- Verify: morning report format (trigger manually)

### Phase 3: Full Night Test
- Enable the 01:00 activation cron
- Let it run overnight with real tasks
- Review morning report
- Check tasks.json for proper state transitions
- Verify no forbidden actions were taken

### Phase 4: Edge Cases
- Test with 0 eligible tasks (should report "no tasks")
- Test with rate limit active (should pause and report)
- Test with Andre sending a message at 03:00 (should pause gracefully)
- Test at 06:30 boundary (should stop starting new tasks)

---

## 9. Changes Needed

### New files:
- `NIGHT_SHIFT.md` — this document
- `data/night-shift-state.json` — runtime state
- `data/night-shift-archive/` — historical reports

### Modified files:
- `HEARTBEAT.md` — add Night Shift section with activation logic, dispatch rules, and stop conditions
- `data/tasks.json` — add `nightShiftEligible` field to task schema (default: true)

### New cron job:
- `0 1 * * *` Europe/London — Night Shift activation check (systemEvent to main session)

### No changes to:
- `openclaw.json`
- LaunchAgents / LaunchDaemons
- Existing cron jobs
- Gateway config

---

## 10. Resolved Design Decisions

1. **`nightShiftEligible` field:** Not a manual tagging requirement. Eligibility is auto-determined from existing fields (priority, tags, dispatch status). The field exists only as a manual override (`false`) for edge cases.

2. **Token limit:** 100K total per night (~20K avg per task at 5-task limit).

3. **Morning report includes station status:** Disk usage, overnight incidents, gateway uptime — not just task summaries.

4. **Dry run test:** Can be executed immediately in any session — no code changes needed. Simulates full Night Shift logic and logs what it WOULD do.

5. **Sub-agents vs crew agents:** Generic sub-agents. Crew personas are context, not separate sessions.

6. **06:30 cutoff task handling:** In-progress task moved back to backlog with "Night Shift partial" note. No dispatchCount penalty.

7. **Frequency:** Every night. Andre can disable via `nightShiftEnabled: false` in tasks.json.

8. **Dreaming concept:** Superseded by Night Shift. No conflict — different purpose (productive work vs reflection).

---

_Design version 1.0 — 2026-06-03_
_Ready for Andre's review before implementation._
