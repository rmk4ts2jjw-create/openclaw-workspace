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

### FreeRide Watcher Burns Rate Limits During Pool Exhaustion
- The `freeride-watcher` LaunchAgent polls OpenRouter every ~16 minutes to test model health
- When the free model pool is exhausted, each poll generates a 429 + a failed rotation attempt (another 429)
- This is counterproductive — it burns rate limit quota without providing any value
- **Mitigation:**
  - Exponential backoff when `all_keys_exhausted` is detected
  - Auto-disable after 3 consecutive failures
  - Manual-only mode during dry spells (`freeride auto` on demand)
- **Status:** Watcher unloaded on 2026-05-22 due to persistent pool exhaustion. Re-enable manually when pool recovers.

## Aider Integration

**When to use Aider:**
- Large multi-file refactors too complex for direct `edit`/`write` tools
- Splitting modules, renaming across codebase, bulk import restructuring
- Always use non-interactive mode: `aider --message "..." --yes`

**When NOT to use Aider:**
- Quick single-file fixes — use direct `edit`/`write`
- Tasks requiring browser/visual verification
- Anything that needs interactive debugging

**Configuration:**
- Installed: `pip install aider-chat` (v0.82.3 installed)
- API key: `OPENROUTER_API_KEY` (already configured)
- Model: `openrouter/openrouter/owl-alpha`
- Config: `~/.aider.conf.yml`
- Usage: `cd <project> && python3 -m aider --model openrouter/openrouter/owl-alpha --no-auto-commits --yes --dark-mode --message "refactor X across Y files"`
- Never use interactive TUI / tmux sessions — non-interactive `--message` only
- Set `--no-auto-commits` to maintain our own git workflow

## Related Files

- **SOURCES.md** — Canonical documentation URLs, compatibility matrix, agent rules
- **AGENTS.md** — Agent work rules (includes source selection rules)
- **FRAMEWORK.md** — This file: framework selection, tooling decisions
