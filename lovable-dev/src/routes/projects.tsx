import { createFileRoute } from "@tanstack/react-router";
import { PageHeader, Pill } from "@/components/PageHeader";
import { getCrew } from "@/lib/crew";

export const Route = createFileRoute("/projects")({
  head: () => ({ meta: [{ title: "Projects — Mission Control" }] }),
  component: ProjectsPage,
});

interface Project {
  id: string;
  name: string;
  description: string;
  status: "active" | "shipping" | "paused";
  progress: number;
  tasks: number;
  lead: string;
  lastActivity: string;
  accent: "violet" | "cyan" | "warning" | "pink";
}

const PROJECTS: Project[] = [
  {
    id: "p1",
    name: "Content Pipeline 2.0",
    description: "Refactor the daily research → idea → newsletter loop. Cut human review time by half.",
    status: "active",
    progress: 64,
    tasks: 9,
    lead: "monkey",
    lastActivity: "12m ago",
    accent: "violet",
  },
  {
    id: "p2",
    name: "Memory Consolidation Engine",
    description: "Nightly job that distills daily logs into long-term MEMORY.md with provenance.",
    status: "shipping",
    progress: 92,
    tasks: 4,
    lead: "archivist",
    lastActivity: "1h ago",
    accent: "warning",
  },
  {
    id: "p3",
    name: "Station Health Watchdog",
    description: "Auto-rollback for any deploy that breaks Discord webhook health > 60s.",
    status: "active",
    progress: 38,
    tasks: 6,
    lead: "lifesupport",
    lastActivity: "3h ago",
    accent: "pink",
  },
  {
    id: "p4",
    name: "Local AI Inference Lab",
    description: "Spin up an on-device Qwen3 fallback for offline runs. Bench against current cloud calls.",
    status: "paused",
    progress: 18,
    tasks: 3,
    lead: "engineer",
    lastActivity: "2d ago",
    accent: "cyan",
  },
];

const accentBorder: Record<Project["accent"], string> = {
  violet: "border-l-violet",
  cyan: "border-l-cyan-accent",
  warning: "border-l-warning",
  pink: "border-l-pink-accent",
};

const accentBar: Record<Project["accent"], string> = {
  violet: "bg-violet",
  cyan: "bg-cyan-accent",
  warning: "bg-warning",
  pink: "bg-pink-accent",
};

const statusVariant: Record<Project["status"], "online" | "violet" | "default"> = {
  active: "violet",
  shipping: "online",
  paused: "default",
};

function ProjectsPage() {
  return (
    <>
      <PageHeader icon="🚀" title="Projects" meta={`${PROJECTS.length} active`}>
        Initiatives connecting tasks, memory, and docs.
      </PageHeader>

      <div className="grid gap-4 md:grid-cols-2">
        {PROJECTS.map((p) => {
          const lead = getCrew(p.lead);
          return (
            <div
              key={p.id}
              className={`rounded-xl border border-border bg-card/60 border-l-4 ${accentBorder[p.accent]} p-5`}
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="font-bold">{p.name}</h3>
                <Pill variant={statusVariant[p.status]}>{p.status}</Pill>
              </div>
              <p className="mt-2 text-sm text-muted-foreground leading-relaxed">{p.description}</p>

              <div className="mt-4">
                <div className="flex items-center justify-between text-[11px] font-mono text-muted-foreground mb-1">
                  <span>progress</span>
                  <span>{p.progress}%</span>
                </div>
                <div className="h-1.5 w-full rounded-full bg-muted overflow-hidden">
                  <div
                    className={`h-full ${accentBar[p.accent]}`}
                    style={{ width: `${p.progress}%` }}
                  />
                </div>
              </div>

              <div className="mt-4 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2 text-muted-foreground">
                  {lead && (
                    <img
                      src={lead.avatar}
                      alt={lead.name}
                      loading="lazy"
                      width={20}
                      height={20}
                      className="h-5 w-5 rounded border border-border object-cover"
                    />
                  )}
                  <span>lead · {lead?.name}</span>
                </div>
                <div className="flex items-center gap-3 font-mono text-muted-foreground">
                  <span>{p.tasks} tasks</span>
                  <span>·</span>
                  <span>{p.lastActivity}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}
