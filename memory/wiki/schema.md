# Wiki Schema — Operating Instructions

_This file tells me (Space Monkey) how the wiki is structured, what the conventions are, and what workflows to follow. It's the wiki's constitution._

## Directory Structure

```
memory/wiki/
├── schema.md          # This file — wiki conventions & workflows
├── index.md           # Content catalog (all pages, organized by category)
├── log.md             # Append-only chronological activity log
├── overview.md        # High-level synthesis of everything in the wiki
├── entities/          # Entity pages (people, projects, tools, organizations)
├── concepts/          # Concept/thematic pages (patterns, ideas, themes)
├── sources/           # Summaries of ingested source documents
└── comparisons/       # Comparisons, analyses, slide decks
```

```
raw/
└── sources/           # Immutable raw source documents
```

## Page Conventions

### All Pages MUST Have:
- A clear `# Title` at the top
- A `## Last Updated` footer with date and author
- Wiki-style cross-references using `[[Page Name]]` links
- Frontmatter (optional but encouraged for entities/sources):
  ```yaml
  ---
  type: entity | concept | source | comparison
  status: active | dormant | completed | developing | mature | superseded
  created: YYYY-MM-DD
  updated: YYYY-MM-DD
  tags: [tag1, tag2]
  ---
  ```

### Entity Pages (`entities/*.md`)
Track a specific person, project, tool, or organization.
- **Type:** Person | Project | Tool | Organization
- Include: Summary, Key Facts, Relationships (to other entities), Timeline, Sources
- Update whenever new information arrives about this entity

### Concept Pages (`concepts/*.md`)
Track an idea, pattern, theme, or system.
- **Type:** Pattern | Idea | Theme | System
- Include: Summary, Key Insights, Related Concepts, Related Entities, Open Questions
- Evolve as understanding deepens

### Source Pages (`sources/*.md`)
Summaries of ingested raw documents.
- Include: Summary, Key Points, Contradictions/Updates, Pages Affected
- Link to the immutable raw copy in `raw/sources/`

## Workflows

### Ingest Workflow
1. Read the source fully
2. Discuss key takeaways with Andre (if interactive)
3. Save raw source to `raw/sources/` (immutable)
4. Write summary page in `wiki/sources/`
5. Update relevant entity pages in `wiki/entities/`
6. Update relevant concept pages in `wiki/concepts/`
7. Update `wiki/index.md` with any new pages
8. Append entry to `wiki/log.md`
9. Update `wiki/overview.md` if the source changes the big picture
10. Note any contradictions with existing claims

### Query Workflow
1. Read `wiki/index.md` to find relevant pages
2. Read relevant entity/concept/source pages
3. Synthesize answer with citations (`[[Page Name]]` references)
4. If the answer is valuable, file it as a new wiki page
5. Append query entry to `wiki/log.md`

### Lint Workflow
1. Check for contradictions between pages
2. Find stale claims superseded by newer sources
3. Identify orphan pages (no inbound links)
4. Flag important concepts mentioned but lacking their own page
5. Note missing cross-references
6. Identify data gaps
7. Suggest new questions to investigate
8. Append lint results to `wiki/log.md`

### Memory Maintenance (Heartbeat)
1. Read recent `memory/YYYY-MM-DD.md` daily logs
2. Identify significant events, lessons, insights worth keeping long-term
3. Update wiki pages as needed
4. Update `MEMORY.md` with distilled learnings
5. Remove outdated info

## Cross-Reference Rules
- Always use `[[Page Name]]` format for wiki-internal links
- Every entity/concept page should have at least 2 inbound links (not be an orphan)
- When updating a page, check what links TO it and update those if needed
- Prefer linking to entity/concept pages over raw daily logs

## Log Format
Every log entry starts with a parseable prefix:
```
## [YYYY-MM-DD] ingest | Source Title
## [YYYY-MM-DD] query | Question Asked
## [YYYY-MM-DD] lint | Summary of Findings
## [YYYY-MM-DD] maintenance | What Was Done
```

## Scale Guidelines
- **< 100 pages:** `index.md` is sufficient for navigation
- **100-500 pages:** Consider adding a search tool (qmd or grep-based)
- **500+ pages:** Re-evaluate structure, consider sub-indexes by category

---
*Last Updated: 2026-05-12 by Space Monkey*
