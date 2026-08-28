---
name: OCI-Ops MCP Server
description: Install recipe for oci-ops CLI MCP server — internal OCI CLI for substrate and overlay operations
metadata:
  owner: cloudshell_team
  last_updated: 2026-05-20
---

# OCI-Ops MCP Server

Internal OCI CLI exposing substrate and overlay operations as MCP tools. Services are modular — the `OCI_OPS_SERVICES` env var controls which tool modules are loaded (e.g. `scm` for PR/repo operations only).

## Prereqs

- `uv` / `uvx`
- Python 3.11 resolvable by `uvx`
- OCI CLI configured (`~/.oci/config` with a valid profile)
- SSH agent running if using SCM operations over SSH

Setup guide: [OCI-OPS MCP Installation Guide](https://confluence.oraclecorp.com/confluence/display/CLOUDSHELL/OCI-OPS+MCP+Installation+Guide)

Verify prereqs:

```bash
uv --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
test -n "$SSH_AUTH_SOCK" && echo "SSH agent OK" || echo "SSH agent not running"
```

## Install

No separate CLI installation is required for this pack's MCP startup path. The pack's MCP config runs `oci-ops mcp` through `uvx` from the global-release Artifactory index:

```bash
uvx --python 3.11 \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  oci-ops mcp --profile DEFAULT
```

Use the Confluence install guide only when the user wants the standalone `oci-ops` CLI outside MCP.

## Auth

Uses the same OCI CLI config profile param as the other OCI-backed servers (`oci_config_profile`, default `DEFAULT`). SSH_AUTH_SOCK is forwarded for git-over-SSH operations.

## Params

| Param | Purpose | Default |
|---|---|---|
| `oci_config_profile` | OCI CLI config profile name | `DEFAULT` |
| `oci_ops_services` | Comma-separated service modules to expose | `scm,shepherd,runbooks` |

Known services: `scm`, `sccp`, `ssv2`, `ticketing`, `shepherd`, `jira`, `runbooks`. Do NOT use `ALL` — the server exposes thousands of tools (full OCI CLI surface) which overwhelms LLM context and causes 500 errors.

## Verify

```bash
OCI_OPS_SERVICES="${OCI_OPS_SERVICES:-scm,shepherd,runbooks}" uvx --python 3.11 \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  oci-ops mcp --profile DEFAULT
```

The server should start and wait on stdio. Ctrl-C to stop. If package resolution fails, check VPN and global-release Artifactory access.

## Failure modes

- **Package resolution fails** — verify VPN and global-release Artifactory access; the pack uses `uvx`, not a preinstalled `oci-ops` binary.
- **Auth errors** — verify the OCI profile named by `oci_config_profile` works in `~/.oci/config`. If the standalone CLI is already installed, `oci-ops scm list-repos --profile DEFAULT` is an optional smoke test.
- **No tools exposed** — `OCI_OPS_SERVICES` is empty or set to an invalid service name. Use `scm,shepherd,runbooks` for the pack default or scope to one known service.
- **500 errors / context overflow** — `OCI_OPS_SERVICES` set to `ALL`. Exposes the full OCI CLI surface (thousands of tools) which overwhelms LLM context. Scope to specific services.
- **SSH failures** — `SSH_AUTH_SOCK` not set or agent not running. Start with `eval $(ssh-agent)` and `ssh-add`.
- **Startup issues** — check logs at `~/.oci-ops/logs/oci-ops.log`.
