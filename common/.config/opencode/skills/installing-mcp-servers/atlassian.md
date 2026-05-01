---
name: Atlassian MCP Server
description: Install recipe for mcp-atlassian (Jira + Confluence) — uvx from Artifactory or clone from internal fork
metadata:
  owner: platform_org
  last_updated: 2026-03-22
---

# Atlassian MCP Server (Jira + Confluence)

Provides access to Jira and Confluence — issue search, page retrieval, comments, labels.

## Prereqs

- `uv` / `uvx`

For the clone option (Option B):
- `git`
- SSH access to OCI DevOps

Verify prereqs:

```bash
uv --version
```

## Option A: uvx (no pre-install needed)

The pack's MCP config uses `uvx` to pull `mcp-atlassian` from Artifactory at runtime. No pre-install step required. The first run is slow (~60-90s) as it fetches the package and dependencies.

Verify the Artifactory index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple/mcp-atlassian/" | head -5
```

If the index returns HTML with package links, uvx will work. No further action needed.

## Option B: clone from internal fork (faster startup)

If the uvx pull is too slow or you want a local checkout:

```bash
git clone --depth 1 ssh://oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com/namespaces/axuxirvibvvo/projects/bfs/repositories/mcp-atlassian \
  ~/.local/share/mcp-servers/mcp-atlassian

cd ~/.local/share/mcp-servers/mcp-atlassian
uv venv
uv sync
```

When using the local clone, the MCP config command needs to point at the local checkout instead of using uvx. The command changes from `uvx ... mcp-atlassian` to:

```json
["uv", "run", "--project", "{env:HOME}/.local/share/mcp-servers/mcp-atlassian", "mcp-atlassian", "--jira-url", "..."]
```

**MUTATION:** This modifies pack source at `mcp/atlassian.json`. Confirm with the user before editing. Note that pack updates or reinstalls will overwrite this change.

## Auth

Uses web session (SSO cookies). No API token needed. The `--jira-use-web-session` and `--confluence-use-web-session` flags are set in the pack template.

The user must be logged into Jira and Confluence in their browser for auth to work.

## Verify

For Option A (uvx):

```bash
uvx --python 3.12 --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple" mcp-atlassian --help
```

For Option B (local clone):

```bash
cd ~/.local/share/mcp-servers/mcp-atlassian && uv run mcp-atlassian --help
```

## Failure modes

- **Artifactory unreachable** — check VPN connection. Verify with `curl -s <index_url> | head -5`.
- **uvx first run takes >2 minutes** — normal for large dependency trees. Consider Option B for faster subsequent starts.
- **Web session auth fails** — user is not logged into Jira/Confluence in their browser, or SSO session expired. Log in and retry.
