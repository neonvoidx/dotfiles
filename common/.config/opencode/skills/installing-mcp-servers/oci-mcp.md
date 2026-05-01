---
name: OCI MCP Server
description: Install recipe for the OCI Cloud MCP server — clone from GitHub oracle/mcp and uv sync
metadata:
  owner: platform_org
  last_updated: 2026-03-22
---

# OCI MCP Server

Provides direct access to OCI SDK APIs — invoke any OCI service client operation in-process.

## Prereqs

- `git`
- `uv`
- `python3` (3.11+)
- OCI CLI configured (`~/.oci/config` with a valid profile)

Verify prereqs:

```bash
git --version && uv --version && python3 --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
```

## Install

The `oracle/mcp` GitHub repo is a monorepo containing many MCP servers. The one this pack uses is `oci-cloud-mcp-server` (Python SDK variant) at `src/oci-cloud-mcp-server`. A separate `oci-api-mcp-server` (OCI CLI variant) also exists in the repo — do not confuse the two.

```bash
git clone --depth 1 https://github.com/oracle/mcp.git \
  ~/.local/share/mcp-servers/mcp

cd ~/.local/share/mcp-servers/mcp/src/oci-cloud-mcp-server
uv venv
uv sync
```

The pack's MCP config references this path via the `mcp_servers_dir_rel` profile param (default: `.local/share/mcp-servers`). The full resolved path is `~/.local/share/mcp-servers/mcp/src/oci-cloud-mcp-server`.

## Auth

Uses OCI SDK auth — reads `~/.oci/config` automatically. Standard OCI CLI setup (`oci setup config`) is sufficient. No additional environment variables needed.

## Verify

```bash
cd ~/.local/share/mcp-servers/mcp/src/oci-cloud-mcp-server
uv run python -m oracle.oci_cloud_mcp_server.server
```

The server should start and wait on stdio. Ctrl-C to stop.

## Failure modes

- **OCI config missing** — run `oci setup config` to create `~/.oci/config`. You need a tenancy OCID, user OCID, region, and API key.
- **Path mismatch** — the most common issue. The directory name in the cloned repo doesn't match what the MCP config expects. See the path verification step above.
- **uv sync fails** — check Python version (`python3 --version`, must be 3.11+). Check that `uv` is up to date (`uv self update`).
- **Module not found at runtime** — the venv wasn't created in the right directory. Ensure `uv venv` and `uv sync` ran inside the server's directory, not the repo root.
