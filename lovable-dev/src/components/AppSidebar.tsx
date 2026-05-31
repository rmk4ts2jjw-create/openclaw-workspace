import { Link, useRouterState } from "@tanstack/react-router";
import {
  Target,
  Calendar as CalendarIcon,
  Rocket,
  Brain,
  FileText,
  Users,
  Gamepad2,
  Satellite,
  AlertTriangle,
} from "lucide-react";

const sections = [
  {
    label: "OPERATIONS",
    items: [
      { title: "Tasks", to: "/tasks", icon: Target },
      { title: "Calendar", to: "/calendar", icon: CalendarIcon },
      { title: "Incidents", to: "/incidents", icon: AlertTriangle },
    ],
  },
  {
    label: "KNOWLEDGE",
    items: [
      { title: "Memory", to: "/memory", icon: Brain },
      { title: "Docs", to: "/docs", icon: FileText },
    ],
  },
  {
    label: "STATION",
    items: [
      { title: "Projects", to: "/projects", icon: Rocket },
      { title: "Team", to: "/team", icon: Users },
      { title: "Visual", to: "/visual", icon: Gamepad2 },
    ],
  },
] as const;

export function AppSidebar() {
  const path = useRouterState({ select: (s) => s.location.pathname });
  const isActive = (to: string) =>
    to === "/" ? path === "/" : path === to || path.startsWith(to + "/");

  return (
    <aside className="hidden md:flex w-60 shrink-0 flex-col bg-sidebar text-sidebar-foreground border-r border-sidebar-border">
      <div className="px-5 pt-6 pb-4">
        <Link to="/" className="block">
          <div className="rounded-lg border border-sidebar-border bg-card/40 px-4 py-3 shadow-[inset_0_0_0_1px_oklch(0.30_0.10_295/0.25)]">
            <div className="font-mono text-[11px] tracking-[0.22em] text-muted-foreground">
              MISSION
            </div>
            <div className="font-mono text-base font-bold tracking-[0.18em]">
              CONTROL
            </div>
          </div>
        </Link>
        <div className="mt-3 flex items-center gap-2 px-1">
          <span className="status-dot online animate-pulse-soft" />
          <Satellite className="h-3.5 w-3.5 text-violet/90" />
          <span className="font-mono text-[11px] tracking-[0.22em] text-muted-foreground">
            STATION <span className="text-foreground/90">ONLINE</span>
          </span>
        </div>
      </div>

      <nav className="flex-1 px-3 py-2 space-y-4">
        {sections.map((section) => (
          <div key={section.label} className="space-y-1">
            <div className="px-3 pt-1 pb-1 font-mono text-[10px] tracking-[0.28em] text-muted-foreground/70">
              {section.label}
            </div>
            {section.items.map((item) => {
              const active = isActive(item.to);
              const Icon = item.icon;
              return (
                <Link
                  key={item.to}
                  to={item.to}
                  className={[
                    "group flex items-center justify-between rounded-md px-3 py-2 text-sm transition-colors",
                    active
                      ? "bg-sidebar-accent text-sidebar-accent-foreground border border-violet/40 shadow-[0_0_0_1px_oklch(0.62_0.22_295/0.25),0_8px_24px_-12px_oklch(0.62_0.22_295/0.5)]"
                      : "text-sidebar-foreground/80 hover:bg-card/40 hover:text-sidebar-foreground",
                  ].join(" ")}
                >
                  <span className="flex items-center gap-3">
                    <Icon className="h-4 w-4" />
                    <span className="font-medium">{item.title}</span>
                  </span>
                  {active && <span className="status-dot online" />}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      <div className="px-5 py-4 border-t border-sidebar-border">
        <div className="flex items-center gap-2">
          <div className="h-7 w-7 rounded-full bg-violet/30 border border-violet/50 grid place-items-center text-xs font-bold">
            N
          </div>
          <div className="font-mono text-[11px] text-muted-foreground tracking-wider">
            commander
          </div>
        </div>
      </div>
    </aside>
  );
}
