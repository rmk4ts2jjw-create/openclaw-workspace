# Browser Automation Findings

**Date:** 2026-06-07
**Tested by:** OWL (subagent task-browser-auto-001)
**Browser:** OpenClaw dedicated Chrome profile (Chromium via CDP on port 18800)
**CLI version:** OpenClaw 2026.6.1

---

## Summary

The OpenClaw browser tool is a **CLI-driven Chromium browser** controlled via the `openclaw browser` command. It provides comprehensive browser automation capabilities through a Playwright-based backend. All core automation tasks — navigation, form filling, login flows, screenshots, PDF generation, and JavaScript evaluation — work reliably.

---

## Test Results

### 1. Navigation & Content Extraction ✅ PASS

**What was tested:** Navigate to a URL and extract page content via snapshots.

**Commands used:**
- `openclaw browser open "https://example.com" --label "example"`
- `openclaw browser snapshot` (AI format)
- `openclaw browser snapshot --format aria` (accessibility tree)
- `openclaw browser screenshot`
- `openclaw browser evaluate --fn '() => ({ title, url })'`

**Results:**
- Navigation is instant and reliable
- `snapshot` returns a structured accessibility tree with refs for interaction
- `--format aria` returns the raw accessibility tree (more verbose, no refs)
- Screenshots save to `~/.openclaw/media/browser/` as JPG
- `evaluate` runs arbitrary JS and returns JSON-serialized results
- Page title, URL, headings, paragraphs, links all extractable

**Limitations:**
- No `--json` flag on `status` command
- No `--target` flag on `snapshot` — must use `focus` first to switch tabs

---

### 2. Form Filling & Submission ✅ PASS

**What was tested:** Fill text fields, select radio buttons/checkboxes, submit a form.

**Test site:** `https://httpbin.org/forms/post` (pizza order form)

**Commands used:**
- `openclaw browser fill --fields '[{"ref":"e5","value":"Test User"}, ...]'`
- `openclaw browser click "e19"` (radio button)
- `openclaw browser click "e27"` (checkbox)
- `openclaw browser click "e44"` (submit button)

**Results:**
- `fill` command fills multiple fields at once via JSON array — very efficient
- Radio buttons and checkboxes clickable by ref
- Form submission navigates to the result page
- Server received all form data correctly (verified via httpbin response)
- 4 text fields + 2 clicks filled in seconds

**Limitations:**
- Must use `snapshot` first to get refs — cannot fill by CSS selector or name
- Refs are page-specific and change after navigation (must re-snapshot)

---

### 3. Login Flow ✅ PASS

**What was tested:** Complete login → access protected page → logout cycle.

**Test site:** `https://the-internet.herokuapp.com/login`

**Credentials:** `tomsmith` / `SuperSecretPassword!`

**Commands used:**
- `openclaw browser fill --fields '[{"ref":"e16","value":"tomsmith"},{"ref":"e20","value":"SuperSecretPassword!"}]'`
- `openclaw browser click "e21"` (Login button)
- `openclaw browser click "e12"` (Logout link)
- `openclaw browser navigate "https://the-internet.herokuapp.com/logout"` (fallback)

**Results:**
- Login successful — redirected to `/secure` with "You logged into a secure area!" message
- Session cookies persisted across navigation
- Logout via direct `navigate` worked
- Failed login (wrong credentials) correctly stayed on login page with error message
- Session management (cookies) works correctly

**Limitations:**
- Logout via `<a>` click didn't trigger navigation (the site uses JavaScript/AJAX for logout) — workaround: use `navigate` directly to the logout URL
- `wait --url "**/login"` timed out after 20s when the URL didn't change (expected behavior but important to know)
- HTTP Basic Auth (`httpbin.org/basic-auth/user/passwd`) fails at the network level (`ERR_INVALID_AUTH_CREDENTIALS`) — the browser can't handle HTTP auth challenges

---

### 4. JavaScript-Heavy SPA vs Static Pages ✅ PASS (both)

**Static page tested:** `https://example.com`
**SPA tested:** `https://react.dev` (Next.js, React 19, server components, interactive widgets)

**Results:**
- **Static pages:** Instant load, complete snapshot with all content
- **SPA (React.dev):** Full rendering of JavaScript-heavy content including:
  - Navigation links, search button, dark mode toggle
  - Code examples with syntax
  - Interactive combobox (event selector)
  - Video lists with 19+ items, each with links and Save buttons
  - Dynamic headings, paragraphs, images
  - All content accessible in the snapshot tree
- No difference in automation capability between static and SPA pages
- The browser fully renders JavaScript before snapshot (Playwright waits for load)

**Limitations:**
- Very large pages produce truncated snapshots (use `--limit` to control)
- Some SPA navigation (client-side routing) may not trigger full page load — use `wait` with specific conditions

---

### 5. Additional Features Tested

#### Tab Management ✅ PASS
- `openclaw browser tabs` — lists all open tabs with labels, URLs, and IDs
- `openclaw browser open <url> --label <name>` — opens new tab with label
- `openclaw browser focus <label>` — switches to tab by label
- `openclaw browser close <label>` — closes tab by label
- Labels make tab management reliable (no need to track raw IDs)

#### Screenshots ✅ PASS
- `openclaw browser screenshot` — saves to `~/.openclaw/media/browser/*.jpg`
- `--full-page` flag available for full-page screenshots
- `--ref <n>` available to screenshot a specific element

#### PDF Generation ✅ PASS
- `openclaw browser pdf` — saves current page as PDF to `~/.openclaw/media/browser/`

#### Cookies ✅ PASS
- `openclaw browser cookies` — lists all cookies with name, value, domain, expiry, httpOnly, secure, sameSite flags
- Session cookies persist across navigations within the same profile

#### Console Errors ✅ PASS
- `openclaw browser console --level error` — captures page console errors with timestamps and locations
- Useful for debugging failed resource loads and JS errors

#### Dropdown Selection ✅ PASS
- `openclaw browser select "ref" "Option Text"` — selects `<option>` in a `<select>` element
- Verified selection state in subsequent snapshot

#### Keyboard Input ✅ PASS
- `openclaw browser type "ref" "text"` — types text character by character into a field
- `openclaw browser press "Tab"` — moves focus to next element
- `openclaw browser press "Enter"` — submits form / activates element

#### JavaScript Evaluation ✅ PASS
- `openclaw browser evaluate --fn '() => expression'` — runs arbitrary JS
- Can access DOM, return computed values, trigger alerts
- Returns JSON-serialized results

#### Wait Commands ✅ PARTIAL
- `openclaw browser wait --text "string"` — waits for text to appear ✅
- `openclaw browser wait --url "**/pattern"` — waits for URL to match ✅ (but times out if URL doesn't change)
- `openclaw browser dialog --accept` — arms dialog handler (must be called BEFORE dialog appears) ⚠️

---

## Known Limitations & Workarounds

| Limitation | Workaround |
|---|---|
| No `--target` flag on most commands | Use `focus <label>` to switch tabs first |
| Refs expire after navigation | Always re-snapshot after page changes |
| HTTP Basic Auth fails | Use form-based login instead |
| AJAX links may not trigger navigation via click | Use `navigate` directly to the URL |
| `dialog --accept` must be pre-armed | Call before the action that triggers the dialog |
| Large pages truncate snapshots | Use `--limit` to increase node count |
| No direct CSS selector or XPath targeting | Use snapshot refs (e1, e2, ...) for all interactions |
| `wait --url` has 20s default timeout | Use only when URL is expected to change |

---

## Architecture Notes

- **Transport:** CDP (Chrome DevTools Protocol) on port 18800
- **Profile:** Dedicated "openclaw" profile (separate from user's browser)
- **Engine:** Playwright-based (inferred from command structure and behavior)
- **Headless:** No (runs with visible browser by default)
- **Browser detection:** Auto-detects Chrome at `/Applications/Google Chrome.app`

---

## Verdict

The OpenClaw browser automation tool is **production-ready** for:
- Web scraping and content extraction
- Form filling and submission
- Login/session-based workflows
- Screenshot and PDF generation
- JavaScript-heavy SPA interaction
- Multi-tab workflows

**Not suitable for:**
- HTTP Basic Auth (use form-based auth instead)
- Real-time dialog handling (requires pre-arming)
- Scenarios requiring CSS/XPath selectors (ref-based only)
