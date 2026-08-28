---
name: DOPE MCP Server
description: Install recipe for the DevOps Platform Engineering MCP server — uvx from the global-release Artifactory index
metadata:
  owner: platform_org
  last_updated: 2026-07-09
---

# DOPE MCP Server

Provides access to DevOps Platform Engineering tools — Shepherd deployments, Grafana dashboards, alarms, logging, metrics, phonebook, and runbooks.

## Prereqs

- `uv` / `uvx`
- `DOPE_ENV_FILE` environment variable set and pointing to a valid DOPE env file

Verify prereqs:

```bash
uv --version
test -n "$DOPE_ENV_FILE" && test -f "$DOPE_ENV_FILE" && echo "DOPE env file present" || echo "DOPE env file missing"
```

## Install

No separate installation needed. The pack's MCP config uses `uvx` to pull the pinned `devops_mcp==1.1.46` server from the global-release Artifactory index at runtime. The pin prevents `uvx --index` from selecting a newer, unrelated package with a different entry point.

- Index: `{params.artifactory_release_pypi:-https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/}`

Verify the index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/devops-mcp/" | head -5
```

If the index returns HTML with package links, `uvx` will resolve the package on first run. Subsequent starts are fast.

## Auth

Credentials are loaded from an env file. `DOPE_ENV_FILE` must be set in the shell environment and point to this file. The file contents and setup instructions are in the DOPE team's onboarding guide.

If `DOPE_ENV_FILE` is not set or the file doesn't exist, the server will fail to start. Do not create or populate the env file — direct the user to the DOPE onboarding guide.

The env file is read when the MCP process starts. After creating, refreshing, or replacing the DOPE env file, restart the harness or MCP process before retesting. Do not paste env-file contents into chat.

DOPE credentials are separate from OCI-Ops/OCI CLI session auth. If DOPE fails while OCI-Ops works, debug `DOPE_ENV_FILE` and DOPE credential freshness first.

## Tool exposure

The DOPE server exposes 80+ tools, and the shipped profiles keep it disabled by default. When enabling `dope` in a profile, add a narrow `dope.allowed_tools` list in that same profile; the allow-list renders to harness-native tool gating such as Codex `enabled_tools` in `config.toml`.

## Verify

The DOPE server does not support `--help`. Start it and confirm it waits on stdio without errors:

```bash
DOPE_ENV_FILE="$DOPE_ENV_FILE" uvx \
  --index "https://artifactory.oci.oraclecorp.com/api/pypi/global-release-pypi/simple/" \
  devops_mcp==1.1.46
```

It should print a startup message and block waiting for MCP protocol messages. Ctrl-C to stop. If it exits immediately with an error, check `DOPE_ENV_FILE` and credentials.

## Failure modes

- **`DOPE_ENV_FILE` not set** — export it in your shell profile (`.zshrc`, `.bashrc`). The DOPE onboarding guide has the setup steps.
- **Env file exists but server fails** — the env file may have expired or invalid credentials. Re-run the DOPE credential setup, then restart the harness/MCP process.
- **Credential refreshed but failures persist** — confirm the harness process inherited the updated `DOPE_ENV_FILE`; stale MCP subprocesses keep using the old startup environment.
- **Artifactory unreachable** — check VPN connection. Note DOPE uses the *release* PyPI (`global-release-pypi`), not the dev index.
