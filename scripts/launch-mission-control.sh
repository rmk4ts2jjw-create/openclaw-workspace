#!/bin/bash
# Launch Mission Control Dashboard
# Starts the TanStack Start dev server and opens the browser

DASHBOARD_DIR="$HOME/mission-control-dashboard"
PORT=8080

# Check if already running
if lsof -i ":$PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
    # Already running, just open the browser
    open "http://localhost:$PORT/tasks"
    exit 0
fi

# Start the dev server in the background
cd "$DASHBOARD_DIR"
nohup ~/.bun/bin/bun run dev > /tmp/mission-control.log 2>&1 &

# Wait for server to start
for i in $(seq 1 30); do
    if curl -s -o /dev/null "http://localhost:$PORT/" 2>/dev/null; then
        open "http://localhost:$PORT/tasks"
        exit 0
    fi
    sleep 1
done

# If we get here, the server didn't start
echo "Mission Control failed to start. Check /tmp/mission-control.log" >&2
open "http://localhost:$PORT/tasks"
