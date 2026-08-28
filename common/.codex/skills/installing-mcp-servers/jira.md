---
name: Jira MCP Server (TCT fork)
description: Install recipe for the Jira MCP server — TCT/Ticketing team's Jira-only fork of mcp-atlassian from the ticketing Artifactory index
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Jira MCP Server (TCT Fork)

Provides access to the OCI Jira instance (`jira.oci.oraclecorp.com`) — issue search, retrieval, comments, transitions. Uses the Ticketing team's hardened fork of `mcp-atlassian`, which adds OCI-specific guardrails to protect Jira instances from queries that could cause outages.

## Prereqs

- `uv` / `uvx`
- A Jira Personal Access Token (PAT) — created in the OCI Jira UI under Profile → Personal Access Tokens

Verify prereqs:

```bash
uv --version
test -n "$JIRA_PAT" && echo "JIRA_PAT set" || echo "JIRA_PAT missing"
```

## Install

No separate installation needed. The pack's MCP config uses `uvx` to pull `mcp-atlassian` from the ticketing team's Artifactory index at runtime:

- Primary index: `https://artifactory.oci.oraclecorp.com/api/pypi/ticketing-fe-repository-dev-pypi-local/simple` — the TCT fork
- Dependency index: `{params.artifactory_release_pypi:-https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/}` — the shared global-release pypi mirror, used for the fork's transitive dependencies

Verify the ticketing Artifactory index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/ticketing-fe-repository-dev-pypi-local/simple/mcp-atlassian/" | head -5
```

If the index returns HTML with package links, `uvx` will resolve the package on first run. Expect ~60-90s on the first launch; subsequent starts are fast.

## Auth

Uses a Jira Personal Access Token read from the `JIRA_PAT` environment variable. The pack config wires it to the `JIRA_PERSONAL_TOKEN` env var that `mcp-atlassian` expects.

1. Create a PAT in the Jira UI: Profile avatar → Personal Access Tokens → Create token. Scope it to the permissions you need (read-only is sufficient for the pack's default tool list).
2. Export it in your shell:

```bash
export JIRA_PAT="<your-token>"
```

Add the export to your shell rc file (`~/.zshrc`, `~/.bashrc`, etc.) to persist across sessions.

## Read-only mode

The server respects a `READ_ONLY_MODE` env var, wired from the shared `jira_read_only` profile param with an inline default of `"true"` — the server refuses any write operation (create issue, add comment, transition, etc.). Set `jira_read_only: "false"` in your profile if you need writes against either the primary Jira or Jira Service Desk server.

## Verify

```bash
uvx --python 3.12 \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/ticketing-fe-repository-dev-pypi-local/simple" \
  mcp-atlassian --help
```

If the command prints help text, the fork is reachable and `uvx` will resolve it at runtime. The `--help` path doesn't require auth, so you can verify package resolution separately from PAT setup.

## Failure modes

- **Ticketing Artifactory unreachable** — check VPN. Verify with the curl command above. If the index is down, there is no fallback — this pack deliberately uses the TCT fork, not the upstream `mcp-atlassian` package.
- **`JIRA_PAT` not set** — the server starts but every tool call fails with auth errors. Check `test -n "$JIRA_PAT" && echo "JIRA_PAT set" || echo "JIRA_PAT missing"` in the shell that launched the harness.
- **PAT expired or revoked** — same symptoms as unset. Regenerate the PAT in Jira and update your env var.
- **Connected but no useful Jira tools** — inspect profile `allowed_tools`, confirm `JIRA_PAT` is visible to the harness process, and do not switch this server to web-session auth. The TCT fork is PAT-based.
- **Read-only mode blocking a write** — if a tool call fails with a read-only error, check the shared `jira_read_only` param in your active profile.

## Related

- Jira Service Desk access: [jira-sd.md](jira-sd.md)
- Confluence access: [confluence.md](confluence.md)
