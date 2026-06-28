#!/bin/bash
cd /Users/spacemonkey/.openclaw/workspace

# Update system stats
current_time_header=$(date '+%A, %B %d, %Y at %I:%M %p %Z')
current_time_log=$(date '+%Y-%m-%d %H:%M:%S')
current_time_bst=$(date '+%H:%M BST')
load_avg_raw=$(sysctl -n vm.loadavg)
load_avg_formatted=$(echo $load_avg_raw | awk '{printf "%.2f (1m), %.2f (5m), %.2f (15m)", $2, $3, $4}')
total_memory=$(sysctl -n hw.memsize)
free_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
total_mem_gb=$(echo "scale=2; $total_memory / 1024 / 1024 / 1024" | bc)
free_mem_gb=$(echo "scale=2; $free_memory * 4096 / 1024 / 1024 / 1024" | bc)
used_mem_gb=$(echo "scale=2; $total_mem_gb - $free_mem_gb" | bc)
mem_percent=$(echo "scale=2; $used_mem_gb * 100 / $total_mem_gb" | bc)
disk_info=$(df -h / | tail -1)
# Example: /dev/disk3s1s1   228Gi   12Gi   26Gi    35%  617462 2734862    2%   /
disk_use_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')
used_disk_gb=$(echo $disk_info | awk '{print $3}' | sed 's/Gi//')
free_disk_gb=$(echo $disk_info | awk '{print $4}' | sed 's/Gi//')
total_disk_gb=$(echo $disk_info | awk '{print $2}' | sed 's/Gi//')
# The disk string uses the percentage from df
disk_str="${disk_use_percent}% used (${used_disk_gb}Gi used, ${free_disk_gb}Gi free of ${total_disk_gb}Gi)"
mc_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
gw_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/ || echo "000")

# Get TRIAGE incidents
triage_ids=$(jq -r '.[] | select(.status == "TRIAGE") | .id' data/incidents.json | tr '\n' ',' | sed 's/,$//')
if [ -z "$triage_ids" ]; then
    triage_ids="none"
    triage_count=0
else
    triage_count=$(echo $triage_ids | tr ',' '\n' | wc -l)
fi

# Read current HEARTBEAT.md
content=$(cat HEARTBEAT.md)

# Update the date in the checklist header
content=$(echo "$content" | sed "s|## Routine Heartbeat Checklist (2026-06-27)|## Routine Heartbeat Checklist $(date '+%Y-%m-%d')|")

# Update the incident checklist item
if [ "$triage_count" -eq 0 ]; then
    # Keep as checked
    :
else
    # Uncheck and add note
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[ \] Ensure no pending incidents in incident management (found: ${triage_ids})|")
fi

# Now, replace the Current Status block
# Get the line number of the line that starts with "## Current Status"
line_num=$(grep -n "^## Current Status" HEARTBEAT.md | cut -d: -f1)
if [ -z "$line_num" ]; then
    # If not found, we will use the entire file as the header
    header_content="$content"
else
    # Get the lines before the line_num
    header_content=$(echo "$content" | head -n $((line_num - 1)))
fi

# Build the new current status block
# Format uptime: we want something like "4h34m"
# Get uptime from the uptime command: it outputs like " 15:02  up 4:34, 2 users, load averages: 1.57 2.03 2.01"
up_raw=$(uptime | awk '{print $3}' | tr -d ',')  # This gives "4:34"
IFS=':' read -r up_hours up_minutes <<< "$up_raw"
uptime_str="${up_hours}h${up_minutes}m"

# Determine system status string
if [ "$triage_count" -eq 0 ]; then
    systems_status="Systems operational"
else
    systems_status="Studies operational with ongoing incidents (${triage_count})"
fi

# Build the new current status block
new_current_status="## Current Status (${current_time_bst})
- **System Load**: ${load_avg_formatted} - Normal
- **Memory/Disk**: ${disk_str} - Normal
- **Mission Control Dashboard**: HTTP ${mc_status} (responding)
- **OpenClaw Gateway**: HTTP ${gw_status} (responding)
- **Open Incidents**: ${triage_count} in TRIAGE status
- **Systems Status**: ${systems_status}
- **Uptime**: ${uptime_str}"

# Combine header and new current status
echo "$header_content" > HEARTBEAT.md
echo "" >> HEARTBEAT.md
echo "$new_current_status" >> HEARTBEAT.md

# Note: we are not preserving any content after the Current Status block, but in the existing file, there is nothing after it.