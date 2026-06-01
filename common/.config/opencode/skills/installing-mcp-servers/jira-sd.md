---
name: Jira Service Desk MCP Server (TCT fork)
description: Install recipe for the Jira Service Desk MCP server — same TCT fork as the primary Jira server, configured against the SD instance
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Jira Service Desk MCP Server

Same `mcp-atlassian` fork as the primary [jira server](jira.md), configured against the Jira Service Desk instance (`jira-sd.mc1.oracleiaas.com`). Used for OTS tickets and service desk workflows.

## Prereqs

Same as [jira.md](jira.md). One additional requirement: a separate PAT for the SD Jira instance, stored in the `JIRA_SD_PAT` environment variable.

## Install

No separate installation. The pack config uses the same `uvx` + ticketing Artifactory index as the primary jira server. If you've verified [jira.md](jira.md), this server resolves too.

## Auth

Uses a Jira Service Desk PAT read from `JIRA_SD_PAT`. Create it in the SD Jira UI (`jira-sd.mc1.oracleiaas.com`) → Profile avatar → Personal Access Tokens. This is a **separate Jira instance** with its own PATs — your primary `JIRA_PAT` will not authenticate against the SD instance.

```bash
export JIRA_SD_PAT="<your-token>"
```

Persist it in your shell rc file the same way you handled `JIRA_PAT`.

## Read-only mode

Respects the shared `jira_read_only` profile param used by the primary Jira server. It defaults to `"true"` through the pack config; set `jira_read_only: "false"` to enable writes against both Jira instances in the same profile.

## Verify

Same `uvx ... mcp-atlassian --help` command as [jira.md](jira.md). If the primary jira server works, this one works too — they share the same binary, only the URL and PAT differ.

## Failure modes

- **Wrong PAT set** — the most common issue. Easy to mistakenly export `JIRA_PAT` when you meant `JIRA_SD_PAT`, or to use the primary PAT against the SD instance. The SD instance rejects primary Jira PATs with a 401.
- **Creating the PAT on the wrong host** — when creating the PAT, confirm your browser URL shows `jira-sd.mc1.oracleiaas.com`, not `jira.oci.oraclecorp.com`. Tokens created on one instance do not work on the other.
- **Connected but no useful Jira-SD tools** — inspect profile `allowed_tools`, confirm `JIRA_SD_PAT` is visible to the harness process, and keep this server on the TCT PAT-auth fork.

Everything else behaves identically to [jira.md](jira.md).
