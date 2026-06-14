# Recall Engine — Design Document

## 1. Problem Statement

OpenClaw has **7 distinct memory/knowledge systems**, each with different access patterns, formats, and coverage:

| System | Access | Format | Coverage | Status |
|--------|--------|--------|----------|--------|
| MEMORY.md | `read` / `memory_get` | Markdown | Curated long-term memory | ✅ Working |
| Daily notes | `read` file | Markdown | Raw daily logs | ✅ Working |
| Memory Wiki | `wiki_search` / `wiki_get` | Markdown + frontmatter | Entities, concepts, lessons | ✅ Working (local) |
| Station Memory | `exec` SQLite tool | Structured JSON | Architecture decisions, lessons | ✅ Working |
| Workboard | `workboard_list` | Structured JSON | Active tasks, backlog | ✅ Working |
| Skill Workshop | `skill_workshop list/inspect` | Markdown + frontmatter | Skill proposals, procedures | ✅ Working |
| Skill definitions | `read` SKILL.md | Markdown | Installed skill capabilities | ✅ Working |
| memory_search | Tool call | Semantic | All indexed memory | ❌ **BROKEN** — no OpenAI embedding key |

**Current behavior:** I search 1-2 sources (usually wiki + daily log) and reason from that. I don't synthesise across all systems. This means I miss relevant context, repeat past mistakes, and rediscover known solutions.

**AGENTS.md already defines a 3-step recall** (Wiki → Workboard → Daily Log) but it's incomplete and doesn't cover Station Memory, Skill Workshop, skills, or project files.

## 2. Architecture

```
User Request
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│                   RECALL ENGINE                         │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Classifier  │→│  Dispatcher  │→│   Merger    │    │
│  │             │  │             │  │             │    │
│  │ Fast vs     │  │ Fan-out to  │  │ Deduplicate │    │
│  │ Deep recall │  │ relevant    │  │ Rank by     │    │
│  │ based on    │  │ sources     │  │ relevance   │    │
│  │ request     │  │             │  │             │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Sources:                                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │Wiki      │ │Station   │ │Workboard │ │Skill     │  │
│  │(search)  │ │Memory    │ │(list)    │ │Workshop  │  │
│  │          │ │(exec)    │ │          │ │(list)    │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐               │
│  │MEMORY.md │ │Daily Log │ │Project   │               │
│  │(read)    │ │(read)    │ │Files     │               │
│  │          │ │          │ │(read)    │               │
│  └──────────┘ └──────────┘ └──────────┘               │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │           Context Package Generator              │   │
│  │  Executive summary, decisions, incidents,       │   │
│  │  tasks, skills, risks, deps, rejected approaches│   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
     │
     ▼
Reasoning begins with full context
```

## 3. Retrieval Pipeline

### Step 1: Classify Request Mode

**Fast Recall** — Simple factual questions:
- "What port does MC run on?"
- "What's the Docker host IP?"
- "Is skill X activated?"

**Deep Recall** — Complex work requiring synthesis:
- Keywords: `architecture`, `plan`, `refactor`, `design`, `governance`, `new feature`, `review`, `build`
- Any request that would benefit from knowing prior decisions, related incidents, or existing skills

### Step 2: Dispatch to Sources

**Fast Recall** (1-2 sources, minimal overhead):
1. Wiki search (primary knowledge store)
2. Daily log (if time-relevant)

**Deep Recall** (all relevant sources, parallel where possible):

| Priority | Source | Query Method | When to Include |
|----------|--------|-------------|-----------------|
| 1 | Wiki | `wiki_search(query)` | Always |
| 2 | Station Memory | `exec station-memory-tool.cjs search` | Always |
| 3 | Workboard | `workboard_list` (filter by status/label) | If task-related |
| 4 | Skill Workshop | `skill_workshop list` + inspect relevant | If skill-related |
| 5 | MEMORY.md | `read` or `memory_get` | Always (it's in project context already) |
| 6 | Daily log | `read` most recent 1-2 days | If time-relevant |
| 7 | Skill definitions | `read` SKILL.md for relevant skills | If matching skill found |
| 8 | Project files | `read` specific files | If architecture/refactor |

### Step 3: Merge and Deduplicate

**Deduplication rules:**
- Same content from Wiki and Station Memory → keep Wiki version (richer context)
- Same lesson from daily log and Station Memory → keep Station Memory (structured)
- Same task from Workboard and daily log → keep Workboard (authoritative)
- Skill proposal + installed skill with same name → keep installed skill (active > proposed)

**Ranking strategy:**
1. **Recency** — newer results rank higher (within 30 days)
2. **Source authority** — Station Memory > Wiki > Daily Logs > Workboard
3. **Relevance** — exact keyword match > partial match > semantic similarity
4. **Status** — `current`/`active` > `deprecated`/`archived`
5. **Specificity** — specific entity/concept > general topic

### Step 4: Generate Context Package

Structured output (see Section 5 below).

## 4. Implementation Approach

### Option A: Pure Prompt-Based (No Code)

Add a **Recall Engine procedure** to AGENTS.md that defines the pipeline as a checklist. The agent follows it manually for each Deep Recall.

**Pros:** No implementation work. Immediate.
**Cons:** Relies on agent discipline. Easy to skip steps. No deduplication logic.

### Option B: Shell Script + Prompt Hybrid

Write a `scripts/recall.sh` script that:
1. Takes a query string
2. Runs `wiki_search`, `station-memory search`, `workboard_list` in parallel
3. Merges results into a single JSON file
4. The agent reads the JSON and generates the Context Package

**Pros:** Deterministic retrieval. Parallel execution. Reusable.
**Cons:** Script maintenance. Doesn't handle ranking/dedup well.

### Option C: Full Implementation

Build a `recall` tool (Node.js) that:
1. Exposes as a script: `node scripts/recall.js "query" --mode deep`
2. Fans out to all sources
3. Deduplicates and ranks
4. Outputs Context Package as Markdown

**Pros:** Best experience. Reusable. Testable.
**Cons:** Implementation effort (~2-3 hours).

### Recommendation: **Start with Option A, evolve to Option B**

The Recall Engine is primarily a **workflow discipline** problem, not a tooling problem. The agent needs to know *what to search* and *how to synthesise*. A well-written AGENTS.md procedure achieves 80% of the value with 0% implementation cost.

Option B (shell script) can be added later if the prompt-based approach proves unreliable.

## 5. Context Package Format

```markdown
## Context Package — [Topic]
**Generated:** [timestamp]
**Mode:** Fast / Deep
**Sources searched:** [list]

### Executive Summary
[2-3 sentence synthesis of what was found]

### Relevant Prior Decisions
- [Decision] (source: [wiki/station-memory], date: [date])

### Related Incidents
- [Incident] (status: [open/resolved], source: [station-memory/wiki])

### Related Tasks
- [Task] (status: [backlog/in-progress/done], source: [workboard])

### Related Skills
- [Skill] (status: [active/proposed/blocked], source: [skill-workshop])

### Risks
- [Risk] (source: [lesson-learned/incident])

### Dependencies
- [Dependency] (source: [decision/architecture])

### Previously Rejected Approaches
- [Approach] — rejected because [reason] (source: [decision-log])

### Suggested Files for Deeper Reading
- [file path] — [why it's relevant]

### Confidence
- **High** = multiple corroborating sources
- **Medium** = single source or partial match
- **Low** = inferred, no direct source found
```

## 6. Workflow Integration

### When to Trigger

**Fast Recall** (automatic for every request):
- Before answering any question about prior work, decisions, dates, people, preferences, or todos
- Before starting any task

**Deep Recall** (automatic for complex work):
- Architecture design or review
- Planning (multi-step work)
- Major refactors (touching 3+ files)
- Governance decisions (skill activation, policy changes)
- New features (anything not done before)
- Incident investigation

### Where in the Workflow

```
User Request
    │
    ▼
[Classify: Fast or Deep]
    │
    ▼
[Recall Engine — search all relevant sources]
    │
    ▼
[Generate Context Package]
    │
    ▼
[Reason using Context Package]
    │
    ▼
[Execute / Respond]
```

### Integration with AGENTS.md

Replace the current "MANDATORY: Check Memory Before Starting Any Task" section (Steps 1-3) with:

```
## Recall Engine

Before ANY work:
1. Classify: Fast (factual) or Deep (complex)
2. Search all relevant sources per the Recall Engine procedure
3. Generate Context Package
4. Use Context Package to inform approach

Deep Recall is automatic for: architecture, planning, refactors, governance, new features.
```

## 7. Known Limitations

1. **`memory_search` is broken** — no OpenAI embedding key. The Recall Engine works around this by using `wiki_search` (local) + `station-memory search` (FTS5) as the semantic search layer. Fixing `memory_search` would improve coverage.

2. **No cross-source joins** — the engine can't answer "what tasks are related to incidents that triggered architecture decisions" in one pass. It finds each piece separately and the agent synthesises.

3. **Ranking is heuristic** — no ML-based relevance. Relies on recency + authority + specificity rules.

4. **Project file search is manual** — the engine suggests files for deeper reading but doesn't search file contents. A `grep`-based content search could be added.

5. **Session history is not searched** — prior conversations in the same session are in context, but older sessions require `sessions_history` calls. Not included in the initial design due to token cost.

## 8. Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Context recall rate | ≥80% of relevant sources found | Manual audit: after completing a task, check if any relevant prior work was missed |
| Duplicate work rate | <10% | Track instances where agent rediscovers something already in Station Memory |
| Context Package quality | Useful without manual supplementation | Andre rates: did the package contain what was needed? |
| Fast Recall latency | <30 seconds | Time from request to reasoning start |
| Deep Recall latency | <2 minutes | Time from request to reasoning start |

## 9. Implementation Plan

### Phase 1: Procedure (Immediate — No Code)
1. Write the Recall Engine procedure into AGENTS.md
2. Define Fast vs Deep classification rules
3. Define the Context Package format as a template
4. Test on next 5 Deep Recall requests

### Phase 2: Shell Script (If Phase 1 proves unreliable)
1. Write `scripts/recall.sh` that fans out to wiki + station-memory + workboard
2. Output merged JSON
3. Agent reads JSON and generates Context Package

### Phase 3: Full Tool (If Phase 2 is insufficient)
1. Build `scripts/recall.js` with ranking and deduplication
2. Add project file content search (grep-based)
3. Add session history search (optional, token-costly)

---

_Design version: 1.0_
_Date: 2026-06-14_
_Author: Space Monkey_
