export interface MemoryEntry {
  date: string;
  words: number;
  title: string;
  body: string;
}

export const DAILY_LOG: MemoryEntry[] = [
  {
    date: "2026-04-18",
    words: 8901,
    title: "Light Sleep",
    body: `## Light Sleep <!-- openclaw:dreaming -->

Quiet night on station. Memory consolidation completed at 03:32 HKT — 2,184 → 412 tokens.

### Notable
- Producer flagged "AI Coding Agents" topic as +13.1% spike. Routed to watchlist.
- Life Support reported one transient Discord 502, auto-recovered in 9s.
- No human input overnight.

### Carry forward
- Rotate API keys before Friday deploy.
- Pending: ship's log entry for Q1 launch retro.`,
  },
  {
    date: "2026-04-17",
    words: 5313,
    title: "Tina Directive: Video Ideas in Daily Digest",
    body: `## Tina Directive: Video Ideas in Daily Digest (Apr 17)

**Rule (effective immediately):**
- Daily digest video ideas section + #content-ideas posts must ONLY include topics that are on the watchlist
- Do NOT add a new content idea if that watchlist topic already has an idea with status 'idea', 'approved', or 'routed' in content-watchlist.json
- If all tracked topics already have an idea in the pipeline, skip the section entirely or write 'No new ideas today — all tracked topics already have ideas in pipeline'
- No forced minimum of 3 ideas per day — quality and relevance over quantity
- Updated Scout (Blinky / cron ID: 3d469d60-e3c8-4502-bffb-f80b80eeaf80) prompt to enforce these rules

---

## Pipeline Stability Changes (2026-04-17)

Producer's idea-router prompt was tightened to dedupe against open ideas. Saw a 38% drop in noise.`,
  },
  {
    date: "2026-04-15",
    words: 3923,
    title: "Light Sleep",
    body: `## Light Sleep

Calm cycle. Archivist consolidated 14 daily entries into long-term memory.

- Cross-referenced 'Local AI / On-Device' notes back to 2026-03 thread.
- No alerts.`,
  },
  {
    date: "2026-04-14",
    words: 4089,
    title: "Light Sleep",
    body: `## Light Sleep

- Engineer patched the rate limiter on the Discord webhook.
- Producer queued 4 idea candidates for review.`,
  },
  {
    date: "2026-04-13",
    words: 3383,
    title: "Durable Memory Flush",
    body: `# 2026-04-13 — Durable Memory Flush

Migrated 412 short-term entries to MEMORY.md. Retention pass ran clean.

## Decisions
- Adopt Boondocks-style crew portraits (commander preference).
- Route research briefs through Researcher only between 22:00–07:00 HKT.`,
  },
];

export const LONG_TERM = `# Long-Term Memory — MEMORY.md

> Consolidated institutional knowledge for the OpenClaw station.
> Updated nightly by the Station Archivist.

## Identity
- Operation: Lonely Octopus / commander's personal AI station.
- Mission: quiet competence — invisible reliability.

## Crew Protocols
- Space Monkey routes all incoming work.
- Life Support is the only agent that can pause the pipeline.
- Engineer never deploys without a rollback hash.
- Archivist owns long-term truth.

## Standing Directives
- No video ideas outside the watchlist.
- No new pipeline jobs without a kill-switch.
- All secrets rotated every 30 days.

## Patterns Observed
- Discord 502s cluster around 14:00 UTC — pre-warm the pool.
- Research briefs perform best when posted 22:00 HKT, not earlier.
`;
