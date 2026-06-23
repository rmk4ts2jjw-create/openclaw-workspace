#!/usr/bin/env ts-node
/**
 * audit-incidents.ts — Incident Audit Report
 * 
 * Iterates through all TRIAGE incidents and identifies legacy ghosts
 * (incidents older than 48 hours that may need manual review).
 * 
 * Usage: npx ts-node scripts/audit-incidents.ts
 */

import { readFileSync, existsSync } from "fs";
import { join } from "path";

const INCIDENTS_PATH = join(process.env.HOME || "~", ".openclaw/workspace/data/incidents.json");
const LEGACY_THRESHOLD_HOURS = 48;

interface Incident {
  id: string;
  title: string;
  severity: string;
  status: string;
  opened: string;
  lastActivity: string;
  summary?: string;
  tags?: string[];
  _recurrence?: number;
}

function ageInHours(ts: string): number {
  const date = new Date(ts);
  if (isNaN(date.getTime())) return 0;
  return (Date.now() - date.getTime()) / (1000 * 60 * 60);
}

function formatAge(hours: number): string {
  if (hours < 1) return `${Math.round(hours * 60)}m`;
  if (hours < 24) return `${Math.round(hours)}h`;
  return `${Math.floor(hours / 24)}d ${Math.round(hours % 24)}h`;
}

function main() {
  if (!existsSync(INCIDENTS_PATH)) {
    console.error(`❌ Incidents file not found: ${INCIDENTS_PATH}`);
    process.exit(1);
  }

  const incidents: Incident[] = JSON.parse(readFileSync(INCIDENTS_PATH, "utf-8"));
  const triage = incidents.filter((i) => i.status === "TRIAGE");
  const legacy = triage.filter((i) => ageInHours(i.opened) > LEGACY_THRESHOLD_HOURS);

  console.log("╔══════════════════════════════════════════════════════════════════════╗");
  console.log("║                    INCIDENT AUDIT REPORT                            ║");
  console.log("╚══════════════════════════════════════════════════════════════════════╝");
  console.log();
  console.log(`Total incidents: ${incidents.length}`);
  console.log(`Active (TRIAGE): ${triage.length}`);
  console.log(`Legacy ghosts (>48h): ${legacy.length}`);
  console.log();

  // All triage incidents
  console.log("── All TRIAGE Incidents ──────────────────────────────────────────────");
  console.log();
  console.log(`${"ID".padEnd(10)} ${"Age".padEnd(10)} ${"Sev".padEnd(5)} ${"Status".padEnd(12)} Title`);
  console.log("─".repeat(100));

  const sorted = [...triage].sort((a, b) => new Date(a.opened).getTime() - new Date(b.opened).getTime());

  for (const inc of sorted) {
    const age = ageInHours(inc.opened);
    const ageStr = formatAge(age);
    const isLegacy = age > LEGACY_THRESHOLD_HOURS;
    const flag = isLegacy ? " ⚠️" : "";
    console.log(
      `${inc.id.padEnd(10)} ${ageStr.padEnd(10)} ${(inc.severity || "—").padEnd(5)} ${inc.status.padEnd(12)} ${inc.title.slice(0, 55)}${flag}`
    );
  }

  // Legacy ghosts section
  if (legacy.length > 0) {
    console.log();
    console.log("── ⚠️  Legacy Ghosts (>48h) ──────────────────────────────────────────");
    console.log();
    for (const inc of legacy) {
      const age = ageInHours(inc.opened);
      console.log(`  ${inc.id} — ${formatAge(age)} old`);
      console.log(`    Title: ${inc.title}`);
      console.log(`    Opened: ${inc.opened}`);
      console.log(`    Last activity: ${inc.lastActivity}`);
      console.log(`    Recurrence: ${inc._recurrence || 1}x`);
      console.log(`    Tags: ${(inc.tags || []).join(", ")}`);
      console.log();
    }
    console.log("Recommendation: Review legacy ghosts for manual resolution or escalation.");
  } else {
    console.log();
    console.log("✅ No legacy ghosts found. All TRIAGE incidents are < 48 hours old.");
  }

  console.log();
  console.log(`Report generated: ${new Date().toISOString()}`);
}

main();
