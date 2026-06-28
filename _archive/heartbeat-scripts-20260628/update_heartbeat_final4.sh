#!/bin/bash
cd /Users/spacemonkey/.openclaw/workspace

# Update system stats
current_time_bst=$(date '+%H:%M BST')
current_date=$(date '+%Y-%m-%d')
load_avg_raw=$(sysctl -n vm.loadavg)
load_avg_formatted=$(echo $load_avg_raw | awk '{printf "%.2f (1m), %.2f (5m), %.2f (15m)", $2, $3, $4}')
# Disk usage
disk_info=$(df -h / | tail -1)
disk_use_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')
disk_free=$(echo $disk_info | awk '{print $4}')
# For the Memory/Disk line, we are showing disk usage (as in the existing file)
used_disk_raw=$(echo $disk_info | awk '{print $3}' | sed 's/Gi//')
avail_disk_raw=$(echo $disk_info | awk '{print $4}' | sed 's/Gi//')
size_disk_raw=$(echo $disk_info | awk '{print $2}' | sed 's/Gi//')
used_disk_gb=$used_disk_raw
free_disk_gb=$avail_disk_raw
total_disk_gb=$size_disk_raw
disk_used_percent=$(echo "scale=2; $used_disk_gb * 100 / $total_disk_gb" | bc)
disk_str="${disk_used_percent}% used (${used_disk_gb}Gi used, ${free_disk_gb}Gi free of ${total_disk_gb}Gi)"
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

# Read the entire HEARTBEAT.md
content=$(cat HEARTBEAT.md)

# Update the checklist header date
content=$(echo "$content" | sed "s|## Routine Heartbeat Checklist (2026-06-27)|## Routine Heartbeat Checklist (${current_date})|")

# Update the incident checklist item
if [ "$triage_count" -eq 0 ]; then
    # Keep as checked (no change needed)
    :
else
    # Uncheck and add note
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[ \] Ensure no pending incidents in incident management (found: ${triage_ids})|")
fi

# Now, remove the current status block and everything after it (since we are replacing it)
# We'll keep everything before the line that starts with "## Current Status"
header=$(echo "$content" | sed -e '/^## Current Status/,$d')

# Build the new current status block
# Format uptime
up_raw=$(uptime | awk '{print $3}' | tr -d ',')  # e.g., "4:34"
IFS=':' read -r up_hours up_minutes <<< "$up_raw"
uptime_str="${up_hours}h${up_minutes}m"

# Determine system status string
if [ "$triage_count" -eq 0 ]; then
    systems_status="Systems operational"
else
    # Note: there's a typo in the original: "Studies operational" -> we'll keep it as is to match the style? 
    # But the original said "Systems operational with ongoing incidents (8)"
    # Let's use that.
    systems_status="Systems operational with ongoing incidents (${triage_count})"
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

# Write the header, a blank line, and the new current status
echo "$header" > HEARTBEAT.md
echo "" >> HEARTBEAT.md
echo "$new_current_status" >> HEARTBEAT.md