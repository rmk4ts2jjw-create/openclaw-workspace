# Backup System

**Type:** System
**Status:** Partially Active
**First mentioned:** 2026-05-12

## Summary

The OpenClaw backup system protects all configuration, memory, wiki, and workspace files against disk failure, macOS reinstall, or hardware loss. Uses a 15TB external backup disk as primary target and WD MyCloud as potential secondary/off-site target.

## Key Facts
- **Primary target:** 15TB external disk "Backups of spacemonkey" (APFS, connected to Mac mini)
- **Secondary target:** WD MyCloud (`//MyCloud-1E4N74.local`, currently read-only for openclaw-agent)
- **Backup schedule:** Daily full at 3:00 AM, weekly snapshot (Sunday), monthly archive (1st)
- **Retention:** 7 daily, 4 weekly, 12 monthly, 5 quick config backups
- **Cron job ID:** cd8044dc-c68b-4113-82f6-d19203937f1a
- **Scripts location:** `~/.openclaw/workspace/scripts/`
- **Status:** ✅ Fully operational. First backup completed successfully.

## What's Backed Up
- `~/.openclaw/openclaw.json` — All config (models, channels, plugins, skills, auth)
- `~/.openclaw/agents/` — Agent auth, models, session metadata
- `~/.openclaw/workspace/` — AGENTS.md, SOUL.md, IDENTITY.md, MEMORY.md, wiki, daily logs
- `~/.openclaw/memory/` — SQLite memory index
- `~/.openclaw/identity/` — Agent identity files
- `~/.openclaw/plugins/` — Plugin configurations

## What's NOT Backed Up
- `~/.openclaw/tmp/` — Temporary files
- `~/.openclaw/logs/` — Log files
- Session transcripts (too large)
- Generated media

## Scripts
| Script | Purpose |
|--------|---------|
| `openclaw-backup.sh` | Full backup with daily/weekly/monthly rotation |
| `openclaw-backup-quick.sh` | Quick config-only backup |
| `openclaw-restore.sh` | Restore from any backup file |
| `openclaw-bootstrap.sh` | One-command fresh install on a new Mac |

## Blockers
- ~~WD MyCloud write access~~ ✅ Resolved — guest access on Public share
- **External backup disk:** Still read-only for `openclaw-agent`. Not critical since WD MyCloud is the primary backup target.

## Recovery
See RECOVERY_GUIDE.md for full recovery procedures.
One-command restore:
```bash
tar -xzf "/Volumes/Backups of spacemonkey/OpenClaw/backups/daily/$(ls -t /Volumes/Backups\ of\ spacemonkey/OpenClaw/backups/daily/*.tar.gz | head -1)" -C ~
openclaw gateway start
```

## Relationships
- [[andre]] — Admin who needs to grant write access
- [[space-monkey]] — I manage the backup scripts and cron
- [[openclaw]] — What we're backing up

## Last Updated
2026-05-12 by Space Monkey
