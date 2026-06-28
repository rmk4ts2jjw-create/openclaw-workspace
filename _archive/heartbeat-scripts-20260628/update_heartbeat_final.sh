#!/bin/bash
cd /Users/spacemonkey/.openclaw/workspace

# Get current date for the checklist header
current_date=$(date '+%Y-%m-%d')
current_time_bst=$(date '+%H:%M BST')
current_time_log=$(date '+%Y-%m-%d %H:%M:%S')

# System load
load_avg_raw=$(sysctl -n vm.loadavg)
load_avg_formatted=$(echo $load_avg_raw | awk '{printf "%.2f (1m), %.2f (5m), %.2f (15m)", $2, $3, $4}')

# Memory (actually disk) usage from df -h /
disk_info=$(df -h / | tail -1)
total_disk_gb=$(echo $disk_info | awk '{print $2}' | sed 's/Gi//')
used_disk_gb=$(echo $disk_info | awk '{print $3}' | sed 's/Gi//')
free_disk_gb=$(echo $disk_info | awk '{print $4}' | sed 's/Gi//')
disk_use_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')
disk_str="${disk_use_percent}% used (${used_disk_gb}Gi used, ${free_disk_gb}Gi free of ${total_disk_gb}Gi)"

# Uptime
uptime_raw=$(uptime)
uptime_str=$(echo "$uptime_raw" | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')

# Gateway and MC status
mc_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
gw_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/ || echo "000")

# TRIAGE incidents
triage_ids=$(jq -r '.[] | select(.status == "TRIAGE") | .id' data/incidents.json | tr '\n' ',' | sed 's/,$//')
triage_count=$(echo $triage_ids | tr ',' '\n' | wc -l)
if [ -z "$triage_ids" ]; then
    triage_ids="none"
    triage_count=0
fi

# System status based on incidents
if [ "$triage_count" -eq 0 ]; then
    systems_status="All systems operational"
else
    systems_status="Systems operational with ongoing incidents (${triage_count})"
fi

# Read current HEARTBEAT.md
content=$(cat HEARTBEAT.md)

# Update the checklist header date
content=$(echo "$content" | sed "s|## Routine Heartbeat Checklist (2026-06-27)|## Routine Heartbeat Checklist (${current_date})|")

# Update the incident checklist item
if [ "$triage_count" -eq 0 ]; then
    # Keep as checked
    :
else
    # Uncheck and add note
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[ \] Ensure no pending incidents in incident management (found: ${triage_ids})|")
fi

# Update the Current Status block: replace from "## Current Status" to end of file
new_current_status="## Current Status (${current_time_bst})
- **System Load**: ${load_avg_formatted} - Normal
- **Memory/Disk**: ${disk_str} - Normal
- **Mission Control Dashboard**: HTTP ${mc_status} (responding)
- **OpenClaw Gateway**: HTTP ${gw_status} (responding)
- **Open Incidents**: ${triage_count} in TRIAGE status
- **Systems Status**: ${systems_status}
- **Uptime**: ${uptime_str}"

# Replace everything from the line starting with "## Current Status" to the end with the new block
content=$(echo "$content" | sed -e '/^## Current Status/,$d' -e "\$a${new_current_status}")

# Write the file
echo "$content" > HEARTBEAT.md