# Mission Control v2 — Developer Guide

> **Stack:** Next.js 16 (App Router) + React 19 · FastAPI (Python) · TypeScript (strict) · npm
> **Location:** `mc-v2/frontend/` (Next.js) · `mc-v2/backend/` (FastAPI)

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Route Structure](#2-route-structure)
3. [Component Tree](#3-component-tree)
4. [Authentication](#4-authentication)
5. [API Client](#5-api-client)
6. [Theming](#6-theming)
7. [Adding a New Page](#7-adding-a-new-page)
8. [Adding a New API Endpoint](#8-adding-a-new-api-endpoint)

---

## 1. Project Structure

```
mc-v2/
├── frontend/                         # Next.js 16 App Router
│   ├── src/
│   │   ├── app/                      # App Router pages & layouts
│   │   ├── api/                      # Orval-generated API client
│   │   │   ├── generated/            #   Auto-generated query/mutation hooks
│   │   │   └── mutator.ts            #   Custom fetch wrapper
│   │   ├── auth/                     # Auth facade (Clerk + local mode)
│   │   ├── components/
│   │   │   ├── atoms/                # Smallest reusable (BrandMark, StatusDot, etc.)
│   │   │   ├── molecules/            # Simple composites
│   │   │   ├── organisms/            # Complex composites (Sidebar, UserMenu, etc.)
│   │   │   ├── templates/            # Layout shells (DashboardShell, etc.)
│   │   │   ├── ui/                   # Radix-based primitives (button, dialog, etc.)
│   │   │   ├── providers/            # AuthProvider, QueryProvider
│   │   │   ├── auth/                 # Auth-specific components
│   │   │   ├── boards/               # Board-specific components
│   │   │   ├── agents/               # Agent-specific components
│   │   │   └── activity/             # Activity feed components
│   │   └── lib/                      # Utilities (cn(), api-base, hooks)
│   ├── public/
│   ├── tailwind.config.cjs
│   ├── orval.config.ts               # Orval codegen config
│   └── package.json
├── backend/                          # FastAPI Python
│   ├── app/
│   │   ├── api/                      # Route handlers
│   │   ├── models/                   # SQLAlchemy models
│   │   ├── schemas/                  # Pydantic schemas
│   │   ├── services/                 # Business logic
│   │   └── main.py
│   ├── alembic/                      # DB migrations
│   └── requirements.txt
├── docs/
├── scripts/
├── compose.yml
└── Makefile
```

---

## 2. Route Structure

Next.js App Router with pages in `frontend/src/app/`. Layout files provide shared shells.

### Complete Route Map

```
Path                           Page Component              Auth Required
────                            ─────────────              ─────────────
/                              LandingHero                 No
/dashboard                     DashboardPage               Yes
/onboarding                    OnboardingPage              Yes
/sign-in/[[...rest]]           SignInPage / LocalAuthLogin No
/boards                        BoardsPage                  Yes
/boards/new                    CreateBoardPage             Yes
/boards/[boardId]              BoardDetailPage             Yes
/boards/[boardId]/approvals    (approvals panel)           Yes
/boards/[boardId]/edit         EditBoardPage               Yes
/boards/[boardId]/webhooks     (webhooks list)             Yes
/agents                        AgentsPage                  Yes (admin)
/agents/new                    CreateAgentPage             Yes (admin)
/agents/[agentId]              AgentDetailPage             Yes
/agents/[agentId]/edit         EditAgentPage               Yes (admin)
/board-groups                  BoardGroupsPage             Yes
/board-groups/new              CreateBoardGroupPage        Yes
/board-groups/[groupId]        BoardGroupDetailPage        Yes
/board-groups/[groupId]/edit   EditBoardGroupPage          Yes
/gateways                      GatewaysPage                Yes (admin)
/gateways/new                  CreateGatewayPage           Yes (admin)
/gateways/[gatewayId]          GatewayDetailPage           Yes
/gateways/[gatewayId]/edit     EditGatewayPage             Yes (admin)
/approvals                     GlobalApprovalsPage         Yes
/activity                      ActivityPage (SSE)          Yes
/settings                      SettingsPage                Yes
/organization                  OrganizationPage            Yes
/skills                        SkillsPage                  Yes
/skills/marketplace            MarketplacePage             Yes
/skills/marketplace/[skillId]  SkillDetailPage             Yes
/skills/marketplace/new        CreateSkillPage             Yes
/skills/packs                  PacksPage                   Yes
/skills/packs/new              CreatePackPage              Yes
/skills/packs/[packId]         PackDetailPage              Yes
/tags                          TagsPage                    Yes
/tags/add                      AddTagPage                  Yes
/tags/[tagId]                  TagDetailPage               Yes
/custom-fields                 CustomFieldsPage            Yes (admin)
/custom-fields/new             CreateCustomFieldPage       Yes (admin)
/custom-fields/[fieldId]       FieldDetailPage             Yes
/invite                        InvitePage                  No
/loading                       loading.tsx (spinner)       —
```

### Key Patterns

- **Dynamic routes** use `[param]` directory naming (Next.js convention)
- **List pages** typically export `export const dynamic = "force-dynamic"` to prevent static prerendering
- **Auth gating** is done inside each page via `<SignedIn>` / `<SignedOut>` components from `@/auth/clerk`
- **Layout hierarchy:** Root layout → DashboardShell → DashboardPageLayout → page content

---

## 3. Component Tree

### Mount Hierarchy

```
<html>
  <body className="bg-app text-strong">
    <AuthProvider>                    ← ClerkProvider or LocalAuthLogin gate
      <QueryProvider>                 ← TanStack QueryClientProvider
        <GlobalLoader />
        <DashboardShell>              ← Sidebar + Header + content area
          <DashboardPageLayout>       ← Optional structured wrapper
            {page content}
```

### Layout Types

| Layout | File | Purpose |
|---|---|---|
| Root Layout | `src/app/layout.tsx` | Fonts, providers, `<html>`/`<body>` |
| DashboardShell | `components/templates/DashboardShell.tsx` | Sidebar + header + `md:grid-cols-[260px_1fr]` grid |
| DashboardPageLayout | `components/templates/DashboardPageLayout.tsx` | Adds page header (title, description, action buttons) |
| LandingShell | `components/templates/LandingShell.tsx` | Public nav + footer |

### Component Organization

```
components/
├── atoms/           # Smallest: BrandMark, StatusDot, StatusPill, Markdown, HeroKicker
├── molecules/       # Simple: DependencyBanner
├── organisms/       # Complex: DashboardSidebar, UserMenu, OrgSwitcher, LandingHero, TaskBoard
├── templates/       # Shells: DashboardShell, DashboardPageLayout, LandingShell
├── ui/              # Primitives: button, input, dialog, popover, select, tabs, command, badge, card
├── providers/       # AuthProvider, QueryProvider
├── auth/            # AdminOnlyNotice, SignedOutPanel
├── boards/          # BoardsTable
├── agents/          # AgentsTable
├── activity/        # ActivityFeed
```

---

## 4. Authentication

### Two Modes

Controlled by `NEXT_PUBLIC_AUTH_MODE` env var:

| Value | Behavior |
|---|---|
| `"clerk"` | Uses Clerk for auth. Requires `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`. Clerk middleware protects routes. |
| `"local"` | Uses sessionStorage-based token. No middleware. User enters API token via `LocalAuthLogin` component. |

### Key Files

| File | Purpose |
|---|---|
| `src/auth/mode.ts` | `AuthMode` enum |
| `src/auth/clerk.tsx` | Central facade: wraps Clerk hooks with local-mode fallbacks |
| `src/auth/localAuth.ts` | SessionStorage token persistence |
| `src/auth/redirects.ts` | Safe redirect URL resolution (prevents open redirects) |
| `src/proxy.ts` | Next.js middleware: Clerk middleware or no-op |
| `src/components/providers/AuthProvider.tsx` | Root provider — decides Clerk vs local mode |
| `src/components/organisms/LocalAuthLogin.tsx` | Token input UI for local mode |

### Import Pattern

Use the auth facade instead of Clerk directly:

```tsx
import {
  useAuth, useUser, SignedIn, SignedOut,
  SignInButton, SignOutButton,
} from "@/auth/clerk";
```

### Org-Level Auth

```tsx
import { useOrganizationMembership } from "@/lib/use-organization-membership";

function MyComponent() {
  const { isAdmin, isLoading } = useOrganizationMembership();
  if (!isAdmin) return <AdminOnlyNotice />;
  // ... admin-only content
}
```

### Flow

1. Root layout mounts `AuthProvider`
2. `AuthProvider` checks `NEXT_PUBLIC_AUTH_MODE`:
   - **Local mode**: no token → shows `LocalAuthLogin`; validates token against `/api/v1/users/me`, stores in `sessionStorage`
   - **Clerk mode**: wraps in `<ClerkProvider>`
3. Middleware (`proxy.ts`): Clerk middleware protects routes in Clerk mode; no-op in local mode
4. All pages use the `@/auth/clerk` facade

---

## 5. API Client

### How It Works

1. **FastAPI** backend auto-generates OpenAPI spec at `/openapi.json`
2. **Orval** reads the spec and generates typed React Query hooks
3. Hooks use a **custom fetch wrapper** (`src/api/mutator.ts`) that handles auth headers and error parsing

### Key Files

| File | Purpose |
|---|---|
| `src/api/mutator.ts` | `customFetch<T>()` — the actual HTTP call function |
| `src/lib/api-base.ts` | Resolves base URL (`NEXT_PUBLIC_API_URL` or `<host>:8000`) |
| `src/api/generated/` | 25 auto-generated API modules (one per FastAPI tag) |
| `orval.config.ts` | Codegen configuration |

### The `customFetch` Wrapper

- Auto-sets `Content-Type: application/json`
- Attaches `Authorization` header:
  - **Local mode**: reads token from `sessionStorage`
  - **Clerk mode**: calls `window.Clerk.session.getToken()`
- Parses JSON responses
- Throws `ApiError` on non-ok status (includes `status`, `message`, `data`)

### Usage Pattern

```tsx
import { useListBoardsApiV1BoardsGet } from "@/api/generated/boards/boards";
import type { listBoardsApiV1BoardsGetResponse } from "@/api/generated/boards/boards";
import { ApiError } from "@/api/mutator";

function BoardList() {
  const { data, isLoading, error } = useListBoardsApiV1BoardsGet<
    listBoardsApiV1BoardsGetResponse,
    ApiError
  >(
    { limit: 200 },
    {
      query: {
        enabled: Boolean(isSignedIn),
        refetchInterval: 30_000,    // Poll every 30s
      },
    },
  );
}
```

### Mutation Pattern

```tsx
import { useCreateBoardApiV1BoardsPost } from "@/api/generated/boards/boards";

const createBoard = useCreateBoardApiV1BoardsPost({
  mutation: {
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["/api/v1/boards"] }),
  },
});
```

### Streaming (SSE)

Used in the activity page for real-time updates:

```tsx
const streamResult = await streamTasksApiV1BoardsBoardIdTasksStreamGet(
  boardId, { since },
  { headers: { Accept: "text/event-stream" }, signal: abortController.signal }
);
const response = streamResult.data as Response;
const reader = response.body!.getReader();
// Read chunks with exponential backoff reconnection
```

---

## 6. Theming

### Approach

Light-mode only. CSS custom properties + Tailwind utility classes. No dark mode.

### CSS Variables (defined in `src/app/globals.css`)

```css
:root {
  --bg: #f8fafc;
  --surface: #ffffff;
  --surface-muted: #f1f5f9;
  --surface-strong: #e2e8f0;
  --border: #e2e8f0;
  --border-strong: #cbd5e1;
  --text: #0f172a;
  --text-muted: #64748b;
  --text-quiet: #94a3b8;
  --accent: #2563eb;
  --accent-strong: #1d4ed8;
  --accent-soft: rgba(37, 99, 235, 0.12);
  --success: #16a34a;
  --warning: #d97706;
  --danger: #dc2626;
  --shadow-panel: ...;
  --shadow-card: ...;
}
```

### Custom Utility Classes

Defined in `globals.css` via `@layer utilities`:

```
bg-app          → background: var(--bg)
text-strong     → color: var(--text)
text-muted      → color: var(--text-muted)
text-quiet      → color: var(--text-quiet)
surface-card    → background: var(--surface); border + shadow
surface-panel   → background: var(--surface); border-radius + shadow
surface-muted   → background: var(--surface-muted)
```

### `cn()` Utility

Located at `src/lib/utils.ts`. Merges Tailwind classes without conflicts:

```tsx
import { cn } from "@/lib/utils";
<button className={cn("px-4 py-2", isActive && "bg-blue-600")} />
```

### Tailwind Config

- Font families via CSS variables: `--font-heading` (Sora), `--font-body` (IBM Plex Sans), `--font-display` (DM Serif Display)
- Plugin: `tailwindcss-animate`
- `darkMode: ["class"]` exists but never used

### Landing Page

Uses a completely separate class-based system under `.landing-enterprise` with its own CSS variables (`--primary-navy`, `--accent-gold`, `--accent-teal`, etc.).

---

## 7. Adding a New Page

### Step-by-step

**1. Create the route directory**

```
frontend/src/app/my-new-page/page.tsx
```

For dynamic routes:

```
frontend/src/app/my-new-page/[slug]/page.tsx
```

**2. Write the page component**

```tsx
import { SignedIn, SignedOut, useAuth } from "@/auth/clerk";
import { DashboardPageLayout } from "@/components/templates/DashboardPageLayout";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";  // For list pages

export default function MyNewPage() {
  const { isSignedIn } = useAuth();

  return (
    <SignedIn>
      <DashboardPageLayout
        heading="My New Page"
        description="A description of this page."
        actions={<ActionButton />}
      >
        {/* Page content */}
      </DashboardPageLayout>
    </SignedIn>
  );
}
```

**3. If the page needs data, use a generated React Query hook**

```tsx
import { useListFooApiV1FooGet } from "@/api/generated/foo/foo";
```

**4. For admin-only pages, gate with `useOrganizationMembership`**

```tsx
import { useOrganizationMembership } from "@/lib/use-organization-membership";
import { AdminOnlyNotice } from "@/components/auth/AdminOnlyNotice";
```

**5. If the page is public, wrap in `<SignedOut>` or skip auth gating**

**6. If the page needs a sidebar link, add it in `DashboardSidebar`**

DashboardSidebar is at `src/components/organisms/DashboardSidebar.tsx`. Add a nav item following the existing pattern.

---

## 8. Adding a New API Endpoint

### Backend (FastAPI)

**1. Add the route in `backend/app/api/`**

```python
# backend/app/api/foo.py
from fastapi import APIRouter, Depends
from app.schemas.foo import Foo, FooCreate
from app.services import foo as foo_service

router = APIRouter(prefix="/api/v1/foo", tags=["foo"])

@router.get("/")
def list_foo():
    return foo_service.list_all()

@router.post("/")
def create_foo(data: FooCreate):
    return foo_service.create(data)
```

**2. Register the router in `backend/app/main.py`**

```python
from app.api import foo
app.include_router(foo.router)
```

**3. Add a Pydantic schema in `backend/app/schemas/`**

```python
# backend/app/schemas/foo.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class Foo(BaseModel):
    id: UUID
    name: str
    created_at: datetime

class FooCreate(BaseModel):
    name: str
```

**4. Add a SQLAlchemy model in `backend/app/models/`**

```python
# backend/app/models/foo.py
from sqlalchemy import Column, String
from app.models.base import Base

class FooModel(Base):
    __tablename__ = "foo"
    name = Column(String, nullable=False)
```

**5. Add business logic in `backend/app/services/`**

```python
# backend/app/services/foo.py
from app.models.foo import FooModel
from app.db import SessionLocal

def list_all():
    with SessionLocal() as db:
        return db.query(FooModel).all()
```

### Frontend (API Client Regeneration)

**6. Regenerate the API client**

```bash
# Ensure the backend is running at http://127.0.0.1:8000
cd frontend
npx orval  # Reads openapi.json and regenerates src/api/generated/
```

**7. Use the generated hook**

```tsx
import { useListFooApiV1FooGet } from "@/api/generated/foo/foo";
```

### Without Backend Running (Using a Local Spec)

Override the Orval input:

```bash
ORVAL_INPUT=../backend/openapi.json npx orval
```

---

## Quick Reference

| Task | Command / File |
|---|---|
| Dev server | `cd frontend && npm run dev` |
| Regenerate API client | `cd frontend && npx orval` |
| Run tests | `cd frontend && npm test` |
| Lint | `cd frontend && npm run lint` |
| Typecheck | `cd frontend && npm run typecheck` |
| CSS variable reference | `frontend/src/app/globals.css` |
| Auth facade | `frontend/src/auth/clerk.tsx` |
| API base URL | `frontend/src/lib/api-base.ts` |
| Custom fetch | `frontend/src/api/mutator.ts` |
| Orval config | `frontend/orval.config.ts` |
| Org membership | `frontend/src/lib/use-organization-membership.ts` |
| URL sorting hook | `frontend/src/lib/use-url-sorting.ts` |
| Optimistic delete | `frontend/src/lib/list-delete.ts` |
