# mcp-atlassian web session troubleshooting

## Mechanism

`mcp-atlassian` with `--jira-use-web-session` (or `--confluence-use-web-session`) uses **Playwright** to manage browser-based authentication. It does NOT use `browser_cookie3`.

### State file location

```
~/.atlassian/<sha256_of_url>.json
```

Each target URL gets its own state file. Compute the filename:

```python
from hashlib import sha256
sha256("https://jira-sd.mc1.oracleiaas.com".encode()).hexdigest()
# → 6da09e15f1f2a7cb1b4e93652d25986a5a4d1a7b88c345c8e11963abbf355842
```

### TTL

State files are valid for **6 hours** (`token_ttl = 3600 * 6` in `utils/web.py`). After 6 hours, the MCP server should launch a Playwright browser for interactive re-authentication on next startup.

### Browser selection

Defaults to Chrome. Override with environment variables:
- `MCP_BROWSER` — `chrome` (default) or `msedge`
- `MCP_BROWSER_PATH` — explicit executable path
- `MCP_BROWSER_RDP_URL` — connect to existing browser via CDP

## Diagnosing 401 errors

When `mcp-atlassian` returns `Authentication failed for Jira API (401)`:

1. **Check the state file age:**
   ```bash
   ls -la ~/.atlassian/<hash>.json
   ```
   If older than 6 hours, the cached session is expired.

2. **Check if Playwright re-auth triggered:**
   On MCP restart, if the state file is expired, Playwright should open a Chrome window for login. If running as a background process (e.g., spawned by an agent harness), the browser window may not appear or may fail silently.

3. **Fix: delete the state file and reconnect:**
   ```bash
   rm ~/.atlassian/<hash>.json
   ```
   Then restart the MCP server (e.g., `/mcp` → reconnect in Claude Code). Playwright will open Chrome for SSO authentication. Complete the login in the browser window.

4. **If the browser doesn't appear:** Check that Chrome is installed and Playwright can launch it. The MCP server sets `PLAYWRIGHT_BROWSERS_PATH` to `~/.atlassian/` — Playwright browser binaries may need to be installed there.

## Multiple Jira instances

Each instance gets its own state file with independent TTL. One instance can be authenticated while another is expired. The `atlassian` and `atlassian-sd` MCP servers in `.mcp.json` point to different URLs and maintain separate state files.

| MCP server | URL | State file hash prefix |
|---|---|---|
| `atlassian` | `jira.oci.oraclecorp.com` | `f2d0e857...` |
| `atlassian-sd` | `jira-sd.mc1.oracleiaas.com` | `6da09e15...` |

## Source reference

Auth logic: `mcp_atlassian/utils/web.py` — `login_and_save_state()`, `get_cookies_from_state()`, `get_state_file()`
Config: `mcp_atlassian/jira/config.py` — `auth_type = "web"` when `JIRA_USE_WEB_SESSION` is truthy
