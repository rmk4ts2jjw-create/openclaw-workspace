import type { ReactNode } from "react";

export function PageHeader({
  icon,
  title,
  meta,
  right,
  children,
}: {
  icon?: string;
  title: string;
  meta?: string;
  right?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight flex items-center gap-2">
          {icon && <span className="text-2xl leading-none">{icon}</span>}
          <span>{title}</span>
          {meta && (
            <span className="ml-3 font-mono text-xs text-muted-foreground tracking-wider">
              {meta}
            </span>
          )}
        </h1>
        {children && <div className="mt-2 text-sm text-muted-foreground">{children}</div>}
      </div>
      {right}
    </div>
  );
}

export function EmptyState({
  title = "No data yet",
  hint,
}: {
  title?: string;
  hint?: string;
}) {
  return (
    <div className="rounded-xl border border-dashed border-border/80 bg-card/30 px-6 py-14 text-center">
      <div className="font-mono text-xs tracking-[0.25em] text-muted-foreground">
        — EMPTY —
      </div>
      <div className="mt-3 font-semibold">{title}</div>
      {hint && <div className="mt-1 text-sm text-muted-foreground">{hint}</div>}
    </div>
  );
}

export function Pill({
  children,
  variant = "default",
}: {
  children: ReactNode;
  variant?: "default" | "violet" | "online" | "warning" | "error" | "cyan" | "pink";
}) {
  const map: Record<string, string> = {
    default: "bg-muted text-muted-foreground border-border",
    violet: "bg-violet/15 text-[oklch(0.85_0.12_295)] border-violet/40",
    online: "bg-online/10 text-[oklch(0.88_0.18_145)] border-online/40",
    warning: "bg-warning/10 text-[oklch(0.92_0.16_90)] border-warning/40",
    error: "bg-destructive/10 text-[oklch(0.85_0.18_25)] border-destructive/40",
    cyan: "bg-cyan-accent/10 text-[oklch(0.85_0.12_200)] border-cyan-accent/40",
    pink: "bg-pink-accent/10 text-[oklch(0.85_0.16_0)] border-pink-accent/40",
  };
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2 py-0.5 font-mono text-[10px] uppercase tracking-wider ${map[variant]}`}
    >
      {children}
    </span>
  );
}
