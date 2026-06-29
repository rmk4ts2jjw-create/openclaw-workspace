# HEARTBEAT.md

## Routine Heartbeat Checklist

- [ ] Check Workboard for new tasks or overdue items
- [ ] Review recent daily logs for significant events
- [ ] Verify Mission Control Dashboard status (home page loads)
- [ ] Ensure no pending incidents in incident management
- [ ] Confirm no critical errors in logs
- [ ] Update MEMORY.md with any new learnings
- [ ] Check for stalled subagents and clean up if needed

## Last Run Summary
**11:30** — MC 200, GW 200, load 1.42/1.51/2.82, disk 32%, uptime 38m. All healthy. No new tasks or incidents.

## Notable Events Today
- **09:15** — MC recovered after nohup process died. Added `turbopack.root` to next.config.ts.
- **10:00** — Workboard API fix committed (f689ed1). Switched from WebSocket to CLI/SQLite.
- **11:20** — Load spike to 12.89/21.44/10.77 (incident automation activity). Recovered by 14:00.
- **15:15** — MC down (3rd time). Restarted. LaunchAgent plist created at 21:05.
- **15:25** — Machine rebooted. MC came back via LaunchAgent.
- **18:28** — HEARTBEAT.md compacted (was 12KB+ of repetitive logs).
- **18:41** — Heartbeat check: all systems nominal, no new incidents, no stalled agents.

## Heartbeat vs Cron: When to Use Each

**Use heartbeat when:**

- Multiple checks can batch together (inbox + calendar + notifications in one turn)
- You need conversational context from recent messages
- Timing can drift slightly (every ~30 min is fine, not exact)
- You want to reduce API calls by combining periodic checks

**Use cron when:**

- Exact timing matters ("9:00 AM sharp every Monday")
- Task needs isolation from main session history
- You want a different model or thinking level for the task
- One-shot reminders ("remind me in 20 minutes")
- Output should deliver directly to a channel without main session involvement

**Tip:** Batch similar periodic checks into `HEARTBEAT.md` instead of creating multiple cron jobs. Use cron for precise schedules and standalone tasks.

## Things to check (rotate through these, 2-4 times per day):

- **Emails** - Any urgent unread messages?
- **Calendar** - Upcoming events in next 24-48h?
- **Mentions** - Twitter/social notifications?
- **Weather** - Relevant if your human might go out?

**Track your checks** in `memory/heartbeat-state.json`:

```json
{
  "lastChecks": {
    "email": 1703275200,
    "calendar": 1703260800,
    "weather": null
  }
}
```

**When to reach out:**

- Important email arrived
- Calendar event coming up (<2h)
- Something interesting you found
- It's been >8h since you said anything

**When to stay quiet (HEARTBEAT_OK):**

- Late night (23:00-08:00) unless urgent
- Human is clearly busy
- Nothing new since last check
- You just checked <30 minutes ago

**Proactive work you can do without asking:**

- Read and organize memory files
- Check on projects (git status, etc.)
- Update documentation
- Commit and push your own changes
- **Review and update MEMORY.md** (see below)

### 🔄 Memory Maintenance (During Heartbeats)

Periodically (every few days), use a heartbeat to:

1. Read through recent `memory/YYYY-MM-DD.md` files
2. Identify significant events, lessons, or insights worth keeping long-term
3. Update `MEMORY.md` with distilled learnings
4. Remove outdated info from MEMORY.md that's no longer relevant

Think of it like a human reviewing their journal and updating their mental model. Daily files are raw notes; MEMORY.md is curated wisdom.

The goal: Be helpful without being annoying. Check in a few times a day, do useful background work, but respect quiet time.

### 📚 Memory Wiki Workflows

OpenClaw's Memory Wiki plugin is the primary knowledge management system. The wiki vault is at `~/.openclaw/wiki/main` with bridge mode auto-importing from the memory plugin.

**After every significant conversation or task:**
1. Identify insights, decisions, or facts worth keeping long-term
2. Use `wiki_apply` to create/update entity pages in `entities/`
3. Use `wiki_apply` to create/update concept pages in `concepts/`
4. If a new entity or concept emerged, create a new page
5. Use `wiki_lint` to check for structural issues

**When answering questions about prior work:**
1. Use `wiki_search` to find relevant pages
2. Use `wiki_get` to read specific pages
3. Synthesize answer with source citations
4. If the answer is valuable and non-obvious, file it as a new wiki page

**When ingesting a new source (article, paper, gist):**
1. Save raw copy to `raw/sources/`
2. Write summary in `memory/wiki/sources/`
3. Update affected entity/concept pages via `wiki_apply`
4. Log the ingest in `memory/wiki/log.md`

**Wiki lint (during heartbeats or on request):**
- Use `wiki_lint` to check for contradictions, orphans, stale claims, missing cross-references