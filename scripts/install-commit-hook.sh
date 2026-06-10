#!/usr/bin/env bash
# install-commit-hook.sh — Installs Station Memory post-commit hook in both repos

set -e

WORKSPACE_ROOT="/Users/spacemonkey/.openclaw/workspace"
MC_DASHBOARD_DIR="$WORKSPACE_ROOT/mission-control-dashboard"
HOOK_SCRIPT="$WORKSPACE_ROOT/scripts/station-memory-commit-hook.sh"

# Check if hook script exists
if [ ! -f "$HOOK_SCRIPT" ]; then
    echo "❌ Hook script not found: $HOOK_SCRIPT"
    exit 1
fi

echo "🔧 Installing Station Memory post-commit hooks..."

# Function to install hook in a repo
install_hook() {
    local repo_dir="$1"
    local repo_name="$(basename "$repo_dir")"
    
    echo "→ Installing in: $repo_name"
    
    local hooks_dir="$repo_dir/.git/hooks"
    local hook_file="$hooks_dir/post-commit"
    
    # Check if this is a git repo
    if [ ! -d "$hooks_dir" ]; then
        echo "   ❌ Not a git repo, skipping"
        return
    fi
    
    # Backup existing hook
    if [ -f "$hook_file" ]; then
        mv "$hook_file" "$hook_file.backup"
        echo "   📋 Backed up existing hook to: $hook_file.backup"
    fi
    
    # Copy our hook and make executable
    cat > "$hook_file" <<'HOOK'
#!/bin/bash
# Station Memory post-commit hook
# Automatically ingests commit metadata into Station Memory database

# Get the commit hash from Git (passed as $1 by Git)
COMMIT_HASH="$1"

# Skip if no commit hash (shouldn't happen in post-commit)
if [ -z "$COMMIT_HASH" ]; then
    echo "⚠️  No commit hash, skipping Station Memory ingestion"
    exit 0
fi

# Change to repo directory and run the hook script
cd "$(git rev-parse --show-toplevel)"
exec "/Users/spacemonkey/.openclaw/workspace/scripts/station-memory-commit-hook.sh" "$COMMIT_HASH"
HOOK
    
    chmod +x "$hook_file"
    echo "   ✅ Installed post-commit hook"
}

# Install in both repos
install_hook "$WORKSPACE_ROOT"
install_hook "$MC_DASHBOARD_DIR"

echo ""
echo "✅ Station Memory post-commit hooks installed!"
echo ""
echo "🔍 Next step: Make a test commit in either repo and verify with:"
echo "   node scripts/station-memory-tool.cjs search \"[commit message]\""
echo ""
echo "💡 To uninstall, restore backups and remove the hook files"