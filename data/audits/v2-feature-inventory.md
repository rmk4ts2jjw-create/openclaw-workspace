# mc-v2 Feature Inventory

**Audit Date:** 2026-06-20
**Source:** `/Users/spacemonkey/.openclaw/workspace/mc-v2`
**Existing Dashboard:** `/Users/spacemonkey/.openclaw/workspace/mission-control-dashboard`

---

## Classification Key

| Label | Meaning |
|-------|---------|
| **KEEP AS-IS** | Already complete and correct — use directly |
| **KEEP BUT RESTYLE** | Functionally correct, needs visual/theme alignment |
| **MERGE WITH OUR VERSION** | Has parts we want AND parts we should replace — combine |
| **REPLACE WITH OUR VERSION** | Our existing version is better; skip mc-v2 version |

---

## 1. PAGES / ROUTES

### 1.1 Landing & Auth

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/` | `src/app/page.tsx` | Landing page with hero and shell | **REPLACE** | Our existing dashboard index is the real home — mc-v2's landing is unused (already a shell behind `/dashboard`) |
| `/sign-in` | `src/app/sign-in/[[...rest]]/page.tsx` | Clerk/Local auth sign-in | **KEEP AS-IS** | Auth is a prerequisite; mc-v2 handles dual-mode (Clerk + local) well |
| `/invite` | `src/app/invite/page.tsx` | Accept org invite by token | **KEEP AS-IS** | Not in existing dashboard; new capability |
| `/onboarding` | `src/app/onboarding/page.tsx` | First-time user onboarding (name, timezone) | **KEEP BUT RESTYLE** | Needs to match our theme, but the flow is right |

### 1.2 Dashboard

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/dashboard` | `src/app/dashboard/page.tsx` | Main dashboard: metrics, workload, throughput, gateway health, sessions, pending approvals, recent activity | **MERGE** | mc-v2 has rich metrics & data from backend; our existing dashboard has the Agent Office with pixel sprites and station ambience. Best of both: use mc-v2 metrics data layer, our visual presentation |

### 1.3 Agents

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/agents` | `src/app/agents/page.tsx` | Agent list with table, sorting, delete | **KEEP BUT RESTYLE** | Data model matches; restyle to our theme |
| `/agents/new` | `src/app/agents/new/page.tsx` | Create agent form (name, board, emoji, heartbeat config, identity profile) | **KEEP BUT RESTYLE** | Full form; matches our agent model |
| `/agents/[agentId]` | `src/app/agents/[agentId]/page.tsx` | Agent detail: overview, health, activity events | **MERGE** | mc-v2 has clean data display; our existing Agent Office has richer visual context (rooms, sprites). Combine data + visuals |
| `/agents/[agentId]/edit` | `src/app/agents/[agentId]/edit/page.tsx` | Edit agent form | **KEEP BUT RESTYLE** | |

### 1.4 Boards

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/boards` | `src/app/boards/page.tsx` | Board list with table, sorting, delete | **KEEP BUT RESTYLE** | |
| `/boards/new` | `src/app/boards/new/page.tsx` | Create board form (name, gateway, group, description) | **KEEP BUT RESTYLE** | |
| `/boards/[boardId]` | `src/app/boards/[boardId]/page.tsx` | Board detail: task board (kanban), live feed, chat, approvals, agents list, task CRUD, SSE streams | **MERGE** | Core feature. mc-v2 has real kanban + SSE + task management. Our existing has tabs-style task views. Use mc-v2's real-time task board but restyle the cards |
| `/boards/[boardId]/edit` | `src/app/boards/[boardId]/edit/page.tsx` | Board settings: name, gateway, type (goal/general), rules (5 toggles), webhooks CRUD, onboarding | **KEEP BUT RESTYLE** | Very rich settings page |
| `/boards/[boardId]/approvals` | `src/app/boards/[boardId]/approvals/page.tsx` | Board-scoped approvals panel | **KEEP BUT RESTYLE** | |
| `/boards/[boardId]/webhooks/[webhookId]/payloads` | `src/app/boards/[boardId]/webhooks/[webhookId]/payloads/page.tsx` | Webhook payload history viewer | **KEEP AS-IS** | Not in our existing dashboard; new feature |

### 1.5 Gateways

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/gateways` | `src/app/gateways/page.tsx` | Gateway list with table, sorting, delete | **KEEP BUT RESTYLE** | |
| `/gateways/new` | `src/app/gateways/new/page.tsx` | Create gateway form (name, URL, token, device pairing, workspace root, TLS) | **KEEP AS-IS** | Properly validates and tests connection |
| `/gateways/[gatewayId]` | `src/app/gateways/[gatewayId]/page.tsx` | Gateway detail: connection info, runtime, status, agents table | **KEEP BUT RESTYLE** | |
| `/gateways/[gatewayId]/edit` | `src/app/gateways/[gatewayId]/edit/page.tsx` | Edit gateway form | **KEEP BUT RESTYLE** | |

### 1.6 Board Groups

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/board-groups` | `src/app/board-groups/page.tsx` | Board group list with table, sorting, delete | **KEEP AS-IS** | Not in our existing dashboard |
| `/board-groups/new` | `src/app/board-groups/new/page.tsx` | Create board group with member boards | **KEEP AS-IS** | |
| `/board-groups/[groupId]` | `src/app/board-groups/[groupId]/page.tsx` | Board group detail: heartbeat, chat, memory, boards, agents | **KEEP AS-IS** | |
| `/board-groups/[groupId]/edit` | `src/app/board-groups/[groupId]/edit/page.tsx` | Edit board group + manage member boards | **KEEP AS-IS** | |

### 1.7 Skills

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/skills` | `src/app/skills/page.tsx` | Redirects to `/skills/marketplace` | **KEEP AS-IS** | |
| `/skills/marketplace` | `src/app/skills/marketplace/page.tsx` | Skill marketplace: search, filter, sort, install/uninstall, version picker | **KEEP AS-IS** | Not in existing dashboard |
| `/skills/marketplace/new` | `src/app/skills/marketplace/new/page.tsx` | Submit new marketplace skill | **KEEP AS-IS** | |
| `/skills/marketplace/[skillId]/edit` | `src/app/skills/marketplace/[skillId]/edit/page.tsx` | Edit marketplace skill | **KEEP AS-IS** | |
| `/skills/packs` | `src/app/skills/packs/page.tsx` | Skill packs: sync from git, delete, sync all | **KEEP AS-IS** | |
| `/skills/packs/new` | `src/app/skills/packs/new/page.tsx` | Create skill pack from git URL | **KEEP AS-IS** | |
| `/skills/packs/[packId]/edit` | `src/app/skills/packs/[packId]/edit/page.tsx` | Edit skill pack | **KEEP AS-IS** | |

### 1.8 Other Pages

| Route | mc-v2 File | Description | Classification | Notes |
|-------|-----------|-------------|----------------|-------|
| `/activity` | `src/app/activity/page.tsx` | Full activity feed with live SSE streaming, filtering, search | **MERGE** | mc-v2 has live-streaming activity; our existing has EventLog + RecentEventsPanel. Use mc-v2 data pipeline with our visual treatment |
| `/approvals` | `src/app/approvals/page.tsx` | Global approvals dashboard across all boards | **KEEP AS-IS** | Not in existing dashboard |
| `/settings` | `src/app/settings/page.tsx` | User settings: profile name, timezone, delete account | **KEEP BUT RESTYLE** | |
| `/organization` | `src/app/organization/page.tsx` | Org management: members, invites, board access control | **KEEP AS-IS** | Not in existing dashboard; full RBAC |
| `/tags` | `src/app/tags/page.tsx` | Tag management: list, sort, delete | **KEEP BUT RESTYLE** | |
| `/tags/add` | `src/app/tags/add/page.tsx` | Create tag form | **KEEP BUT RESTYLE** | |
| `/tags/[tagId]/edit` | `src/app/tags/[tagId]/edit/page.tsx` | Edit tag form | **KEEP BUT RESTYLE** | |
| `/custom-fields` | `src/app/custom-fields/page.tsx` | Custom field definitions: list, sort, delete | **KEEP AS-IS** | Not in existing dashboard |
| `/custom-fields/new` | `src/app/custom-fields/new/page.tsx` | Create custom field form | **KEEP AS-IS** | |
| `/custom-fields/[fieldId]/edit` | `src/app/custom-fields/[fieldId]/edit/page.tsx` | Edit custom field form | **KEEP AS-IS** | |

---

## 2. COMPONENTS

### 2.1 Templates (page layouts)

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `DashboardShell` | `templates/DashboardShell.tsx` | **KEEP BUT RESTYLE** | Core layout with sidebar |
| `DashboardPageLayout` | `templates/DashboardPageLayout.tsx` | **KEEP BUT RESTYLE** | Higher-level page wrapper with title, description, actions |
| `LandingShell` | `templates/LandingShell.tsx` | **REPLACE** | We have our own landing |

### 2.2 Organisms (complex composites)

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `DashboardSidebar` | `organisms/DashboardSidebar.tsx` | **KEEP BUT RESTYLE** | Main nav sidebar |
| `LandingHero` | `organisms/LandingHero.tsx` | **REPLACE** | Our own landing is better |
| `TaskBoard` | `organisms/TaskBoard.tsx` | **MERGE** | Kanban board with drag-and-drop; real-time. Keep functionality, restyle cards to match our aesthetic |
| `LocalAuthLogin` | `organisms/LocalAuthLogin.tsx` | **KEEP AS-IS** | Local auth mode |
| `BoardSidebarStats` | *(likely in layouts)* | **KEEP BUT RESTYLE** | |

### 2.3 Board-specific Components

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `BoardChatComposer` | `BoardChatComposer.tsx` | **KEEP AS-IS** | Chat with agents on board detail |
| `BoardApprovalsPanel` | `BoardApprovalsPanel.tsx` | **KEEP AS-IS** | Board approvals view |
| `BoardGoalPanel` | `BoardGoalPanel.tsx` | **KEEP AS-IS** | Goal board panel |
| `BoardOnboardingChat` | `BoardOnboardingChat.tsx` | **KEEP AS-IS** | Onboarding wizard for new boards |
| `DependencyBanner` | `molecules/DependencyBanner.tsx` | **KEEP AS-IS** | Task dependency visual |

### 2.4 Tables

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `AgentsTable` | `agents/AgentsTable.tsx` | **KEEP BUT RESTYLE** | |
| `BoardsTable` | `boards/BoardsTable.tsx` | **KEEP BUT RESTYLE** | |
| `GatewaysTable` | `gateways/GatewaysTable.tsx` | **KEEP BUT RESTYLE** | |
| `BoardGroupsTable` | `board-groups/BoardGroupsTable.tsx` | **KEEP BUT RESTYLE** | |
| `TagsTable` | `tags/TagsTable.tsx` | **KEEP BUT RESTYLE** | |
| `CustomFieldsTable` | `custom-fields/CustomFieldsTable.tsx` | **KEEP BUT RESTYLE** | |
| `MarketplaceSkillsTable` | `skills/MarketplaceSkillsTable.tsx` | **KEEP BUT RESTYLE** | |
| `SkillPacksTable` | `skills/SkillPacksTable.tsx` | **KEEP BUT RESTYLE** | |
| `MembersInvitesTable` | `organization/MembersInvitesTable.tsx` | **KEEP BUT RESTYLE** | |
| `BoardAccessTable` | `organization/BoardAccessTable.tsx` | **KEEP BUT RESTYLE** | |

### 2.5 Forms

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `GatewayForm` | `gateways/GatewayForm.tsx` | **KEEP AS-IS** | Connection testing, validation |
| `TagForm` | `tags/TagForm.tsx` | **KEEP BUT RESTYLE** | |
| `CustomFieldForm` | `custom-fields/CustomFieldForm.tsx` | **KEEP AS-IS** | Complex form with field type selection |
| `SkillInstallDialog` | `skills/SkillInstallDialog.tsx` | **KEEP AS-IS** | |

### 2.6 Activity

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `ActivityFeed` | `activity/ActivityFeed.tsx` | **MERGE** | mc-v2 has live updates; merge with our EventLog visual style |
| `LiveFeedCard` | (inline in board detail page) | **KEEP AS-IS** | |

### 2.7 Atoms (UI primitives)

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `StatusPill` | `atoms/StatusPill.tsx` | **KEEP BUT RESTYLE** | |
| `StatusDot` | `atoms/StatusDot.tsx` | **KEEP BUT RESTYLE** | |
| `Markdown` | `atoms/Markdown.tsx` | **MERGE** | mc-v2 has its own; we have our own. pick one |
| `BrandMark` | `atoms/BrandMark.tsx` | **REPLACE** | Use our brand |

### 2.8 Auth Components

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `AuthProvider` | `providers/AuthProvider.tsx` | **KEEP AS-IS** | Dual-mode Clerk + local |
| `QueryProvider` | `providers/QueryProvider.tsx` | **KEEP AS-IS** | TanStack Query setup |
| `SignedOutPanel` | `auth/SignedOutPanel.tsx` | **KEEP BUT RESTYLE** | |

### 2.9 UI Kit (shadcn-style)

| Component | File | Classification | Notes |
|-----------|------|----------------|-------|
| `button` | `ui/button.tsx` | **REPLACE** | Use our button component |
| `input` | `ui/input.tsx` | **REPLACE** | Use our input |
| `textarea` | `ui/textarea.tsx` | **REPLACE** | Use ours |
| `select` | `ui/select.tsx` | **REPLACE** | Use ours |
| `dialog` | `ui/dialog.tsx` | **REPLACE** | Use ours |
| `badge` | `ui/badge.tsx` | **REPLACE** | Use ours |
| `searchable-select` | `ui/searchable-select.tsx` | **KEEP AS-IS** | Custom, good implementation |
| `dropdown-select` | `ui/dropdown-select.tsx` | **REPLACE** | Use ours |
| `confirm-action-dialog` | `ui/confirm-action-dialog.tsx` | **KEEP BUT RESTYLE** | Reusable confirm |
| `global-loader` | `ui/global-loader.tsx` | **KEEP BUT RESTYLE** | |

---

## 3. BACKEND API ENDPOINTS

### 3.1 Auth & Users

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| POST | `/api/v1/auth/bootstrap` | Resolve caller identity from token | **KEEP AS-IS** |
| GET | `/api/v1/users/me` | Get current user profile | **KEEP AS-IS** |
| PATCH | `/api/v1/users/me` | Update current user profile | **KEEP AS-IS** |
| DELETE | `/api/v1/users/me` | Delete current user + org data | **KEEP AS-IS** |

### 3.2 Agents

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/agents` | List agents | **KEEP AS-IS** |
| GET | `/api/v1/agents/stream` | SSE stream of agent changes | **KEEP AS-IS** |
| POST | `/api/v1/agents` | Create agent | **KEEP AS-IS** |
| GET | `/api/v1/agents/{agent_id}` | Get agent detail | **KEEP AS-IS** |
| PATCH | `/api/v1/agents/{agent_id}` | Update agent | **KEEP AS-IS** |
| DELETE | `/api/v1/agents/{agent_id}` | Delete agent | **KEEP AS-IS** |
| POST | `/api/v1/agents/{agent_id}/heartbeat` | Agent heartbeat endpoint | **KEEP AS-IS** |
| POST | `/api/v1/agents/{agent_id}/nudge` | Nudge agent | **KEEP AS-IS** |
| POST | `/api/v1/agents/{agent_id}/command` | Send command to agent | **KEEP AS-IS** |

### 3.3 Boards

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/boards` | List boards | **KEEP AS-IS** |
| POST | `/api/v1/boards` | Create board | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}` | Get board | **KEEP AS-IS** |
| PATCH | `/api/v1/boards/{board_id}` | Update board | **KEEP AS-IS** |
| DELETE | `/api/v1/boards/{board_id}` | Delete board | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/snapshot` | Full board snapshot (tasks, agents, approvals, chat) | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/group-snapshot` | Cross-board group snapshot | **KEEP AS-IS** |

### 3.4 Tasks

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/boards/{board_id}/tasks` | List tasks on board | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/tasks` | Create task | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/tasks/{task_id}` | Get task | **KEEP AS-IS** |
| PATCH | `/api/v1/boards/{board_id}/tasks/{task_id}` | Update task (status, priority, tags, custom fields) | **KEEP AS-IS** |
| DELETE | `/api/v1/boards/{board_id}/tasks/{task_id}` | Delete task | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/tasks/stream` | SSE stream of task changes | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/tasks/{task_id}/comments` | List task comments | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/tasks/{task_id}/comments` | Create task comment | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/tasks/{task_id}/dependencies` | Manage task dependencies | **KEEP AS-IS** |

### 3.5 Approvals

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/boards/{board_id}/approvals` | List approvals | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/approvals` | Create approval | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/approvals/stream` | SSE stream of approval changes | **KEEP AS-IS** |
| PATCH | `/api/v1/boards/{board_id}/approvals/{approval_id}` | Update approval (approve/reject) | **KEEP AS-IS** |

### 3.6 Board Memory & Chat

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/boards/{board_id}/memory` | List board memory | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/memory` | Create board memory entry | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/memory/stream` | SSE stream of board memory | **KEEP AS-IS** |

### 3.7 Board Onboarding

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| POST | `/api/v1/boards/{board_id}/onboarding/start` | Start onboarding session | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/onboarding/answer` | Submit onboarding answer | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/onboarding/confirm` | Confirm onboarding (set goal/config) | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/onboarding/state` | Get onboarding state | **KEEP AS-IS** |

### 3.8 Board Webhooks

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/boards/{board_id}/webhooks` | List webhooks | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/webhooks` | Create webhook | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/webhooks/{webhook_id}` | Get webhook | **KEEP AS-IS** |
| PATCH | `/api/v1/boards/{board_id}/webhooks/{webhook_id}` | Update webhook | **KEEP AS-IS** |
| DELETE | `/api/v1/boards/{board_id}/webhooks/{webhook_id}` | Delete webhook | **KEEP AS-IS** |
| POST | `/api/v1/boards/{board_id}/webhooks/{webhook_id}/ingest` | Inbound webhook payload | **KEEP AS-IS** |
| GET | `/api/v1/boards/{board_id}/webhooks/{webhook_id}/payloads` | List payload history | **KEEP AS-IS** |

### 3.9 Gateways

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/gateways` | List gateways | **KEEP AS-IS** |
| POST | `/api/v1/gateways` | Create gateway | **KEEP AS-IS** |
| GET | `/api/v1/gateways/{gateway_id}` | Get gateway detail | **KEEP AS-IS** |
| PATCH | `/api/v1/gateways/{gateway_id}` | Update gateway | **KEEP AS-IS** |
| DELETE | `/api/v1/gateways/{gateway_id}` | Delete gateway | **KEEP AS-IS** |
| GET | `/api/v1/gateways/status` | Check gateway connection status | **KEEP AS-IS** |
| GET | `/api/v1/gateways/sessions` | List gateway sessions | **KEEP AS-IS** |
| GET | `/api/v1/gateways/sessions/{session_key}` | Get session detail | **KEEP AS-IS** |
| POST | `/api/v1/gateways/sessions/{session_key}/message` | Send message to session | **KEEP AS-IS** |
| GET | `/api/v1/gateways/sessions/{session_key}/history` | Get session history | **KEEP AS-IS** |
| POST | `/api/v1/gateways/{gateway_id}/templates-sync` | Sync gateway templates | **KEEP AS-IS** |
| POST | `/api/v1/gateways/{gateway_id}/souls-sync` | Sync gateway souls | **KEEP AS-IS** |
| GET | `/api/v1/gateways/commands` | List available gateway commands | **KEEP AS-IS** |

### 3.10 Board Groups

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/board-groups` | List board groups | **KEEP AS-IS** |
| POST | `/api/v1/board-groups` | Create board group | **KEEP AS-IS** |
| GET | `/api/v1/board-groups/{group_id}` | Get board group | **KEEP AS-IS** |
| PATCH | `/api/v1/board-groups/{group_id}` | Update board group | **KEEP AS-IS** |
| DELETE | `/api/v1/board-groups/{group_id}` | Delete board group | **KEEP AS-IS** |
| GET | `/api/v1/board-groups/{group_id}/snapshot` | Get board group snapshot | **KEEP AS-IS** |
| POST | `/api/v1/board-groups/{group_id}/heartbeat` | Apply heartbeat to group boards | **KEEP AS-IS** |

### 3.11 Board Group Memory

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/board-groups/{group_id}/memory` | List group memory | **KEEP AS-IS** |
| POST | `/api/v1/board-groups/{group_id}/memory` | Create group memory | **KEEP AS-IS** |
| GET | `/api/v1/board-groups/{group_id}/memory/stream` | SSE group memory stream | **KEEP AS-IS** |

### 3.12 Organizations

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/organizations/me` | Get my organization | **KEEP AS-IS** |
| PATCH | `/api/v1/organizations/me` | Update organization | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/member` | Get my membership | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/list` | List my organizations | **KEEP AS-IS** |
| POST | `/api/v1/organizations/me/active` | Set active organization | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/members` | List members | **KEEP AS-IS** |
| PATCH | `/api/v1/organizations/me/members/{member_id}` | Update member role | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/members/{member_id}` | Get member detail | **KEEP AS-IS** |
| PUT | `/api/v1/organizations/me/members/{member_id}/access` | Update member board access | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/invites` | List invites | **KEEP AS-IS** |
| POST | `/api/v1/organizations/me/invites` | Create invite | **KEEP AS-IS** |
| DELETE | `/api/v1/organizations/me/invites/{invite_id}` | Revoke invite | **KEEP AS-IS** |
| POST | `/api/v1/organizations/invites/accept` | Accept invite by token | **KEEP AS-IS** |

### 3.13 Tags

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/tags` | List tags | **KEEP AS-IS** |
| POST | `/api/v1/tags` | Create tag | **KEEP AS-IS** |
| GET | `/api/v1/tags/{tag_id}` | Get tag | **KEEP AS-IS** |
| PATCH | `/api/v1/tags/{tag_id}` | Update tag | **KEEP AS-IS** |
| DELETE | `/api/v1/tags/{tag_id}` | Delete tag | **KEEP AS-IS** |

### 3.14 Custom Fields

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/organizations/me/custom-fields` | List custom field definitions | **KEEP AS-IS** |
| POST | `/api/v1/organizations/me/custom-fields` | Create custom field definition | **KEEP AS-IS** |
| GET | `/api/v1/organizations/me/custom-fields/{definition_id}` | Get definition | **KEEP AS-IS** |
| PATCH | `/api/v1/organizations/me/custom-fields/{definition_id}` | Update definition | **KEEP AS-IS** |
| DELETE | `/api/v1/organizations/me/custom-fields/{definition_id}` | Delete definition | **KEEP AS-IS** |

### 3.15 Skills Marketplace

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/skills/marketplace` | List marketplace skills | **KEEP AS-IS** |
| POST | `/api/v1/skills/marketplace` | Create marketplace skill | **KEEP AS-IS** |
| GET | `/api/v1/skills/marketplace/{skill_id}` | Get skill detail | **KEEP AS-IS** |
| PATCH | `/api/v1/skills/marketplace/{skill_id}` | Update skill | **KEEP AS-IS** |
| POST | `/api/v1/skills/marketplace/{skill_id}/install` | Install skill to gateway | **KEEP AS-IS** |
| POST | `/api/v1/skills/marketplace/{skill_id}/uninstall` | Uninstall skill from gateway | **KEEP AS-IS** |

### 3.16 Skill Packs

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/skills/packs` | List skill packs | **KEEP AS-IS** |
| POST | `/api/v1/skills/packs` | Create skill pack from git | **KEEP AS-IS** |
| GET | `/api/v1/skills/packs/{pack_id}` | Get skill pack | **KEEP AS-IS** |
| PATCH | `/api/v1/skills/packs/{pack_id}` | Update skill pack | **KEEP AS-IS** |
| DELETE | `/api/v1/skills/packs/{pack_id}` | Delete skill pack | **KEEP AS-IS** |
| POST | `/api/v1/skills/packs/{pack_id}/sync` | Sync pack from git | **KEEP AS-IS** |

### 3.17 Activity

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/activity` | List activity events | **KEEP AS-IS** |
| GET | `/api/v1/activity/stream` | SSE stream of activity | **KEEP AS-IS** |
| GET | `/api/v1/activity/task-comments/stream` | SSE stream of task comments | **KEEP AS-IS** |

### 3.18 Metrics

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/metrics/dashboard` | Dashboard metrics (kpis, throughput, wip, pending approvals) | **KEEP AS-IS** |
| GET | `/api/v1/metrics/dashboard/activity` | Activity-based metrics | **KEEP AS-IS** |

### 3.19 Souls Directory

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/api/v1/souls-directory/search` | Search souls directory | **KEEP AS-IS** |
| GET | `/api/v1/souls-directory/{handle}/{slug}` | Get markdown entry | **KEEP AS-IS** |

### 3.20 Health

| Method | Path | Description | Classification |
|--------|------|-------------|----------------|
| GET | `/health` | Liveness probe | **KEEP AS-IS** |
| GET | `/healthz` | Health check | **KEEP AS-IS** |
| GET | `/readyz` | Readiness probe | **KEEP AS-IS** |
| GET | `/api/v1/agent/health` | Agent health check | **KEEP AS-IS** |

---

## 4. DATA MODELS (Database)

| Model | File | Description | Classification |
|-------|------|-------------|----------------|
| `User` | `models/users.py` | User profiles (Clerk + local) | **KEEP AS-IS** |
| `Organization` | `models/organizations.py` | Organizations/tenants | **KEEP AS-IS** |
| `OrganizationMember` | `models/organization_members.py` | User membership in orgs | **KEEP AS-IS** |
| `OrganizationInvite` | `models/organization_invites.py` | Pending invites | **KEEP AS-IS** |
| `OrganizationBoardAccess` | `models/organization_board_access.py` | Per-member board access | **KEEP AS-IS** |
| `Gateway` | `models/gateways.py` | OpenClaw gateway connections | **KEEP AS-IS** |
| `Board` | `models/boards.py` | Boards (task containers) | **KEEP AS-IS** |
| `BoardGroup` | `models/board_groups.py` | Board grouping | **KEEP AS-IS** |
| `BoardMemory` | `models/board_memory.py` | Board chat/memory entries | **KEEP AS-IS** |
| `BoardGroupMemory` | `models/board_group_memory.py` | Cross-board group memory | **KEEP AS-IS** |
| `BoardOnboardingSession` | `models/board_onboarding.py` | Board setup sessions | **KEEP AS-IS** |
| `BoardWebhook` | `models/board_webhooks.py` | Inbound webhook configs | **KEEP AS-IS** |
| `BoardWebhookPayload` | `models/board_webhook_payloads.py` | Webhook payload history | **KEEP AS-IS** |
| `Agent` | `models/agents.py` | AI agents | **KEEP AS-IS** |
| `Task` | `models/tasks.py` | Tasks on boards | **KEEP AS-IS** |
| `TaskDependency` | `models/task_dependencies.py` | Task dependency links | **KEEP AS-IS** |
| `TaskFingerprint` | `models/task_fingerprints.py` | Dedup fingerprints | **KEEP AS-IS** |
| `TaskCustomFieldDefinition` | `models/task_custom_fields.py` | Custom field schemas | **KEEP AS-IS** |
| `TaskCustomFieldValue` | `models/task_custom_fields.py` | Custom field values | **KEEP AS-IS** |
| `BoardTaskCustomField` | `models/task_custom_fields.py` | Board-custom field mapping | **KEEP AS-IS** |
| `Tag` | `models/tags.py` | Organization tags | **KEEP AS-IS** |
| `TagAssignment` | `models/tag_assignments.py` | Task-tag assignments | **KEEP AS-IS** |
| `Approval` | `models/approvals.py` | Approval requests | **KEEP AS-IS** |
| `ApprovalTaskLink` | `models/approval_task_links.py` | Approval-task associations | **KEEP AS-IS** |
| `ActivityEvent` | `models/activity_events.py` | Activity log entries | **KEEP AS-IS** |
| `SkillPack` | `models/skills.py` | Git-based skill packs | **KEEP AS-IS** |
| `MarketplaceSkill` | `models/skills.py` | Marketplace skill definitions | **KEEP AS-IS** |
| `GatewayInstalledSkill` | `models/skills.py` | Gateway-skill installations | **KEEP AS-IS** |
| `TenancyBase` (mixin) | `models/tenancy.py` | Multi-tenant base class | **KEEP AS-IS** |

---

## 5. SERVICES / BUSINESS LOGIC

| Service | File | Description | Classification |
|---------|------|-------------|----------------|
| `GatewayDispatchService` | `services/openclaw/gateway_dispatch.py` | RPC dispatching to OpenClaw gateways | **KEEP AS-IS** |
| `GatewaySessionService` | `services/openclaw/session_service.py` | Session inspection & management | **KEEP AS-IS** |
| `AgentLifecycleService` | `services/openclaw/provisioning_db.py` | Agent CRUD + provisioning flow | **KEEP AS-IS** |
| `GatewayAdminLifecycleService` | `services/openclaw/admin_service.py` | Gateway template sync | **KEEP AS-IS** |
| `BoardOnboardingMessagingService` | `services/openclaw/onboarding_service.py` | Chat-based board setup | **KEEP AS-IS** |
| `GatewayCoordinationService` | `services/openclaw/coordination_service.py` | Lead/main agent coordination | **KEEP AS-IS** |
| `OpenClawAuthorizationPolicy` | `services/openclaw/policies.py` | Agent permission checks | **KEEP AS-IS** |
| `BoardSnapshotService` | `services/board_snapshot.py` | Build full board snapshots | **KEEP AS-IS** |
| `BoardGroupSnapshotService` | `services/board_group_snapshot.py` | Cross-board group snapshots | **KEEP AS-IS** |
| `BoardLifecycleService` | `services/board_lifecycle.py` | Board delete cascade | **KEEP AS-IS** |
| `ActivityLogService` | `services/activity_log.py` | Record activity events | **KEEP AS-IS** |
| `TagService` | `services/tags.py` | Tag assignment management | **KEEP AS-IS** |
| `TaskDependencyService` | `services/task_dependencies.py` | Dependency validation | **KEEP AS-IS** |
| `OrganizationService` | `services/organizations.py` | Org membership, invites, board access | **KEEP AS-IS** |
| `ApprovalTaskLinkService` | `services/approval_task_links.py` | Approval-task linking | **KEEP AS-IS** |
| `MentionsService` | `services/mentions.py` | Agent mention extraction | **KEEP AS-IS** |
| `LeadPolicyService` | `services/lead_policy.py` | Board lead election | **KEEP AS-IS** |
| `SoulsDirectoryService` | `services/souls_directory.py` | Souls markdown directory | **KEEP AS-IS** |
| `AdminAccessService` | `services/admin_access.py` | Admin-only actor guard | **KEEP AS-IS** |
| `QueueWorker` | `services/queue_worker.py` | RQ worker for async jobs | **KEEP AS-IS** |
| Webhook Queue | `services/webhooks/queue.py` | Webhook delivery queue | **KEEP AS-IS** |

---

## 6. UTILITIES / LIBRARIES

### 6.1 Frontend Lib

| File | Description | Classification |
|------|-------------|----------------|
| `lib/api-base.ts` | Base API URL resolution | **KEEP AS-IS** |
| `lib/agent-emoji.ts` | Agent emoji picker options | **KEEP AS-IS** |
| `lib/agent-templates.ts` | Default identity profiles | **KEEP AS-IS** |
| `lib/backoff.ts` | Exponential backoff with jitter | **KEEP AS-IS** |
| `lib/datetime.ts` | Date/time parsing utilities | **KEEP AS-IS** |
| `lib/display-name.ts` | Actor name resolution | **KEEP AS-IS** |
| `lib/formatters.ts` | Timestamp formatters | **MERGE** | Merge with our formatters |
| `lib/gateway-form.ts` | Gateway URL validation + connection check | **KEEP AS-IS** |
| `lib/list-delete.ts` | Optimistic list delete mutation | **KEEP AS-IS** |
| `lib/onboarding.ts` | Onboarding completion check | **KEEP BUT RESTYLE** |
| `lib/skills-source.ts` | Skills source type helpers | **KEEP AS-IS** |
| `lib/timezones.ts` | Supported timezone list | **KEEP BUT RESTYLE** |
| `lib/use-organization-membership.ts` | Hook for admin check | **KEEP AS-IS** |
| `lib/use-url-sorting.ts` | URL-based table sorting | **KEEP AS-IS** |
| `lib/utils.ts` | General utilities (cn) | **MERGE** | Merge with our utils |
| `hooks/usePageActive.ts` | Page visibility hook | **KEEP AS-IS** |

### 6.2 Backend Core

| File | Description | Classification |
|------|-------------|----------------|
| `core/auth.py` | Auth context, Clerk verification, HS256 JWT | **KEEP AS-IS** |
| `core/agent_auth.py` | Agent X-Agent-Token auth | **KEEP AS-IS** |
| `core/agent_tokens.py` | Agent token generation | **KEEP AS-IS** |
| `core/auth_mode.py` | Clerk vs local mode detection | **KEEP AS-IS** |
| `core/config.py` | Settings via pydantic-settings | **KEEP AS-IS** |
| `core/rate_limit.py` | Rate limiter (memory/Redis) | **KEEP AS-IS** |
| `core/rate_limit_backend.py` | Rate limit backend abstraction | **KEEP AS-IS** |
| `core/error_handling.py` | Error handler registration | **KEEP AS-IS** |
| `core/logging.py` | Structured logging config | **KEEP AS-IS** |
| `core/security_headers.py` | Security headers middleware | **KEEP AS-IS** |
| `core/time.py` | UTC time helpers | **KEEP AS-IS** |
| `core/version.py` | App version | **KEEP AS-IS** |
| `core/durations.py` | Duration parsing | **KEEP AS-IS** |
| `core/client_ip.py` | Client IP resolution | **KEEP AS-IS** |

### 6.3 Database Layer

| File | Description | Classification |
|------|-------------|----------------|
| `db/session.py` | SQLModel async session, Alembic integration | **KEEP AS-IS** |
| `db/crud.py` | Generic CRUD helpers (get, save, delete) | **KEEP AS-IS** |
| `db/pagination.py` | Limit/offset pagination | **KEEP AS-IS** |
| `db/query_manager.py` | Query filtering utilities | **KEEP AS-IS** |
| `db/queryset.py` | Fluent query builder | **KEEP AS-IS** |

---

## 7. INFRASTRUCTURE & CONFIG

| File | Description | Classification |
|------|-------------|----------------|
| `compose.yml` | Docker Compose (5 services: db, redis, backend, frontend, worker) | **KEEP AS-IS** |
| `Makefile` | Build system (setup, lint, typecheck, test, coverage, build, docker) | **KEEP AS-IS** |
| `install.sh` | One-command installer (Docker/local modes, systemd) | **KEEP AS-IS** |
| `.github/workflows/ci.yml` | CI pipeline (check, installer matrix, E2E) | **KEEP AS-IS** |
| `install.sh` | Platform detection, external database, systemd | **KEEP AS-IS** |
| `backend/Dockerfile` | FastAPI container | **KEEP AS-IS** |
| `frontend/Dockerfile` | Next.js container | **KEEP AS-IS** |
| `backend/alembic.ini` + `migrations/` | DB migration system | **KEEP AS-IS** |
| `frontend/cypress/` + `cypress.config.ts` | E2E test suite | **KEEP AS-IS** |
| `docs/` (19 files) | Full documentation: arch, deployment, dev, ops, API refs, policy | **KEEP AS-IS** |

---

## 8. SUMMARY STATISTICS

| Category | Total Items | KEEP AS-IS | KEEP BUT RESTYLE | MERGE | REPLACE |
|----------|-------------|-----------|-------------------|-------|---------|
| Pages/Routes | 38 | 17 | 16 | 3 | 2 |
| Components | 40+ | 12 | 16 | 4 | 8 |
| Backend API Endpoints | 75+ | 75 | 0 | 0 | 0 |
| Data Models | 28 | 28 | 0 | 0 | 0 |
| Services | 20 | 20 | 0 | 0 | 0 |
| Libraries/Utils | 25 | 19 | 3 | 2 | 1 |
| Infrastructure | 10 | 10 | 0 | 0 | 0 |
| **TOTAL** | **236+** | **181** | **35** | **9** | **11** |

---

## KEY DECISIONS

### Backend: KEEP ALL AS-IS
The mc-v2 backend is the **source of truth** — it has all the APIs, models, services, and auth we need. Our existing dashboard's backend (`mission-control-dashboard/src/routes/api/`) is minimal (3 endpoints: agent-status, tasks, events). We should drop it and use mc-v2's backend exclusively.

### UI Kit: REPLACE with ours
mc-v2 uses its own shadcn-style components (button, input, select, dialog, badge). We should replace these with our own UI kit to maintain visual consistency.

### Dashboard: MERGE
mc-v2's dashboard has real metrics from the backend. Our existing dashboard has the Agent Office with pixel sprites, rooms, and station ambience. The best result combines: use mc-v2 metrics data + navigation, embed our Agent Office visually.

### Board Detail: MERGE
mc-v2 has a real kanban board with SSE streaming, task CRUD, etc. Our existing board view is text-based. Use mc-v2's TaskBoard but restyle the cards to match our aesthetic.

### Docs/Infra: KEEP AS-IS
The Docker Compose, Makefile, CI, installer, and documentation are comprehensive and should be used directly.

### New Features (not in existing dashboard): KEEP AS-IS
Board groups, skills marketplace, skill packs, webhooks, custom fields, approvals system, organization management with RBAC — these are all new capabilities that mc-v2 brings.
