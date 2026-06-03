# Review Agent — Design Document

## Purpose

The Review Agent manages the lifecycle of external code/work review. It detects
completed work, generates review packages, tracks review status, and records
decisions on recommendations.

---

## Responsibilities

### 1. Detect Completed Work Requiring Review

Monitor for completed features, significant refactors, architectural changes,
infrastructure changes, and security changes.

Do NOT generate packages for small bug fixes, docs updates, minor UI changes,
or routine maintenance.

**Detection signals:**
- Task status changes to `done` (from `tasks.json` or API)
- Architectural decisions documented in `MEMORY.md` or `AGENTS.md`
- New routes or API endpoints added to the MC dashboard
- Changes to critical infrastructure (`scripts/`, `data/` schemas, cron jobs)

### 2. Generate Review Packages

When triggered, create a review package from the `review-package.md` template
in `pending/`. Use the following ID format: `REV-YYYY-MM-DD-NNN`.

Package must include:
- Summary of what was completed
- All files changed (from git diff)
- Decisions made and reasoning
- Risks identified
- Known limitations
- Proposed next steps
- Specific questions for the reviewer

### 3. Track Review Status

State machine for each review:

```
pending → in-review → reviewed → actioned → archived
```

| State | Meaning |
|-------|---------|
| `pending` | Package generated, not yet sent for review |
| `in-review` | Package sent to reviewer, awaiting response |
| `reviewed` | Recommendations received |
| `actioned` | Decisions made on all recommendations |
| `archived` | Complete, audit trail preserved |

### 4. Accept Reviewer Recommendations

When recommendations are received (from the reviewer), log them using the
`recommendation.md` template in `recommendations/`.

File naming: `REV-YYYY-MM-DD-NNN-recommendations.md`

### 5. Record Decisions

For every recommendation, record the decision using the `decision-log.md`
template. Outcomes:

| Outcome | Meaning |
|---------|---------|
| `accepted` | Recommendation will be implemented |
| `rejected` | Recommendation will not be implemented (reason required) |
| `deferred` | Decision postponed (reason required) |

Every decision requires a reason. No recommendation should be silently ignored.

### 6. Maintain Audit History

All review packages, recommendations, and decision logs are kept permanently.
Nothing is deleted — only archived. The `reviewed/` directory holds completed
review cycles.

---

## Workflow (Manual — Phase 1)

```
1. OpenClaw completes work
       ↓
2. Review Agent detects completion
       ↓
3. Generate review package → pending/
       ↓
4. Andre reviews work (manually)
       ↓
5. Write recommendations → recommendations/
       ↓
6. Review Agent records decisions → decision-log/
       ↓
7. Accepted items → implement
       ↓
8. Archive → reviewed/
```

## Workflow (Automated — Phase 2, Future)

```
1. OpenClaw completes work
       ↓
2. Review Agent detects completion
       ↓
3. Generate review package
       ↓
4. Submit to external AI reviewer (via chosen integration)
       ↓
5. Receive structured recommendations
       ↓
6. Review Agent logs decisions
       ↓
7. Accepted items → auto-dispatch implementation tasks
       ↓
8. Archive
```

---

## Future Implementation Plan

### Phase 1 (Current): Framework ✅
- Directory structure created
- Templates created
- Workflow documented
- First review package generated

### Phase 2: Manual Testing
- Use the process manually for 2-3 cycles
- Andre pastes review packages into external AI
- Recommendations returned to OpenClaw via `recommendations/` folder
- Decisions recorded
- Evaluate whether recommendations genuinely improve work quality

### Phase 3: Automated Review Pipeline
- Implement chosen integration method (see PHASE-2-ANALYSIS.md)
- Automate package submission
- Automate recommendation ingestion
- Auto-dispatch accepted improvements as tasks

---

## File Layout

```
review-system/
├── pending/            # Packages awaiting review
├── reviewed/           # Completed review cycles (audit trail)
├── recommendations/   # Reviewer recommendations
├── templates/          # review-package.md, recommendation.md, decision-log.md
├── review-agent/       # This design document
├── logs/               # Review agent activity log
└── README.md           # System overview
```
