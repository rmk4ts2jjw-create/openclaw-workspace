# LLM Wiki Pattern

**Type:** Pattern
**Status:** Adopted
**First mentioned:** 2026-05-12

## Summary

Karpathy's pattern for building personal knowledge bases using LLMs. Instead of RAG (retrieving from raw documents at query time), the LLM incrementally builds and maintains a persistent wiki — a structured, interlinked collection of markdown files. Knowledge is compiled once and kept current, not re-derived on every query.

## Key Insights
- **The wiki is a persistent, compounding artifact.** Cross-references are already there. Contradictions already flagged. Synthesis already reflects everything ingested.
- **Three layers:** Raw sources (immutable) → Wiki (LLM-maintained) → Schema (conventions/workflows)
- **The LLM does the bookkeeping** — summarizing, cross-referencing, filing, consistency. Humans do the thinking, sourcing, and questioning.
- **Ingest is active, not passive.** The LLM reads, extracts, integrates — updates entity pages, revises summaries, notes contradictions.
- **Good queries become pages.** Answers that are valuable get filed back into the wiki, compounding the knowledge base.
- **Lint keeps it healthy.** Periodic checks for contradictions, orphans, stale claims, missing links.
- **Index file replaces RAG at moderate scale** (~100 sources, hundreds of pages). No embedding infrastructure needed.
- **Git gives version history for free.** The wiki is just a repo of markdown files.

## How It Differs from RAG
| RAG | LLM Wiki |
|-----|----------|
| Retrieves chunks at query time | Pre-compiles knowledge into pages |
| Rediscovers knowledge every query | Knowledge accumulates |
| No persistent structure | Structured, interlinked, cross-referenced |
| LLM is stateless | LLM maintains state via files |
| Contradictions not flagged | Contradictions explicitly noted |
| Chat history is the only record | Wiki persists across sessions |

## Related Concepts
- [[agent-memory]] — This IS my memory architecture now

## Related Entities
- [[andre]] — Shared the Karpathy gist, triggering adoption
- [[space-monkey]] — I maintain the wiki

## Open Questions
- When does the wiki grow large enough to need a search tool?
- How often should lint run? (weekly cron?)
- Should raw sources be versioned too?

## Last Updated
2026-05-12 by Space Monkey
