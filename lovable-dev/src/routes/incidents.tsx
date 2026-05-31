import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { PageHeader, Pill } from "@/components/PageHeader";
import { CREW } from "@/lib/crew";

export const Route = createFileRoute("/incidents")({
  head: () => ({ meta: [{ title: "Incidents & Alerts — Mission Control" }] }),
  component: IncidentsPage,
});

type Health = "HEALTHY" | "DEGRADED" | "DOWN";
type Severity = "P1" | "P2" | "P3";
type IncStatus = "TRIAGE" | "MITIGATING" | "RESOLVED";

interface Watch {
  id: string;
  name: string;
  target: string;
  health: Health;
  metric: string;
  metricPct: number; // 0-100, lower = healthier for error rate, higher = healthier for uptime
  metricKind: "latency" | "errors" | "uptime";
  lastChecked: string;
  tags: string[];
}

interface Incident {
  id: string;
  title: string;
  severity: Severity;
  status: IncStatus;
  owner: string; // crew id
  opened: string;
  summary: string;
  tags: string[];
}

const WATCH: Watch[] = [
  {
    id: "w1",
    name: "edge-worker.prod",
    target: "cloudflare/worker",
    health: "HEALTHY",
    metric: "p95 latency 142ms",
    metricPct: 18,
    metricKind: "latency",
    lastChecked: "12s ago",
    tags: ["prod", "edge", "critical"],
  },
  {
    id: "w2",
    name: "primary-db.prod",
    target: "postgres/main",
    health: "DEGRADED",
    metric: "error rate 2.4%",
    metricPct: 62,
    metricKind: "errors",
    lastChecked: "34s ago",
    tags: ["prod", "db"],
  },
  {
    id: "w3",
    name: "auth-gateway",
    target: "api/auth",
    health: "HEALTHY",
    metric: "uptime 99.98%",
    metricPct: 99,
    metricKind: "uptime",
    lastChecked: "8s ago",
    tags: ["prod", "auth"],
  },
  {
    id: "w4",
    name: "log-pipeline",
    target: "vector→s3",
    health: "DOWN",
    metric: "no events 6m",
    metricPct: 92,
    metricKind: "errors",
    lastChecked: "1m ago",
    tags: ["telemetry"],
  },
  {
    id: "w5",
    name: "billing-webhook",
    target: "stripe→api",
    health: "HEALTHY",
    metric: "p95 latency 88ms",
    metricPct: 11,
    metricKind: "latency",
    lastChecked: "22s ago",
    tags: ["prod", "billing"],
  },
  {
    id: "w6",
    name: "nightly-backup",
    target: "pg_dump→r2",
    health: "HEALTHY",
    metric: "last run 4h ago",
    metricPct: 100,
    metricKind: "uptime",
    lastChecked: "4m ago",
    tags: ["backup"],
  },
];

const INCIDENTS: Incident[] = [
  {
    id: "INC-204",
    title: "Log pipeline silent — vector → s3",
    severity: "P2",
    status: "MITIGATING",
    owner: "engineer",
    opened: "12m ago",
    summary:
      "No events landing in s3 since 09:14 UTC. Vector agent on edge-worker appears alive but flushing 0 records.",
    tags: ["telemetry", "prod"],
  },
  {
    id: "INC-203",
    title: "Primary DB error rate elevated",
    severity: "P3",
    status: "TRIAGE",
    owner: "lifesupport",
    opened: "38m ago",
    summary:
      "Sustained 2-3% error rate on primary-db.prod. Suspect connection pool exhaustion under burst.",
    tags: ["db", "prod"],
  },
  {
    id: "INC-202",
    title: "Edge worker cold-start spike post-deploy",
    severity: "P3",
    status: "RESOLVED",
    owner: "engineer",
    opened: "yesterday",
    summary:
      "Cold starts > 800ms after v142 deploy. Mitigated by reverting bundle splitter config.",
    tags: ["edge"],
  },
  {
    id: "INC-201",
    title: "Auth token rotation failed in staging",
    severity: "P1",
    status: "RESOLVED",
    owner: "monkey",
    opened: "2d ago",
    summary:
      "Rotation job exited 1 due to expired KMS grant. Re-issued grant, rotation now green.",
    tags: ["auth", "staging"],
  },
];

function IncidentsPage() {
  const [tab, setTab] = useState<"watch" | "incidents">("watch");
  const open = INCIDENTS.filter((i) => i.status !== "RESOLVED").length;

  return (
    <>
      <PageHeader
        icon="⚠"
        title="Incidents & Alerts"
        meta={`${WATCH.length} watched · ${open} open`}
      />

      <div className="mb-6 inline-flex rounded-lg border border-border bg-card/40 p-1 font-mono text-[11px] tracking-[0.18em]">
        <TabBtn active={tab === "watch"} onClick={() => setTab("watch")}>
          WATCHLIST ({WATCH.length})
        </TabBtn>
        <TabBtn active={tab === "incidents"} onClick={() => setTab("incidents")}>
          INCIDENTS ({INCIDENTS.length})
        </TabBtn>
      </div>

      {tab === "watch" ? <WatchList /> : <IncidentList />}
    </>
  );
}

function TabBtn({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={[
        "px-3 py-1.5 rounded-md transition-colors",
        active
          ? "bg-violet/20 text-foreground border border-violet/40"
          : "text-muted-foreground hover:text-foreground",
      ].join(" ")}
    >
      {children}
    </button>
  );
}

const healthAccent: Record<Health, string> = {
  HEALTHY: "border-l-online",
  DEGRADED: "border-l-warning",
  DOWN: "border-l-destructive",
};

const healthPill: Record<Health, "online" | "warning" | "error"> = {
  HEALTHY: "online",
  DEGRADED: "warning",
  DOWN: "error",
};

const barColor = (h: Health) =>
  h === "HEALTHY"
    ? "bg-online"
    : h === "DEGRADED"
      ? "bg-warning"
      : "bg-destructive";

function WatchList() {
  return (
    <>
      <div className="mb-3 flex items-center justify-between">
        <div className="font-mono text-[11px] tracking-[0.22em] text-muted-foreground">
          AUTO-REFRESH · 10s
        </div>
        <button className="rounded-md border border-violet/40 bg-violet/15 px-3 py-1.5 text-xs font-mono tracking-wider hover:bg-violet/25 transition-colors">
          + ADD TARGET
        </button>
      </div>
      <div className="space-y-3">
        {WATCH.map((w) => (
          <div
            key={w.id}
            className={`rounded-xl border border-border bg-card/60 border-l-4 ${healthAccent[w.health]} p-4`}
          >
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="min-w-0">
                <div className="flex flex-wrap items-center gap-2">
                  <h3 className="font-mono text-sm font-bold">{w.name}</h3>
                  <Pill variant={healthPill[w.health]}>{w.health}</Pill>
                </div>
                <div className="mt-1 font-mono text-[11px] text-muted-foreground tracking-wider">
                  {w.target} · checked {w.lastChecked}
                </div>
              </div>
              <div className="text-right shrink-0">
                <div className="font-mono text-xs text-foreground/90">
                  {w.metric}
                </div>
              </div>
            </div>
            <div className="mt-3 h-1.5 w-full rounded-full bg-muted overflow-hidden">
              <div
                className={`h-full ${barColor(w.health)}`}
                style={{ width: `${Math.max(6, w.metricPct)}%` }}
              />
            </div>
            <div className="mt-3 flex flex-wrap gap-1.5">
              {w.tags.map((t) => (
                <Pill key={t}>#{t}</Pill>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

const sevPill: Record<Severity, "error" | "warning" | "violet"> = {
  P1: "error",
  P2: "warning",
  P3: "violet",
};

const statusPill: Record<IncStatus, "warning" | "cyan" | "online"> = {
  TRIAGE: "warning",
  MITIGATING: "cyan",
  RESOLVED: "online",
};

const sevAccent: Record<Severity, string> = {
  P1: "border-l-destructive",
  P2: "border-l-warning",
  P3: "border-l-violet",
};

function IncidentList() {
  return (
    <>
      <div className="mb-3 flex justify-end">
        <button className="rounded-md border border-violet/40 bg-violet/15 px-3 py-1.5 text-xs font-mono tracking-wider hover:bg-violet/25 transition-colors">
          + DECLARE INCIDENT
        </button>
      </div>
      <div className="space-y-3">
        {INCIDENTS.map((inc) => {
          const owner = CREW.find((c) => c.id === inc.owner);
          return (
            <div
              key={inc.id}
              className={`rounded-xl border border-border bg-card/60 border-l-4 ${sevAccent[inc.severity]} p-4`}
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-mono text-[11px] text-muted-foreground tracking-wider">
                      {inc.id}
                    </span>
                    <Pill variant={sevPill[inc.severity]}>{inc.severity}</Pill>
                    <Pill variant={statusPill[inc.status]}>{inc.status}</Pill>
                  </div>
                  <h3 className="mt-1 text-sm font-semibold text-foreground">
                    {inc.title}
                  </h3>
                </div>
                <div className="text-right shrink-0">
                  <div className="font-mono text-[11px] text-muted-foreground tracking-wider">
                    opened {inc.opened}
                  </div>
                  {owner && (
                    <div className="mt-1 flex items-center gap-2 justify-end">
                      <img
                        src={owner.avatar}
                        alt={owner.name}
                        className="h-5 w-5 rounded"
                      />
                      <span className="font-mono text-[11px] text-foreground/80">
                        {owner.name}
                      </span>
                    </div>
                  )}
                </div>
              </div>
              <p className="mt-3 text-sm text-foreground/85 leading-relaxed">
                {inc.summary}
              </p>
              <div className="mt-3 flex flex-wrap gap-1.5">
                {inc.tags.map((t) => (
                  <Pill key={t}>#{t}</Pill>
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}