#!/bin/bash
# Morning Report — daily email report
# Fires at 07:00 BST via macOS crontab
# Sends plain-text email. Logs to ~/.openclaw/logs/morning-report.log on failure.

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
MC_DIR="$WORKSPACE/mission-control-dashboard"
DATA_DIR="$WORKSPACE/data"
LOG_DIR="$WORKSPACE/logs"
REPORT_LOG="$LOG_DIR/morning-report.log"
CB_DIR="$WORKSPACE/scripts/circuit-breaker"

mkdir -p "$LOG_DIR"

DATE=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M %Z')
SUBJECT="OpenClaw Morning Report — $DATE"
TO="${MORNING_REPORT_TO:-andre@example.com}"  # override via env var

log() { echo "$(date '+%H:%M:%S') $*" >> "$REPORT_LOG"; }
log "=== Morning Report START ==="

# ── Helper: age in hours from ISO timestamp ───────────────────────────────
hours_since() {
  local ts="$1"
  local epoch
  epoch=$(date -j -f '%Y-%m-%dT%H:%M:%S' "${ts%%.*}" '+%s' 2>/dev/null || echo 0)
  echo $(( ($(date +%s) - epoch) / 3600 ))
}

# ── 1. System Status ───────────────────────────────────────────────────────

# Gateway
if pgrep -f "openclaw" >/dev/null 2>&1; then
  GW_STATUS="Running"
  GW_UPTIME=$(ps -o etime= -p "$(pgrep -f 'openclaw' | head -1)" 2>/dev/null | tr -d ' ' || echo "unknown")
else
  GW_STATUS="DOWN"
  GW_UPTIME="N/A"
fi

# MC Dashboard
MC_HTTP=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 2>/dev/null || echo "000")
case "$MC_HTTP" in
  200) MC_STATUS="OK (HTTP 200)" ;;
  301|302) MC_STATUS="Redirect (HTTP $MC_HTTP)" ;;
  000) MC_STATUS="Unreachable" ;;
  *) MC_STATUS="HTTP $MC_HTTP" ;;
esac

# Docker host
if ping -c 1 -t 5 192.168.68.50 >/dev/null 2>&1; then
  DOCKER_HOST="Reachable"
else
  DOCKER_HOST="Unreachable"
fi

# Circuit breaker
CB_STATUS="All closed"
if [ -d "$WORKSPACE/scripts" ] && [ -f "$WORKSPACE/scripts/circuit-breaker.sh" ]; then
  CB_CHECK=$(bash "$WORKSPACE/scripts/circuit-breaker.sh" status 2>/dev/null || echo "")
  if echo "$CB_CHECK" | grep -qi "tripped\|TRIPPED"; then
    CB_STATUS="TRIPPED: $(echo "$CB_CHECK" | grep -i trip | head -1)"
  fi
fi

# ── 2. Activity (last 24h) ─────────────────────────────────────────────────

SINCE=$(date -v-24H '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -d '24 hours ago' '+%Y-%m-%dT%H:%M:%S')

# Tasks completed in last 24h
TASKS_COMPLETED=0
if [ -f "$DATA_DIR/tasks.json" ]; then
  TASKS_COMPLETED=$(python3 -c "
import json, sys
try:
    tasks = json.load(open('$DATA_DIR/tasks.json'))
    if not isinstance(tasks, list): tasks = [tasks]
    since = '$SINCE'
    count = 0
    for t in tasks:
        if t.get('status') != 'done': continue
        # Check history for completed action within 24h
        for h in reversed(t.get('history', [])):
            if h.get('action') in ('completed', 'done'):
                ts = h.get('ts', '')
                if ts >= since:
                    count += 1
                break
        else:
            # Fallback: check completedAt or lastActivity
            ca = t.get('completedAt', '') or t.get('lastActivity', '')
            if ca >= since:
                count += 1
    print(count)
except Exception as e:
    print(0)
" 2>/dev/null || echo 0)
fi

# Incidents created in last 24h
INCD_CREATED=0
INCD_RESOLVED=0
if [ -f "$DATA_DIR/incidents.json" ]; then
  INCD_CREATED=$(python3 -c "
import json
try:
    incs = json.load(open('$DATA_DIR/incidents.json'))
    if not isinstance(incs, list): incs = [incs]
    since = '$SINCE'
    print(sum(1 for i in incs if (i.get('ts') or i.get('createdAt') or '') >= since))
except: print(0)
" 2>/dev/null || echo 0)
  INCD_RESOLVED=$(python3 -c "
import json
try:
    incs = json.load(open('$DATA_DIR/incidents.json'))
    if not isinstance(incs, list): incs = [incs]
    since = '$SINCE'
    count = 0
    for i in incs:
        if i.get('status') != 'RESOLVED': continue
        for h in reversed(i.get('history', [])):
            if h.get('action') in ('resolved', 'RESOLVED'):
                if (h.get('ts') or '') >= since:
                    count += 1
                break
    print(count)
except: print(0)
" 2>/dev/null || echo 0)
fi

# Deploys in last 24h (git log in MC repo)
DEPLOYS=0
DEPLOY_STATUS="none"
if [ -d "$MC_DIR/.git" ]; then
  DEPLOYS=$(git -C "$MC_DIR" log --since="24 hours ago" --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DEPLOYS" -gt 0 ]; then
    # Check for build/deploy keywords
    DEPLOY_STATUS="$DEPLOYS commits"
    if git -C "$MC_DIR" log --since="24 hours ago" --oneline 2>/dev/null | grep -qi "deploy\|build\|release"; then
      DEPLAGS=$(git -C "$MC_DIR" log --since="24 hours ago" --oneline 2>/dev/null | grep -ic "deploy\|build\|release")
      DEPLOY_STATUS="$DEPLOY_STATUS ($DEPLAGS deploy-related)"
    fi
  fi
fi

# Skills invoked (from session logs — count skill workshop uses)
SKILLS_INVOKED="N/A"
if [ -f "$LOG_DIR/morning-report.log" ]; then
  # Count skill_workshop invocations in last 24h from gateway log
  SKILL_COUNT=$(grep -c "skill_workshop" "$LOG_DIR/morning-report.log" 2>/dev/null || echo 0)
  SKILLS_INVOKED="$Skill_count logged"
fi

# OpenRouter usage (check FreeRide quota if available)
OR_USAGE="N/A"
if [ -f "$DATA_DIR/quota-budget.json" ]; then
  OR_USAGE=$(python3 -c "
import json
try:
    d = json.load(open('$DATA_DIR/quota-budget.json'))
    print(f\"\${d.get('spent', 0):.2f} of \${d.get('budget', 10):.0f} (\${d.get('pct', 0):.0f}%%)\")
except: print('N/A')
" 2>/dev/null || echo "N/A")
else
  OR_USAGE="No quota file (est. <$10 buffer)"
fi

# ── 3. Attention ────────────────────────────────────────────────────────────

ATTENTION_ITEMS=""

# Active incidents requiring action (non-TRIAGE, non-RESOLVED)
if [ -f "$DATA_DIR/incidents.json" ]; then
  ATT_INCD=$(python3 -c "
import json
try:
    incs = json.load(open('$DATA_DIR/incidents.json'))
    if not isinstance(incs, list): incs = [incs]
    lines = []
    for i in incs:
        status = i.get('status', '')
        if status in ('RESOLVED', 'CLOSED'): continue
        title = i.get('title', i.get('id', 'Unknown'))
        sev = i.get('severity', '')
        iid = i.get('id', '')
        lines.append(f'  • [{iid}] {title} (severity: {sev}, status: {status})')
    print('\n'.join(lines[:10]))
except: print('')
" 2>/dev/null || echo "")
  if [ -n "$ATT_INCD" ]; then
    ATTENTION_ITEMS="${ATTENTION_ITEMS}\n▸ Incidents requiring action:\n${ATT_INCD}"
  fi
fi

# Failed deploys (check deploy log)
DEPLOY_FAIL=0
if [ -f "$LOG_DIR/deploy.log" ]; then
  DEPLOY_FAIL=$(grep -c -i "fail\|error" "$LOG_DIR/deploy.log" 2>/dev/null || echo 0)
  if [ "$DEPLOY_FAIL" -gt 0 ]; then
    ATTENTION_ITEMS="${ATTENTION_ITEMS}\n▸ Failed deploys detected in logs: $DEPLOY_FAIL errors"
  fi
fi

# Gateway DOWN
if [ "$GW_STATUS" = "DOWN" ]; then
  ATTENTION_ITEMS="${ATTENTION_ITEMS}\n▸ ⚠️ GATEWAY IS DOWN"
fi

# Circuit breaker tripped
if echo "$CB_STATUS" | grep -qi "TRIPPED"; then
  ATTENTION_ITEMS="${ATTENTION_ITEMS}\n▸ ⚠️ Circuit breaker(s) tripped: $CB_STATUS"
fi

# ── 4. Quick Status ─────────────────────────────────────────────────────────

ACTIVE_INCD=0
TOTAL_OPEN_INCD=0
if [ -f "$DATA_DIR/incidents.json" ]; then
  TOTAL_OPEN_INCD=$(python3 -c "
import json
try:
    incs = json.load(open('$DATA_DIR/incidents.json'))
    if not isinstance(incs, list): incs = [incs]
    print(sum(1 for i in incs if i.get('status') not in ('RESOLVED', 'CLOSED')))
except: print(0)
" 2>/dev/null || echo 0)
fi

BACKLOG_TASKS=0
if [ -f "$DATA_DIR/tasks.json" ]; then
  BACKLOG_TASKS=$(grep -c '"status"[[:space:]]*:[[:space:]]*"backlog"' "$DATA_DIR/tasks.json" 2>/dev/null || echo 0)
fi

SKILLS_ACTIVE=$(ls ~/.openclaw/workspace/skills/ 2>/dev/null | wc -l | tr -d ' ')
NIGHT_SHIFT="Disabled"

# ── Build email body ───────────────────────────────────────────────────────

BODY="OpenClaw Morning Report — $DATE
Generated: $NOW
========================================

SYSTEM STATUS
  Gateway:         $GW_STATUS (uptime: $GW_UPTIME)
  MC Dashboard:    $MC_STATUS
  Docker Host:     $DOCKER_HOST
  Circuit Breaker: $CB_STATUS

ACTIVITY (last 24h)
  Deploys:          $DEPLOY_STATUS
  Tasks Completed:  $TASKS_COMPLETED
  Incidents Created: $INCD_CREATED / Resolved: $INCD_RESOLVED
  OpenRouter Usage: $OR_USAGE
"

if [ -n "$ATTENTION_ITEMS" ]; then
  BODY="$BODY
ATTENTION REQUIRED
$(echo -e "$ATTENTION_ITEMS")
"
else
  BODY="$BODY
ATTENTION REQUIRED
  Nothing requiring action.
"
fi

BODY="$BODY
QUICK STATUS
  Active Incidents: $TOTAL_OPEN_INCD
  Backlog Tasks:    $BACKLOG_TASKS
  Night Shift:      $NIGHT_SHIFT
  Skills Active:    $SKILLS_ACTIVE
  Next Deadline:    Skill Lifecycle Mgmt metrics — 22 Jun 2026

========================================
This is an automated report. Do not reply.
"

# ── Send email ──────────────────────────────────────────────────────────────

{
  echo "To: $TO"
  echo "Subject: $SUBJECT"
  echo "Content-Type: text/plain; charset=UTF-8"
  echo ""
  echo "$BODY"
} | /usr/sbin/sendmail -t -oi 2>>"$REPORT_LOG"

if [ $? -eq 0 ]; then
  log "Email sent to $TO"
  echo "✅ Morning report sent to $TO"
else
  log "ERROR: sendmail failed"
  echo "$BODY" >> "$REPORT_LOG"
  echo "❌ Email failed — logged to $REPORT_LOG"
fi

# Trim log to last 1000 lines
tail -1000 "$REPORT_LOG" > "${REPORT_LOG}.tmp" && mv "${REPORT_LOG}.tmp" "$REPORT_LOG"

log "=== Morning Report DONE ==="
