#!/usr/bin/env bash
# station-memory-commit-hook.sh – Post-commit hook to ingest commit metadata into Station Memory
# Arguments: $1 = commit hash (provided by Git as $GIT_COMMIT)
# This script is intended to be placed in .git/hooks/post-commit and called by Git.

set -e

COMMIT_HASH="$1"
# Resolve repository root and name
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")

# Gather commit info
COMMIT_MESSAGE=$(git log -1 --pretty=%B "$COMMIT_HASH")
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r "$COMMIT_HASH" | tr '\n' ',' | sed 's/,$//')

# Insert commit record into Station Memory (skip if already exists)
node - <<'NODE'
const Database = require('better-sqlite3');
const { join } = require('node:path');
const WORKSPACE = "/Users/spacemonkey/.openclaw/workspace";
const db = new Database(join(WORKSPACE, 'data', 'station-memory.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Check if record already exists for this commit
const existing = db.prepare('SELECT 1 FROM records WHERE id = ?').get(process.argv[2]);
if (existing) {
  console.log('Commit already present in Station Memory, skipping');
  db.close();
  process.exit(0);
}

const insert = db.prepare(`
  INSERT INTO records (id, type, title, summary, files_changed, status, date, author, source,
                       commit_hash, commit_message, commit_repo, created_at, updated_at)
  VALUES (?, 'commit', ?, ?, ?, 'current', ?, ?, 'commit-ingest', ?, ?, ?, ?, ?)
`);
const now = new Date().toISOString();
const filesArr = process.argv[5] ? process.argv[5].split(',') : [];
insert.run(
  process.argv[2],          // id (commit hash)
  process.argv[3],          // title (commit message first line)
  process.argv[4],          // summary (full commit message)
  JSON.stringify(filesArr), // files_changed
  now.slice(0, 10),         // date
  'monkey',                 // author
  process.argv[2],          // commit_hash
  process.argv[3],          // commit_message (short title)
  process.argv[1],          // commit_repo (repo name)
  now,                      // created_at
  now                       // updated_at
);

// Also add tag "commit" and repo name
const tagStmt = db.prepare('INSERT OR IGNORE INTO record_tags (record_id, tag) VALUES (?, ?)');
tagStmt.run(process.argv[2], 'commit');
tagStmt.run(process.argv[2], process.argv[1]);

console.log('Station Memory commit record inserted for ' + process.argv[2]);
db.close();
NODE "$REPO_NAME" "$COMMIT_HASH" "$COMMIT_MESSAGE" "$CHANGED_FILES"