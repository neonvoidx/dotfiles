---
name: OTS MCP Server
description: Install recipe for the OTS MCP server — uvx from Artifactory with OCI profile auth
metadata:
  owner: platform_org
  last_updated: 2026-03-31
---

# OTS MCP Server

Provides OTS ticket read access for incident triage and handoff workflows.

## Prereqs

- `uv` / `uvx`
- OCI config file exists at `~/.oci/config`
- The configured OCI profile exists (pack default: `DEFAULT`)

Verify prereqs:

```bash
uv --version
test -f ~/.oci/config && echo "OCI config exists" || echo "OCI config MISSING"
grep -n "^\[DEFAULT\]" ~/.oci/config || echo "OCI profile DEFAULT not found"
```

## Install

No pre-install needed. The pack template uses `uvx` to pull `ots_mcp@latest` from Artifactory's release PyPI at runtime.

Verify the Artifactory index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/ots-mcp/" | head -5
```

## Auth

This server reads OCI SDK configuration from:

- `OCI_CONFIG` (pack default: `~/.oci/config`)
- `OCI_PROFILE` (pack default: `DEFAULT`)

Do not write credentials into pack files. If auth fails, fix the local OCI config/profile.

## Verify

Start the server and confirm it stays up on stdio:

```bash
OCI_CONFIG="$HOME/.oci/config" OCI_PROFILE="DEFAULT" \
  uvx --python 3.12 --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  ots_mcp@latest
```

It should start and wait for MCP protocol messages. Ctrl-C to stop.

## Failure modes

- **Artifactory unreachable** — check VPN/network access to Oracle Artifactory.
- **OCI config/profile mismatch** — `OCI_PROFILE` not present in `OCI_CONFIG`.
- **Auth errors from OTS API** — local OCI account may not have OTS access; verify account permissions.
