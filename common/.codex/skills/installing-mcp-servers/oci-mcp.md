---
name: OCI MCP Server
description: Install recipe for the OCI Cloud MCP server — uvx from PyPI (oracle.oci-cloud-mcp-server)
metadata:
  owner: platform_org
  last_updated: 2026-04-09
---

# OCI MCP Server

Provides direct access to OCI SDK APIs — invoke any OCI service client operation in-process via the Python SDK. Distributed as `oracle.oci-cloud-mcp-server` on PyPI.

Two tools:
- `invoke_oci_api` — call any OCI SDK method by fully-qualified name
- `list_client_operations` — enumerate available SDK operations for a given service client

## Prereqs

- `uv` / `uvx`
- `python3` (3.13+) — `uvx --python 3.13` handles this automatically if not installed system-wide
- OCI CLI configured (`~/.oci/config` with a valid profile)

Verify prereqs:

```bash
uv --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
```

## Install

No separate installation. The pack's MCP config uses `uvx` to pull `oracle.oci-cloud-mcp-server` from PyPI at runtime:

```bash
uvx --python 3.13 oracle.oci-cloud-mcp-server --help
```

If the command responds, PyPI is reachable and the server will start under aipack.

## Auth

Uses OCI SDK auth — reads `~/.oci/config` automatically. The profile param `oci_config_profile` (default: `DEFAULT`) selects which OCI config profile. The pack config exports this as `OCI_PROFILE` and `OCI_CONFIG=~/.oci/config` via env.

Standard OCI CLI setup (`oci setup config` or `oci session authenticate`) is sufficient. No additional environment variables needed beyond what the pack config provides.

## Verify

```bash
uvx --python 3.13 oracle.oci-cloud-mcp-server --help
```

On first run, `uvx` fetches the package from PyPI (~10-30s). Subsequent starts are fast.

## Failure modes

- **PyPI unreachable** — check network. Verify with the command above.
- **OCI config missing** — run `oci setup config` or `oci session authenticate` to create `~/.oci/config`.
- **Wrong profile** — if `oci_config_profile` in your aipack profile points at a non-existent OCI config profile, all SDK calls fail. Check `grep '\[.*\]' ~/.oci/config` to list available profile names.
- **Python version mismatch** — the server requires Python 3.13+. The pack config pins `--python 3.13` so `uvx` will fetch the right Python even if your system version is older.
