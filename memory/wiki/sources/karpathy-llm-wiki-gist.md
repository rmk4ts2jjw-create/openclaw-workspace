# Source: Karpathy LLM Wiki Gist

**Type:** Gist
**Source:** https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
**Date:** 2026-05-12 (ingested)
**Ingested:** 2026-05-12

## Summary

Andre shared this gist as the blueprint for improving my memory. It describes a pattern where an LLM incrementally builds and maintains a persistent wiki — a structured, interlinked collection of markdown files — instead of using traditional RAG. The wiki compounds over time, with the LLM handling all maintenance (cross-references, consistency, contradiction flagging).

## Key Points
- **Core idea:** Wiki is a persistent, compounding artifact between raw sources and the user
- **Three layers:** Raw sources (immutable), Wiki (LLM-maintained), Schema (conventions)
- **Ingest flow:** Read → discuss → summarize → update entities/concepts → update index → log
- **Query flow:** Search index → read pages → synthesize with citations → file valuable answers
- **Lint flow:** Check contradictions, orphans, stale claims, missing links, data gaps
- **Two special files:** index.md (content catalog) and log.md (chronological record)
- **Scale:** Index file works up to ~100 sources / hundreds of pages; then add search tool
- **Tooling:** Obsidian for viewing, qmd for search, Marp for slides, Dataview for queries
- **Git:** The wiki is just a git repo — version history for free
- **Human's job:** Curate sources, direct analysis, ask questions, think about meaning
- **LLM's job:** Everything else (summarizing, cross-referencing, filing, bookkeeping)

## Contradictions / Updates
- None — this is the first source, establishing the pattern

## Pages Created/Updated
- [[llm-wiki-pattern]] — Concept page created
- [[agent-memory]] — Concept page updated with wiki context
- [[space-monkey]] — Entity page updated with wiki memory architecture
- All entity pages created as part of bootstrap
- [[overview]] — Initial synthesis written
- [[index.md]] — Initial catalog created
- [[log.md]] — Bootstrap entry added
- [[schema.md]] — Wiki conventions written

## Raw Source
See: `raw/sources/karpathy-llm-wiki-gist.md`

## Last Updated
2026-05-12 by Space Monkey
