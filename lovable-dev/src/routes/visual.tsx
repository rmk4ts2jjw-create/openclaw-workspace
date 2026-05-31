import { createFileRoute } from "@tanstack/react-router";
import { PageHeader } from "@/components/PageHeader";
import { CREW } from "@/lib/crew";
import { AgentOffice } from "@/components/AgentOffice";

export const Route = createFileRoute("/visual")({
  head: () => ({ meta: [{ title: "Agent Office — Mission Control" }] }),
  component: VisualPage,
});

function VisualPage() {
  return (
    <>
      <PageHeader icon="🎮" title="Agent Office" right={
        <span className="flex items-center gap-2 font-mono text-xs">
          <span className="status-dot online animate-pulse-soft" />
          <span className="text-[oklch(0.88_0.18_145)] tracking-widest">LIVE</span>
        </span>
      }>
        Live pixel-art station — agents drift, work, and rest in real time.
      </PageHeader>

      <div className="mx-auto max-w-3xl">
        <AgentOffice />
      </div>

      {/* Live ticker */}
      <div className="mt-5 rounded-lg border border-border bg-card/50 px-4 py-2 overflow-hidden">
        <div className="flex items-center gap-3 font-mono text-xs whitespace-nowrap overflow-x-auto scrollbar-none">
          <span className="flex items-center gap-1 text-[oklch(0.88_0.18_145)]"><span className="status-dot online" /> LIVE</span>
          <span className="text-muted-foreground">·</span>
          <span>Monkey: <span className="text-[oklch(0.85_0.12_295)]">ACTIVE</span></span>
          <span className="text-muted-foreground">·</span>
          <span>Life Support: OK (56m ago)</span>
          <span className="text-muted-foreground">·</span>
          <span>Engineer: <span className="text-muted-foreground">ON-DEMAND</span></span>
          <span className="text-muted-foreground">·</span>
          <span>Archivist: <span className="text-muted-foreground">STANDBY</span> · next in 11h</span>
        </div>
      </div>

      {/* Crew status cards */}
      <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {CREW.map((c) => (
          <div key={c.id} className="rounded-lg border border-border bg-card/60 p-3 flex items-center gap-3">
            <img src={c.avatar} alt={c.name} width={40} height={40} className="h-10 w-10 rounded object-cover" />
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <div className="text-sm font-semibold truncate">{c.name}</div>
                <span className={`status-dot ${c.status === "active" ? "online" : "warn"}`} />
              </div>
              <div className="font-mono text-[10px] text-muted-foreground tracking-wider uppercase">
                {c.status === "active" ? "ON DUTY" : "AWAY"}
              </div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
