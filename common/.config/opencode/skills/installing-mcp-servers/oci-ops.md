---
name: OCI-Ops MCP Server
description: Install recipe for oci-ops CLI MCP server — internal OCI CLI for substrate and overlay operations
metadata:
  owner: cloudshell_team
  last_updated: 2026-03-31
---

# OCI-Ops MCP Server

Internal OCI CLI exposing substrate and overlay operations as MCP tools. Services are modular — the `OCI_OPS_SERVICES` env var controls which tool modules are loaded (e.g. `scm` for PR/repo operations only).

## Prereqs

- Python 3.10+
- `uv` (for uv install method) or Homebrew (for macOS/Linux)
- OCI CLI configured (`~/.oci/config` with a valid profile)
- SSH agent running if using SCM operations over SSH

Setup guide: [OCI-OPS MCP Installation Guide](https://confluence.oraclecorp.com/confluence/display/CLOUDSHELL/OCI-OPS+MCP+Installation+Guide)

Verify prereqs:

```bash
python3 --version  # must be 3.10+
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
echo "${SSH_AUTH_SOCK:+SSH agent OK}" || echo "SSH agent not running"
```

## Install

The MCP server is bundled with the `oci-ops` CLI. Install the CLI and the server is available.

**Option A — uv (all platforms including Windows):**

```bash
uv tool install 'oci-ops[local]' --python 3.11 \
  --index-url=https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple
```

**Option B — Homebrew (macOS/Linux):**

```bash
brew tap cloudshell/oci-ops ssh://git@bitbucket.oci.oraclecorp.com:7999/cloudshell/homebrew-ociops.git
brew install cloudshell/oci-ops/oci-ops
```

After install, verify: `oci-ops --version`

The pack's MCP config invokes `oci-ops mcp --profile {params.oci_ops_profile}` directly.

## Auth

Uses OCI CLI config profile (controlled by `oci_ops_profile` param, default `DEFAULT`). SSH_AUTH_SOCK is forwarded for git-over-SSH operations.

## Params

| Param | Purpose | Default |
|---|---|---|
| `oci_ops_profile` | OCI CLI config profile name | `DEFAULT` |
| `oci_ops_services` | Comma-separated service modules to expose | `scm` |

Known services: `scm`, `sccp`, `ssv2`, `ticketing`, `shepherd`, `jira`, `runbooks`. Do NOT use `ALL` — the server exposes thousands of tools (full OCI CLI surface) which overwhelms LLM context and causes 500 errors.

## Verify

```bash
oci-ops mcp --profile DEFAULT
```

The server should start and wait on stdio. Ctrl-C to stop. If `--profile` is rejected, check `oci-ops mcp --help` for the correct flag name.

## Failure modes

- **`oci-ops` not found** — the binary is internal-only. Follow the Confluence install guide linked above.
- **Auth errors** — verify `oci-ops` works standalone first: `oci-ops scm list-repos --profile DEFAULT`.
- **No tools exposed** — `OCI_OPS_SERVICES` is empty or set to an invalid service name. Use `scm` for SCM operations.
- **500 errors / context overflow** — `OCI_OPS_SERVICES` set to `ALL`. Exposes the full OCI CLI surface (thousands of tools) which overwhelms LLM context. Scope to specific services.
- **SSH failures** — `SSH_AUTH_SOCK` not set or agent not running. Start with `eval $(ssh-agent)` and `ssh-add`.
- **Startup issues** — check logs at `~/.oci-ops/logs/oci-ops.log`.
