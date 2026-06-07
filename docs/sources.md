# External Documentation References

**Purpose:** Prevent framework contamination. Every agent on this system MUST use this file (and `SOURCES.md`) to determine which documentation sources are valid for a given project.

**Canonical authority:** `SOURCES.md` at the workspace root. This file mirrors its key content for convenience within the `docs/` structure.

**Last verified:** 2026-05-21

---

## How To Use This File

1. **Identify the project's stack** — read `package.json`, `vite.config`, framework config
2. **Look up the stack** in the Project Type → Sources table below
3. **Load ONLY those sources** — no others
4. **Check the Compatibility Matrix** before combining any tools
5. **Follow the Agent Rules** (Section 4)

---

## Tier 1: Canonical Framework Sources (Highest Authority)

| Framework | URL | Covers | Forbidden to mix with |
|---|---|---|---|
| TanStack Start | `https://context7.com/websites/tanstack_start/llms.txt` | routing, loaders, server functions, SSR, hydration | Next.js App Router, Remix, React Router SSR |
| Next.js | `https://context7.com/vercel/next.js/llms.txt` | App Router, Server Components, Server Actions, caching | TanStack Start, Remix, Vite SSR assumptions |
| SvelteKit | `https://context7.com/sveltejs/kit/llms.txt` | filesystem routing, load functions, server/client separation | React hooks, Next.js APIs, TanStack Router |
| React | `https://context7.com/facebook/react/llms.txt` | hooks, component semantics, rendering behavior | routing decisions, framework choice |
| Astro | `https://context7.com/withastro/astro/llms.txt` | content-heavy apps, islands architecture | — |
| Nuxt | `https://context7.com/nuxt/nuxt/llms.txt` | Vue-based prototypes | — |

---

## Tier 2: Styling & Components

| Source | URL | Notes |
|---|---|---|
| Tailwind CSS | `https://context7.com/websites/tailwindcss/llms.txt` | utility classes, responsive design, theming |
| shadcn/ui | `https://context7.com/shadcn-ui/ui/llms.txt` | **NOT a runtime lib** — components are copied locally |
| Radix UI | `https://context7.com/radix-ui/primitives/llms.txt` | shadcn dependency |
| TanStack Table | `https://context7.com/tanstack/table/llms.txt` | dashboard-heavy apps |

---

## Tier 3: Runtimes & Tooling

| Source | URL | Notes |
|---|---|---|
| Bun | `https://context7.com/websites/bun/llms.txt` | current default runtime |
| Vite | `https://context7.com/vitejs/vite/llms.txt` | many generators use it |
| pnpm | `https://context7.com/pnpm/pnpm/llms.txt` | if a prototype uses it |
| Docker | `https://context7.com/websites/docker/llms.txt` | future deployment standardization |

---

## Tier 4: Backend & Systems Languages (future projects)

| Source | URL | Covers |
|---|---|---|
| Rust | `https://context7.com/rust-lang/rust/llms.txt` | ownership, borrowing, lifetimes, concurrency, async, Cargo |
| Go | `https://context7.com/golang/go/llms.txt` | goroutines, channels, interfaces, HTTP server, concurrency |
| Python | `https://context7.com/websites/python_3/llms.txt` | stdlib, async/await, type hints, file I/O, subprocess |

---

## Tier 5: Agent Architecture (framework-agnostic)

| Source | URL | Covers |
|---|---|---|
| Claude Code | `https://context7.com/anthropics/claude-code/llms.txt` | multi-agent orchestration, sub-agents, hooks, delegation |
| OpenClaw | `https://context7.com/websites/openclaw_ai/llms.txt` | gateway architecture, plugin lifecycle, sandbox policies, agent workspace |

**Advisory only (don't override Tier 1-4):**
- Martin Fowler Architecture Guides (event-driven systems, CQRS, modular monoliths)
- Microsoft Cloud Design Patterns (retry, queues, pub/sub, circuit breakers)

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

### FORBIDDEN COMBINATIONS

| Combination | Why |
|---|---|
| Next.js + TanStack Start | Conflicting routing/server models |
| Next.js + Vite SSR | Different runtime pipeline |
| SvelteKit + React hooks | Incompatible component model |
| Bun-only APIs + Node deployment | Runtime incompatibilities |
| npm lockfiles + pnpm | Dependency resolution drift |
| Remix loaders + TanStack loaders | Similar but different behavior |
| App Router + Pages Router | Next.js internal conflict |

---

## Project Type → Correct Sources Lookup

### TanStack Start Project
**Detect by:** `@tanstack/start` in package.json, `app.config.ts` with TanStack plugin
**Load:** TanStack Start, React, Tailwind CSS, Vite, Bun (+ shadcn/ui + Radix if used,+ TanStack Table if tables needed)

### Next.js Project
**Detect by:** `next` in package.json, `next.config.js`/`next.config.mjs`
**Load:** Next.js, React, Tailwind CSS (+ shadcn/ui + Radix if used)

### SvelteKit Project
**Detect by:** `@sveltejs/kit` in package.json, `svelte.config.js`
**Load:** SvelteKit, Tailwind CSS, Vite

### Astro Project
**Detect by:** `astro` in package.json, `astro.config.mjs`
**Load:** Astro, Tailwind CSS

### Rust / Go / Python Projects
**Detect by:** `Cargo.toml` / `go.mod` / `pyproject.toml` or `requirements.txt`
**Load:** Only the matching language docs from Tier 4

---

## Agent Rules for Source Selection

1. **DETECT THE STACK FIRST** — read config files before coding
2. **LOAD ONLY RELEVANT SOURCES** — never load framework docs for frameworks the project doesn't use
3. **USE ARCHITECTURE SOURCES SEPARATELY** — advisory only, never override framework docs
4. **FOLLOW SOURCE PRIORITY** — Framework > Runtime > UI > Architecture > Tutorials
5. **WHEN IN DOUBT, ASK** — don't guess, don't mix

---

## Related Files

- **`SOURCES.md`** (workspace root) — Canonical full version of this file with verification log
- **`docs/framework.md`** — Build tool rules, coding agent delegation, anti-patterns
- **`AGENTS.md`** — Agent work rules (source selection rules summary)
