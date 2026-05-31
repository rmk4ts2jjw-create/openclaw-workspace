import { useMemo, useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Search } from "lucide-react";
import { PageHeader } from "@/components/PageHeader";
import { Markdown } from "@/components/Markdown";
import { DAILY_LOG, LONG_TERM } from "@/lib/memory-data";

export const Route = createFileRoute("/memory")({
  head: () => ({ meta: [{ title: "Memory — Mission Control" }] }),
  component: MemoryPage,
});

type Tab = "daily" | "long";

function MemoryPage() {
  const [tab, setTab] = useState<Tab>("daily");
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState(DAILY_LOG[0].date);

  const filtered = useMemo(
    () =>
      DAILY_LOG.filter(
        (e) =>
          e.title.toLowerCase().includes(q.toLowerCase()) ||
          e.body.toLowerCase().includes(q.toLowerCase()) ||
          e.date.includes(q)
      ),
    [q]
  );
  const current = DAILY_LOG.find((e) => e.date === selected) ?? DAILY_LOG[0];

  return (
    <>
      <PageHeader icon="🧠" title="Memory">
        Daily logs and long-term institutional memory.
      </PageHeader>

      <div className="mb-5 flex gap-2">
        <TabBtn active={tab === "daily"} onClick={() => setTab("daily")}>Daily Log</TabBtn>
        <TabBtn active={tab === "long"} onClick={() => setTab("long")}>Long-term</TabBtn>
      </div>

      {tab === "daily" ? (
        <div className="grid gap-4 md:grid-cols-[320px_1fr]">
          <div className="space-y-3">
            <div className="relative">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="search entries…"
                className="w-full rounded-md border border-border bg-card/60 pl-9 pr-3 py-2 text-sm placeholder:text-muted-foreground focus:outline-none focus:border-violet/60"
              />
            </div>
            <div className="space-y-2 max-h-[70vh] overflow-y-auto pr-1">
              {filtered.length === 0 && (
                <div className="rounded-md border border-dashed border-border px-3 py-6 text-center text-xs text-muted-foreground">
                  No entries match.
                </div>
              )}
              {filtered.map((e) => {
                const active = e.date === selected;
                return (
                  <button
                    key={e.date}
                    onClick={() => setSelected(e.date)}
                    className={`w-full text-left rounded-lg border px-3 py-3 transition-colors ${
                      active
                        ? "border-violet/60 bg-violet/10 shadow-[0_0_0_1px_oklch(0.62_0.22_295/0.3)]"
                        : "border-border bg-card/40 hover:border-violet/40"
                    }`}
                  >
                    <div className="font-mono text-sm font-semibold">{e.date}</div>
                    <div className="font-mono text-[10px] text-muted-foreground mt-0.5">
                      {e.words.toLocaleString()} words
                    </div>
                    <div className="mt-2 text-xs text-muted-foreground line-clamp-2">
                      ## {e.title}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="rounded-xl border border-border bg-card/40 p-6 max-h-[78vh] overflow-y-auto">
            <div className="font-mono text-[11px] tracking-[0.25em] text-muted-foreground mb-4">
              {current.date} · {current.words.toLocaleString()} WORDS
            </div>
            <Markdown source={current.body} />
          </div>
        </div>
      ) : (
        <div className="rounded-xl border border-border bg-card/40 p-6 max-h-[78vh] overflow-y-auto">
          <div className="font-mono text-[11px] tracking-[0.25em] text-muted-foreground mb-4">
            MEMORY.md · LONG-TERM
          </div>
          <Markdown source={LONG_TERM} />
        </div>
      )}
    </>
  );
}

function TabBtn({ active, onClick, children }: { active: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-md border px-4 py-2 text-sm font-medium transition-colors ${
        active
          ? "border-violet/60 bg-violet/15 text-foreground shadow-[0_0_0_1px_oklch(0.62_0.22_295/0.3)]"
          : "border-border bg-card/40 text-muted-foreground hover:text-foreground"
      }`}
    >
      {children}
    </button>
  );
}
