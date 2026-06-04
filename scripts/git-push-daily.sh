#!/bin/bash
# ── Daily GitHub Push ────────────────────────────────────────────────────────
# Pushes mc-prod and mc-dev repos once per day if there are actual changes.
# Shell-only — zero AI tokens burned.
#
# Usage: Called by cron at 04:00 UTC daily.
#
# Strategy:
#   - For each repo: cd, git add -A, check if there's anything to commit
#     (git diff --cached --quiet), commit with timestamp message, push.
#   - If no working tree changes → skip (nothing to push).
#   - Logs stdout+stderr to logs/git-push-daily.log.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
LOG="$WORKSPACE/logs/git-push-daily.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')

mkdir -p "$(dirname "$LOG")"

echo "[$DATE] Daily push started" >> "$LOG"

REPOS=(
  "$WORKSPACE/mission-control-dashboard|origin|main|mc-prod"
  "$WORKSPACE/mission-control-dashboard-dev|origin|main|mc-dev"
)

for entry in "${REPOS[@]}"; do
  IFS='|' read -r REPO_DIR REMOTE BRANCH LABEL <<< "$entry"

  if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "[$DATE] [$LABEL] SKIP — not a git repo: $REPO_DIR" >> "$LOG"
    continue
  fi

  cd "$REPO_DIR"

  # Stage everything (tracked + untracked)
  git add -A

  # Check if there's actually anything staged
  if git diff --cached --quiet; then
    echo "[$DATE] [$LABEL] SKIP — no changes" >> "$LOG"
    continue
  fi

  CNT=$(git diff --cached --numstat | wc -l | tr -d ' ')
  MSG="chore: daily auto-push $(date '+%Y-%m-%d') — ${CNT} file(s) changed"

  git commit -m "$MSG" --quiet
  git push "$REMOTE" "$BRANCH" --quiet 2>&1 | tee -a "$LOG"

  echo "[$DATE] [$LABEL] PUSHED — $MSG" >> "$LOG"
done

echo "[$DATE] Daily push complete" >> "$LOG"
