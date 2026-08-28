---
name: Confluence MCP Server
description: Install recipe for the Confluence MCP server — upstream mcp-atlassian from the global-dev Artifactory index, web-session auth
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Confluence MCP Server

Provides access to Confluence — page retrieval, search, comments, labels, attachments. Uses the **upstream** `mcp-atlassian` package (not the TCT Jira-only fork, which has Confluence support stripped).

## Prereqs

- `uv` / `uvx`
- A logged-in Confluence session in your browser (for web-session auth)

Verify prereqs:

```bash
uv --version
```

## Install

No separate installation needed. The pack's MCP config uses `uvx` to pull upstream `mcp-atlassian` from the global-dev Artifactory index at runtime:

- Index: `{params.artifactory_dev_pypi:-https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple}`

Verify the index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple/mcp-atlassian/" | head -5
```

If the index returns HTML with package links, `uvx` will resolve the package on first run (~60-90s). Subsequent starts are fast.

## Auth

Uses web-session SSO — no API token or PAT required. The pack config passes `--confluence-use-web-session` to `mcp-atlassian`, which reads session cookies from the user's browser. You must be logged into `confluence.oraclecorp.com` in your browser for auth to succeed.

## Verify

```bash
uvx --python 3.12 \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple" \
  mcp-atlassian --help
```

If the command prints help text, `uvx` will resolve the package at runtime.

## Failure modes

- **Global-dev Artifactory unreachable** — check VPN. Verify with the curl command above.
- **Not logged into Confluence** — tool calls will fail with 401 errors. Log into `confluence.oraclecorp.com` in your browser and retry.
- **SSO session expired** — browser session expired or cookies cleared. Log back in.
- **Connected but no Confluence tools** — confirm the command uses upstream `mcp-atlassian` from global-dev with `--confluence-use-web-session`. The TCT Jira fork intentionally does not provide Confluence support.
- **First run slow** — normal. `uvx` fetches the package from Artifactory. Subsequent starts are fast.

## Why is this a separate server from `jira` and `jira-sd`?

In v0.3.0 of `oci-dev-starter-pack`, the former `atlassian` server was split into `jira`, `jira-sd`, and `confluence`. The split reflects a real difference in package sourcing and auth:

- `jira` / `jira-sd` use the **TCT/Ticketing team's hardened fork** from a private ticketing Artifactory index, with PAT auth and read-only guardrails
- `confluence` uses the **upstream** `mcp-atlassian` package from the shared global-dev index, with web-session auth

Splitting them lets each half use its correct package source and auth model independently.

## Related

- Primary Jira: [jira.md](jira.md)
- Jira Service Desk: [jira-sd.md](jira-sd.md)
