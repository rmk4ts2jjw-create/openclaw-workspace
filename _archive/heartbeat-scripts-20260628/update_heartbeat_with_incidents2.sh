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
    # Keep as checked
    :
else
    # Uncheck and add note
    content=$(echo "$content" | sed "s|- \[x\] Ensure no pending incidents in incident management|- \[ \] Ensure no pending incidents in incident management (found: $triage_ids)|")
fi

# Update Today's Summary: replace the second bullet line (the one about full stable day)
if [ "$triage_ids" = "none" ]; then
    # No incidents, keep the original
    :
else
    # Replace the line that starts with "- Full stable day"
    content=$(echo "$content" | sed "s|- Full stable day — no outages, no new incidents after morning|- Ongoing incidents: $triage_ids (from previous days)|")
fi

# Update Last Run Summary line: append note about incidents if any
if [ "$triage_ids" = "none" ]; then
    # No incidents, nothing to append
    :
else
    # We want to append to the line that ends with ". Check completed."
    # We'll match the line that starts with "- $current_time_log" and ends with ". Check completed."
    # and append " | Ongoing incidents: $triage_ids" before the newline.
    # Use sed with a capture group.
    content=$(echo "$content" | sed -E "s|(- $current_time_log .* Check completed\.)|\1 | Ongoing incidents: $triage_ids|")
fi

# Write the file
echo "$content" > HEARTBEAT.md