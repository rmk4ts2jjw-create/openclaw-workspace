# Karpathy LLM Wiki — Implementation Plan for OpenClaw

## Goal

Transform my flat, append-only memory files into a persistent, compounding knowledge wiki — a structured, interlinked collection of markdown pages that grows richer with every interaction, ingest, and query.

## Current State

- `MEMORY.md` — exists but empty (no curated long-term memory yet)
- `memory/YYYY-MM-DD.md` — daily raw logs (only one: 2026-05-11.md)
- `memory/mission-control-plan.md` — a project plan, not really memory
- No structure, no cross-references, no entity pages, no index, no log
- Memory is essentially a flat diary — I rediscover everything from scratch each session

## Target Architecture

```
~/.openclaw/workspace/
├── MEMORY.md                  # Kept as-is: long-term curated memory (human-readable summary)
├── memory/
│   ├── YYYY-MM-DD.md          # Daily raw logs (keep existing pattern)
│   └── wiki/                  # THE WIKI (new)
│       ├── schema.md          # Wiki conventions, structure, workflows (the "CLAUDE.md" for the wiki)
│       ├── index.md           # Content catalog — every page, one-line summary, organized by category
│       ├── log.md             # Append-only chronological record of ingests, queries, lint passes
│       ├── overview.md        # High-level synthesis of everything in the wiki
│       ├── entities/          # Entity pages (people, projects, tools, concepts)
│       │   ├── andre.md
│       │   ├── space-monkey.md
│       │   ├── mission-control.md
│       │   └── openclaw.md
│       ├── concepts/          # Concept/thematic pages
│       │   ├── agent-memory.md
│       │   ├── mission-control-dashboard.md
│       │   └── llm-wiki-pattern.md
│       ├── sources/           # Summaries of ingested source documents
│       │   └── karpathy-llm-wiki-gist.md
│       └── comparisons/       # Comparison tables, analyses, slide decks
│           └── (future)
└── raw/                       # Raw source documents (immutable)
    └── sources/               # Articles, papers, images, data files
        └── (future ingests)
```

## The Three Layers (per Karpathy)

### Layer 1: Raw Sources (`raw/sources/`)
- Immutable collection of source documents
- Articles, papers, images, data files, screenshots
- I read from these but never modify them
- This is the source of truth

### Layer 2: The Wiki (`memory/wiki/`)
- LLM-generated markdown files
- Summaries, entity pages, concept pages, comparisons, overview, synthesis
- I own this layer entirely — create, update, cross-reference, maintain
- Andre reads it; I write it

### Layer 3: The Schema (`memory/schema.md`)
- Conventions, structure, workflows
- What to do when ingesting sources, answering questions, linting
- Co-evolved over time
- Makes me a disciplined wiki maintainer, not a generic chatbot

## Core Workflows

### 1. Ingest Workflow
When Andre drops a source or I discover something worth filing:
1. Read the source fully
2. Discuss key takeaways with Andre (if interactive)
3. Write/update a summary page in `wiki/sources/`
4. Update relevant entity pages in `wiki/entities/`
5. Update relevant concept pages in `wiki/concepts/6. Update `wiki/index.md` with any new pages
7. Append entry to `wiki/log.md`
8. Update `wiki/overview.md` if the source changes the big picture
9. Note contradictions with existing claims
10. A single source may touch 10-15 wiki pages

### 2. Query Workflow
When Andre asks a question:
1. Read `wiki/index.md` to find relevant pages
2. Read relevant entity/concept/source pages
3. Synthesize answer with citations (page references)
4. If the answer is valuable/filed-worthy → save it as a new wiki page
5. Explorations compound in the knowledge base just like ingested sources

### 3. Lint Workflow
Periodically (or on request):
1. Check for contradictions between pages
2. Find stale claims newer sources have superseded
3. Identify orphan pages (no inbound links)
4. Flag important concepts mentioned but lacking their own page
5. Note missing cross-references
6. Identify data gaps that could be filled with web search
7. Suggest new questions to investigate
8. Append lint results to `wiki/log.md`

### 4. Memory Maintenance Workflow (tie-in to existing)
During heartbeats or periodic reviews:
1. Read recent `memory/YYYY-MM-DD.md` daily logs
2. Identify significant events, lessons, insights worth keeping long-term
3. Update wiki pages as needed
4. Update `MEMORY.md` with distilled learnings (keep it as a human-readable summary)
5. Remove outdated info

## Special Files

### `wiki/index.md` — Content Catalog
- Every wiki page listed with link + one-line summary
- Organized by category: Entities, Concepts, Sources, Comparisons
- I update it on every ingest
- I read it first when answering queries (replaces RAG at moderate scale)
- Metadata: date created, last updated, source count

### `wiki/log.md` — Chronological Record
- Append-only timeline of what happened and when
- Format: `## [YYYY-MM-DD] ingest | Title` or `## [YYYY-MM-DD] query | Question` or `## [YYYY-MM-DD] lint | Findings`
- Parseable with grep: `grep "^## \[" log.md | tail -5`
- Gives timeline of wiki evolution

### `wiki/overview.md` — Synthesis
- High-level summary of everything in the wiki
- Evolving thesis / picture of what we know
- Updated when major new sources arrive or big connections are made

## Wiki Page Conventions

### Entity Pages (`wiki/entities/*.md`)
```markdown
# Entity Name

**Type:** Person | Project | Tool | Organization
**Status:** Active | Dormant | Completed
**First mentioned:** YYYY-MM-DD

## Summary
One-paragraph description.

## Key Facts
- Bullet points of important attributes

## Relationships
- [[Related Entity]] — nature of relationship
- [[Another Entity]] — nature of relationship

## Timeline
- YYYY-MM-DD — Event or update

## Sources
- [[source-name]] — what it contributed

## Last Updated
YYYY-MM-DD by Space Monkey
```

### Concept Pages (`wiki/concepts/*.md`)
```markdown
# Concept Name

**Type:** Pattern | Idea | Theme | System
**Status:** Developing | Mature | Superseded

## Summary
What is this concept?

## Key Insights
- Important points

## Related Concepts
- [[Other Concept]] — how they connect

## Related Entities
- [[Entity]] — relevance

## Open Questions
- What we don't know yet

## Last Updated
YYYY-MM-DD by Space Monkey
```

### Source Pages (`wiki/sources/*.md`)
```markdown
# Source: Title

**Type:** Article | Paper | Gist | Image | Data
**Source:** URL or file path
**Date:** YYYY-MM-DD
**Ingested:** YYYY-MM-DD

## Summary
What's this source about? Key takeaways.

## Key Points
- Important facts/claims

## Contradictions / Updates
- Where this source disagrees with or updates existing wiki knowledge

## Pages Affected
- [[entity-page]] — what was updated
- [[concept-page]] — what was updated

## Raw Source
Path to immutable raw copy in `raw/sources/`
```

## Integration with Existing OpenClaw Memory

| Existing | Wiki Equivalent | Relationship |
|----------|----------------|--------------|
| `MEMORY.md` | `wiki/overview.md` | MEMORY.md becomes a human-readable summary; overview.md is the detailed synthesis |
| `memory/YYYY-MM-DD.md` | `wiki/log.md` | Daily logs stay as raw diary; log.md is the structured wiki activity log |
| `memory/*.md` project plans | `wiki/entities/project-name.md` | Project plans get distilled into entity pages |
| Heartbeat memory maintenance | Wiki lint workflow | Lint becomes a scheduled heartbeat/cron task |
| `memory_search` tool | `wiki/index.md` + file reads | Index file replaces RAG for moderate scale |

## Phase 1: Bootstrap (Do Now)

1. Create directory structure
2. Write `wiki/schema.md` — the wiki's operating instructions
3. Write `wiki/index.md` — initial catalog
4. Write `wiki/log.md` — seed with bootstrap entry
5. Write `wiki/overview.md` — initial synthesis from existing memory
6. Create entity pages for known entities (Andre, Space Monkey, Mission Control, OpenClaw)
7. Create concept pages for known concepts (Agent Memory, Mission Control Dashboard, LLM Wiki Pattern)
8. Ingest the Karpathy gist as first source
9. Update `MEMORY.md` to reference the wiki

## Phase 2: Operationalize (Do This Week)

1. Add wiki maintenance to heartbeat checklist (periodic lint)
2. Create a cron job for weekly wiki health check
3. Update AGENTS.md with wiki workflows
4. Start filing daily log insights into wiki pages
5. Begin cross-referencing entity/concept pages

## Phase 3: Scale (Ongoing)

1. Ingest new sources as they arrive (articles, papers, conversations)
2. Build comparison pages and analyses
3. Evolve schema based on what works
4. Consider search tool if wiki grows beyond ~hundred0 pages (qmd or simple grep)
5. Potentially build small tools for wiki stats, orphan detection, etc.

## Success Criteria

- [ ] Wiki directory structure exists and is populated with initial pages
- [ ] `wiki/schema.md` documents conventions and workflows
- [ ] `wiki/index.md` catalogs all pages
- [ ] `wiki/log.md` tracks activity
- [ ] At least 4 entity pages created
- [ ] At least 3 concept pages created
- [ ] Karpathy gist ingested as first source
- [ ] `MEMORY.md` references the wiki
- [ ] AGENTS.md updated with wiki workflows
- [ ] Heartbeat/lint cron job configured

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Wiki grows stale without maintenance | Scheduled lint via cron; heartbeat checks |
| Too many pages, index.md insufficient | Add search tool (qmd) when needed |
| Cross-references break | Lint workflow catches orphans and missing links |
| Andre can't find things | Index.md as entry point; overview.md as synthesis |
| I forget to update wiki after conversations | AGENTS.md protocol: always file insights after significant conversations |
| Wiki becomes a mess | Schema.md enforces conventions; lint enforces hygiene |

---
*Created: 2026-05-12 by Space Monkey*
*Based on: Karpathy's LLM Wiki pattern (https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)*
