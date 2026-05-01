---
name: DOPE MCP Server
description: Install recipe for the DevOps Platform Engineering MCP server — uvx from Artifactory or clone from OCI DevOps
metadata:
  owner: platform_org
  last_updated: 2026-03-31
---

# DOPE MCP Server

Provides access to DevOps Platform Engineering tools — Shepherd deployments, Grafana dashboards, alarms, logging, metrics, phonebook, and runbooks.

## Prereqs

- `uv` / `uvx`
- `DOPE_ENV_FILE` environment variable set and pointing to a valid DOPE env file

Verify prereqs:

```bash
uv --version
echo "DOPE_ENV_FILE=$DOPE_ENV_FILE"
test -f "$DOPE_ENV_FILE" && echo "env file exists" || echo "env file MISSING"
```

## Install

No pre-install needed. The pack template uses `uvx` to pull `devops_mcp@latest` from Artifactory's release PyPI at runtime.

Verify the Artifactory index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/devops-mcp/" | head -5
```

## Option B: clone from source (faster startup)

If the uvx pull is too slow or you want a local checkout:

```bash
git clone --depth 1 ssh://oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com/namespaces/axuxirvibvvo/projects/developer_productivity_tools/repositories/devops_mcp \
  ~/.local/share/mcp-servers/devops_mcp

cd ~/.local/share/mcp-servers/devops_mcp
uv venv
uv sync
```

When using the local clone, the MCP config command changes from `uvx ... devops_mcp@latest` to:

```json
["uv", "run", "--project", "{env:HOME}/.local/share/mcp-servers/devops_mcp", "devops_mcp"]
```

**MUTATION:** This modifies pack source at `mcp/dope.json`. Confirm with the user before editing. Note that pack updates or reinstalls will overwrite this change.

## Auth

Credentials are loaded from an env file. `DOPE_ENV_FILE` must be set in the shell environment and point to this file. The file contents and setup instructions are in the DOPE team's onboarding guide.

If `DOPE_ENV_FILE` is not set or the file doesn't exist, the server will fail to start. Do not create or populate the env file — direct the user to the DOPE onboarding guide.

## Tool profiles

The DOPE server exposes 80+ tools across 17 profiles. To avoid overwhelming the agent with irrelevant tools, set `ENABLED_PROFILES` to a comma-delimited list of profile names. Only tools belonging to those profiles will be registered.

```bash
ENABLED_PROFILES=shepherd,grafana,alarms,canary,metrics,logs,info
```

If `ENABLED_PROFILES` is unset, all tools remain enabled (backward compatible). Unprofiled tools also remain enabled regardless of the setting.

Available profiles: `accounts`, `alarms`, `canary`, `grafana`, `info`, `limits`, `logs`, `metrics`, `odo`, `regionbuild`, `runbooks`, `securitycentral`, `serviceregistry`, `shepherd`. Full mapping is in `APP_PROFILES.md` in the devops_mcp repo:

```bash
git clone ssh://oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com/namespaces/axuxirvibvvo/projects/developer_productivity_tools/repositories/devops_mcp
```

When using aipack, this is handled automatically — each pack profile sets `dope_enabled_profiles` as a param, and the DOPE MCP config reads it as `ENABLED_PROFILES`. No manual env var setup needed.

## Verify

The DOPE server does not support `--help`. Start it and confirm it waits on stdio without errors:

```bash
DOPE_ENV_FILE="$DOPE_ENV_FILE" uvx \
  --index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  devops_mcp@latest
```

It should print a startup message and block waiting for MCP protocol messages. Ctrl-C to stop. If it exits immediately with an error, check `DOPE_ENV_FILE` and credentials.

## Failure modes

- **`DOPE_ENV_FILE` not set** — export it in your shell profile (`.zshrc`, `.bashrc`). The DOPE onboarding guide has the setup steps.
- **Env file exists but server fails** — the env file may have expired or invalid credentials. Re-run the DOPE credential setup.
- **Artifactory unreachable** — check VPN connection. Note DOPE uses the *release* PyPI (`global-release-pypi`), not the dev index.
