#!/bin/bash
# incident-lifecycle.sh — Unified incident lifecycle management
# Runs: auto-resolve + dedup in a single pass
# Called by cron (replaces Daily Incident Auto-Resolve cron + runs alongside incident-dedup)
# Pure shell + Python — zero model calls

WORKSPACE="$HOME/.openclaw/workspace"
LOG_FILE="$WORKSPACE/logs/incident-lifecycle.log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }

echo "[$(timestamp)] [LIFECYCLE] Starting incident lifecycle run..." >> "$LOG_FILE"

# ── Step 1: Auto-resolve incidents ──────────────────────────────────────────
echo "[$(timestamp)] [LIFECYCLE] Step 1: Auto-resolve..." >> "$LOG_FILE"
python3 /Users/spacemonkey/.openclaw/workspace/scripts/auto-resolve-incidents.py 5 >> "$LOG_FILE" 2>&1
echo "[$(timestamp)] [LIFECYCLE] Step 1 complete" >> "$LOG_FILE"

# ── Step 2: Deduplicate remaining open incidents ────────────────────────────
echo "[$(timestamp)] [LIFECYCLE] Step 2: Dedup..." >> "$LOG_FILE"
bash /Users/spacemonkey/.openclaw/workspace/scripts/incident-dedup.sh >> "$LOG_FILE" 2>&1
echo "[$(timestamp)] [LIFECYCLE] Step 2 complete" >> "$LOG_FILE"

echo "[$(timestamp)] [LIFECYCLE] Complete" >> "$LOG_FILE"
