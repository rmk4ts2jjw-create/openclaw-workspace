const fs = require('fs');
const path = '/Users/spacemonkey/.openclaw/workspace/memory/heartbeat-state.json';
let state = JSON.parse(fs.readFileSync(path, 'utf8'));

// Ensure lastChecks exists
if (!state.lastChecks) state.lastChecks = {};

// Get current time in seconds
const now = parseInt(`${require('child_process').execSync('date +%s')}`);

const items = ["weather", "git_commit", "memory_maintenance", "heartbeat"];
const intervals = {
  weather: 21600, // 6 hours
  git_commit: 14400, // 4 hours
  memory_maintenance: 86400, // 24 hours
  heartbeat: 43200 // 12 hours
};

let nextToCheck = state.nextToCheck || 0;
let item = items[nextToCheck];
let lastCheck = state.lastChecks[item] || 0;
let interval = intervals[item];

let performed = false;
let result = '';

if (now - lastCheck >= interval) {
  performed = true;
  state.lastChecks[item] = now;

  // Perform the check based on item
  switch (item) {
    case 'weather':
      // Fetch weather from wttr.in for London
      try {
        const { execSync } = require('child_process');
        const weather = execSync('curl -s "wttr.in/London?format=3"').toString().trim();
        result = `Weather: ${weather}`;
      } catch (e) {
        result = 'Weather check failed';
      }
      break;
    case 'git_commit':
      try {
        const { execSync } = require('child_process');
        // Check if there are changes
        const status = execSync('git status --porcelain', { cwd: '/Users/spacemonkey/.openclaw/workspace' }).toString().trim();
        if (status) {
          // There are changes, commit and push
          execSync('git add -A', { cwd: '/Users/spacemonkey/.openclaw/workspace' });
          execSync('git commit -m "Heartbeat commit: automated commit from heartbeat"', { cwd: '/Users/spacemonkey/.openclaw/workspace' });
          execSync('git push', { cwd: '/Users/spacemonkey/.openclaw/workspace' });
          result = 'Git: Changes committed and pushed';
        } else {
          result = 'Git: No changes to commit';
        }
      } catch (e) {
        result = `Git check failed: ${e.message}`;
      }
      break;
    case 'memory_maintenance':
      try {
        // Update MEMORY.md from recent daily notes
        const { execSync } = require('child_process');
        const yesterday = new Date((now - 86400) * 1000).toISOString().slice(0,10); // YYYY-MM-DD
        const dailyNotePath = `/Users/spacemonkey/.openclaw/workspace/memory/${yesterday}.md`;
        let notable = [];
        try {
          const content = execSync(`cat ${dailyNotePath}`).toString();
          const lines = content.split('\n');
          notable = lines.filter(line => {
            const lower = line.toLowerCase();
            return lower.includes('decided') || lower.includes('lesson') || lower.includes('idea') || 
                   lower.includes('todo') || lower.includes('blocked') || lower.includes('breakthrough') || 
                   lower.includes('insight') || lower.includes('') ; // we'll take all lines for now, but we can refine
          });
          // Limit to 5 lines
          notable = notable.slice(0,5);
        } catch (e) {
          // Daily note might not exist
          notable = [];
        }
        if (notable.length > 0) {
          // Update MEMORY.md
          const memopath = '/Users/spacemonkey/.openclaw/workspace/MEMORY.md';
          let memo = fs.existsSync(memopath) ? fs.readFileSync(memopath, 'utf8') : '';
          // Avoid duplicating today's date section
          const dateSection = `\n## ${yesterday}\n`;
          if (!memo.includes(dateSection)) {
            memo += dateSection;
            notable.forEach(line => {
              memo += `- ${line.trim()}\n`;
            });
            fs.writeFileSync(memopath, memo);
            result = `Memory: Updated MEMORY.md with ${notable.length} items from ${yesterday}`;
          } else {
            result = `Memory: Section for ${yesterday} already exists in MEMORY.md`;
          }
        } else {
          result = `Memory: No notable items found in ${yesterday}.md`;
        }
      } catch (e) {
        result = `Memory maintenance failed: ${e.message}`;
      }
      break;
    case 'heartbeat':
      try {
        const { execSync } = require('child_process');
        // List cron jobs
        const cronList = execSync('cron list').toString().trim();
        result = `Heartbeat: Cron jobs listed.${cronList ? '\\n' + cronList : ''}`;
      } catch (e) {
        result = `Heartbeat check failed: ${e.message}`;
      }
      break;
    default:
      result = `Unknown item: ${item}`;
  }
} else {
  result = `Skipped ${item} (last checked ${Math.floor((now - lastCheck)/3600)} hours ago)`;
}

// Advance the pointer
state.nextCheck = (nextToCheck + 1) % items.length;

// Write back state
fs.writeFileSync(path, JSON.stringify(state, null, 2));

console.log(result);