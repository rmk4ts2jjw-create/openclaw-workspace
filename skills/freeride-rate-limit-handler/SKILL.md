---
name: "freeride-rate-limit-handler"
description: "Manages FreeRide model rate-limit footguns and configures AI routing for cost efficiency"
---

# FreeRide Rate-Limit Handler Proposal

**Objective:** Prevent exhausted OpenRouter free model pool by:
1. Applying patch to enable fallback chains
2. Configuring rate-limit-aware routing
3. Implementing model group prioritization

**Solution:**
1. Patch system to cluster fallback models by region/cost
2. Add priority routing rules in OpenClaw config
3. Configure circuit-breaker pattern for AI tier transitions

**Owner:** spacemonkey@OpenClaw.org
****Priority: Critical

Reference existing skills: `freeride`, `healthcheck`{
