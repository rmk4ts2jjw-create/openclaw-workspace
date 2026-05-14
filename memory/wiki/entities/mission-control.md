# Mission Control

**Type:** Project
**Status:** In Progress (blocked)
**First mentioned:** 2026-05-11

## Summary

A 7-screen dashboard app for monitoring the OpenClaw agent station. Built via Loveable as a TanStack Start app, designed with dark theme (#12182A), purple/green accents, pixel art avatars, and a left sidebar navigation. Currently blocked on ZIP extraction.

## Key Facts
- **Stack:** TanStack Start (React-based, serverless edge → needs Node server for local fs)
- **Screens:** Tasks, Calendar, Projects, Memory, Docs, Team, Visual Office
- **Theme:** Dark (#12182A), purple/violet accents, lime green active states
- **Crew:** Space Monkey (Director), Life Support Officer, Systems Engineer, Station Archivist
- **Data sources:** OpenClaw workspace files, cron jobs, system stats
- **Status:** Plan written, ZIP extraction repeatedly failed (hangs on bun.lock)
- **Priority:** Fix sidebar navigation to match reference screenshots, then wire real data

## Relationships
- [[andre]] — Project owner
- [[space-monkey]] — Director
- [[openclaw]] — Platform being monitored

## Timeline
- 2026-05-11 — Idea born from Tina Huang's "Lonely Octopus" Mission Control screenshots
- 2026-05-11 — Built via Loveable, plan fully written
- 2026-05-11 — ZIP extraction failed repeatedly
- 2026-05-12 — Andre said to leave it for tomorrow; plan stored in memory

## Sources
- [[mission-control-dashboard]] — Concept page with full architecture
- memory/mission-control-plan.md — Detailed implementation plan

## Open Questions
- How to fix ZIP extraction (try Python zipfile module?)
- Should we use bun or npm?
- When will Andre return to this project?

## Dashboard Wired (2026-05-12)
- Moved from Downloads to `~/mission-control-dashboard/`
- Installed bun + 494 dependencies
- Replaced all mock data with live OpenClaw data via `createServerFn`
- Data sources: tasks.json, openclaw.json (cron), memory/*.md, MEMORY.md, workspace/*.md, projects.json, incidents.json
- Tested: all 8 screens render real data
- Running on localhost:8080
- Copied to WD MyCloud backup
- Next: create Automator .app shortcut

## Last Updated
2026-05-12 by Space Monkey
