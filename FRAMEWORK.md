# FRAMEWORK.md — Framework Selection & Documentation Authority

**Purpose:** Ensure every agent uses the right framework for the right project and the right docs for that framework.

**Documentation Authority:** `SOURCES.md` is the single source of truth for canonical documentation URLs. Always check SOURCES.md before loading any framework docs.

---

## Active Project Stacks

### Mission Control Dashboard
- **Stack:** TanStack Start + React + Vite + Tailwind CSS + shadcn/ui
- **Runtime:** Bun
- **Repo:** `~/.openclaw/workspace/mission-control-dashboard/`
- **Branch strategy:** `main` = prod (port 3000), `dev` = dev (port 3001)
- **Correct sources:** See `SOURCES.md` → "TanStack Start Project"

---

## Framework Selection Guide

### When to use TanStack Start
- Full-stack React apps with SSR
- When you need type-safe routing and server functions
- Default choice for new projects on this system
- **Docs:** `https://context7.com/websites/tanstack_start/llms.txt`

### When to use Next.js
- When inheriting a project that already uses Next.js (e.g., from Lovable)
- When you need App Router, Server Components, or Server Actions
- When the project has `next.config.js`
- **Docs:** `https://context7.com/vercel/next.js/llms.txt`

### When to use SvelteKit
- When inheriting a project that already uses SvelteKit (e.g., from Replit)
- When the project has `svelte.config.js`
- **Docs:** `https://context7.com/sveltejs/kit/llms.txt`

### When to use Astro
- Content-heavy sites, blogs, documentation
- When inheriting from an AI generator that chose Astro
- **Docs:** `https://context7.com/withastro/astro/llms.txt`

### When to use Nuxt
- Vue-based prototypes (future use)
- **Docs:** `https://context7.com/nuxt/nuxt/llms.txt`

---

## Build Tool Rules

For coding work on Mission Control or any project, use the right tool for the job size:

| Tool | Use For | Example |
|------|---------|---------|
| Direct edit/write | Single-file fixes, quick changes | "Fix this bug", "Add this component", "Delete dead code" |
| Sequential direct edits | Multi-file refactors, module splits | "Split this 500-line file", "Refactor imports across 10 files" — one file at a time, commit after each |
| Sub-agents | Parallel tasks, research, verification | "Review all routes for dead code", "Check every component for SSR safety" |

Do NOT use OpenClaw chat for complex multi-file coding work. Use direct edits — one file at a time, committed individually. OpenClaw executes, monitors, and wires data.

---

## Anti-Patterns (Framework Contamination)

These are the mistakes that have happened before and must never happen again:

1. **Next.js patterns in TanStack Start** — App Router, Server Actions, `next/headers` in a TanStack project
2. **TanStack patterns in Next.js** — TanStack loaders, TanStack Router in a Next.js project
3. **React hooks in SvelteKit** — `useState`, `useEffect` in `.svelte` files
4. **Vite SSR assumptions in Next.js** — different runtime pipeline
5. **Bun-only APIs in Node deployments** — runtime incompatibilities

**The fix:** Always read `SOURCES.md` first. Load only the sources for the detected stack.

---

## Gotchas

### Lovable/Replit Sprite Exports May Have Solid Backgrounds
- When Lovable or Replit generates/upscales sprite PNGs, they may be exported with a **solid background** instead of transparency
- Specifically: `*-4x-v2.png` files were exported with `rgb(18, 24, 42)` navy background — appeared as grey boxes behind agent sprites on the station floorplan
- The original `*.png` files (without `-4x-v2`) had proper transparency
- **Fix:** Use the original transparent PNGs, or re-export from source with alpha channel
- **Verification:** After any sprite asset update, check a few pixels with an image tool to confirm transparency before committing

### Cron Job Replacement: DELETE Old Cron, Don't Just Disable
- When replacing an OpenClaw cron job with a LaunchAgent (or any other mechanism), **DELETE the old cron job immediately**
- Do NOT just disable it — disabled jobs can be re-enabled accidentally or survive config resets that re-enable all jobs
- **Always verify deletion with `openclaw cron list`** — confirm the job ID is gone, not just `enabled: false`
- **Real incident:** Daily Station Check cron `dae7406b` was an `agentTurn` job that burned tokens for 10+ days (May 21–31) because it was supposed to be disabled when the LaunchAgent replacement was created, but it remained enabled. It spawned an isolated AI session every night at 11pm, hit the 120s timeout in `model-call-started`, and burned tokens on each attempt. The shell-only LaunchAgent was working correctly the whole time — the old cron was a duplicate nobody deleted.
- **Rule:** New replacement goes live → old cron gets deleted the same session. No exceptions.

### FreeRide Watcher Burns Rate Limits During Pool Exhaustion
- The `freeride-watcher` LaunchAgent polls OpenRouter every ~16 minutes to test model health
- When the free model pool is exhausted, each poll generates a 429 + a failed rotation attempt (another 429)
- This is counterproductive — it burns rate limit quota without providing any value
- **Mitigation:**
  - Exponential backoff when `all_keys_exhausted` is detected
  - Auto-disable after 3 consecutive failures
  - Manual-only mode during dry spells (`freeride auto` on demand)
- **Status:** Watcher unloaded on 2026-05-22 due to persistent pool exhaustion. Re-enable manually when pool recovers.



## Agent Communication Rules

### Status Reports Only
When the user asks "anything else?" or "more recommendations?", respond with a **status report only**:
- What was completed
- What's remaining (if anything)
- Any blockers

**Do NOT:**
- Generate new work or recommendations unless explicitly asked to review a specific area
- Suggest improvements, fixes, or new features unprompted
- Continue iterating on the same topic after the user has moved on

**Why:** Open-ended "anything else" prompts caused the 87-session token explosion. The agent kept generating more recommendations indefinitely. Never again.

### Exceptions
- If the user explicitly says "review X" or "check Y" → do the review
- If there's a critical security/stability issue → flag it immediately
- If the user asks a direct question → answer it concisely

## Security Rules

### 1. Gateway Binding
- Gateway always binds to `127.0.0.1` (localhost only)
- Already confirmed safe — no action needed

### 2. API Cost Runaway Prevention
- **Hard spending limits:** Set at the API provider level (OpenRouter spending cap)
- **Circuit breaker:** If 5+ consecutive tool calls fail with the same error, stop and alert — do NOT retry forever
- **Token logging:** Log token counts per session for visibility and cost tracking

### 3. Skill Verification
- Before installing any ClawHub skill: verify the author, check install count, confirm the GitHub repo is legitimate
- **FreeRide skill verification:** Confirm it's from `openclaw-eco/free-ride` — not a typosquat or fork

### 4. Update Strategy
- Test before applying major version bumps
- Our `2026.5.18 → 2026.5.19` update partially failed — lesson learned
- Always have a rollback plan before upgrading

## Related Files

- **SOURCES.md** — Canonical documentation URLs, compatibility matrix, agent rules
- **AGENTS.md** — Agent work rules (includes source selection rules)
- **FRAMEWORK.md** — This file: framework selection, tooling decisions
