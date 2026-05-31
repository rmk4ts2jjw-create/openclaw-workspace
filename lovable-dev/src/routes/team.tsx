import { createFileRoute } from "@tanstack/react-router";
import { PageHeader, Pill } from "@/components/PageHeader";
import { CREW, MISSION_STATEMENT, type CrewMember } from "@/lib/crew";

export const Route = createFileRoute("/team")({
  head: () => ({ meta: [{ title: "Team — Mission Control" }] }),
  component: TeamPage,
});

const accentBorder: Record<string, string> = {
  violet: "border-l-violet",
  pink: "border-l-pink-accent",
  cyan: "border-l-cyan-accent",
  warning: "border-l-warning",
};

const accentText: Record<string, string> = {
  violet: "text-[oklch(0.85_0.12_295)]",
  pink: "text-[oklch(0.85_0.16_0)]",
  cyan: "text-[oklch(0.85_0.12_200)]",
  warning: "text-[oklch(0.92_0.16_90)]",
};

function TeamPage() {
  const director = CREW[0];
  const lifesupport = CREW.find((c) => c.id === "lifesupport")!;
  const engineer = CREW.find((c) => c.id === "engineer")!;
  const archivist = CREW.find((c) => c.id === "archivist")!;
  return (
    <>
      <PageHeader icon="👥" title="Crew Roster" meta={`${CREW.length} agents`} />

      <div className="mb-8 rounded-xl border border-border bg-card/40 px-6 py-5">
        <div className="font-mono text-[11px] tracking-[0.25em] text-muted-foreground mb-2">
          MISSION
        </div>
        <p className="text-sm leading-relaxed italic text-foreground/90">
          "{MISSION_STATEMENT}"
        </p>
      </div>

      <SectionDivider label="MISSION DIRECTOR" />
      <CrewCard m={director} />

      <SectionDivider label="STATION OPS" />
      <div className="space-y-4">
        <CrewCard m={lifesupport} />
        <CrewCard m={engineer} />
      </div>

      <SectionDivider label="INTEL & ARCHIVE" />
      <CrewCard m={archivist} />

      <div className="mt-10 rounded-xl border border-border bg-card/40 p-5">
        <div className="mb-3 font-mono text-[10px] tracking-[0.28em] text-muted-foreground">
          INFRA PIPELINE
        </div>
        <div className="flex flex-wrap items-center gap-x-2 gap-y-2 font-mono text-xs">
          <FlowNode>{lifesupport.emoji} Life Support</FlowNode>
          <Arrow />
          <FlowFile>alerts.json</FlowFile>
          <Arrow />
          <FlowNode>{engineer.emoji} Engineer</FlowNode>
          <Arrow />
          <FlowFile>incident-log.md</FlowFile>
          <Arrow />
          <FlowNode>{archivist.emoji} Archivist</FlowNode>
          <Arrow />
          <FlowNode>{director.emoji} Monkey</FlowNode>
        </div>
      </div>
    </>
  );
}

function SectionDivider({ label }: { label: string }) {
  return (
    <div className="my-6 flex items-center gap-3">
      <div className="h-px flex-1 bg-border" />
      <div className="font-mono text-[11px] tracking-[0.3em] text-muted-foreground">
        {label}
      </div>
      <div className="h-px flex-1 bg-border" />
    </div>
  );
}

function FlowNode({ children }: { children: React.ReactNode }) {
  return (
    <span className="rounded-md border border-violet/40 bg-violet/10 px-2 py-1 text-foreground/90">
      {children}
    </span>
  );
}

function FlowFile({ children }: { children: React.ReactNode }) {
  return (
    <span className="rounded-md border border-border bg-background/50 px-2 py-1 text-muted-foreground">
      {children}
    </span>
  );
}

function Arrow() {
  return <span className="text-muted-foreground">→</span>;
}

function CrewCard({ m }: { m: CrewMember }) {
  return (
    <div className={`rounded-xl border border-border bg-card/60 border-l-4 ${accentBorder[m.accent]} p-5`}>
      <div className="flex items-start gap-4">
        <div className="shrink-0 rounded-lg border border-border bg-background/50 p-1">
          <img
            src={m.avatar}
            alt={m.name}
            loading="lazy"
            width={64}
            height={64}
            className="h-16 w-16 rounded-md"
          />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
            <h3 className={`text-lg font-bold ${accentText[m.accent]}`}>
              {m.emoji} {m.name}
            </h3>
            <span className="text-sm text-muted-foreground">{m.role}</span>
          </div>
          <div className="mt-2 flex flex-wrap items-center gap-2">
            <Pill>⚙ {m.model}</Pill>
            <Pill variant={m.mode === "Always ON" ? "online" : "default"}>
              {m.mode === "Always ON" ? "∞ Always ON" : "ON-DEMAND"}
            </Pill>
            <Pill variant={m.status === "active" ? "online" : "default"}>
              {m.status === "active" ? "ACTIVE" : m.status === "ondemand" ? "STANDBY" : m.status.toUpperCase()}
            </Pill>
          </div>
          <p className="mt-3 text-sm text-foreground/85 leading-relaxed">{m.description}</p>
        </div>
      </div>
    </div>
  );
}
