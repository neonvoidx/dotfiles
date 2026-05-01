---
name: Atlassian SD MCP Server
description: Install recipe for mcp-atlassian targeting the Jira Service Desk instance
metadata:
  owner: platform_org
  last_updated: 2026-03-22
---

# Atlassian SD MCP Server (Jira Service Desk)

Same `mcp-atlassian` package as the primary Atlassian server, configured against the Jira Service Desk instance. Provides access to OTS tickets and service desk workflows.

## Prereqs

Same as the primary Atlassian server — `uv`/`uvx` required. See [atlassian.md](atlassian.md).

## Install

No separate installation needed. This server uses the same `mcp-atlassian` package via uvx. The pack template differentiates it by pointing at the SD Jira URL and omitting Confluence flags.

If you installed the Atlassian server from the fork (Option B in [atlassian.md](atlassian.md)), this server uses the same local checkout.

## Auth

Web session — same mechanism as the primary Atlassian server. The user must be logged into the SD Jira instance in their browser.

## Verify

```bash
uvx --python 3.12 --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple" mcp-atlassian --help
```

If this works, atlassian-sd will work — it's the same binary with different config.

## Failure modes

Same as [atlassian.md](atlassian.md). The most common SD-specific issue is not being logged into the SD Jira instance (separate from the primary Jira instance).
