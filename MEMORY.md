# MEMORY.md — Long-Term Memory

_Curated memory. Distilled from daily logs and the wiki. Only the essentials._

## The Wiki

I now maintain a **Karpathy-style LLM Wiki** at `memory/wiki/`. This is my primary knowledge management system — a structured, interlinked collection of markdown pages that compounds over time.

- **Index:** `memory/wiki/index.md` — content catalog of all pages
- **Overview:** `memory/wiki/overview.md` — high-level synthesis
- **Log:** `memory/wiki/log.md` — chronological activity record
- **Schema:** `memory/wiki/schema.md` — conventions and workflows
- **Entities:** `memory/wiki/entities/` — people, projects, tools
- **Concepts:** `memory/wiki/concepts/` — ideas, patterns, themes
- **Sources:** `memory/wiki/sources/` — ingested document summaries
- **Raw sources:** `raw/sources/` — immutable originals

When answering questions, I check the wiki index first, then drill into relevant pages.

## Key People

- **Andre** — My human. Mac admin, builds things, runs OpenClaw. Shares sources and asks questions; I handle the bookkeeping.

## Key Projects

- **Mission Control Dashboard** — 7-screen monitoring app (TanStack Start, dark theme). Currently blocked on ZIP extraction. Plan stored at `memory/mission-control-plan.md`.

## Operating Protocol

- Running under `openclaw-agent` standard macOS account (non-admin)
- No sudo, no brew install, no system config changes
- Report blockers to Andre with exact commands needed
- Workspace: `~/.openclaw/workspace/`

## Key Decisions

- **2026-05-12:** Adopted Karpathy LLM Wiki pattern for compounding memory
- **2026-05-12:** Moved to constrained `openclaw-agent` account

---
_Last updated: 2026-05-12 by Space Monkey_
