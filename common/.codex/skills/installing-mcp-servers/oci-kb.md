---
name: OCI KB MCP Server
description: Install recipe for the OCI KB MCP server — uvx from the global-release Artifactory index
metadata:
  owner: platform_org
  last_updated: 2026-04-09
---

# OCI KB MCP Server

Semantic search over all OCI internal developer documentation (`internal-docs.oraclecorp.com`). Uses OCI GenAI Agents with a RAG tool backed by a Knowledge Base containing every markdown file from the internal docs site. Cross-tenancy BOAT access policy enables any Oracle employee to query.

Two tools:
- `search(query, top_k)` — semantic search, returns source snippets with document IDs
- `getDocument(document_id)` — fetch full markdown content by ID

## Prereqs

- `uv` / `uvx`
- OCI CLI configured with security-token auth (`~/.oci/config`)

Verify prereqs:

```bash
uv --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
```

## Install

No separate installation needed. The pack's MCP config uses `uvx` to pull `oci-kb-mcp` from the global-release Artifactory index at runtime:

- Index: `{params.artifactory_release_pypi:-https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/}`

Verify the index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/oci-kb-mcp/" | head -5
```

If the index returns HTML with package links, `uvx` will resolve the package on first run.

## Auth

Uses OCI security-token auth. The profile param `oci_config_profile` (default: `DEFAULT`) selects which OCI config profile to use. The profile must include `security_token_file` and `key_file`.

If the token is expired:

```bash
oci session authenticate
```

The GenAI Agent endpoint is in `us-chicago-1`. The cross-tenancy policy allows any BOAT user to invoke the agent — no additional IAM setup on the user's side. The MCP config sets `OCI_REGION=us-chicago-1` as an env override so the agent call resolves correctly regardless of the user's default region.

## Verify

```bash
uvx --from oci-kb-mcp@latest \
  --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  ocikb-mcp-server --help
```

If the command responds, the package is reachable. The server reads OCI config on startup.

## Failure modes

- **Artifactory unreachable** — check VPN. Verify with the curl command above.
- **OCI session expired** — `search` calls fail with auth errors. Run `oci session authenticate` to refresh.
- **Wrong OCI profile** — if `oci_config_profile` in your aipack profile points at a non-existent OCI config profile, calls fail. Check `grep '\[.*\]' ~/.oci/config` to list available profile names.
- **First run slow** — `uvx` resolves and fetches the package on first launch. Subsequent starts are fast.
