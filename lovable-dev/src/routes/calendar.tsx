import { createFileRoute } from "@tanstack/react-router";
import { PageHeader, Pill } from "@/components/PageHeader";

export const Route = createFileRoute("/calendar")({
  head: () => ({ meta: [{ title: "Calendar — Mission Control" }] }),
  component: CalendarPage,
});

type Kind = "daily" | "recurring" | "one-shot";
interface Job {
  id: string;
  title: string;
  kind: Kind;
  schedule: string;
  next: string;
  enabled: boolean;
  prompt: string;
}

const JOBS: Job[] = [
  { id: "j1", title: "Scout: Morning AI Brief", kind: "daily", schedule: "0 7 * * * (Asia/Hong_Kong)", next: "—", enabled: false, prompt: "You are Scout, an AI research agent for the commander. Pull overnight signals from the watchlist and post a brief…" },
  { id: "j2", title: "Researcher: Evening Research Brief", kind: "daily", schedule: "0 22 * * * (Asia/Hong_Kong)", next: "in 1h 1m", enabled: true, prompt: "You are Researcher, an AI agent. FALLBACK CHECK: run session_status first. Summarize the day's research signals…" },
  { id: "j3", title: "Test reminder", kind: "one-shot", schedule: "once at 6/4/2026, 7:14:58 pm", next: "—", enabled: false, prompt: "Post exactly this message to Discord channel: '🧪 Test reminder — this is Inky, timing test from 2 minutes ago. It works.'" },
  { id: "j4", title: "Producer: Content Idea Router", kind: "recurring", schedule: '{"kind":"every","everyMs":300000,"anchorMs":1775572517330}', next: "in 3m", enabled: false, prompt: "You are Producer for the content pipeline. FALLBACK CHECK: run session_status first. If the model is NOT anthropic, abort." },
  { id: "j5", title: "Archivist: Nightly Memory Consolidation", kind: "daily", schedule: "30 3 * * * (Asia/Hong_Kong)", next: "in 6h 12m", enabled: true, prompt: "You are the Station Archivist. Consolidate today's daily log into long-term memory. Extract patterns, decisions, and TODOs." },
];

const kindStyle: Record<Kind, { bar: string; pill: "online" | "violet" | "pink"; dot: string }> = {
  daily: { bar: "border-l-online", pill: "online", dot: "online" },
  recurring: { bar: "border-l-violet", pill: "violet", dot: "violet" },
  "one-shot": { bar: "border-l-pink-accent", pill: "pink", dot: "error" },
};

function CalendarPage() {
  return (
    <>
      <PageHeader icon="📅" title="Scheduler" meta={`${JOBS.length} jobs`}>
        Every cron and scheduled task on the station.
      </PageHeader>

      <div className="mb-5 flex flex-wrap items-center gap-4 text-xs">
        <span className="flex items-center gap-2"><span className="status-dot online" /> daily</span>
        <span className="flex items-center gap-2"><span className="status-dot violet" /> recurring</span>
        <span className="flex items-center gap-2"><span className="status-dot error" /> one-shot</span>
      </div>

      <div className="space-y-3">
        {JOBS.map((j) => {
          const s = kindStyle[j.kind];
          return (
            <div
              key={j.id}
              className={`rounded-xl border border-border bg-card/60 border-l-4 ${s.bar} px-5 py-4`}
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="flex items-center gap-3 flex-wrap">
                  <h3 className="font-semibold">{j.title}</h3>
                  <Pill variant={s.pill}>{j.kind}</Pill>
                  <Pill variant={j.enabled ? "online" : "default"}>
                    {j.enabled ? "ENABLED" : "DISABLED"}
                  </Pill>
                </div>
                <div className="font-mono text-xs text-muted-foreground">
                  next: <span className={j.next === "—" ? "" : "text-foreground"}>{j.next}</span>
                </div>
              </div>
              <div className="mt-2 font-mono text-xs text-muted-foreground break-all">
                {j.schedule}
              </div>
              <div className="mt-3 text-sm text-muted-foreground line-clamp-2">{j.prompt}</div>
            </div>
          );
        })}
      </div>
    </>
  );
}
