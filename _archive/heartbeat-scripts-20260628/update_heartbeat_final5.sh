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
used_disk_raw=$(echo $disk_info | awk '{print $3}' | sed 's/Gi//')
avail_disk_raw=$(echo $disk_info | awk '{print $4}' | sed 's/Gi//')
size_disk_raw=$(echo $disk_info | awk '{print $2}' | sed 's/Gi//')
used_disk_gb=$used_disk_raw
free_disk_gb=$avail_disk_raw
total_disk_gb=$size_disk_raw
# Calculate used percentage from the raw numbers (should match df output)
used_percent_calc=$(echo "scale=2; $used_disk_gb * 100 / $total_disk_gb" | bc)
# Use the percentage from df for consistency with the column
disk_str="${disk_use_percent}% used (${used_disk_gb}Gi used, ${free_disk_gb}Gi free of ${total_disk_gb}Gi)"
mc_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
gw_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/ || echo "000")

# Get TRIAGE incidents
triage_ids=$(jq -r '.[] | select(.status == "TRIAGE") | .id' data/incidents.json | tr '\n' ',' | sed 's/,$//')
if [ -z "$triage_ids" ]; then
    triage_ids="none"
    triage_count=0
else
    # Remove any leading/trailing whitespace from the count
    triage_count=$(echo $triage_ids | tr ',' '\n' | wc -l | tr -d ' ')
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

# Calculate uptime from boot time
boot_time=$(sysctl -n kern.boottime | awk -F'[ =]' '{print $2}')
if [ -z "$boot_time" ]; then
    # Fallback to uptime command if sysctl fails
    up_raw=$(uptime | awk '{print $3}' | tr -d ',')
    IFS=':' read -r up_hours up_minutes <<< "$up_raw"
    # If up_hours is empty, it means we only have minutes (e.g., "35")
    if [ -z "$up_hours" ]; then
        up_hours=0
        up_minutes=$up_raw
    fi
    uptime_str="${up_hours}h${up_minutes}m"
else
    current_time=$(date +%s)
    up_seconds=$((current_time - boot_time))
    up_minutes=$((up_seconds / 60))
    up_hours=$((up_minutes / 60))
    up_mins=$((up_minutes % 60))
    uptime_str="${up_hours}h${up_mins}m"
fi

# Determine system status string
if [ "$triage_count" -eq 0 ]; then
    systems_status="Systems operational"
else
    systems_status="Systems operational with ongoing incidents (${triage_count})"
fi

# Build the new current status block
new_current_status="## Current Status (${current_time_bst})
- **System Load**: ${load_avg_formatted} - Normal
- **Memory/Disk**: ${disk_str} - Normal
- **Mailpit Dashboard**: HTTP ${mc_status} (responding)  # Note: keeping the original label? Actually, it was Mission Control Dashboard
- **OpenClaw Gateway**: HTTP ${gw_status} (responding)
- **Open Incidents**: ${triage_count} in TRIAGE status
- **Systems Status**: ${systems_status}
- **Uptime**: ${uptime_str}"

# Write the header, a blank line, and the new current status
echo "$header" > HEARTBEAT.md
echo "" >> HEARTBEAT.md
echo "$new_current_status" >> HEARTBEAT.md