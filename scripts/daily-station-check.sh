#!/bin/bash
# Daily Station Check — completely shell-only, zero model calls
# System crontab: 0 23 * * * (Europe/London)
# Sends daily sitrep via `openclaw message send` CLI

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
MC_DIR="$WORKSPACE/mission-control-dashboard"
DATA_DIR="$WORKSPACE/data"
LOG_DIR="$WORKSPACE/logs"
HEALTH_LOG="$WORKSPACE/memory/health-log.md"
DAILY_LOG="$WORKSPACE/memory"
TELEGRAM_TARGET="7507878944"

mkdir -p "$LOG_DIR" "$DAILY_LOG"

TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M')
LOG_FILE="$LOG_DIR/daily-station-check.log"

log() { echo "$(date '+%H:%M:%S') $*" >> "$LOG_FILE"; }

log "=== Daily Station Check START ==="

# ── 1. System Health ────────────────────────────────────────────────────────

LOAD=$(sysctl -n vm.loadavg 2>/dev/null || echo "N/A")
DISK_LINE=$(df -h / 2>/dev/null | tail -1)
DISK_PCT=$(echo "$DISK_LINE" | awk '{print $5}' | tr -d '%')
DISK_USED=$(echo "$DISK_LINE" | awk '{print $3}')
DISK_FREE=$(echo "$DISK_LINE" | awk '{print $4}')
DISK_TOTAL=$(echo "$DISK_LINE" | awk '{print $2}')
MEM=$(vm_stat 2>/dev/null | head -5 || echo "N/A")
UPTIME=$(uptime 2>/dev/null | sed 's/.*up/up/' || echo "N/A")

log "Load: $LOAD"
log "Disk: $DISK_USED used, $DISK_FREE free, ${DISK_PCT}% of $DISK_TOTAL"
log "Uptime: $UPTIME"

# Append to health-log.md
{
  echo ""
  echo "## $NOW (Europe/London) — Daily Station Check"
  echo "- **Load Average**: $(echo "$LOAD" | awk '{print $2, $3, $4}')"
  echo "- **Disk**: $DISK_TOTAL total, $DISK_USED used, $DISK_FREE free, **${DISK_PCT}%** used"
  echo "- **Memory**: $(echo "$MEM" | head -1)"
  echo "- **Uptime**: $UPTIME"
} >> "$HEALTH_LOG"

# ── 2. Git Auto-Commit ─────────────────────────────────────────────────────

GIT_STATUS="unchanged"
if [ -d "$MC_DIR/.git" ]; then
  cd "$MC_DIR"
  CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGES" -gt 0 ]; then
    git add -A 2>/dev/null
    git commit -m "auto: daily commit" 2>/dev/null && {
      GIT_STATUS="committed $CHANGES file(s)"
      git push 2>/dev/null && GIT_STATUS="$GIT_STATUS + pushed" || GIT_STATUS="$GIT_STATUS (push failed)"
    } || {
      GIT_STATUS="commit failed"
    }
    log "Git: $GIT_STATUS"
  else
    GIT_STATUS="no changes"
    log "Git: no changes"
  fi
else
  GIT_STATUS="no git repo"
  log "Git: no .git in $MC_DIR"
fi

echo "- **Git**: $GIT_STATUS" >> "$HEALTH_LOG"

# ── 3. Task Cleanup ────────────────────────────────────────────────────────

ARCHIVED=0
TASKS_ACTIVE=0
TASKS_AWAITING=0

if [ -f "$DATA_DIR/tasks.json" ]; then
  TASKS_FILE="$DATA_DIR/tasks.json"

  # Count active and awaiting tasks (use grep -c; suppress failure with || true)
  TASKS_ACTIVE=$(grep -c '"status"[[:space:]]*:[[:space:]]*"active"' "$TASKS_FILE" 2>/dev/null || true); TASKS_ACTIVE=${TASKS_ACTIVE:-0}
  TASKS_AWAITING=$(grep -c '"status"[[:space:]]*:[[:space:]]*"awaiting_review"' "$TASKS_FILE" 2>/dev/null || true); TASKS_AWAITING=${TASKS_AWAITING:-0}
  TASKS_COMPLETED=$(grep -c '"status"[[:space:]]*:[[:space:]]*"done"' "$TASKS_FILE" 2>/dev/null || true); TASKS_COMPLETED=${TASKS_COMPLETED:-0}

  # Archive: move done tasks older than 30 days to archive
  CUTOFF=$(date -v-30d '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -d '30 days ago' '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || echo "")
  ARCHIVE_FILE="$DATA_DIR/tasks-archive.json"

  if [ -n "$CUTOFF" ] && [ "$TASKS_COMPLETED" -gt 0 ] && command -v python3 >/dev/null 2>&1; then
    ARCHIVED=$(python3 -c "
import json, sys, os, tempfile, shutil
def safe_write(path, data):
    try:
        if os.path.exists(path): shutil.copy2(path, path + '.bak')
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', suffix='.tmp')
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(data, f, indent=2)
                f.flush(); os.fsync(f.fileno())
            os.rename(tmp, path)
        except:
            if os.path.exists(tmp): os.remove(tmp)
            raise
    except: pass
try:
    tasks = json.load(open('$TASKS_FILE'))
    if not isinstance(tasks, list): tasks = [tasks]
    cutoff = '$CUTOFF'
    to_archive = [t for t in tasks if t.get('status') == 'done' and t.get('updatedAt','') < cutoff]
    remaining = [t for t in tasks if t not in to_archive]
    if to_archive:
        try:
            old = json.load(open('$ARCHIVE_FILE'))
            if not isinstance(old, list): old = [old]
        except: old = []
        old.extend(to_archive)
        safe_write('$ARCHIVE_FILE', old)
        safe_write('$TASKS_FILE', remaining)
    print(len(to_archive))
except Exception as e:
    print(0, file=sys.stderr)
    print(0)
" 2>/dev/null || echo 0)
    ARCHIVED="${ARCHIVED:-0}"
  fi
  log "Tasks: $TASKS_ACTIVE active, $TASKS_AWAITING awaiting review, $ARCHIVED archived"
else
  log "Tasks: no tasks.json found"
fi

echo "- **Tasks**: $TASKS_ACTIVE active, $TASKS_AWAITING awaiting review, $ARCHIVED archived" >> "$HEALTH_LOG"

# ── 4. Backup Check ─────────────────────────────────────────────────────────

BACKUP_STATUS="no volumes mounted"
BACKUP_AGE=""

for VOL in /Volumes/OpenClaw-WD /Volumes/Public /Volumes/WD-MyCloud; do
  if [ -d "$VOL" ]; then
    LATEST_BACKUP=$(find "$VOL" -name 'openclaw-backup-*.tar.gz' -maxdepth 3 2>/dev/null | sort | tail -1)
    if [ -n "$LATEST_BACKUP" ]; then
      BACKUP_DATE=$(stat -f '%Sm' -t '%Y-%m-%d' "$LATEST_BACKUP" 2>/dev/null || stat -c '%y' "$LATEST_BACKUP" 2>/dev/null | cut -d' ' -f1)
      AGE_DAYS=$(( ($(date +%s) - $(date -j -f '%Y-%m-%d' "$BACKUP_DATE" +%s 2>/dev/null || date -d "$BACKUP_DATE" +%s 2>/dev/null || echo 0)) / 86400 ))
      BACKUP_STATUS="mounted: $VOL | latest: $(basename "$LATEST_BACKUP") (${AGE_DAYS}d old)"
      if [ "$AGE_DAYS" -gt 7 ]; then
        BACKUP_STATUS="$BACKUP_STATUS ⚠️ STALE"
      fi
    else
      BACKUP_STATUS="mounted: $VOL | no backup files found ⚠️"
    fi
    break
  fi
done

log "Backup: $BACKUP_STATUS"
echo "- **Backup**: $BACKUP_STATUS" >> "$HEALTH_LOG"

# ── 5. Daily Summary ────────────────────────────────────────────────────────

OVERALL="✅ ALL SYSTEMS NOMINAL"
if [ "$DISK_PCT" -gt 90 ]; then
  OVERALL="⚠️ DISK CRITICAL: ${DISK_PCT}%"
elif echo "$BACKUP_STATUS" | grep -q "STALE"; then
  OVERALL="⚠️ BACKUP STALE"
elif echo "$BACKUP_STATUS" | grep -q "no volumes"; then
  OVERALL="⚠️ NO BACKUP VOLUME MOUNTED"
fi

echo "- **Overall**: $OVERALL" >> "$HEALTH_LOG"

# Append to daily memory log
{
  ""
  echo "## Daily Station Check — $NOW"
  echo "- System: $(echo "$LOAD" | awk '{print $2}') load, ${DISK_PCT}% disk, uptime: $UPTIME"
  echo "- Git: $GIT_STATUS"
  echo "- Tasks: $TASKS_ACTIVE active, $TASKS_AWAITING awaiting review, $ARCHIVED archived"
  echo "- Backup: $BACKUP_STATUS"
  echo "- Status: $OVERALL"
} >> "$DAILY_LOG/$TODAY.md" 2>/dev/null || true

log "Overall: $OVERALL"

# ── 6. Telegram Sitrep ──────────────────────────────────────────────────────

SITREP="📡 DAILY SITREP — ${TODAY} | ${TASKS_ACTIVE} active · ${TASKS_AWAITING} awaiting review · ${DISK_PCT}% disk · ${OVERALL}"

if echo "$OVERALL" | grep -q "✅"; then
  SITREP="📡 DAILY SITREP — ${TODAY} | ${TASKS_ACTIVE} active · ${TASKS_AWAITING} awaiting review · ${DISK_PCT}% disk · ✅ ALL SYSTEMS NOMINAL"
else
  SITREP="📡 DAILY SITREP — ${TODAY} | ${TASKS_ACTIVE} active · ${TASKS_AWAITING} awaiting review · ${DISK_PCT}% disk · ${OVERALL}"
fi

# Send via OpenClaw CLI — no model calls, openclaw is in PATH via LaunchAgent plist
openclaw message send \
  --channel telegram \
  --target "$TELEGRAM_TARGET" \
  --message "$SITREP" \
  --silent \
  2>> "$LOG_FILE" || {
    log "ERROR: Failed to send Telegram message"
    echo "Telegram send FAILED — check logs" >&2
    exit 1
  }

log "Telegram sent: $SITREP"
log "=== Daily Station Check DONE ==="

# Trim log to last 500 lines
tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
