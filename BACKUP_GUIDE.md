# BACKUP_GUIDE.md — OpenClaw Backup System

_How the backup system works, how to maintain it, and how to set up off-site replication._

## Architecture

```
Mac Mini (source)
├── ~/.openclaw/                    ← What we're backing up
│   ├── openclaw.json               ← Config (models, channels, plugins)
│   ├── agents/                     ← Agent auth & models
│   ├── workspace/                  ← Memory, wiki, identity, daily logs
│   │   ├── AGENTS.md, SOUL.md, IDENTITY.md, USER.md
│   │   ├── MEMORY.md               ← Long-term memory
│   │   ├── memory/                 ← Daily logs + wiki
│   │   │   ├── YYYY-MM-DD.md
│   │   │   └── wiki/               ← Karpathy LLM Wiki
│   │   └── scripts/                ← Backup scripts
│   ├── memory/                     ← SQLite memory index
│   ├── identity/                   ← Agent identity
│   └── plugins/                    ← Plugin configs
│
├── Backup Disk (15TB external)     ← PRIMARY BACKUP
│   └── OpenClaw/
│       ├── backups/
│       │   ├── daily/              ← 7 days of full backups
│       │   ├── weekly/             ← 4 weeks of snapshots
│       │   ├── monthly/            ← 12 months of archives
│       │   └── quick/              ← 5 latest config-only backups
│       ├── sync/workspace/         ← Real-time workspace mirror
│       ├── logs/                   ← Backup state & history
│       └── archives/               ← Long-term archives + bootstrap script
│
└── WD MyCloud (network)            ← SECONDARY/OFF-SITE
    └── OpenClaw/
        └── sync/workspace/         ← Workspace mirror (off-site)
```

## Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `openclaw-backup.sh` | Full backup (daily/weekly/monthly) | `~/.openclaw/workspace/scripts/` |
| `openclaw-backup-quick.sh` | Quick config-only backup | `~/.openclaw/workspace/scripts/` |
| `openclaw-restore.sh` | Restore from backup | `~/.openclaw/workspace/scripts/` |
| `openclaw-bootstrap.sh` | One-command fresh install | `~/.openclaw/workspace/scripts/` |

## Setting Up Automatic Backups

### 1. OpenClaw Cron Job (runs under openclaw-agent)

Add a cron job via OpenClaw:
```
Daily full backup at 3:00 AM
```

### 2. macOS LaunchDaemon (runs under admin, for full disk access)

For backups that need to read the full `~/.openclaw` directory, create a LaunchDaemon:

```xml
<!-- /Library/LaunchDaemons/com.openclaw.backup.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/spacemonkey/.openclaw/workspace/scripts/openclaw-backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/spacemonkey/.openclaw/workspace/logs/backup-stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/spacemonkey/.openclaw/workspace/logs/backup-stderr.log</string>
</dict>
</plist>
```

Load it:
```bash
sudo launchctl load /Library/LaunchDaemons/com.openclaw.backup.plist
```

## Setting Up WD MyCloud Write Access

The WD MyCloud is currently mounted read-only for the `openclaw-agent` account.
To enable write access for off-site backup replication:

### Option A: Mount with write credentials
```bash
# Mount the WD MyCloud share with admin credentials
mount -t smbfs //admin@MyCloud-1E4N74.local/Shares/OpenClaw /Volumes/WD-MyCloud-OpenClaw
```

### Option B: Use the WD MyCloud web interface
1. Log in to the WD MyCloud dashboard (http://MyCloud-1E4N74.local)
2. Create a shared folder for OpenClaw backups
3. Set permissions for the `spacemonkey` user to read/write
4. Mount the share with credentials

### Option C: Sync via rsync over SSH (if SSH is enabled on WD MyCloud)
```bash
rsync -avz --delete ~/.openclaw/workspace/ admin@MyCloud-1E4N74.local:/shares/OpenClaw/sync/workspace/
```

## Maintenance

### Monthly checks:
1. Verify backup disk has space: `df -h "/Volumes/Backups of spacemonkey"`
2. Check latest backup exists: `ls -lt "/Volumes/Backups of spacemonkey/OpenClaw/backups/daily/" | head -5`
3. Test restore: `bash ~/.openclaw/workspace/scripts/openclaw-restore.sh` (on a test machine)
4. Check backup logs: `tail -20 ~/.openclaw/workspace/logs/backup-stderr.log`

### After major changes:
Run a quick backup immediately:
```bash
bash ~/.openclaw/workspace/scripts/openclaw-backup-quick.sh
```

## Security Notes

- Backups contain sensitive data: API keys, tokens, Telegram bot keys, auth tokens
- The backup disk should be encrypted (FileVault or APFS encrypted)
- The WD MyCloud should use a strong password and be on a private network
- Never commit backups to a public git repo
- The `openclaw.json` contains secrets — treat backups as sensitive

---
*Last Updated: 2026-05-12 by Space Monkey*
