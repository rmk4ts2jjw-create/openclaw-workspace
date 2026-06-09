#!/usr/bin/env node
// scripts/station-memory-tool.js
// Station Memory CLI tool — agent-accessible interface
//
// Usage:
//   node station-memory-tool.js search <query> [--type <type>] [--limit <n>]
//   node station-memory-tool.js get <id>
//   node station-memory-tool.js related <id>
//   node station-memory-tool.js list [--type <type>]
//   node station-memory-tool.js stats
//   node station-memory-tool.js ingest-task <task-id>
//   node station-memory-tool.js ingest-incident <incident-id>
//   node station-memory-tool.js seed

const Database = require("better-sqlite3");
const { readFileSync, existsSync } = require("node:fs");
const { join } = require("node:path");

const WORKSPACE = "/Users/spacemonkey/.openclaw/workspace";
const DB_PATH = join(WORKSPACE, "data", "station-memory.db");

function getDb() {
  if (!existsSync(DB_PATH)) {
    console.log(JSON.stringify({ error: "Database not found. Run seed first.", path: DB_PATH }));
    process.exit(1);
  }
  const db = new Database(DB_PATH, { readonly: true });
  db.pragma("foreign_keys = ON");
  return db;
}

function rowToRecord(row) {
  if (!row) return null;
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    summary: row.summary,
    decision: row.decision,
    reason: row.reason,
    supersedes: row.supersedes,
    problem: row.problem,
    rootCause: row.root_cause,
    fix: row.fix,
    filesChanged: JSON.parse(row.files_changed || "[]"),
    neverDoThis: row.never_do_this,
    timeline: row.timeline,
    resolution: row.resolution,
    prevention: row.prevention,
    originalObjective: row.original_objective,
    outcome: row.outcome,
    lessons: JSON.parse(row.lessons || "[]"),
    recommendations: JSON.parse(row.recommendations || "[]"),
    alternativeConsidered: row.alternative_considered,
    decisionOwner: row.decision_owner,
    reviewDate: row.review_date,
    rule: row.rule,
    examples: row.examples,
    issue: row.issue,
    currentState: row.current_state,
    workaround: row.workaround,
    owner: row.owner,
    priority: row.priority,
    status: row.status,
    date: row.date,
    author: row.author,
    source: row.source,
    tags: [],
    relatedIds: [],
  };
}

function loadRelations(db, record) {
  if (!record) return null;
  const tags = db.prepare("SELECT tag FROM record_tags WHERE record_id = ?").all(record.id);
  const related = db.prepare("SELECT target_id FROM record_relations WHERE source_id = ?").all(record.id);
  record.tags = tags.map(t => t.tag);
  record.relatedIds = related.map(r => r.target_id);
  return record;
}

function formatRecord(record, verbose = false) {
  if (!record) return "Record not found.";

  let out = `[${record.id}] ${record.title}\n`;
  out += `Type: ${record.type} | Status: ${record.status} | Date: ${record.date} | Author: ${record.author}\n`;
  out += `${record.summary}\n`;

  if (verbose) {
    if (record.decision) out += `\nDecision: ${record.decision}`;
    if (record.reason) out += `\nReason: ${record.reason}`;
    if (record.problem) out += `\nProblem: ${record.problem}`;
    if (record.rootCause) out += `\nRoot Cause: ${record.rootCause}`;
    if (record.fix) out += `\nFix: ${record.fix}`;
    if (record.resolution) out += `\nResolution: ${record.resolution}`;
    if (record.prevention) out += `\nPrevention: ${record.prevention}`;
    if (record.rule) out += `\nRule: ${record.rule}`;
    if (record.rissue) out += `\nIssue: ${record.issue}`;
    if (record.currentState) out += `\nCurrent State: ${record.currentState}`;
    if (record.workaround) out += `\nWorkaround: ${record.workaround}`;
    if (record.outcome) out += `\nOutcome: ${record.outcome}`;
    if (record.filesChanged && record.filesChanged.length > 0) {
      out += `\nFiles: ${record.filesChanged.join(", ")}`;
    }
    if (record.lessons && record.lessons.length > 0) {
      out += `\nLessons:\n${record.lessons.map(l => `  • ${l}`).join("\n")}`;
    }
    if (record.recommendations && record.recommendations.length > 0) {
      out += `\nRecommendations:\n${record.recommendations.map(r => `  • ${r}`).join("\n")}`;
    }
  }

  if (record.tags.length > 0) {
    out += `\nTags: ${record.tags.join(", ")}`;
  }
  if (record.relatedIds.length > 0) {
    out += `\nRelated: ${record.relatedIds.join(", ")}`;
  }

  return out;
}

// ── Commands ─────────────────────────────────────────────────────────────────

function cmdSearch(args) {
  const query = args._.slice(1).join(" ");
  if (!query) {
    console.log(JSON.stringify({ error: "Usage: search <query> [--type <type>] [--limit <n>]" }));
    return;
  }

  const typeIdx = args.type ? args.type : null;
  const limit = parseInt(args.limit || "10", 10);

  const db = getDb();

  try {
    // Try FTS
    const ftsQuery = query.split(/\s+/).map(t => `"${t.replace(/"/g, "")}"`).join(" OR ");
    let sql = `SELECT r.*, rank FROM records_fts fts JOIN records r ON r.id = fts.id WHERE records_fts MATCH ?`;
    const params = [ftsQuery];
    if (typeIdx) { sql += " AND r.type = ?"; params.push(typeIdx); }
    sql += " ORDER BY rank LIMIT ?"; params.push(limit);

    const rows = db.prepare(sql).all(...params);
    if (rows.length > 0) {
      const results = rows.map(row => {
        const rec = loadRelations(db, rowToRecord(row));
        return { ...rec, relevanceScore: 1 / (1 + Math.abs(row.rank)) };
      });
      console.log(JSON.stringify({ query, count: results.length, results }, null, 2));
      return;
    }
  } catch { /* fall through to LIKE */ }

  // LIKE fallback
  const likeQ = `%${query}%`;
  let sql2 = `SELECT * FROM records WHERE (title LIKE ? OR summary LIKE ? OR decision LIKE ? OR reason LIKE ? OR problem LIKE ? OR root_cause LIKE ? OR fix LIKE ? OR rule LIKE ? OR issue LIKE ? OR workaround LIKE ? OR resolution LIKE ? OR outcome LIKE ?)`;
  const params2 = Array(12).fill(likeQ);
  if (typeIdx) { sql2 += " AND type = ?"; params2.push(typeIdx); }
  sql2 += " ORDER BY date DESC LIMIT ?"; params2.push(limit);

  const rows2 = db.prepare(sql2).all(...params2);
  const results = rows2.map((row, i) => {
    const rec = loadRelations(db, rowToRecord(row));
    return { ...rec, relevanceScore: 1 / (1 + i) };
  });
  console.log(JSON.stringify({ query, count: results.length, results }, null, 2));
}

function cmdGet(args) {
  const id = args._[1];
  if (!id) { console.log(JSON.stringify({ error: "Usage: get <id>" })); return; }

  const db = getDb();
  const row = db.prepare("SELECT * FROM records WHERE id = ?").get(id);
  const record = loadRelations(db, rowToRecord(row));
  console.log(JSON.stringify(record, null, 2));
}

function cmdRelated(args) {
  const id = args._[1];
  if (!id) { console.log(JSON.stringify({ error: "Usage: related <id>" })); return; }

  const db = getDb();
  const rows = db.prepare(`
    SELECT r.* FROM records r
    JOIN record_relations rel ON rel.target_id = r.id WHERE rel.source_id = ?
    UNION
    SELECT r.* FROM records r
    JOIN record_relations rel ON rel.source_id = r.id WHERE rel.target_id = ?
  `).all(id, id);
  const results = rows.map(row => loadRelations(db, rowToRecord(row)));
  console.log(JSON.stringify({ source: id, count: results.length, related: results }, null, 2));
}

function cmdList(args) {
  const type = args.type || null;
  const db = getDb();

  let rows;
  if (type) {
    rows = db.prepare("SELECT * FROM records WHERE type = ? ORDER BY date DESC").all(type);
  } else {
    rows = db.prepare("SELECT * FROM records ORDER BY date DESC").all();
  }
  const results = rows.map(row => loadRelations(db, rowToRecord(row)));
  console.log(JSON.stringify({ count: results.length, records: results }, null, 2));
}

function cmdStats(args) {
  const db = getDb();
  const total = (db.prepare("SELECT COUNT(*) as n FROM records").get()).n;
  const byType = db.prepare("SELECT type, COUNT(*) as n FROM records GROUP BY type").all();
  const byStatus = db.prepare("SELECT status, COUNT(*) as n FROM records GROUP BY status").all();
  console.log(JSON.stringify({
    total,
    byType: Object.fromEntries(byType.map(r => [r.type, r.n])),
    byStatus: Object.fromEntries(byStatus.map(r => [r.status, r.n])),
  }, null, 2));
}

// ── Main ─────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const command = args[0];

// Parse --flags
const flags = { _: [command] };
for (let i = 1; i < args.length; i++) {
  if (args[i].startsWith("--")) {
    const key = args[i].slice(2);
    const val = args[i + 1] && !args[i + 1].startsWith("--") ? args[++i] : true;
    flags[key] = val;
  } else {
    flags._.push(args[i]);
  }
}

switch (command) {
  case "search": cmdSearch(flags); break;
  case "get": cmdGet(flags); break;
  case "related": cmdRelated(flags); break;
  case "list": cmdList(flags); break;
  case "stats": cmdStats(flags); break;
  case "seed":
    console.log(JSON.stringify({ error: "Run seed-station-memory.ts directly" }));
    break;
  default:
    console.log("Station Memory Tool — agent interface");
    console.log("");
    console.log("Commands:");
    console.log("  search <query> [--type <type>] [--limit <n>]  Search knowledge base");
    console.log("  get <id>                                        Get record by ID");
    console.log("  related <id>                                    Get all related records");
    console.log("  list [--type <type>]                            List all records");
    console.log("  stats                                           Database statistics");
    console.log("");
    console.log("Types: architecture-decision, lesson-learned, incident-knowledge,");
    console.log("       completed-task-summary, operational-decision, framework-rule,");
    console.log("       runbook, known-issue");
}
