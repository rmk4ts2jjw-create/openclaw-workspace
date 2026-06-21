# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Station Memory

Shared SQLite-backed knowledge store. Any agent session can query it — no conversation history needed.

**Tool:** `node scripts/station-memory-tool.cjs` (in `mission-control-dashboard/`)

```bash
# Search (FTS5 full-text + LIKE fallback)
node scripts/station-memory-tool.cjs search "LaunchAgent" --limit 5

# Get specific record
node scripts/station-memory-tool.cjs get sm-001

# Get related records (bidirectional)
node scripts/station-memory-tool.cjs related sm-002

# List by type
node scripts/station-memory-tool.cjs list --type lesson-learned

# Stats
node scripts/station-memory-tool.cjs stats
```

**Before starting any significant work, query Station Memory:**
- "Have we solved this before?"
- "Has this failed before?"
- "Is there an architecture decision?"
- "Is there a framework rule?"

**DB location:** `data/station-memory.db`
**Auto-ingestion:** Tasks → knowledge on completion, Incidents → knowledge on resolution

---

### OpenCode

- Binary: `/Users/spacemonkey/.opencode/bin/opencode`
- Version: 1.17.8
- NOT in PATH — use full path
- Web UI: http://192.168.68.64:4097

---

Add whatever helps you do your job. This is your cheat sheet.

## Related

- [Agent workspace](/concepts/agent-workspace)
