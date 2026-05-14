# Proposed Cron Jobs for Mission Control
# All created as DISABLED for review before enabling

## Existing (already created)
1. Work Dispatcher — every 15 min — DISABLED (was erroring on Telegram delivery)
2. OpenClaw Daily Backup — daily 3 AM — exists but erroring

## Proposed (to create, all disabled)

3. Log Rotation — weekly Sunday 2 AM
   - Rotate and compress logs older than 7 days
   - Archive to WD MyCloud

4. Storage Health Check — daily 6 AM
   - Check local disk usage
   - Check WD MyCloud availability
   - Alert if disk >80% or WD MyCloud unreachable

5. Task Queue Cleanup — daily midnight
   - Archive completed tasks older than 30 days
   - Move to data/tasks-archive.json

6. Wiki Lint — weekly Monday 3 AM
   - Check for orphan pages
   - Check for stale claims
   - Update wiki health in overview.md

7. System Health Snapshot — every 6 hours
   - CPU, disk, memory snapshot
   - Log to memory/health-log.md
   - Display on Mission Control dashboard

8. Backup Verification — weekly Sunday 4 AM
   - Verify latest backup integrity
   - Test restore of a small file
   - Log results

9. Mission Control Build Check — daily 9 AM
   - Check if MC dashboard builds successfully
   - If build fails, log error details
   - Optional: auto-restart dev server if crashed

10. Activity Summary — daily 8 PM
    - Summarize day's activity from logs
    - Update daily memory file
    - Post summary to Mission Control activity feed
