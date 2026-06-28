#!/bin/bash
cd /Users/spacemonkey/.openclaw/workspace

# Update system stats
current_time_header=$(date '+%A, %B %d, %Y at %I:%M %p %Z')
current_time_log=$(date '+%Y-%m-%d %H:%M:%S')
load_avg=$(sysctl -n vm.loadavg | awk '{print $2","$3","$4}')
total_memory=$(sysctl -n hw.memsize)
free_memory=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
total_mem_gb=$(echo "scale=2; $total_memory / 1024 / 1024 / 1024" | bc)
free_mem_gb=$(echo "scale=2; $free_memory * 4096 / 1024 / 1024 / 1024" | bc)
used_mem_gb=$(echo "scale=2; $total_mem_gb - $free_mem_gb" | bc)
mem_percent=$(echo "scale=2; $used_mem_gb * 100 / $total_mem_gb" | bc)
disk_info=$(df -h / | tail -1)
disk_use_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')
disk_free=$(echo $disk_info | awk '{print $4}')
mc_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
gw_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/ || echo "000")

# Get TRIAGE incidents
triage_ids=$(jq -r '.[] | select(.status == "TRIAGE") | .id' data/incidents.json | tr '\n' ',' | sed 's/,$//')
if [ -z "$triage_ids" ]; then
    triage_ids="none"
fi

# Read current HEARTBEAT.md
content=$(cat HEARTBEAT.md)

# Replace system stats placeholders
content=$(echo "$content" | sed "s|\$current_time_header|$current_time_header|g")
content=$(echo "$content" | sed "s|\$current_time_log|$current_time_log|g")
content=$(echo "$content" | sed "s|\$load_avg|$load_avg|g")
content=$(echo "$content" | sed "s|\$mem_percent|$mem_percent|g")
content=$(echo "$content" | sed "s|\$free_mem_gb|$free_mem_gb|g")
content=$(echo "$content" | sed "s|\$total_mem_gb|$total_mem_gb|g")
content=$(echo "$content" | sed "s|\$disk_use_percent|$disk_use_percent|g")
content=$(echo "$content" | sed "s|\$disk_free|$disk_free|g")

# Update the incident checklist item
if [ "$triage_ids" = "none" ]; then
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[x\] Ensure no pending incidents in incident management|")
else
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[ \] Ensure no pending incidents in incident management (found: $triage_ids)|")
fi

# Update Today's Summary: replace the second bullet line
if [ "$triage_ids" = "none" ]; then
    # No incidents, keep the original
    :
else
    # Replace the line that starts with "- Full stable day"
    content=$(echo "$content" | sed "s|- Full stable day — no outages, no new incidents after morning|- Ongoing incidents: $triage_ids (from previous days)|")
fi

# Update Last Run Summary line
if [ "$triage_ids" = "none" ]; then
    # No incidents, keep the original format but we already updated the stats
    :
else
    # Append a note about incidents at the end of the line
    # The line currently looks like:
    # - 2026-06-28 15:03:08 — MC 200, GW 200 (port 18789), load 2.14,2.16,3.49, disk 32% (26Gi free). Check completed.
    # We want to add: " | Ongoing incidents: $triage_ids"
    content=$(echo "$content" | sed "s|\(- $current_time_log — MC $mc_status, GW $gw_status (port 18789), load $load_avg, disk $disk_use_percent% ($disk_free free). Check completed\.\)|\1 | Ongoing incidents: $triage_ids|")
fi

# Write the file
echo "$content" > HEARTBEAT.md