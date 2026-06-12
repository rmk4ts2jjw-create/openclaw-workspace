# External AI Review System

## Purpose

Validate whether external AI review improves the quality of OpenClaw's work
before investing in automation.

**Phase 1 (current):** Framework only. Manual review process. No external API calls.

## Directory Structure

```
review-system/
├── pending/            # Review packages awaiting review
├── reviewed/           # Completed review cycles (audit trail)
├── recommendations/   # Reviewer recommendations
├── templates/          # Reusable templates
│   ├── review-package.md
│   ├── recommendation.md
│   └── decision-log.md
├── review-agent/       # Design docs and analysis
│   ├── DESIGN.md
│   └── PHASE-2-ANALYSIS.md
├── logs/               # Review agent activity log
└── README.md           # This file
```

## Review Triggers

Generate review packages when:
- Feature completed
- Significant refactor completed
- Architectural change made
- Infrastructure change made
- Security change made

Do NOT generate for:
- Small bug fixes
- Documentation updates
- Minor UI changes
- Routine maintenance

## Review Workflow

```
1. OpenClaw completes work
       ↓
2. Review Agent detects completion
       ↓
3. Generate review package → pending/
       ↓
4. Andre reviews (manually in Phase 1)
       ↓
5. Write recommendations → recommendations/
       ↓
6. Review Agent records decisions → decision-log/
       ↓
7. Accepted items → implement
       ↓
8. Archive → reviewed/
```

## State Machine

```
pending → in-review → reviewed → actioned → archived
```

## Success Criteria

A successful Phase 1 implementation provides:
- [x] Review system directory structure
- [x] Working templates (review-package, recommendation, decision-log)
- [x] Review workflow documented
- [x] Review-agent design documented
- [x] Phase 2 architecture comparison completed
- [x] First review package generated (REV-2026-06-04-001)

## Assessment

### 1. Is the review process likely to improve outcomes?

**Yes, with caveats.** External review adds value when:
- The reviewer has different expertise or perspective
- The work involves architectural decisions with long-term consequences
- There are non-obvious risks or edge cases

External review adds less value when:
- The work is routine or well-understood
- The reviewer has the same blind spots as the implementer
- The overhead of generating packages exceeds the value of feedback

**Recommendation:** Test with 3-5 review cycles. If at least 2 produce
actionable recommendations that improve the work, proceed to Phase 2.

### 2. Is Phase 2 automation justified?

**Conditional yes.** Automation is justified if:
- Manual review produces consistent value (see above)
- The review cycle time is acceptable (target: <24h from completion to recommendations)
- The cost of external API calls is reasonable (~$100/month for daily reviews)

If manual review doesn't produce value, automation won't help — it will just
produce expensive noise faster.

### 3. Which integration option should be implemented first?

**Option B: OpenRouter** (see `review-agent/PHASE-2-Analysis.md`)

- Already integrated into OpenClaw
- Provider-agnostic (swap models without code changes)
- Lowest maintenance burden
- ~$100/month at 1 review/day

Fallback: Option C with DeepSeek for cost reduction.

### 4. Phased Roadmap

| Phase | Goal | Status |
|-------|------|--------|
| **Phase 1** | Framework + manual testing | ✅ Complete (2026-06-12) |
| **Phase 2** | Manual review cycles (3-5 tests) | 🔜 Next |
| **Phase 3** | Automated browser review (DeepSeek) | ⏳ Future |
| **Phase 4** | OpenRouter reviewer (API-based) | ⏳ Future |
| **Phase 5** | Automated review loop (end-to-end) | ⏳ Future |
| **Phase 6** | Night Shift integration | ⏳ Future |

**Phase 2 manual test process:**
1. Andre takes `pending/REV-2026-06-04-001.md`
2. Pastes into external AI (DeepSeek, Claude, etc.)
3. Saves recommendations to `recommendations/REV-2026-06-04-001-recommendations.md`
4. Space Monkey records decisions in `decision-log/`
5. Accepted items become implementation tasks
6. Archive to `reviewed/`

After 3-5 cycles, evaluate: are recommendations genuinely improving work quality?
If yes → implement Phase 3 with OpenRouter.
