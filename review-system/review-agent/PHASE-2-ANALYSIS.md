# Phase 2 Integration Analysis

## Three Options for Automated External AI Review

---

## Option A: Browser Automation

OpenClaw uses browser tooling to submit review packages to DeepSeek, ChatGPT,
or Claude via their web interfaces.

| Factor | Assessment |
|--------|------------|
| **Implementation Complexity** | HIGH — Requires browser automation, login management, DOM interaction with each provider's UI. Each provider has different UI patterns. |
| **Reliability** | LOW — Web UIs change frequently. Login sessions expire. Rate limits are opaque. CAPTCHAs may appear. |
| **Maintenance Burden** | HIGH — Every provider UI change breaks the automation. Requires constant monitoring and updates. |
| **Operational Risks** | Account lockout, ToS violations (automated access), session hijacking, provider-specific anti-bot measures. |
| **Scalability** | LOW — One browser session per provider. Parallel reviews require multiple sessions. |
| **Cost** | Free (uses existing accounts) |

**Verdict:** Not recommended. High maintenance, low reliability, ToS risks.

---

## Option B: OpenRouter Reviewer

OpenClaw submits review packages through OpenRouter using a dedicated reviewer
model (e.g., `anthropic/claude-sonnet-4`, `openai/gpt-4o`).

| Factor | Assessment |
|--------|------------|
| **Implementation Complexity** | MEDIUM — Single API endpoint, OpenAI-compatible. Already integrated into OpenClaw's model routing. |
| **Reliability** | HIGH — Stable API, well-documented, provider-agnostic. |
| **Maintenance Burden** | LOW — One integration point. Model selection can be changed via config. |
| **Operational Risks** | LOW — API key management only. No ToS issues (API is intended for programmatic use). |
| **Scalability** | HIGH — Rate limits are clear and generous. Can swap models if one is rate-limited. |
| **Estimated Cost** | ~$3-5 per review (assuming ~5K input + ~2K output tokens). At 1 review/day: ~$90-150/month. |

**Verdict:** Recommended. Best balance of simplicity, reliability, and cost.

---

## Option C: Dedicated Reviewer Account

OpenClaw submits review packages to a dedicated DeepSeek or Claude API account
used solely for review.

| Factor | Assessment |
|--------|------------|
| **Implementation Complexity** | MEDIUM — Direct API integration. Slightly more complex than OpenRouter (separate SDK/auth per provider). |
| **Reliability** | HIGH — Direct provider API, no middleman. |
| **Maintenance Burden** | MEDIUM — Provider-specific SDK updates, separate billing, separate key management. |
| **Operational Risks** | LOW — Standard API usage. Account isolation is actually a security benefit. |
| **Scalability** | MEDIUM — Bound by single provider's rate limits. No automatic failover. |
| **Estimated Cost** | DeepSeek: ~$0.50-1/review (very cheap). Claude: ~$3-5/review. At 1 review/day: ~$15-150/month depending on provider. |

**Verdict:** Good alternative if cost is primary concern (DeepSeek) or if specific
model capabilities are needed. Less flexible than OpenRouter.

---

## Comparison Matrix

| Factor | A: Browser | B: OpenRouter | C: Dedicated API |
|--------|-----------|---------------|------------------|
| Complexity | 🔴 High | 🟡 Medium | 🟡 Medium |
| Reliability | 🔴 Low | 🟢 High | 🟢 High |
| Maintenance | 🔴 High | 🟢 Low | 🟡 Medium |
| Risks | 🔴 High | 🟢 Low | 🟢 Low |
| Scalability | 🔴 Low | 🟢 High | 🟡 Medium |
| Cost | 🟢 Free | 🟡 $$/review | 🟢-🟡 $-$$/review |
| **Overall** | ❌ | ✅ **Best** | 🟡 Good |

---

## Recommendation

**Option B (OpenRouter)** is the preferred Phase 2 approach.

**Rationale:**
1. Already integrated into OpenClaw's infrastructure
2. Provider-agnostic — can swap reviewer models without code changes
3. Single API key, single billing, single integration point
4. Lowest maintenance burden
5. Clear rate limits and failover options
6. Cost is reasonable for the value (~$100/month at 1 review/day)

**Fallback:** Option C with DeepSeek if cost becomes a concern. DeepSeek's API
is significantly cheaper and the quality is sufficient for code review tasks.

**Avoid:** Option A entirely. Browser automation for this use case is fragile
and violates most providers' ToS.

---

## Implementation Notes for Phase 3

When implementing Option B:

1. Create a `reviewer` model config in `openclaw.json` pointing to the chosen
   OpenRouter model
2. Add a `submit-review` server function that:
   - Reads the review package from `pending/`
   - Constructs a review prompt with the package content
   - Sends to OpenRouter via the existing model infrastructure
   - Parses the response into structured recommendations
   - Saves to `recommendations/`
3. Add a `review-agent` cron that:
   - Checks for `pending/` packages
   - Submits them automatically
   - Moves to `in-review/` on submission
4. The main agent processes recommendations from `recommendations/` and
   records decisions in `decision-log/`
