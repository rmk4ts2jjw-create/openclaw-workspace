# Agent Roles & Permissions

## Operations Engine

**Definition:** Task Dispatcher + Agent Execution + Stall Detection + Triage Flow.

The Operations Engine is the system that works through the task backlog autonomously during awake hours. It is NOT the same as Dreaming (which is memory consolidation at 3am).

**How it works:**
1. **Task Dispatcher** (heartbeat) picks the highest-priority dispatchable task from Backlog
2. **Agent Execution** — spawns a sub-agent that works the task, updating `currentStep` and `lastActivity` at every step
3. **Stall Detection** — if a task sits In Progress with no activity for >30 min, it's reset to Backlog
4. **Triage Flow** — if an agent hits a wall (blocked, unclear, needs human input), the task moves to Triage with clear notes explaining what's needed. Tasks never sit frozen In Progress.

**Key rules:**
- ONE task In Progress at a time per agent
- Blocked/unclear tasks → Triage (not frozen In Progress)
- Triage tasks include: what was attempted, what's blocking, what specific action Andre needs to take
- Completed tasks auto-move to Done with summaries
- P1 tasks stay in Backlog for Andre's awareness (not auto-dispatched)
- Night Shift (01:00-07:00) is the Operations Engine running autonomously while Andre sleeps, with stricter limits (max 2-5 tasks, no P1, stops on rate limits)

**Triage is NOT a graveyard.** It's where tasks go when they need human input. Andre reviews Triage regularly and moves approved tasks back to Backlog.

---

## Agent Communication Rules

### Status Reports Only
When the user asks "anything else?" or "more recommendations?", respond with a **status report only**:
- What was completed
- What's remaining (if anything)
- Any blockers

**Do NOT:**
- Generate new work or recommendations unless explicitly asked to review a specific area
- Suggest improvements, fixes, or new features unprompted
- Continue iterating on the same topic after the user has moved on

**Why:** Open-ended "anything else" prompts caused the 87-session token explosion. The agent kept generating more recommendations indefinitely. Never again.

### Exceptions
- If the user explicitly says "review X" or "check Y" → do the review
- If there's a critical security/stability issue → flag it immediately
- If the user asks a direct question → answer it concisely

---

## Security Rules

### 1. Gateway Binding
- Gateway always binds to `127.0.0.1` (localhost only)
- Already confirmed safe — no action needed

### 2. API Cost Runaway Prevention
- **Hard spending limits:** Set at the API provider level (OpenRouter spending cap)
- **Circuit breaker:** If 5+ consecutive tool calls fail with the same error, stop and alert — do NOT retry forever
- **Token logging:** Log token counts per session for visibility and cost tracking

### 3. Skill Verification
- Before installing any ClawHub skill: verify the author, check install count, confirm the GitHub repo is legitimate
- **FreeRide skill verification:** Confirm it's from `openclaw-eco/free-ride` — not a typosquat or fork

### 4. Update Strategy
- Test before applying major version bumps
- Our `2026.5.18 → 2026.5.19` update partially failed — lesson learned
- Always have a rollback plan before upgrading

---

## Component Rules

### IncidentDetailsDrawer.tsx — Hooks Must ALL Be Before Any Early Return

**Two separate Rules of Hooks bugs have been caused by conditional hooks in this file.**

- ALL `useState` and `useEffect` calls must be at the top level of the component function, before ANY early returns, conditions, or loops.
- Never call hooks inside IIFEs (`(() => { ... })()`), nested functions, conditionals, or loops.
- The "Incident Timeline" section previously had `useState` + `useEffect` inside an IIFE in the JSX render — this caused React to crash with "Rendered more hooks than during the previous render."
- The "Runbook" section uses an IIFE for synchronous lookup — this is OK as long as it contains NO hooks.
- **If you need state/effects for a conditional section, lift them to the top level and use conditional rendering in the JSX instead.**
