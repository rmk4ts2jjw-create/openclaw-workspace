# SOURCES.md — Canonical Documentation Authority

**Purpose:** Prevent framework contamination. Every agent on this system MUST use this file to determine which documentation sources are valid for a given project. Never mix frameworks. Never guess.

**Last verified:** 2026-05-21
**Maintainer:** Space Monkey (on behalf of Andre)

---

## How To Use This File

1. **Identify the project's stack** — read `package.json`, `vite.config`, framework config
2. **Look up the stack** in the Project Type → Sources table below
3. **Load ONLY those sources** — no others
4. **Check the Compatibility Matrix** before combining any tools
5. **Follow the Agent Rules** (Section 4)

---

## Tier 1: Canonical Framework Sources (Highest Authority)

These are the primary framework docs. Agents must use the right one for the project's stack. **NEVER mix frameworks from this tier.**

### TanStack Start (current default)
- **Source:** `https://context7.com/websites/tanstack_start/llms.txt`
- **Covers:** routing, loaders, server functions, SSR, hydration
- **Forbidden to mix with:** Next.js App Router, Remix, React Router SSR

### Next.js (what Lovable often generates)
- **Source:** `https://context7.com/vercel/next.js/llms.txt`
- **Covers:** App Router, Server Components, Server Actions, caching
- **Forbidden to mix with:** TanStack Start, Remix, Vite SSR assumptions

### SvelteKit (what Replit sometimes uses)
- **Source:** `https://context7.com/sveltejs/kit/llms.txt`
- **Covers:** filesystem routing, load functions, server/client separation
- **Forbidden to mix with:** React hooks, Next.js APIs, TanStack Router

### React (component layer only — NOT routing)
- **Source:** `https://context7.com/facebook/react/llms.txt`
- **Use for:** hooks, component semantics, rendering behavior
- **Do NOT use for:** routing decisions, framework choice

### Astro (for content-heavy apps from AI generators)
- **Source:** `https://context7.com/withastro/astro/llms.txt`

### Nuxt (future-proofing for Vue-based prototypes)
- **Source:** `https://context7.com/nuxt/nuxt/llms.txt`

---

## Tier 2: Styling & Components

### Tailwind CSS
- **Source:** `https://context7.com/websites/tailwindcss/llms.txt`
- **Covers:** utility classes, responsive design, theming, config

### shadcn/ui
- **Source:** `https://context7.com/shadcn-ui/ui/llms.txt`
- **CRITICAL:** shadcn is NOT a component library runtime. Components are copied locally. Modifications are expected. Many agents get this wrong.

### Radix UI (shadcn depends on it)
- **Source:** `https://context7.com/radix-ui/primitives/llms.txt`

### TanStack Table (common in dashboard-heavy apps)
- **Source:** `https://context7.com/tanstack/table/llms.txt`

---

## Tier 3: Runtimes & Tooling

### Bun (current default)
- **Source:** `https://context7.com/websites/bun/llms.txt`
- **Covers:** runtime, bundling, package management, testing
- **Warning:** avoid mixing Node-specific assumptions blindly

### Vite (critical — many generators use it)
- **Source:** `https://context7.com/vitejs/vite/llms.txt`

### pnpm (if a prototype uses it)
- **Source:** `https://context7.com/pnpm/pnpm/llms.txt`

### Docker (for future deployment standardization)
- **Source:** `https://context7.com/websites/docker/llms.txt`

---

## Tier 4: Backend & Systems Languages (future projects)

### Rust (performance-critical tools, CLI apps, systems programming)
- **Source:** `https://context7.com/rust-lang/rust/llms.txt`
- **Covers:** ownership, borrowing, lifetimes, concurrency, async, standard library, Cargo, error handling, traits, generics

### Go (network services, concurrent workloads, API servers)
- **Source:** `https://context7.com/golang/go/llms.txt`
- **Covers:** goroutines, channels, interfaces, standard library, modules, testing, HTTP server, concurrency patterns

### Python (scripting, data processing, automation)
- **Source:** `https://context7.com/websites/python_3/llms.txt`
- **Covers:** standard library, data structures, async/await, type hints, file I/O, subprocess management

---

## Tier 5: Agent Architecture (framework-agnostic)

### Claude Code (agent orchestration patterns)
- **Source:** `https://context7.com/anthropics/claude-code/llms.txt`
- **Covers:** multi-agent orchestration, sub-agents, hooks, tool invocation, delegation, long-running workflows, context boundaries
- **Framework-agnostic — safe to use with any stack**

### OpenClaw (our own system — gaps Claude Code doesn't cover)
- **Source:** `https://context7.com/websites/openclaw_ai/llms.txt`
- **Covers:** gateway architecture, plugin lifecycle, sandbox policies, agent workspace structure, node execution, memory systems

### Architecture Patterns (advisory only — not implementation docs)
- Martin Fowler Architecture Guides (event-driven systems, CQRS, modular monoliths, bounded contexts, integration patterns)
- Microsoft Cloud Design Patterns (retry patterns, queues, pub/sub, circuit breakers, async workflows, distributed systems)

---

## Compatibility Matrix

### SAFE COMBINATIONS

| Project Type | Core Framework | + React | + Styling | + Tooling | + UI Components |
|---|---|---|---|---|---|
| TanStack Start app | TanStack Start | React | Tailwind CSS | Vite + Bun | shadcn/ui + Radix |
| Next.js app | Next.js | (built in) | Tailwind CSS | (built in) | shadcn/ui + Radix |
| SvelteKit app | SvelteKit | — | Tailwind CSS | Vite | — |
| Astro content app | Astro | optional | Tailwind CSS | (built in) | optional |
| Rust backend | Rust Book | — | — | Cargo | — |
| Go backend | Go docs | — | — | Go modules | — |
| Python backend | Python docs | — | — | pip/poetry | — |

### FORBIDDEN COMBINATIONS (agents must NEVER mix)

| Combination | Why |
|---|---|
| Next.js + TanStack Start | Conflicting routing/server models |
| Next.js + Vite SSR | Different runtime pipeline |
| SvelteKit + React hooks | Incompatible component model |
| Bun-only APIs + Node deployment | Runtime incompatibilities |
| npm lockfiles + pnpm | Dependency resolution drift |
| Express docs + FastAPI | Language mismatch |
| Remix loaders + TanStack loaders | Similar but different behavior |
| App Router + Pages Router | Next.js internal conflict |

---

## Project Type → Correct Sources Lookup

Use this table to quickly identify which sources to load. **Load ONLY the sources listed for the detected project type.**

### TanStack Start Project
**Detect by:** `@tanstack/start` in package.json, `app.config.ts` with TanStack plugin
**Load:**
1. `https://context7.com/websites/tanstack_start/llms.txt` (Tier 1)
2. `https://context7.com/facebook/react/llms.txt` (Tier 1, component layer)
3. `https://context7.com/websites/tailwindcss/llms.txt` (Tier 2)
4. `https://context7.com/vitejs/vite/llms.txt` (Tier 3)
5. `https://context7.com/websites/bun/llms.txt` (Tier 3)
6. `https://context7.com/shadcn-ui/ui/llms.txt` (Tier 2, if shadcn is used)
7. `https://context7.com/radix-ui/primitives/llms.txt` (Tier 2, if shadcn is used)
8. `https://context7.com/tanstack/table/llms.txt` (Tier 2, if tables are needed)

### Next.js Project
**Detect by:** `next` in package.json, `next.config.js`/`next.config.mjs`
**Load:**
1. `https://context7.com/vercel/next.js/llms.txt` (Tier 1)
2. `https://context7.com/facebook/react/llms.txt` (Tier 1, component layer)
3. `https://context7.com/websites/tailwindcss/llms.txt` (Tier 2)
4. `https://context7.com/shadcn-ui/ui/llms.txt` (Tier 2, if shadcn is used)
5. `https://context7.com/radix-ui/primitives/llms.txt` (Tier 2, if shadcn is used)

### SvelteKit Project
**Detect by:** `@sveltejs/kit` in package.json, `svelte.config.js`
**Load:**
1. `https://context7.com/sveltejs/kit/llms.txt` (Tier 1)
2. `https://context7.com/websites/tailwindcss/llms.txt` (Tier 2)
3. `https://context7.com/vitejs/vite/llms.txt` (Tier 3)

### Astro Project
**Detect by:** `astro` in package.json, `astro.config.mjs`
**Load:**
1. `https://context7.com/withastro/astro/llms.txt` (Tier 1)
2. `https://context7.com/websites/tailwindcss/llms.txt` (Tier 2)

### Rust Project
**Detect by:** `Cargo.toml` at project root
**Load:**
1. `https://context7.com/rust-lang/rust/llms.txt` (Tier 4)

### Go Project
**Detect by:** `go.mod` at project root
**Load:**
1. `https://context7.com/golang/go/llms.txt` (Tier 4)

### Python Project
**Detect by:** `pyproject.toml`, `requirements.txt`, or `setup.py`
**Load:**
1. `https://context7.com/websites/python_3/llms.txt` (Tier 4)

---

## Agent Rules for Source Selection

**Every agent on this system MUST follow these rules before generating ANY code:**

### Rule 1: DETECT THE STACK FIRST
- What framework? What runtime? What package manager?
- What router? What SSR mode? What component system?
- **Read `package.json`, `vite.config`, or framework config before coding**
- If the stack is ambiguous, ask the user before proceeding

### Rule 2: LOAD ONLY RELEVANT SOURCES
- For Next.js projects: only Next.js + React + Tailwind + shadcn sources
- For TanStack projects: only TanStack + React + Vite + Tailwind sources
- **NEVER load framework docs for a framework the project doesn't use**
- When in doubt, check the Project Type → Sources table above

### Rule 3: USE ARCHITECTURE SOURCES SEPARATELY
- Architecture guides inform structure, NOT framework APIs
- Fowler says event-driven modules → Next.js still controls routing
- Tier 5 sources are advisory — they don't override Tier 1-4

### Rule 4: FOLLOW SOURCE PRIORITY
1. **Framework docs:** HIGHEST — these define the APIs you call
2. **Runtime docs:** HIGH — these define the platform behavior
3. **UI docs:** MEDIUM — these define component patterns
4. **Architecture guides:** ADVISORY ONLY — these inform structure
5. **Tutorials/blogs:** LOWEST — never use for API decisions

### Rule 5: WHEN IN DOUBT, ASK
- If you can't determine the stack, ask before coding
- If a source link is broken, report it and ask for the correct one
- If you need to combine tools not in the Compatibility Matrix, ask first

---

## Source Verification Log

All links verified on 2026-05-21:

| Source | URL | Status |
|---|---|---|
| TanStack Start | `https://context7.com/websites/tanstack_start/llms.txt` | ✅ |
| Next.js | `https://context7.com/vercel/next.js/llms.txt` | ✅ |
| SvelteKit | `https://context7.com/sveltejs/kit/llms.txt` | ✅ |
| React | `https://context7.com/facebook/react/llms.txt` | ✅ |
| Astro | `https://context7.com/withastro/astro/llms.txt` | ✅ |
| Nuxt | `https://context7.com/nuxt/nuxt/llms.txt` | ✅ |
| Tailwind CSS | `https://context7.com/websites/tailwindcss/llms.txt` | ✅ |
| shadcn/ui | `https://context7.com/shadcn-ui/ui/llms.txt` | ✅ |
| Radix UI | `https://context7.com/radix-ui/primitives/llms.txt` | ✅ |
| TanStack Table | `https://context7.com/tanstack/table/llms.txt` | ✅ |
| Bun | `https://context7.com/websites/bun/llms.txt` | ✅ |
| Vite | `https://context7.com/vitejs/vite/llms.txt` | ✅ |
| pnpm | `https://context7.com/pnpm/pnpm/llms.txt` | ✅ |
| Docker | `https://context7.com/websites/docker/llms.txt` | ✅ |
| Rust | `https://context7.com/rust-lang/rust/llms.txt` | ✅ |
| Go | `https://context7.com/golang/go/llms.txt` | ✅ |
| Python | `https://context7.com/websites/python_3/llms.txt` | ✅ |
| Claude Code | `https://context7.com/anthropics/claude-code/llms.txt` | ✅ |
| OpenClaw | `https://context7.com/websites/openclaw_ai/llms.txt` | ✅ |

---

## Related Files

- **AGENTS.md** — Agent rules (includes source selection rules from this file)
- **FRAMEWORK.md** — Framework selection guide (references this file as authority)
- **MEMORY.md** — Long-term memory (project stack info)
