---
name: OCI KB MCP Server
description: Install recipe for the OCI KB MCP server — clone from OCI DevOps SCM and run with uv
metadata:
  owner: platform_org
  last_updated: 2026-03-30
---

# OCI KB MCP Server

Semantic search over all OCI internal developer documentation (internal-docs.oraclecorp.com). Uses OCI GenAI Agents with a RAG tool backed by a Knowledge Base containing every markdown file from the internal docs site. Cross-tenancy BOAT access policy enables any Oracle employee.

Two tools:
- `search(query, top_k)` — semantic search, returns source snippets with document IDs
- `getDocument(document_id)` — fetch full markdown content by ID

## Prereqs

- `git` (with OCI DevOps SCM SSH access)
- `uv`
- `python3` (3.12+)
- OCI CLI configured with security-token auth (`~/.oci/config`)

Verify prereqs:

```bash
git --version && uv --version && python3 --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
```

## Install

Clone from OCI DevOps SCM into the MCP servers directory:

```bash
git clone ssh://oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com/namespaces/axuxirvibvvo/projects/developer_productivity_tools/repositories/oci_kb_mcp \
  ~/.local/share/mcp-servers/oci_kb_mcp
```

No separate build step needed — `uv run` resolves dependencies at first launch.

The pack's MCP config references this path via the `mcp_servers_dir_rel` profile param (default: `.local/share/mcp-servers`). The full resolved path is `~/.local/share/mcp-servers/oci_kb_mcp`.

## Auth

Uses OCI security-token auth. The profile param `oci_config_profile` (default: `DEFAULT`) selects the OCI config profile. The profile must include `security_token_file` and `key_file`.

If the token is expired:

```bash
oci session authenticate
```

The GenAI Agent endpoint is in us-chicago-1. The cross-tenancy policy allows any BOAT user to invoke the agent — no additional IAM setup is needed on the user's side.

## Verify

```bash
cd ~/.local/share/mcp-servers/oci_kb_mcp
uv run ocikb-mcp-server
```

The server should start FastMCP on stdio. Ctrl-C to stop.

## Failure modes

- **SSH clone fails** — verify OCI DevOps SCM SSH access. Test with `ssh -T oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com 2>&1 | head -1`.
- **OCI session expired** — `search` calls will fail with auth errors. Run `oci session authenticate` to refresh.
- **GenAI Agent endpoint unreachable** — the agent is hosted in us-chicago-1. If your OCI config points to a different region, the env var `OCI_REGION=us-chicago-1` in the MCP config handles the override.
- **First run slow** — `uv run` resolves and installs dependencies on first launch. Subsequent starts are fast.
