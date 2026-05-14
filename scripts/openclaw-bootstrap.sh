#!/bin/bash
# OpenClaw One-Command Bootstrap
# Run this on a fresh Mac to spin up OpenClaw with all current memory and setup
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/openclaw-bootstrap/main/bootstrap.sh | bash
#   OR
#   ./bootstrap.sh /path/to/backup-file.tar.gz
#
# Prerequisites (install first):
#   1. Node.js (v18+): brew install node
#   2. OpenClaw: npm install -g openclaw
#   3. Connect backup disk OR download backup from cloud

set -euo pipefail

echo "============================================"
echo "  OpenClaw Bootstrap — Full Recovery"
echo "============================================"
echo ""

# === Step 1: Check prerequisites ===
echo "[1/6] Checking prerequisites..."

if ! command -v node &>/dev/null; then
    echo "ERROR: Node.js not found. Install with: brew install node"
    exit 1
fi
echo "  Node.js: $(node --version)"

if ! command -v openclaw &>/dev/null; then
    echo "ERROR: OpenClaw not found. Install with: npm install -g openclaw"
    exit 1
fi
echo "  OpenClaw: $(openclaw --version 2>/dev/null || echo 'installed')"

# === Step 2: Find or download backup ===
echo ""
echo "[2/6] Locating backup..."

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
    # Try backup disk
    BACKUP_DISK="/Volumes/Backups of spacemonkey"
    if [ -d "$BACKUP_DISK" ]; then
        echo "  Found backup disk."
        BACKUP_FILE=$(ls -t "$BACKUP_DISK/OpenClaw/backups/daily"/openclaw-full_*.tar.gz 2>/dev/null | head -1)
        if [ -z "$BACKUP_FILE" ]; then
            BACKUP_FILE=$(ls -t "$BACKUP_DISK/OpenClaw/backups/weekly"/openclaw-weekly_*.tar.gz 2>/dev/null | head -1)
        fi
        if [ -z "$BACKUP_FILE" ]; then
            BACKUP_FILE=$(ls -t "$BACKUP_DISK/OpenClaw/backups/quick"/openclaw-config_*.tar.gz 2>/dev/null | head -1)
        fi
    fi
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "  No local backup found."
    echo "  Enter URL to download backup (or press Enter to skip):"
    read -r BACKUP_URL
    if [ -n "$BACKUP_URL" ]; then
        BACKUP_FILE="/tmp/openclaw-backup.tar.gz"
        echo "  Downloading from: $BACKUP_URL"
        curl -fsSL "$BACKUP_URL" -o "$BACKUP_FILE"
    else
        echo "  No backup available. Will do fresh install."
    fi
fi

if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    echo "  Backup file: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
else
    echo "  No backup — fresh install."
fi

# === Step 3: Stop OpenClaw if running ===
echo ""
echo "[3/6] Stopping OpenClaw (if running)..."
openclaw gateway stop 2>/dev/null || true
sleep 2

# === Step 4: Restore from backup ===
echo ""
echo "[4/6] Restoring from backup..."

if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    # Safety backup of any existing install
    if [ -d "$HOME/.openclaw" ]; then
        mv "$HOME/.openclaw" "$HOME/.openclaw.pre-bootstrap.$(date +%Y%m%d_%H%M%S)"
    fi
    tar -xzf "$BACKUP_FILE" -C "$HOME"
    echo "  Restored from backup."
else
    # Fresh install
    echo "  Running OpenClaw onboard..."
    openclaw onboard --mode local --workspace "$HOME/.openclaw/workspace"
    echo "  Fresh install complete."
fi

# === Step 5: Verify ===
echo ""
echo "[5/6] Verifying installation..."
echo "  openclaw.json: $([ -f "$HOME/.openclaw/openclaw.json" ] && echo 'OK ✓' || echo 'MISSING ✗')"
echo "  workspace: $([ -d "$HOME/.openclaw/workspace" ] && echo 'OK ✓' || echo 'MISSING ✗')"
echo "  agents: $([ -d "$HOME/.openclaw/agents" ] && echo 'OK ✓' || echo 'MISSING ✗')"
echo "  memory: $([ -d "$HOME/.openclaw/memory" ] ] && echo 'OK ✓' || echo 'MISSING ✗')"
echo "  wiki: $([ -d "$HOME/.openclaw/workspace/memory/wiki" ] && echo 'OK ✓' || echo 'MISSING ✗')"

# Check workspace files
if [ -d "$HOME/.openclaw/workspace" ]; then
    echo "  AGENTS.md: $([ -f "$HOME/.openclaw/workspace/AGENTS.md" ] && echo 'OK ✓' || echo 'MISSING ✗')"
    echo "  SOUL.md: $([ -f "$HOME/.openclaw/workspace/SOUL.md" ] && echo 'OK ✓' || echo 'MISSING ✗')"
    echo "  IDENTITY.md: $([ -f "$HOME/.openclaw/workspace/IDENTITY.md" ] && echo 'OK ✓' || echo 'MISSING ✗')"
    echo "  MEMORY.md: $([ -f "$HOME/.openclaw/workspace/MEMORY.md" ] && echo 'OK ✓' || echo 'MISSING ✗')"
fi

# === Step 6: Start ===
echo ""
echo "[6/6] Starting OpenClaw..."
openclaw gateway start
sleep 3

echo ""
echo "============================================"
echo "  Bootstrap Complete!"
echo "============================================"
echo ""
echo "OpenClaw should be running at: http://localhost:18789"
echo ""
echo "Next steps:"
echo "  1. Verify: openclaw gateway status"
echo "  2. Check workspace: ls ~/.openclaw/workspace/"
echo "  3. Check wiki: ls ~/.openclaw/workspace/memory/wiki/"
echo "  4. Set up backup cron: see BACKUP_GUIDE.md"
echo ""
