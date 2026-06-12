# Framework Rules

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
| **coding-agent** (Codex) | Large refactors, feature builds, PR reviews, issue-to-PR loops | "Build this feature", "Review this PR", "Fix this issue end-to-end" — delegate to Codex/Claude Code/OpenCode as background workers |

Do NOT use OpenClaw chat for complex multi-file coding work. Use direct edits — one file at a time, committed individually. OpenClaw executes, monitors, and wires data.

### Coding Agent Delegation
- **OpenCode** (`opencode`) is the primary coding agent — use for all multi-file coding work
- **Model:** `openrouter/qwen/qwen3-coder` (paid tier, uses OpenRouter credits)
- **Command:** `opencode run --model openrouter/qwen/qwen3-coder '[task]'`
- **Credits are ONLY for coding tasks via OpenCode** — general chat stays on owl-alpha free tier
- **Codex** (`codex`) is installed but cloud-only (hardcoded to OpenAI API) — do not use
- **Claude Code** is not installed
- Launch with `background:true` for long-running coding sessions
- Always capture a notification route before spawning
- Worker must send completion/failure via `openclaw message send`
- Monitor with `process`; do not kill slow workers without cause
- **Never** run coding agents in `~/.openclaw` or active OpenClaw state dirs
- See `coding-agent` skill for full launch forms and rules
- **For multi-file coding tasks:** use `opencode run --model openrouter/qwen/qwen3-coder '[task]'` via exec. Credits only for coding. General chat stays on owl-alpha free tier.

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

### `setAwaitingReviewCount` Crash — Undefined State Setter Prop Causes Blank SSR Page
- If a state setter (e.g. `setAwaitingReviewCount`) is passed as a prop but **never defined** in the parent component, the SSR render fails silently and the page renders **completely blank**
- No client-side error — the HTML source shows an SSR error
- **Debugging tip:** When a page is blank, always check the SSR error in the HTML source (view-source) before chasing client bundle issues
- **Fix:** Ensure all state setters passed as props are actually defined with `useState` in the parent component

### P1 Dashboard Blank Page: Check SSR Error First
- When the P1 Dashboard renders a blank page, **first check the SSR error in the HTML source** (view-source) before chasing client bundle issues
- The root cause is often an undefined state setter prop (see above) or a Node.js built-in import that breaks SSR
- Client-side debugging tools (React DevTools, console) will show nothing because the page never mounts — the failure happens server-side
- **Always:** view-source → search for error text → identify the offending import or undefined prop

### `node:path` Static Imports Break SSR in Client Components
- Statically importing Node.js built-ins (e.g. `import path from 'node:path'`) in files that **could be imported by client components** will crash the SSR render
- **Fix:** Replace static imports with dynamic `await import()` inside server function handlers only
- Never statically import `node:path`, `node:fs`, or any other Node.js built-in in shared utility files that client components might import
- If a file is used by both server and client code, use dynamic imports for Node.js built-ins at the point of use

### FreeRide Watcher Burns Rate Limits During Pool Exhaustion
- The `freeride-watcher` LaunchAgent polls OpenRouter every ~16 minutes to test model health
- When the free model pool is exhausted, each poll generates a 429 + a failed rotation attempt (another 429)
- This is counterproductive — it burns rate limit quota without providing any value
- **Mitigation:**
  - Exponential backoff when `all_keys_exhausted` is detected
  - Auto-disable after 3 consecutive failures
  - Manual-only mode during dry spells (`freeride auto` on demand)
- **Status:** Watcher unloaded on 2026-05-22 due to persistent pool exhaustion. Re-enable manually when pool recovers.

### `node:fs` Barrel Export Leak — Server-Only Modules Crash Client Bundle
- Any file that imports `node:fs`, `node:path`, or other Node.js built-ins **must NOT** be re-exported through `src/lib/server-data/index.ts`
- When re-exported through the barrel, Vite's bundler resolves the entire module chain for any component that imports from `@/lib/server-data`, pulling server-only code into the client bundle
- **Symptom:** `Importing binding name 'X' is not found` — the bundler can't resolve Node.js built-ins in the browser
- **Affected files:** `predictions.ts`, `performance.ts`, `helpers.ts` (historical)
- **Fix:** Import directly from the module file (e.g. `@/lib/server-data/predictions`), never through the barrel
- **Same pattern as:** helpers.ts leak from commit 7e5b788 — this is the same bug recurring with new server-data modules
- **Rule:** Before adding any new file to the barrel export, check that it has zero Node.js built-in imports

---

## Building Frenzy — 2026-06-07

### What Was Built

**Phase 1: Dashboard Panels**
- Risk Meter: top 3 predicted failures with confidence bars, countdown timers, color-coded urgency
- Auto-Heal Status: total/success/failed counts, heal level indicator, recent actions log
- Performance Insights: agent efficiency bars, success rates, avg duration, proposed tuning suggestions
- Recent Events Panel: real-time station activity feed with color-coded event types
- Dashboard Auto-Refresh: `router.invalidate()` every 30s keeps all panels current
- Enhanced Footer: live health dot, cron count, CPU/RAM stats

**Phase 2: Agent Office Enhancements**
- Task Arrival Packets: animated packets flying from dispatch hub to agent rooms (auto-generating)
- Collaboration Beam: animated energy beam between collaborating agents with traveling pulse
- Sprite Progress Bars: progress indicator above worker sprites with task name and percentage
- Station Reactions: full-station visual reactions (confetti, flash, toast for various events)
- Celebration Overlay: triggers automatically when tasks move to Done
- Sprite Pose Override: celebrating pose support via `spritePose` prop

**Phase 3: DeepSeek Review Loop (10 Iterations)**
1. RecentEventsPanel — real-time activity feed
2. DashboardRefresher — auto-refresh every 30s
3. Filter Buttons Fixed — converted from onClick+useState to `<Link>` with URL search params (fixes hydration issue)
4. Enhanced Footer — live health dot + system stats
5. Quick Stats Bars — Tasks (Backlog/In Progress/Awaiting Review/Done) + Incidents (All/Open/Critical)
6-8. Celebration on Task Completion — confetti + golden flash
9-10. Priority Breakdown Bar — P1/P2/P3 active counts

### Key Technical Decisions

**Filter Buttons: URL Search Params Over React State**
- Root cause of long-standing filter issue: `onClick` + `useState` depends on React hydration
- Fix: converted filter buttons to `<Link>` elements with URL search params (`?view=operational`)
- Filter state derived from URL via `useSearch()` — works even without JS hydration
- Applied to both Tasks (All/Operational/Feature) and Incidents (All/Open/Critical) filters

**Server-Only Module Pattern**
- `predictions.ts` and `performance.ts` use static `import { readFileSync } from "node:fs"` at top level
- These are NOT barrel-exported from `index.ts` to avoid leaking into client bundle
- Imported directly in route files that need them
- If corrupted (e.g. encoding issue during write), ALL pages return 500 — check first when debugging

**Client-Side Components in SSR**
- Components using `useState`/`useEffect` (TaskArrivalPackets, StationReactionOverlay, SpriteProgressBar) don't render in SSR HTML
- This is expected — they appear in the client bundle and hydrate on mount
- Verification: check imports exist and build succeeds, don't rely on SSR HTML for client-only components

### Phase 6 Backlog
- Station Memory: compounding knowledge system (entity tracking, concept linking, searchable memory, memory decay)
- Added as `task-phase6-station-memory` in backlog

---

## Code Review Submission

### Use OpenCode + OpenRouter (Never Browser Automation)
- **Command:** `opencode run --model openrouter/qwen/qwen3-coder --print-logs "$(cat /path/to/review-package.md)"`
- **Output:** Structured JSON with recommendations, risks, priorities
- **Never use browser automation for review submission** — browser is unreliable and slow
- **Time:** ~13 seconds, **Cost:** ~$0.02 per review
- **Validated:** Phase 2 (manual browser, 15min, $0.27) vs Phase 4 (OpenCode, 13s, $0.02) — automated is 70x faster and 14x cheaper
