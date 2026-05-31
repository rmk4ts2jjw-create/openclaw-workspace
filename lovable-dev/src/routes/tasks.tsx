import { useState } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { PageHeader, Pill } from "@/components/PageHeader";
import { getCrew } from "@/lib/crew";

export const Route = createFileRoute("/tasks")({
  head: () => ({ meta: [{ title: "Tasks — Mission Control" }] }),
  component: TasksPage,
});

type Status = "backlog" | "in_progress" | "done";
interface Task {
  id: string;
  title: string;
  assignee: string;
  status: Status;
  ts: string;
  note?: string;
}

const INITIAL: Task[] = [
  { id: "T-104", title: "Draft weekly investor update", assignee: "monkey", status: "in_progress", ts: "2m ago", note: "compiling metrics" },
  { id: "T-103", title: "Patch nightly memory consolidation job", assignee: "engineer", status: "in_progress", ts: "14m ago" },
  { id: "T-102", title: "Audit Discord webhook latencies", assignee: "lifesupport", status: "backlog", ts: "1h ago" },
  { id: "T-101", title: "Cross-reference Q1 launch notes", assignee: "archivist", status: "backlog", ts: "3h ago" },
  { id: "T-100", title: "Rotate API keys for content pipeline", assignee: "engineer", status: "backlog", ts: "5h ago" },
  { id: "T-099", title: "Publish daily AI brief", assignee: "monkey", status: "done", ts: "today, 07:01" },
  { id: "T-098", title: "Verify backup snapshot integrity", assignee: "lifesupport", status: "done", ts: "yesterday" },
  { id: "T-097", title: "Index April research notes", assignee: "archivist", status: "done", ts: "yesterday" },
];

const COLS: { key: Status; label: string; accent: string }[] = [
  { key: "backlog", label: "Backlog", accent: "text-muted-foreground" },
  { key: "in_progress", label: "In Progress", accent: "text-[oklch(0.85_0.12_295)]" },
  { key: "done", label: "Done", accent: "text-[oklch(0.88_0.18_145)]" },
];

function TaskCard({
  t,
  onDragStart,
  dragging,
}: {
  t: Task;
  onDragStart: (id: string) => void;
  dragging: boolean;
}) {
  const a = getCrew(t.assignee);
  return (
    <div
      draggable
      onDragStart={(e) => {
        e.dataTransfer.effectAllowed = "move";
        e.dataTransfer.setData("text/plain", t.id);
        onDragStart(t.id);
      }}
      className={`cursor-grab active:cursor-grabbing rounded-lg border bg-card/70 p-3 transition-all ${
        dragging
          ? "opacity-40 border-violet/80"
          : "border-border hover:border-violet/50"
      }`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="font-mono text-[10px] text-muted-foreground tracking-wider">{t.id}</div>
        <div className="font-mono text-[10px] text-muted-foreground">{t.ts}</div>
      </div>
      <div className="mt-1 text-sm font-medium leading-snug">{t.title}</div>
      {t.note && <div className="mt-1 text-xs text-muted-foreground italic">{t.note}</div>}
      <div className="mt-3 flex items-center gap-2">
        {a && (
          <>
            <img
              src={a.avatar}
              alt={a.name}
              loading="lazy"
              width={20}
              height={20}
              className="h-5 w-5 rounded border border-border object-cover"
            />
            <span className="text-xs text-muted-foreground">{a.name}</span>
          </>
        )}
      </div>
    </div>
  );
}

function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>(INITIAL);
  const [dragId, setDragId] = useState<string | null>(null);
  const [overCol, setOverCol] = useState<Status | null>(null);

  const moveTask = (id: string, status: Status) => {
    setTasks((prev) => {
      const next = prev.map((t) =>
        t.id === id && t.status !== status
          ? { ...t, status, ts: "just now" }
          : t
      );
      // Re-order: moved task goes to the top of its new column
      const moved = next.find((t) => t.id === id);
      if (!moved) return next;
      return [moved, ...next.filter((t) => t.id !== id)];
    });
  };

  return (
    <>
      <PageHeader icon="🎯" title="Tasks" meta={`${tasks.length} active`}>
        Drag a card to reassign its status — assignees and timestamps update automatically.
      </PageHeader>
      <div className="grid gap-4 md:grid-cols-3">
        {COLS.map((col) => {
          const items = tasks.filter((t) => t.status === col.key);
          const isOver = overCol === col.key;
          return (
            <div
              key={col.key}
              onDragOver={(e) => {
                e.preventDefault();
                e.dataTransfer.dropEffect = "move";
                if (overCol !== col.key) setOverCol(col.key);
              }}
              onDragLeave={(e) => {
                // only clear if leaving the column itself
                if (e.currentTarget === e.target) setOverCol(null);
              }}
              onDrop={(e) => {
                e.preventDefault();
                const id = e.dataTransfer.getData("text/plain") || dragId;
                if (id) moveTask(id, col.key);
                setOverCol(null);
                setDragId(null);
              }}
              className={`rounded-xl border bg-card/30 p-3 transition-colors ${
                isOver
                  ? "border-violet/70 bg-violet/10 shadow-[0_0_0_1px_oklch(0.62_0.22_295/0.4)]"
                  : "border-border"
              }`}
            >
              <div className="mb-3 flex items-center justify-between px-1">
                <div className={`font-mono text-xs uppercase tracking-[0.18em] ${col.accent}`}>
                  {col.label}
                </div>
                <Pill>{items.length}</Pill>
              </div>
              <div className="space-y-2 min-h-[80px]">
                {items.length === 0 ? (
                  <div
                    className={`rounded-md border border-dashed px-3 py-6 text-center text-xs transition-colors ${
                      isOver
                        ? "border-violet/60 text-foreground"
                        : "border-border/70 text-muted-foreground"
                    }`}
                  >
                    {isOver ? "Drop here" : "No tasks"}
                  </div>
                ) : (
                  items.map((t) => (
                    <TaskCard
                      key={t.id}
                      t={t}
                      dragging={dragId === t.id}
                      onDragStart={setDragId}
                    />
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>
      <div className="mt-6 text-xs text-muted-foreground font-mono">
        sample data · drag-and-drop is local state · wire to ~/.openclaw/workspace/tasks.json after export
      </div>
    </>
  );
}
