#!/bin/bash
# git-push.sh — Daily GitHub push for mc-prod and mc-dev
# Runs at 04:00 UTC via OpenClaw cron. Shell-only, no model calls.

set -e

WORKSPACE="/Users/spacemonkey/.openclaw/workspace"
LOG="$WORKSPACE/logs/git-push.log"
DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_rmk -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

log() {
  echo "[$DATE] $1" >> "$LOG"
}

push_repo() {
  local repo_path="$1"
  local repo_name="$2"

  cd "$repo_path"

  # Fetch latest to avoid non-fast-forward rejections
  git fetch origin main --quiet 2>/dev/null || {
    log "$repo_name: fetch failed, skipping"
    return 1
  }

  # Stage all changes
  git add -A

  # Only commit if there's something to commit
  if git diff --cached --quiet; then
    log "$repo_name: nothing to commit (up to date)"
    return 0
  fi

  # Commit and push
  git commit -m "chore: daily auto-push [$DATE]" --quiet
  git push origin main --quiet 2>&1

  log "$repo_name: pushed successfully"
}

log "=== Daily push started ==="

push_repo "$WORKSPACE/mission-control-dashboard" "mc-prod"
push_repo "$WORKSPACE/mission-control-dashboard-dev" "mc-dev"

log "=== Daily push complete ==="
