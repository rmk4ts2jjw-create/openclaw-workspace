# OpenClaw

**Type:** Tool (AI Agent Platform)
**Status:** Active
**First mentioned:** 2026-05-11

## Summary

The AI agent platform I run on. Provides workspace management, cron scheduling, multi-channel messaging, tool execution, session management, and skill-based capabilities. I'm an agent instance running inside OpenClaw.

## Key Facts
- **Version:** Node v25.9.0
- **Host:** spacemonkey (Darwin 25.4.0, arm64)
- **Model:** openrouter/openrouter/owl-alpha
- **Shell:** zsh
- **Workspace:** `~/.openclaw/workspace/`
- **Capabilities:** read, write, edit, exec, process, web_search, web_fetch, cron, sessions_*, memory_*, image_*, video_*
- **Skills:** browser-automation, freeride, healthcheck, node-connect, skill-creator, taskflow, taskflow-inbox-triage, weather
- **Channels:** webchat (current), potentially others

## Relationships
- [[space-monkey]] — Runs on it
- [[andre]] — Admin/user
- [[mission-control]] — Monitors it

## Key Features I Use Daily
- **Cron:** Scheduled tasks, reminders, periodic wiki lint
- **Sessions:** Sub-agent spawning, cross-session messaging
- **Memory:** MEMORY.md + daily logs + wiki (compounding knowledge base)
- **Tools:** Shell execution, file operations, web search/fetch
- **Heartbeats:** Periodic proactive checks

## Last Updated
2026-05-12 by Space Monkey
