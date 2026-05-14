# Systems Engineer Brief: Wire Mission Control to Real Data

## Input
- Dashboard project from Lovable at: ~/Downloads/mission-control.zip
- OpenClaw workspace at: ~/.openclaw/workspace/

## Steps

### 1. Unzip
- Extract ~/Downloads/mission-control.zip to ~/mission-control-dashboard
- If unzip hangs, use Python: python3 -c "import zipfile; zipfile.ZipFile('~/Downloads/mission-control.zip').extractall('~/mission-control-dashboard')"

### 2. Explore Project Structure
- Read package.json (stack, deps, scripts)
- Map src/routes/, src/lib/, src/components/
- Identify every file containing mock/sample data
- Read routing setup to understand current navigation
- Note: project may be TanStack Start (serverless edge) — will need Node server functions for local fs reads

### 3. Read OpenClaw Workspace for Real Data
Read and catalog everything that exists:
- ~/.openclaw/openclaw.json → cron jobs, model config, skills, channel config
- ~/.openclaw/workspace/AGENTS.md → crew protocols
- ~/.openclaw/workspace/IDENTITY.md → Space Monkey identity
- ~/.openclaw/workspace/SOUL.md → personality/tone
- ~/.openclaw/workspace/USER.md → user profile
- ~/.openclaw/workspace/MEMORY.md → long-term memory (if exists)
- ~/.openclaw/workspace/memory/ → daily logs YYYY-MM-DD.md (if any)
- ~/.openclaw/workspace/TOOLS.md → local notes
- ~/.openclaw/workspace/skills/ → installed skills
- Shell commands for system stats: df -h, vm_stat, sysctl hw.memsize, ps aux for service status

### 4. Map Real Data to Screens
| Screen | Real Data Source |
|--------|-----------------|
| Tasks | Create task store in workspace (JSON file) |
| Calendar | openclaw.json → cron jobs array |
| Projects | Project files/dirs in workspace |
| Memory | memory/*.md daily logs + MEMORY.md |
| Docs | All .md files in workspace (excluding system files) |
| Team | Hardcoded crew: Space Monkey, Life Support, Systems Engineer, Archivist |
| Visual Office | Agent status from cron + session activity |

### 5. Fix Sidebar Navigation (PRIORITY — match reference screenshots)
- Fixed left sidebar, dark navy background (#12182A)
- "MISSION CONTROL" header with logo at top
- "SPACE MONKEY ONLINE" status with green dot
- Nav items with icons: Tasks, Calendar, Projects, Memory, Docs, Team, Visual
- Active page: purple background highlight + green dot indicator
- Collapsible on mobile, always visible on desktop
- Reference: 4 screenshots from Tina Huang's Mission Control

### 6. Replace Mock Data with Real Data
- Replace every sample data array/object with real fs reads
- Use Node server-side file reads (fs/promises) — NOT edge runtime
- Graceful empty states: "No data yet" instead of broken UI
- Format dates, markdown content, status badges properly

### 7. Wire System Stats
- CPU usage, disk space, memory usage
- Service status: OpenClaw gateway, Docker, Ollama (if running)
- Model info from openclaw.json
- Display on Team page (model info) and Visual Office (live status)

### 8. Ship's Log (Archivist)
- Create ~/.openclaw/workspace/memory/ship-log.md if it doesn't exist
- Format: running markdown log with timestamps
- Each significant event gets a log entry
- Display in Memory screen

### 9. Run It
- bun install (or npm install if no Bun)
- bun dev / npm run dev
- Verify localhost:3000 loads
- Test all 7 screens load without errors

### 10. Report
- List what's showing REAL data vs what's still mock
- Note any blockers or missing data sources
- Suggest next improvements

## Non-Negotiable
The sidebar must match the reference screenshots. Fixed left nav, dark theme, purple active states, green status dots. First thing to fix if it's not right.

## Visual Reference
- Background: #12182A (dark charcoal/navy)
- Accents: purple/violet for branding, lime green for active/online
- Yellow/gold for high-priority labels
- Red for errors/disabled
- Pixel art avatars for each crew member
- Card-based layouts with subtle borders and rounded corners
