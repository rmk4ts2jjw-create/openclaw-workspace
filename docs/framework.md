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
- **Codex** (`codex`) is installed and available — use for background coding work
- **Claude Code** and **OpenCode** are not currently installed
- Launch with `background:true`, `pty:true` for Codex
- Always capture a notification route before spawning
- Worker must send completion/failure via `openclaw message send`
- Monitor with `process`; do not kill slow workers without cause
- **Never** run coding agents in `~/.openclaw` or active OpenClaw state dirs
- See `coding-agent` skill for full launch forms and rules

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
