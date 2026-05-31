import monkey from "@/assets/agent-monkey.png";
import lifesupport from "@/assets/agent-lifesupport.png";
import engineer from "@/assets/agent-engineer.png";
import archivist from "@/assets/agent-archivist.png";

export type CrewStatus = "active" | "standby" | "ondemand" | "error";

export interface CrewMember {
  id: string;
  emoji: string;
  name: string;
  role: string;
  shortRole: string;
  description: string;
  model: string;
  mode: "Always ON" | "ON-DEMAND";
  status: CrewStatus;
  avatar: string;
  accent: "violet" | "pink" | "cyan" | "warning";
}

export const MISSION_STATEMENT =
  "Build a self-running digital station that handles infrastructure, memory, and execution silently in the background — so the human in command can focus on ideas, decisions, and creative work instead of troubleshooting and maintenance. Quiet competence: a system so reliable it becomes invisible, and a crew so trusted that oversight becomes optional.";

export const CREW: CrewMember[] = [
  {
    id: "monkey",
    emoji: "🐒",
    name: "Space Monkey",
    role: "Mission Director",
    shortRole: "Top-level Orchestrator",
    description:
      "Top-level orchestrator and decision-maker. Routes work to the crew, owns the task queue, and keeps the mission on course.",
    model: "claude-sonnet-4-6",
    mode: "Always ON",
    status: "active",
    avatar: monkey,
    accent: "violet",
  },
  {
    id: "lifesupport",
    emoji: "🥷🏽",
    name: "Life Support Officer",
    role: "Infrastructure Controller",
    shortRole: "Infra & Health",
    description:
      "Watches system health, runs guardrails, and keeps everything rollback-ready. Quiet patrol of the station at all hours.",
    model: "claude-sonnet-4-6",
    mode: "Always ON",
    status: "active",
    avatar: lifesupport,
    accent: "pink",
  },
  {
    id: "engineer",
    emoji: "🔧",
    name: "Systems Engineer",
    role: "Coder / Builder",
    shortRole: "Scripts & Deploys",
    description:
      "Writes scripts, edits configs, ships deployments, automates repetitive ops. Wakes up when there is something to build.",
    model: "claude-sonnet-4-6",
    mode: "ON-DEMAND",
    status: "ondemand",
    avatar: engineer,
    accent: "cyan",
  },
  {
    id: "archivist",
    emoji: "📚",
    name: "Station Archivist",
    role: "Memory & Knowledge",
    shortRole: "Logs & Patterns",
    description:
      "Maintains the ship's log, consolidates daily memory, and surfaces patterns from institutional history.",
    model: "claude-sonnet-4-6",
    mode: "ON-DEMAND",
    status: "ondemand",
    avatar: archivist,
    accent: "warning",
  },
];

export const getCrew = (id: string) => CREW.find((c) => c.id === id);
