# Mission Control Dashboard

**Type:** System
**Status:** Developing
**First mentioned:** 2026-05-11

## Summary

The 7-screen dashboard architecture for monitoring the OpenClaw agent station. A TanStack Start app with dark theme, pixel art avatars, and real-time data from the OpenClaw workspace.

## Key Insights
- **7 Screens:** Tasks, Calendar, Projects, Memory, Docs, Team, Visual Office
- **Data flows from workspace files:** cron jobs → Calendar, memory files → Memory, project files → Projects, system stats → Team/Visual
- **Sidebar navigation is the #1 priority** — must match reference screenshots (Tina Huang's "Lonely Octopus")
- **Self-contained Day 1** — no external integrations, reads from `~/.openclaw/workspace/`
- **Crew-based UI** — each screen maps to a crew role (Director, Life Support, Systems Engineer, Archivist)

## Architecture
```
Dashboard (TanStack Start)
├── Sidebar (fixed left nav, dark #12182A)
│   ├── Tasks → task store (JSON file in workspace)
│   ├── Calendar → openclaw.json cron jobs
│   ├── Projects → project files/dirs in workspace
│   ├── Memory → memory/*.md daily logs + MEMORY.md
│   ├── Docs → all .md files in workspace
│   ├── Team → crew info + model info + system stats
│   └── Visual Office → agent status + session activity
└── Data Layer
    ├── Node server-side fs reads (NOT edge runtime)
    ├── System commands: df -h, vm_stat, sysctl, ps aux
    └── Graceful empty states
```

## Related Concepts
- [[agent-memory]] — The Memory screen shows my memory files
- [[llm-wiki-pattern]] — The wiki IS the memory layer for the dashboard

## Related Entities
- [[mission-control]] — The project entity
- [[andre]] — The visionary
- [[space-monkey]] — The director

## Open Questions
- ZIP extraction is the current blocker — try Python zipfile module?
- Bun vs npm for running the project?
- How to handle real-time updates (polling? file watcher?)?

## Last Updated
2026-05-12 by Space Monkey
