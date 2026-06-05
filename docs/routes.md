# Routes Manifest

## Active Routes

Routes are defined by the application itself in `mission-control-dashboard/src/routes/`. This file is a reference — the canonical route list is the route tree in the app.

For the current route listing, check:
```
mission-control-dashboard/src/routes/
```

## Testing Procedure

After any deploy or merge to production:
1. Start/restart the production server (LaunchAgent: `com.openclaw.mc.dashboard`)
2. Verify all routes return HTTP 200
3. Check the dev server on port 3001 for development testing

### Quick Health Check
```bash
# Production (port 3000)
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/

# Development (port 3001)
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/
```

For a full route-by-route check, use the application's API endpoints or manually verify each nav item in the sidebar.
