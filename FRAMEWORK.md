# FRAMEWORK.md — Development Authority & Index

**Purpose:** Ensure every agent uses the right framework, the right repo, and the right workflow.

**Documentation Authority:** This file is the index. Detailed rules live in `docs/`:
- `docs/framework.md` — Framework selection, anti-patterns, build tool rules
- `docs/roles.md` — Agent roles, permissions, merge checklist
- `docs/routes.md` — Active routes manifest
- `docs/stack.md` — Tech stack, dependencies, gotchas
- `docs/workflow.md` — Dev→Prod workflow, automation rules
- `docs/sources.md` — External documentation references

**Repository Authority:** `SOURCES.md` is the single source of truth for canonical documentation URLs.

---

## Four-Repository Structure

```
GitHub (rmk4ts2jjw-create)
├── mc-prod        ← Production (port 3000) — stable, tested code
├── mc-dev         ← Development (port 3001) — prototype integration + testing
├── mc-lovable     ← Lovable prototypes — auto-synced from Lovable (DO NOT TOUCH)
└── mc-replit      ← Replit prototypes — auto-synced from Replit (LEAVE EMPTY)
```

### Workflow
```
Lovable/Replit → mc-lovable / mc-replit (auto-sync)
        ↓
   Andre reviews prototype
        ↓
   Export ZIP → WD MyCloud
        ↓
   Space Monkey pulls into mc-dev (port 3001)
        ↓
   Test features, wire data, verify
        ↓
   Andre approves
        ↓
   Systems Engineer merges to mc-prod (port 3000)
        ↓
   All routes verified 200
```

### Local Directory Mapping
| Local Directory | GitHub Remote | Port | Purpose |
|---|---|---|---|
| `mission-control-dashboard/` | `git@github.com-rmk:rmk4ts2jjw-create/mc-prod.git` | 3000 | Production |
| `mission-control-dashboard-dev/` | `git@github.com-rmk:rmk4ts2jjw-create/mc-dev.git` | 3001 | Development |

### SSH Configuration
- `github.com` → `~/.ssh/id_ed25519_spacemonkey` (spacemonkey-home account)
- `github.com-rmk` → `~/.ssh/id_ed25519_rmk` (rmk4ts2jjw-create account)
- Always use `git@github.com-rmk:` prefix for mc-* repos

### Rules
- **NEVER** push to mc-lovable or mc-replit — Lovable/Replit manage those
- **NEVER** push directly to mc-prod without Andre's approval
- All experiments go to mc-dev (port 3000) first
- Production (port 3000) is the live system — treat it with care

## Active Project Stacks

### Mission Control Dashboard
- **Stack:** TanStack Start + React + Vite + Tailwind CSS + shadcn/ui
- **Runtime:** Bun
- **Repo:** `~/.openclaw/workspace/mission-control-dashboard/`
- **Branch strategy:** `main` is the single branch, served on port 3000. No dev branch.
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



## Operations Engine

**Definition:** Task Dispatcher + Agent Execution + Stall Detection + Triage Flow.

The Operations Engine is the system that works through the task backlog autonomously during awake hours. It is NOT the same as Dreaming (which is memory consolidation at 3am).

**How it works:**
1. **Task Dispatcher** (heartbeat) picks the highest-priority dispatchable task from Backlog
2. **Agent Execution** — spawns a sub-agent that works the task, updating `currentStep` and `lastActivity` at every step
3. **Stall Detection** — if a task sits In Progress with no activity for >30 min, it's reset to Backlog
4. **Triage Flow** — if an agent hits a wall (blocked, unclear, needs human input), the task moves to Triage with clear notes explaining what's needed. Tasks never sit frozen in In Progress.

**Key rules:**
- ONE task In Progress at a time per agent
- Blocked/unclear tasks → Triage (not frozen In Progress)
- Triage tasks include: what was attempted, what's blocking, what specific action Andre needs to take
- Completed tasks auto-move to Done with summaries
- P1 tasks stay in Backlog for Andre's awareness (not auto-dispatched)
- Night Shift (01:00-07:00) is the Operations Engine running autonomously while Andre sleeps, with stricter limits (max 2-5 tasks, no P1, stops on rate limits)

**Triage is NOT a graveyard.** It's where tasks go when they need human input. Andre reviews Triage regularly and moves approved tasks back to Backlog.

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

## Component Rules

### IncidentDetailsDrawer.tsx — Hooks Must ALL Be Before Any Early Return

**Two separate Rules of Hooks bugs have been caused by conditional hooks in this file.**

- ALL `useState` and `useEffect` calls must be at the top level of the component function, before ANY early returns, conditions, or loops.
- Never call hooks inside IIFEs (`(() => { ... })()`), nested functions, conditionals, or loops.
- The "Incident Timeline" section previously had `useState` + `useEffect` inside an IIFE in the JSX render — this caused React to crash with "Rendered more hooks than during the previous render."
- The "Runbook" section uses an IIFE for synchronous lookup — this is OK as long as it contains NO hooks.
- **If you need state/effects for a conditional section, lift them to the top level and use conditional rendering in the JSX instead.**

## Development Workflow

### Two-Instance Strategy

```
Lovable / Replit prototypes
        ↓
mission-control-dashboard-dev/  (port 3001, manual start)
        ↓ test & approve
        ↓ merge features manually (copy files or cherry-pick commits)
        ↓
mission-control-dashboard/      (port 3000, auto-start via LaunchAgent)
```

### Production (`mission-control-dashboard/`)
- **Port:** 3000
- **LaunchAgent:** `com.openclaw.mc.dashboard` (auto-starts on boot)
- **Branch:** `main` — single source of truth
- **Node modules:** 660MB (full dependencies)
- **Log:** `~/.openclaw/workspace/logs/mc-dashboard.log`
- **Error log:** `~/.openclaw/workspace/logs/mc-dashboard-error.log`
- **Never** run experimental changes here
- **Always** verify all routes return 200 after any change

### Development (`mission-control-dashboard-dev/`)
- **Port:** 3001
- **Start manually:** `cd mission-control-dashboard-dev && bun run dev --host --port 3001`
- **Or via script:** `./scripts/start-dev.sh`
- **Purpose:** Test Lovable/Replit prototypes, experiment with new features
- **Can be wiped/re-cloned** without affecting production
- **Not** auto-started on boot

### Shared Resources (workspace level)
- `data/tasks.json` — Both instances read/write the same task data
- `data/incidents.json` — Shared incident data
- `assets/` — Shared sprites, icons, images
- `scripts/` — Backup scripts, health checks, maintenance
- `logs/` — Centralized logs for both instances

### Git Rules
- MC Production and MC Dev are **separate git repos** (same GitHub remote, different local dirs)
- Workspace repo is **separate** from both
- Never commit `node_modules/` or `.vite/` — already in .gitignore
- After any meaningful change: `git status` → commit → push
- **Never force-push** to shared remotes without explicit approval

### Merging Dev → Production
1. Test thoroughly on dev (port 3001)
2. Verify all routes return 200
3. Copy changed files to production (or cherry-pick commits)
4. Restart production server
5. Verify all routes return 200 on production
6. Commit and push

## Related Files

- **SOURCES.md** — Canonical documentation URLs, compatibility matrix, agent rules
- **AGENTS.md** — Agent work rules (includes source selection rules)
- **FRAMEWORK.md** — This file: framework selection, tooling decisions, dev workflow
