---
name: Bitbucket MCP Server
description: Install recipe for the Bitbucket Server MCP — uvx from Artifactory or clone from OCI DevOps
metadata:
  owner: platform_org
  last_updated: 2026-03-31
---

# Bitbucket MCP Server

Provides access to Bitbucket Server — PRs, diffs, code browsing, search.

## Prereqs

- `uv` / `uvx`

For the clone option (Option B):
- `git`
- `node` (v18+)
- `npm`
- SSH access to OCI DevOps (PIV/YubiKey unlocked)

Verify prereqs:

```bash
uv --version
```

## Option A: uvx (no pre-install needed)

The pack's MCP config uses `uvx` to pull `bitbucket-mcp-server` from Artifactory at runtime. No pre-install step required. The first run is slow as it fetches the package and dependencies.

Verify the Artifactory index is reachable:

```bash
curl -s "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple/bitbucket-mcp-server/" | head -5
```

If the index returns HTML with package links, uvx will work. No further action needed.

## Option B: clone from internal fork (faster startup)

If the uvx pull is too slow or you want a local checkout:

```bash
git clone --depth 1 ssh://oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com/namespaces/axuxirvibvvo/projects/AL/repositories/bitbucket-mcp \
  ~/.local/share/mcp-servers/bitbucket-mcp

cd ~/.local/share/mcp-servers/bitbucket-mcp
npm install
npm run build
```

The built entry point must exist at `~/.local/share/mcp-servers/bitbucket-mcp/build/index.js`.

When using the local clone, the MCP config command needs to point at the local checkout instead of using uvx. The command changes from `uvx ... bitbucket-mcp-server` to:

```json
["node", "{env:HOME}/.local/share/mcp-servers/bitbucket-mcp/build/index.js"]
```

**MUTATION:** This modifies pack source at `mcp/bitbucket.json`. Confirm with the user before editing. Note that pack updates or reinstalls will overwrite this change.

## Auth

Requires two environment variables:

- `BITBUCKET_URL` — set via profile params (typically the team's Bitbucket Server URL)
- `BITBUCKET_TOKEN` — a Bitbucket HTTP access token. Generate at `<BITBUCKET_URL>/plugins/servlet/access-tokens/manage`.

The pack template sets `BITBUCKET_ENABLE_READ_ONLY=true` by default.

## Verify

For Option A (uvx):

```bash
uvx --python 3.12 --default-index "https://artifactory.oci.oraclecorp.com/api/pypi/global-dev-pypi/simple" bitbucket-mcp-server --help
```

For Option B (local clone):

```bash
test -f ~/.local/share/mcp-servers/bitbucket-mcp/build/index.js && echo "OK" || echo "MISSING"
```

## Failure modes

- **Artifactory unreachable** — check VPN connection. Verify with `curl -s <index_url> | head -5`.
- **uvx first run takes >2 minutes** — normal for large dependency trees. Consider Option B for faster subsequent starts.
- **Clone hangs** — SSH key not unlocked or wrong hostname. Run `ssh -T oci.private.devops.scmservice.us-phoenix-1.oci.oracleiaas.com 2>&1 | head -1` to verify access.
- **npm install fails** — check node version (`node --version`, must be v18+). Check network access to npm registry.
- **npm run build fails** — read the error output. Common cause: missing TypeScript or build dependencies not resolved by `npm install`.
