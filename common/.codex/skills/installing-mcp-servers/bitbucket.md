---
name: Bitbucket MCP Server
description: Install recipe for the Bitbucket Server MCP — uvx from the global-dev Artifactory index
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Bitbucket MCP Server

Provides access to Bitbucket Server — PRs, diffs, code browsing, search, PR comments and approvals.

## Prereqs

- `uv` / `uvx`
- A Bitbucket HTTP access token exported as `BITBUCKET_TOKEN` in your shell

Verify prereqs:

```bash
uv --version
test -n "$BITBUCKET_TOKEN" && echo "BITBUCKET_TOKEN set" || echo "BITBUCKET_TOKEN missing"
```

## Install

No separate installation needed. The pack's MCP config uses `uvx` to pull `bitbucket-mcp-server` from the global-dev Artifactory index at runtime:

- Index: `{params.artifactory_dev_pypi:-https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple}`

Verify the index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple/bitbucket-mcp-server/" | head -5
```

If the index returns HTML with package links, `uvx` will resolve the package on first run (~60-90s). Subsequent starts are fast.

## Auth

Two pieces, both expected in the shell environment or profile params:

- `BITBUCKET_URL` — defaults to `https://bitbucket.oci.oraclecorp.com`; override with the `bitbucket_url` profile param only for a different Bitbucket instance.
- `BITBUCKET_TOKEN` — a Bitbucket HTTP access token created in the Bitbucket UI at `<BITBUCKET_URL>/plugins/servlet/access-tokens/manage`. Export it in your shell rc (`~/.zshrc`, `~/.bashrc`) so every session picks it up:

```bash
export BITBUCKET_TOKEN="<your-token>"
```

## Read-only and safe-write modes

Read-only tools are always enabled in this pack. Safe-write tools remain opt-in through a profile param:

| Param | Env var | Effect when `"true"` |
|---|---|---|
| `bitbucket_enable_safe_write` | `BITBUCKET_ENABLE_SAFE_WRITE` | Exposes low-risk writes (add comment, approve PR, update PR metadata). |

The pack hardcodes `BITBUCKET_ENABLE_READ_ONLY=true` because the flag gates read tool registration, not access control. Safe-write defaults to `"false"`; the shipped `dev-elevated` profile overrides it to `"true"`.

## Project scoping

The pack defaults `MCP_PROJECT_DEFAULT` and `MCP_PROJECT_LIST` to empty values so the shared starter pack does not privilege any one team. The Bitbucket server treats an empty project list as unrestricted and an empty default as "no default"; tools that require a project will return "Project is required" unless the tool call provides one or your profile sets `bitbucket_project_default`. Set `bitbucket_project_list` only when you want to restrict the server to a comma-separated allowlist of project keys.

## Verify

```bash
uvx --python 3.12 \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple" \
  bitbucket-mcp-server --help
```

If the command prints help text, the package is reachable and `uvx` will resolve it at runtime. `--help` does not require auth, so you can verify package resolution separately from token setup.

## Failure modes

- **Global-dev Artifactory unreachable** — check VPN. Verify with the curl command above.
- **`BITBUCKET_TOKEN` not set** — the server starts but every tool call fails with auth errors. Check `test -n "$BITBUCKET_TOKEN" && echo "BITBUCKET_TOKEN set" || echo "BITBUCKET_TOKEN missing"` in the shell that launched the harness.
- **Token expired or revoked** — same symptoms. Regenerate at `<BITBUCKET_URL>/plugins/servlet/access-tokens/manage` and update your env var.
