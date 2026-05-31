import { useMemo, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Search, FileText } from "lucide-react";
import { PageHeader, Pill } from "@/components/PageHeader";
import { Markdown } from "@/components/Markdown";

export const Route = createFileRoute("/docs")({
  head: () => ({ meta: [{ title: "Docs — Mission Control" }] }),
  component: DocsPage,
});

type DocType = "newsletter" | "brief" | "note" | "content";

interface Doc {
  id: string;
  title: string;
  date: string;
  type: DocType;
  author: string;
  body: string;
}

const DOCS: Doc[] = [
  {
    id: "d-014",
    title: "AI Coding Agents — Weekly Brief",
    date: "2026-04-18",
    type: "brief",
    author: "Researcher",
    body: `# AI Coding Agents — Weekly Brief

Claude Mythos Preview drops with **SWE-bench Verified 93.9%** (+13.1%) and SWE-bench Pro **77.8%** (+24.4%).

## Why it matters
- Biggest coding-agent benchmark leap in months.
- Autonomous multi-vulnerability chaining is a new capability class.

## Recommended action
- Pull a Mythos Preview key for the engineer agent.
- Re-run the deploy-script bake-off next Monday.`,
  },
  {
    id: "d-013",
    title: "Lonely Octopus Newsletter — Issue 24",
    date: "2026-04-17",
    type: "newsletter",
    author: "Producer",
    body: `# Lonely Octopus — Issue 24

This week: local AI is finally usable on a laptop, AI policy heats up, and a candid look at why most agents still need a human supervisor.

> Quiet competence. Sharper signals. Less noise.`,
  },
  {
    id: "d-012",
    title: "Local AI / On-Device — Field Notes",
    date: "2026-04-16",
    type: "note",
    author: "Archivist",
    body: `## Local AI Field Notes

- Qwen3.6-35B-A3B is holding as the top r/LocalLLaMA signal.
- Cerebras hardware coming to AWS Bedrock.
- Inference efficiency + local ecosystem both active.`,
  },
  {
    id: "d-011",
    title: "Q1 Launch Retro — Draft",
    date: "2026-04-15",
    type: "note",
    author: "Space Monkey",
    body: `# Q1 Launch Retro

What worked, what to cut, what to keep. Draft — pending Tina review.`,
  },
  {
    id: "d-010",
    title: "Cron Hardening Plan",
    date: "2026-04-14",
    type: "brief",
    author: "Engineer",
    body: `## Cron Hardening Plan

Three failure modes seen this month. Mitigations:
1. Add session_status fallback gate to every job.
2. Move rate limiter to a token bucket.
3. Alert on >2 consecutive misses, not 1.`,
  },
  {
    id: "d-009",
    title: "Daily AI Brief — 2026-04-14",
    date: "2026-04-14",
    type: "content",
    author: "Scout",
    body: `# Daily AI Brief

Anthropic DoD lawsuit escalates. Microsoft + rival AI companies join support.`,
  },
];

const TYPE_PILL: Record<DocType, "violet" | "online" | "warning" | "cyan"> = {
  newsletter: "violet",
  brief: "online",
  note: "cyan",
  content: "warning",
};

function DocsPage() {
  const [q, setQ] = useState("");
  const [filter, setFilter] = useState<DocType | "all">("all");
  const [selected, setSelected] = useState<string | null>(null);

  const filtered = useMemo(
    () =>
      DOCS.filter(
        (d) =>
          (filter === "all" || d.type === filter) &&
          (q === "" ||
            d.title.toLowerCase().includes(q.toLowerCase()) ||
            d.body.toLowerCase().includes(q.toLowerCase()))
      ),
    [q, filter]
  );

  const current = DOCS.find((d) => d.id === selected);

  return (
    <>
      <PageHeader icon="📄" title="Docs" meta={`${DOCS.length} documents`}>
        Everything the crew has produced.
      </PageHeader>

      <div className="mb-4 flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-[220px]">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="search docs…"
            className="w-full rounded-md border border-border bg-card/60 pl-9 pr-3 py-2 text-sm placeholder:text-muted-foreground focus:outline-none focus:border-violet/60"
          />
        </div>
        {(["all", "newsletter", "brief", "note", "content"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setFilter(t)}
            className={`rounded-md border px-3 py-2 text-xs font-medium transition-colors ${
              filter === t
                ? "border-violet/60 bg-violet/15 text-foreground"
                : "border-border bg-card/40 text-muted-foreground hover:text-foreground"
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {filtered.length === 0 && (
          <div className="rounded-md border border-dashed border-border px-3 py-10 text-center text-sm text-muted-foreground">
            No docs match.
          </div>
        )}
        {filtered.map((d) => (
          <button
            key={d.id}
            onClick={() => setSelected(d.id === selected ? null : d.id)}
            className="w-full text-left rounded-lg border border-border bg-card/60 px-4 py-3 hover:border-violet/50 transition-colors"
          >
            <div className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-3 min-w-0">
                <FileText className="h-4 w-4 shrink-0 text-muted-foreground" />
                <div className="min-w-0">
                  <div className="font-medium truncate">{d.title}</div>
                  <div className="font-mono text-[11px] text-muted-foreground mt-0.5">
                    {d.date} · {d.author}
                  </div>
                </div>
              </div>
              <Pill variant={TYPE_PILL[d.type]}>{d.type}</Pill>
            </div>
            {selected === d.id && (
              <div className="mt-4 rounded-md border border-border bg-background/40 p-4">
                <Markdown source={d.body} />
              </div>
            )}
          </button>
        ))}
      </div>
    </>
  );
}
