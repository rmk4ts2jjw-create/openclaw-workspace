# Workboard Integration Postmortem

**Date:** 2026-06-23
**Author:** Space Monkey (Station Chief)
**Scope:** Post-mortem analysis of Workboard integration (commits 80bdd04, e1b884a, 902d775, 0b63a05)
**Stable baseline:** commit 86f4f55

## Executive Summary

The Workboard integration broke the entire site through **three independent failures**: a React hooks violation causing a client-side crash, hardcoded CSS overrides breaking the design system, and a WebSocket connection that couldn't authenticate. The integration was reverted to the stable build at 86f4f55.

---

## Failure 1: React Hooks Violation (CRITICAL — Page Crash)

**Location:** `src/app/(dashboard)/tasks/page.tsx`, `TaskCard` component

**What happened:**
The `TaskCard` component calls `useSortable({ id: task.id })` at the top of the
component (line ~203 in the Workboard version), **then** checks
`if (!task || !task.status)` and returns null (line ~207).

```tsx
// BROKEN — hook called before guard
function TaskCard({ task, ... }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
    useSortable({ id: task.id });  // ← Hook #1

  if (!task || !task.status) {     // ← Guard: early return skips hook on re-renders
    console.warn("[TaskCard] Skipping render for invalid task:", task);
    return null;
  }
  // ...
}
```

**Why it crashes:**
React hooks must be called unconditionally on every render. If `task` is
undefined on a re-render (e.g., optimistic update removes the task from state
before the WebSocket responds), the early return means `useSortable` is skipped.
React detects the hook order change and throws:
"Rendered fewer hooks than expected during the previous render."

This crashes the entire React tree — not just the tasks page, but the whole
app since the error boundary catches it at the root level.

**Correct approach:**
Move the guard **before** the hook call, or make the hook conditional-safe:

```tsx
function TaskCard({ task, ... }) {
  if (!task || !task.status) return null;  // ← Guard FIRST

  const { attributes, listeners, ... } = useSortable({ id: task.id });  // ← Hook after guard
  // ...
}
```

---

## Failure 2: Hardcoded CSS Overrides (CRITICAL — Site-Wide Breakage)

**Location:** `src/components/TenacitOS/Shell.tsx`

**What happened:**
Commit `0b63a05` ("feat: wire tasks page to Workboard") added two hardcoded
inline styles to the Shell component:

```diff
  style={{
    minHeight: "100vh",
+   background: "linear-gradient(180deg, #0a0a0f 0%, #0d1117 50%, #0a0a0f 100%)",
    color: "var(--text-primary)",
+   fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
  }}
```

**Why it breaks the site:**
- `background: linear-gradient(...)` overrides `var(--background)` from `globals.css`,
  breaking the design system's dark theme CSS variables
- `fontFamily: 'SF Pro Display'` overrides the Inter font defined in `layout.tsx`
- Shell is the **root wrapper** — every page inherits these overrides
- This is the exact same class of bug that was fixed on 2026-06-22 (commit
  `86f4f55` — "fix: remove hardcoded CSS overrides in Shell.tsx")

**Correct approach:**
Shell should only set `minHeight: 100vh` and `color: var(--text-primary)`.
All theming comes from CSS variables in `globals.css` and `layout.tsx`.

---

## Failure 3: WebSocket Handshake Rejection (HIGH — Data Layer Failure)

**Location:** `src/hooks/useWorkboard.ts`

**What happened:**
The initial version (commit `80bdd04`) used a simple WebSocket connection with
the token as a query parameter:

```ts
const ws = new WebSocket(`ws://localhost:18789?token=${t}`);
```

The Gateway rejected this because it expects a **challenge-response handshake**:
1. Client connects
2. Server sends `connect.challenge` event
3. Client sends `connect` method with `client.id`, `client.mode`, and `auth.token`
4. Server responds with `{ ok: true }`

Commit `e1b884a` implemented the handshake but included `role` and `scopes` fields
that the Gateway doesn't accept. Commit `902d775` removed those fields and
the handshake succeeded.

**The handshake fix was correct** — the final version (after `902d775`) sends:
```json
{
  "type": "req",
  "id": "connect",
  "method": "connect",
  "params": {
    "minProtocol": 4,
    "maxProtocol": 4,
    "client": { "id": "openclaw-control-ui", "version": "1.0.0", "platform": "web", "mode": "ui" },
    "auth": { "token": "<token>" }
  }
}
```

**However**, even with a working handshake, the WebSocket approach has
architectural problems (see "Salvageability Assessment" below).

---

## What the Correct Implementation Should Look Like

### Architecture: REST API Bridge, Not Direct WebSocket

The tasks page should **not** connect directly to the Gateway via WebSocket.
Instead, it should use a Next.js API route as a bridge:

```
Tasks Page (client) → fetch("/api/tasks") → Next.js API Route → OpenClaw Workboard API
```

This avoids:
- WebSocket connection management complexity
- Gateway authentication from the browser (token exposure)
- CORS issues
- React hooks violations from async WebSocket state

### Component Guard Pattern

All components using hooks must guard **before** any hook call:

```tsx
function TaskCard({ task, ... }) {
  // GUARD FIRST — no hooks before this
  if (!task || !task.status) return null;

  // HOOKS AFTER GUARD
  const { attributes, listeners, ... } = useSortable({ id: task.id });
  // ...
}
```

### Shell.tsx: Never Override Design Tokens

```tsx
export function Shell({ children }: ShellProps) {
  return (
    <div className="tenacios-shell" style={{ minHeight: "100vh", color: "var(--text-primary)" }}>
      {children}
    </div>
  );
}
```

No `background`, no `fontFamily`, no `backgroundImage`. All from CSS variables.

---

## Salvageability Assessment

### useWorkboard.ts — Salvageable with Changes

The WebSocket client itself is **well-structured**:
- ✅ Proper challenge-response handshake
- ✅ Request/response correlation via ID map
- ✅ Automatic reconnection with backoff
- ✅ Call queue for requests during reconnection
- ✅ Token subscription via `useSyncExternalStore`

**Problems:**
- ❌ Designed for a different API (OpenClaw Gateway RPC, not Workboard REST)
- ❌ Exposes Gateway token to the browser
- ❌ Complex error surface (WebSocket disconnects, timeouts, handshake failures)
- ❌ Overkill for CRUD operations on tasks

**Recommendation:** Keep as a reference implementation but don't use for the tasks
page. If WebSocket RPC is needed for real-time updates later, route it through
a Server-Sent Events (SSE) API route instead.

### Tasks Page Rewrite — Needs Full Redo

The Workboard version added 449 lines of changes to the tasks page. The hooks
violation means the entire `TaskCard` function needs to be restructured.
The data layer should switch from WebSocket RPC to REST API calls.

### Shell.tsx — Already Fixed

The stable build (86f4f55) has the correct Shell.tsx. No action needed.

---

## Recommended Next Steps

1. **Create REST API routes** for Workboard CRUD:
   - `GET /api/workboard/cards` — list cards
   - `POST /api/workboard/cards` — create card
   - `PATCH /api/workboard/cards/[id]` — update card
   - `POST /api/workboard/cards/[id]/move` — move to column
   - `DELETE /api/workboard/cards/[id]` — delete card

2. **Rewrite tasks page** using `fetch("/api/workboard/cards")` instead of
   `useWorkboard().call()`. Keep the existing UI (Kanban columns, drag-and-drop,
   detail drawer).

3. **Fix the React hooks guard** in TaskCard — move `if (!task)` before hooks.

4. **Never touch Shell.tsx** for feature work — it's a design system component.

5. **Add ESLint rule** `react-hooks/rules-of-hooks` as error-level to catch
   violations before they reach production.

---

## Lessons Learned

| Lesson | Source | Impact |
|--------|--------|--------|
| Never put hooks after guards | TaskCard crash | Site-wide 500 |
| Never hardcode CSS in Shell | Design system override | Site-wide style break |
| WebSocket RPC is not REST | Architecture mismatch | Data layer failure |
| Challenge-response ≠ query param | Handshake rejection | Connection failure |
| Test on actual target OS | Linux services on macOS | 6+ wasted processes/5s |

---

## Commit Reference

| Commit | Type | Description |
|--------|------|-------------|
| `86f4f55` | fix | Stable baseline — CSS overrides removed |
| `80bdd04` | feat | Workboard integration — tasks page rewrite + useWorkboard hook |
| `d9280d2` | fix | React hook violation in AvatarModel.tsx (separate issue) |
| `e1b884a` | fix | WebSocket handshake protocol implementation |
| `902d775` | fix | Remove role/scopes from handshake |
| `0b63a05` | feat | Wire tasks page to Workboard (added CSS overrides to Shell) |
