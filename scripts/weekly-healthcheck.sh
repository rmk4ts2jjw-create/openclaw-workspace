#!/bin/bash
# weekly-healthcheck.sh — Shell-only security audit
# Runs every Monday at 08:00 BST via OpenClaw cron.
# Outputs a concise report to logs/healthcheck.log

LOG="/Users/spacemonkey/.openclaw/workspace/logs/healthcheck.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S %Z')

log() { echo "[$DATE] $1" >> "$LOG"; }

log "=== Weekly Healthcheck ==="

# OS version
OS=$(sw_vers -productVersion 2>/dev/null)
log "macOS: $OS"

# Disk encryption
FV=$(fdesetup status 2>/dev/null | head -1)
log "FileVault: $FV"

# Firewall
FW=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | head -1)
log "Firewall: $FW"

# Disk usage
DISK=$(df -h / | tail -1 | awk '{print $5 " used (" $3 "/" $2 ")"}')
log "Disk: $DISK"

# Memory — get page size dynamically (16384 on Apple Silicon, 4096 on Intel)
PAGE_SIZE=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
MEM_PCT=$(vm_stat | awk -v ps="$PAGE_SIZE" '/Pages active/{a=$NF} /Pages wired down/{w=$NF} /Pages speculative/{s=$NF} END{if(a+w+s>0) printf "%.0f%%", (a+w+s)*ps/17179869184*100; else print "N/A"}')
log "Memory: $MEM_PCT"

# Uptime
UP=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
log "Uptime: $UP"

# OpenClaw gateway
GW=$(openclaw gateway status 2>/dev/null | grep -i "Runtime:" | head -1 | awk '{print $2}')
log "Gateway: ${GW:-unknown}"

# Listening ports (non-loopback)
PORTS=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -v "127.0.0.1" | grep -v "::1" | awk '{print $9}' | sort -u | tr '\n' ', ')
log "Public ports: ${PORTS:-none}"

# SSH password auth
SSH_PW=$(grep -i "PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | grep -v "^#" | head -1)
log "SSH password auth: ${SSH_PW:-not configured}"

# Time Machine
TM_RAW=$(tmutil latestbackup 2>/dev/null)
if [ -n "$TM_RAW" ]; then
  TM=$(basename "$TM_RAW" | sed 's/-//g' | xargs -I{} date -jf "%Y%m%d%H%M%S" "{}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$TM_RAW")
else
  TM="No recent backup"
fi
log "Last backup: $TM"

# OpenClaw version
OC=$(openclaw --version 2>/dev/null | head -1)
log "OpenClaw: ${OC:-unknown}"

# Risk flags
RISKS=""
if echo "$FW" | grep -qi "disabled"; then RISKS="$RISKS [FIREWALL_OFF]"; fi
if echo "$FV" | grep -qi "off"; then RISKS="$RISKS [FILEVAULT_OFF]"; fi
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [ "$DISK_PCT" -gt 85 ] 2>/dev/null; then RISKS="$RISKS [DISK_HIGH]"; fi
if [ -n "$RISKS" ]; then
  log "⚠️ RISKS:$RISKS"
else
  log "✅ No critical risks detected"
fi

log "=== Healthcheck complete ==="
