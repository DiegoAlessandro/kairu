# Security

## Architecture

Kairu communicates with a **local** OpenClaw AI gateway running in Docker.
No data leaves your machine unless the AI model itself makes external API calls.

```
User Input → Kairu App → docker exec (stdin) → OpenClaw Container → AI Model
```

## Security Measures

### Input Handling
- User messages are sent via **stdin pipe**, never as command-line arguments
- This prevents input from appearing in `ps` output or process listings
- A temporary file inside the container is used for message passing, then immediately deleted

### Connection
- All communication is **localhost only** (Docker exec / `127.0.0.1`)
- No network listeners are opened by the Kairu app itself
- OpenClaw gateway binds to `127.0.0.1` (not exposed to LAN by default)

### Authentication
- OpenClaw manages its own auth tokens (OAuth) inside the container
- Kairu does not store or handle any API keys directly
- Auth tokens are in container volumes, not in the app bundle

### Permissions
- The app runs as a regular user process
- `LSUIElement = true` (no Dock presence, minimal surface)
- No special entitlements required beyond network client

## Reporting Vulnerabilities

If you find a security issue, please email diegobacigalupo8@gmail.com
instead of opening a public issue. We aim to respond within 48 hours.
