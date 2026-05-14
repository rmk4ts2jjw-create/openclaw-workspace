# RECOVERY_GUIDE.md — OpenClaw Disaster Recovery

_If anything goes wrong — disk failure, macOS reinstall, Mac mini dies — this guide gets you back up and running._

## Quick Recovery (One Command)

If you have the backup disk connected:

```bash
# One command to restore everything:
tar -xzf "/Volumes/OpenClaw-WD/openclaw-agent-backup/backups/daily/$(ls -t /Volumes/OpenClaw-WD/openclaw-agent-backup/backups/daily/*.tar.gz | head -1)" -C ~
openclaw gateway start
```

If you need the full bootstrap (fresh Mac):

```bash
# Download and run the bootstrap script:
curl -fsSL https://YOUR_URL/openclaw-bootstrap.sh | bash
# Or from backup disk:
bash /Volumes/Backups\ of\ spacemonkey/OpenClaw/archives/openclaw-bootstrap.sh
```

## What Gets Backed Up

### Critical (always included)
| Path | What |
|------|------|
| `~/.openclaw/openclaw.json` | All config: models, channels, plugins, skills, auth |
| `~/.openclaw/agents/` | Agent auth, models, session metadata |
| `~/.openclaw/workspace/` | **Everything**: AGENTS.md, SOUL.md, IDENTITY.md, MEMORY.md, wiki, daily logs |
| `~/.openclaw/memory/` | SQLite memory index |
| `~/.openclaw/identity/` | Agent identity files |
| `~/.openclaw/plugins/` | Plugin configurations |
| `~/.openclaw/plugin-skills/` | Installed plugin skills |

### Excluded (not backed up)
| Path | Why |
|------|-----|
| `~/.openclaw/tmp/` | Temporary files, regenerated |
| `~/.openclaw/logs/` | Log files, not needed for recovery |
| `~/.openclaw/agents/*/sessions/*.jsonl` | Session transcripts (too large) |
| `~/.openclaw/media` | Generated media, regenerated |
| `~/.openclaw/.freeride-cache.json` | API cache, regenerated |

## Backup Schedule

| Type | Frequency | Retention | Size |
|------|-----------|-----------|------|
| Quick Config | On demand | Last 5 | ~1 MB |
| Full Daily | Daily at 3:00 AM | Last 7 days | ~50 MB |
| Weekly | Sunday 3:00 AM | Last 4 weeks | ~50 MB |
| Monthly | 1st of month | Last 12 months | ~50 MB |
| Workspace Sync | After every session | Latest only | ~1 MB |

## Recovery Scenarios

### Scenario 1: Config Corruption
```bash
# Restore just config from latest quick backup
tar -xzf "/Volumes/Backups of spacemonkey/OpenClaw/backups/quick/$(ls -t /Volumes/Backups\ of\ spacemonkey/OpenClaw/backups/quick/*.tar.gz | head -1)" -C ~
openclaw gateway restart
```

### Scenario 2: Full Disk Failure / New Mac
1. Install Node.js: `brew install node`
2. Install OpenClaw: `npm install -g openclaw`
3. Connect backup disk
4. Run bootstrap: `bash /Volumes/Backups\ of\ spacemonkey/OpenClaw/archives/openclaw-bootstrap.sh`
5. Done. All memory, wiki, config restored.

### Scenario 3: Partial Restore (just workspace/memory)
```bash
# Extract only workspace from a full backup
tar -xzf "/Volumes/Backups of spacemonkey/OpenClaw/backups/daily/FILE.tar.gz" -C ~ .openclaw/workspace/
```

### Scenario 4: WD MyCloud Recovery (if external disk fails)
The WD MyCloud has a copy at `/Volumes/WD-MyCloud/OpenClaw/sync/workspace/`.
```bash
# Copy workspace from WD MyCloud
cp -r /Volumes/WD-MyCloud/OpenClaw/sync/workspace ~/.openclaw/workspace
```

## Backup Disk Setup

The backup disk is a 15TB external drive: "Backups of spacemonkey"
- Format: Case-sensitive APFS
- Location: Physically connected to the Mac mini
- **Important**: Keep it connected for automatic backups to work

## WD MyCloud Setup

The WD MyCloud is accessible at `//MyCloud-1E4N74.local` via SMB.
- Currently mounted as read-only for the `openclaw-agent` account
- Admin access needed to enable write access
- See BACKUP_GUIDE.md for setup instructions

## Verification

After any restore, verify:
```bash
openclaw gateway status          # Should show "running"
openclaw agents list             # Should list agents
ls ~/.openclaw/workspace/memory/wiki/  # Should show wiki pages
cat ~/.openclaw/workspace/MEMORY.md     # Should have content
```

---
*Last Updated: 2026-05-12 by Space Monkey*
