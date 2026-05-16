# Agent Office System — Detailed Behaviour + Visual Design

_Source: Andre, 2026-05-15_

## Core Experience Target

"A persistent orbital AI workspace where a small digital crew quietly works, collaborates and maintains the station in real time."

The station should feel: inhabited, spatial, operational, calm, reactive, cinematic, persistent.

NOT: static dashboard panels, floating avatars, generic kanban widgets, noisy game UI.

## Room Structure

Each agent has:
- Their own dedicated room
- Unique visual identity
- Operational role reflected in environment design
- Persistent location within the station

Rooms: Engineering bay, Research/archive room, Command/coordination room, Security/monitoring deck, Systems/life-support operations.

Rooms visually communicate: role, personality, current operational state.

## Pixel-Art Room Design

Use original pixel-art room assets as foundation. Each room contains:
- Animated terminals, status monitors, layered background detail
- Props/equipment, operational lighting, subtle ambient motion
- Blinking panels, scrolling terminal text, radar sweeps
- Holographic displays, moving indicators, tiny screen flickers
- Atmospheric lighting pulses

Rooms feel: functional, lived-in, persistent, active even while quiet.

## Agent States

### IDLE STATE
- Seated/resting animation
- Dimmed room lighting, low monitor activity
- Occasional idle movement, quiet ambience
- Leaning back, reading terminal, slow typing, looking at monitor, subtle blinking
- Feel: "crew member waiting for assignment"

### ACTIVE / WORKING STATE
- Faster terminal activity, brighter monitors
- Active typing/interaction animation, increased room activity
- Monitor flicker increases, task progress indicators animate
- Feel: "active mission execution underway"

### COLLABORATION STATE (KEY FEATURE)
- One agent physically leaves their room
- Traverses hallway/station path
- Enters another room
- Visual connection/handoff occurs
- Feel: deliberate, readable, operational
- NOT: random wandering, constant movement, chaotic animation

## Room-to-Room Movement
- Pixel-art hallway traversal, short travel animations
- Station doors/sliding panels, moving light strips, subtle path indicators
- Happens infrequently, feels meaningful, corresponds to real system events
- Examples: Engineering→Command, Research→Archive, Security→affected systems bay

## Visual Collaboration Links
- Subtle animated connection lines/signals between collaborating agents
- Shared task indicators, highlight linked rooms softly
- Data-stream pulse between rooms, holographic connection line
- Shared monitor sync effect, transmission animation
- Avoid: giant glowing beams, noisy effects, excessive motion

## Incident Response Behaviour
- Warning lighting, increased monitor activity, alert-state panels
- Agents moving between rooms more frequently, command room activity spikes
- Keep reactions controlled and cinematic
- Target: "professional operational response" NOT "arcade emergency mode"

## Queue + Task Flow Visualisation
- Incoming transmission packets, dispatch indicators
- Task signals travelling between rooms
- Processing indicators, active mission overlays
- Queue pressure subtly reflected in room activity
- User feels: station is continuously processing and coordinating work

## Ambient Station Life
- Drifting starfield, nebula movement
- Ambient room flicker, distant ship fly-bys
- Occasional status announcements, subtle lighting cycles, idle station chatter
- Persistent atmosphere without distraction

## Operational Readability (At a Glance)
- Who is working, who is idle, who is collaborating
- Where incidents exist, which room is busiest
- Whether the station is calm or under pressure
- Station communicates state before text is read

## Performance + Implementation
- Lightweight, modular, reusable, event-driven
- CSS/Framer Motion, lightweight layered animation
- Reusable room components, room metadata/config system
- Avoid: Phaser, heavy game engines, excessive render loops, expensive particle systems, fake/random behaviours disconnected from real state
- Must remain smooth while permanently open

## Emotional Target
- Attached to the crew, aware of operational activity
- Comfort in station ambience, curiosity about what agents are doing
- Satisfaction simply observing the system
- "This feels like a real AI crew inhabiting a persistent orbital workspace."
