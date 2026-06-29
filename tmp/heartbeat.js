const fs = require('fs');
const path = '/Users/spacemonkey/.openclaw/workspace/memory/heartbeat-state.json';

// Read the state file
let state = {};
try {
  const data = fs.readFileSync(path, 'utf8');
  state = JSON.parse(data);
} catch (err) {
  console.error('Error reading state file:', err);
  // Initialize default state
  state = {
    lastChecks: {
      email: 0,
      calendar: 0,
      mentions: 0,
      weather: 0,
      memory_maintenance: 0
    }
  };
}

// Ensure lastChecks exists
if (!state.lastChecks) {
  state.lastChecks = {
    email: 0,
    calendar: 0,
    mentions: 0,
    weather: 0,
    memory_maintenance: 0
  };
}

// Ensure each key exists
const checkTypes = ['email', 'calendar', 'mentions', 'weather', 'memory_maintenance'];
checkTypes.forEach(type => {
  if (state.lastChecks[type] === undefined) {
    state.lastChecks[type] = 0;
  }
});

// Convert any seconds-based timestamps to milliseconds (if they look like seconds)
// We'll assume that if a timestamp is less than 10000000000 (i.e., less than year 2286 in ms), it's seconds.
// But we don't know. We'll just treat everything as milliseconds and if the value is small, we'll multiply by 1000.
// However, we have an existing weather timestamp that is in seconds (1782734081). We'll convert it.
// We'll check: if the value is less than 10000000000 (about year 2286 in ms) and greater than 1000000000 (year 2001 in seconds), then it's likely seconds.
// We'll convert it to ms by multiplying by 1000.
const now = Date.now();
console.log(`Current time: ${now}`);

checkTypes.forEach(type => {
  const val = state.lastChecks[type];
  if (typeof val === 'number' && val > 0 && val < 10000000000) {
    // Assume it's in seconds and convert to ms
    state.lastChecks[type] = val * 1000;
    console.log(`Converted ${type} from seconds to ms: ${state.lastChecks[type]}`);
  }
});

// Define intervals in milliseconds
const intervals = {
  email: 4 * 60 * 60 * 1000, // 4 hours
  calendar: 6 * 60 * 60 * 1000, // 6 hours
  mentions: 6 * 60 * 60 * 1000, // 6 hours
  weather: 12 * 60 * 60 * 1000, // 12 hours
  memory_maintenance: 2 * 24 * 60 * 60 * 1000 // 2 days
};

const due = {};
checkTypes.forEach(type => {
  const last = state.lastChecks[type];
  const interval = intervals[type];
  due[type] = (now - last) >= interval;
  console.log(`${type}: last=${last}, interval=${interval}, diff=${now - last}, due=${due[type]}`);
});

// We'll collect actions taken
const actions = [];

// Function to simulate checking email (we can't really do it, so we'll just note we skipped)
function checkEmail() {
  actions.push('Email: skipped (no capability)');
  // We still update the timestamp to avoid spamming
  state.lastChecks.email = now;
}

// Function to simulate checking calendar
function checkCalendar() {
  actions.push('Calendar: skipped (no capability)');
  state.lastChecks.calendar = now;
}

// Function to simulate checking mentions
function checkMentions() {
  actions.push('Mentions: skipped (no capability)');
  state.lastChecks.mentions = now;
}

// Function to check weather using web_fetch (we'll call the weather skill via web_fetch to wttr.in)
async function checkWeather() {
  try {
    // We'll use the weather skill by fetching from wttr.in for London
    // Format: wttr.in/London?format=3 gives a one-line summary
    const response = await fetch('https://wttr.in/London?format=3');
    const weatherText = await response.text();
    // Update the weather string in the state (top level)
    state.weather = weatherText.trim();
    // Also update the time and date fields for completeness
    const nowDate = new Date();
    state.date = nowDate.toISOString().split('T')[0];
    // Format time as HH:MM BST (we'll just use toLocaleTimeString with options)
    const options = { hour: '2-digit', minute: '2-digit', hour12: false, timeZone: 'Europe/London' };
    const time = new Date().toLocaleTimeString('en-GB', options);
    state.time = `${time} BST`;
    // Update the last check timestamp
    state.lastChecks.weather = now;
    actions.push(`Weather: updated to "${weatherText.trim()}"`);
  } catch (err) {
    console.error('Error fetching weather:', err);
    actions.push('Weather: failed to fetch');
    // Still update the timestamp to avoid retrying too soon
    state.lastChecks.weather = now;
  }
}

// Function to perform memory maintenance
function doMemoryMaintenance() {
  try {
    // Read the daily logs for the last 2 days (including today)
    const memoryDir = '/Users/spacemonkey/.openclaw/workspace/memory';
    const files = fs.readdirSync(memoryDir);
    const today = new Date().toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const filesToRead = [today, yesterday].map(date => `${date}.md`).filter(f => files.includes(f));
    
    let insights = [];
    filesToRead.forEach(file => {
      const content = fs.readFileSync(`${memoryDir}/${file}`, 'utf8');
      // Simple heuristic: look for lines that contain certain keywords
      const lines = content.split('\n');
      lines.forEach(line => {
        if (line.includes('LESSON') || line.includes('LEARNED') || line.includes('IDEA') || line.includes('TODO:') || line.includes('DECISION')) {
          insights.push(`[${file}] ${line.trim()}`);
        }
      });
    });
    
    // If we found insights, append them to MEMORY.md
    if (insights.length > 0) {
      const memoryPath = '/Users/spacemonkey/.openclaw/workspace/MEMORY.md';
      let memoryContent = '';
      try {
        memoryContent = fs.readFileSync(memoryPath, 'utf8');
      } catch (e) {
        // If file doesn't exist, start with a header
        memoryContent = '# MEMORY.md\n\n## Long-term memory\n\n';
      }
      const timestamp = new Date().toISOString();
      const newEntry = `\n## Memory update from heartbeat on ${timestamp}\n` + insights.map(i => `- ${i}`).join('\n') + '\n';
      fs.writeFileSync(memoryPath, memoryContent + newEntry);
      actions.push(`Memory: added ${insights.length} insights from daily logs`);
    } else {
      actions.push('Memory: no new insights found in recent logs');
    }
    
    // Update the last maintenance time
    state.lastChecks.memory_maintenance = now;
  } catch (err) {
    console.error('Error in memory maintenance:', err);
    actions.push('Memory: error during maintenance');
    // Still update the timestamp to avoid rapid retries
    state.lastChecks.memory_maintenance = now;
  }
}

// Execute due checks
if (due.email) {
  checkEmail();
}
if (due.calendar) {
  checkCalendar();
}
if (due.mentions) {
  checkMentions();
}
if (due.weather) {
  // We need to use async/await, so we'll use a promise
  checkWeather().then(() => {
    // After weather check, we'll continue to memory maintenance and then save
    if (due.memory_maintenance) {
      doMemoryMaintenance();
    }
    saveState();
  });
} else {
  if (due.memory_maintenance) {
    doMemoryMaintenance();
  }
  saveState();
}

function saveState() {
  try {
    fs.writeFileSync(path, JSON.stringify(state, null, 2));
    console.log('State saved successfully');
  } catch (err) {
    console.error('Error saving state:', err);
  }
}

// If weather is not due, we can save immediately after memory maintenance
if (!due.weather) {
  if (due.memory_maintenance) {
    doMemoryMaintenance();
  }
  saveState();
}

// We'll output the actions as the result of the script
console.log('ACTIONS:' + actions.join('|'));