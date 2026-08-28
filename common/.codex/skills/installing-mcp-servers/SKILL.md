---
name: installing-mcp-servers
description: Use when setting up MCP servers from a cold start, onboarding a new environment, troubleshooting server startup, or handling an /onboard MCP evidence packet
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Installing MCP Servers

MCP servers bridge AI agents to external systems — Jira, Bitbucket, cloud APIs, internal tools. A pack's MCP config files describe how to *run* a server (command, env, auth), but getting the server binary or package onto the machine is a separate step. This skill covers that step.

## When to use

- Setting up a new environment with no MCP servers installed
- The onboard workflow reaches the MCP installation step
- The onboard workflow provides an MCP evidence packet for a failed server
- A specific MCP server needs to be installed or reinstalled
- An MCP server fails to start and the issue may be installation-related

## When not to use

- Configuring MCP server entries in the harness (allowlists, env vars, tool permissions) — that's the `mcp-config-constraints` rule in aipack-core and `aipack sync`.
- Troubleshooting profile composition, sync targets, or allowlist routing — invoke `aipack-system` when available.
- Troubleshooting OCA harness config paths or harness loading behavior — invoke `oca-harness-setup`.
- Reinstalling for MCP tool call failures after the server is installed and running — use the server recipe's Auth section and the failing API error instead.

## Onboard handoff contract

When `/onboard` invokes this skill, require or collect this evidence before proposing an install:

- Profile name, harness, and scope.
- MCP server name and owning pack.
- MCP JSON path: `~/.config/aipack/packs/<pack>/mcp/<server>.json`.
- `command`, `env` keys, `auth` notes, and static `available_tools` from the MCP JSON.
- Relevant `aipack setup <profile>`, `aipack profile refs <profile> --json`, `aipack doctor --profile <profile> --json`, inventory listing, and named-server probe failure snippets.
- For Codex startup failures: `rg -n "MCP server stderr|Traceback|No such file or directory|AttributeError|failed" ~/.codex/log/codex-tui.log -S`.

Classify the failure with [mcp-startup-triage.md](references/mcp-startup-triage.md) before acting.

## References

| Reference | Use when |
|---|---|
| [mcp-startup-triage.md](references/mcp-startup-triage.md) | Distinguishing startup crashes from auth, zero-tool, package-source, profile, or harness config-plane failures |
| [mcp-server-inventory.md](references/mcp-server-inventory.md) | Mapping starter-pack MCP servers to upstream/internal ownership references |

## How packs reference MCP servers

Each MCP server in a pack has a JSON config at `packs/<pack>/mcp/<server>.json`. The `command` field tells the harness how to start the server at runtime. That command assumes the server is already installed at a specific path or available via a package manager.

Read the `command` array to understand what the server needs:

- Starts with `uvx` — a Python package pulled on-demand. Usually no pre-install needed, but the package index must be reachable and `uv`/`uvx` must be available.
- Starts with `node` — a Node.js server, typically cloned and built from source. The path in the command tells you where it expects to live.
- Starts with `uv run --project` — a Python project run from a local checkout. Needs the repo cloned and dependencies synced.
- A bare binary path — the binary must exist at that path. Could be built from source, downloaded from a release, or installed via a system package manager.

## Before installing anything

**If troubleshooting in Codex, inspect startup logs first.** MCP startup errors are written to `~/.codex/log/codex-tui.log` and usually give exact root cause (missing path, traceback, auth/env failure) faster than reinstall attempts.

Quick scan:

```bash
rg -n "MCP server stderr|Traceback|No such file or directory|AttributeError|failed" ~/.codex/log/codex-tui.log -S | tail -n 80
```

**Check what the profile actually enables.** Read the active profile YAML and only install servers where `enabled: true`. Installing servers the profile disables is wasted work.

**Verify prereqs for the servers you need.** Common ones: `git`, `node`/`npm`, `uv`/`uvx`, `python3`. Check each with `--version`. If a prereq is missing, stop and report it — do not install system-level tools (Homebrew packages, system Python) without explicit approval.

**Check if the server is already installed.** Extract the binary/module path from the `command` field and check whether it exists. For uvx-based servers, the package is fetched at runtime — verify `uvx` is available and the package index is reachable.

**Treat zero tools as auth/config until proven otherwise.** If a named-server probe or the harness reports a connected server with no useful tools, load [mcp-startup-triage.md](references/mcp-startup-triage.md) before reinstalling.

## Install patterns

**uvx (managed Python packages):** The server is published to a Python package index. `uvx` fetches and runs it on demand — no pre-install step. But the package index URL matters. Internal servers often use private Artifactory indexes specified in the command args. Verify the index is reachable before assuming uvx will work.

Some uvx-based servers can alternatively be cloned and run from source, which avoids slow registry pulls. If a clone URL is available and the user reports slow network, prefer the clone approach.

**Clone and build (Node.js):** Clone the source repo, run `npm install` and `npm run build` (or whatever the project's build system requires). The built output must land at the path the MCP config's `command` expects. Check the repo's README for build instructions — do not assume npm conventions.

**Clone and sync (Python/uv projects):** Clone the source repo, create a venv with `uv venv`, then `uv sync` to install dependencies. The MCP config typically uses `uv run --project <path>` to execute, so the project directory and its `.venv` must exist at the expected location.

**Monorepo subpaths:** Some servers live inside larger repos. The clone gets the whole repo, but the server is at a subpath. Clone the repo, then reference the subpath in the MCP config's command.

## Auth and environment

MCP servers almost always need credentials. The pack's MCP JSON has `env` and `auth` fields describing what's needed. Common patterns:

- **Environment variables** (API tokens, URLs) — must be set in the user's shell environment or in an env file. The `env` block in the MCP JSON shows which variables the server reads.
- **Web session / SSO cookies** — some servers authenticate through the browser. No token setup needed, but the user must be logged in.
- **OCI config** — servers using OCI SDK auth read `~/.oci/config`. Standard OCI CLI setup applies.
- **Env files** — some servers load credentials from a file path. The user needs this file created and populated.

Do not create, guess, or hardcode credentials. If auth setup is required, walk the user through it or point them to the relevant setup guide.

Each server's install recipe (linked in the server index below) has a dedicated **Auth** section with the specific credentials, env vars, and setup steps for that server.

## Verification

After installing a server, verify it can start:

1. Run the `command` from the MCP JSON directly in a shell
2. The server should start and listen on stdio (MCP transport)
3. If it prints an error and exits, the install or auth is broken — read the error
4. Ctrl-C to stop it once confirmed

For uvx-based servers, verify the package resolves: run the command with `--help` if the server supports it.

## After installation

Installing the server binary or fixing auth is step one. Return to `/onboard` or invoke `aipack-system` for profile composition, sync dry-run, real sync, and harness restart guidance. Do not apply sync from this skill unless the user explicitly approves that mutation in the current turn.

## Server index

Per-server install recipes for servers bundled with this pack:

| Server | Doc | Summary |
|--------|-----|---------|
| jira | [jira.md](jira.md) | OCI Jira — TCT/Ticketing fork from ticketing Artifactory, PAT auth, read-only by default |
| jira-sd | [jira-sd.md](jira-sd.md) | Jira Service Desk — same TCT fork, separate PAT |
| confluence | [confluence.md](confluence.md) | Confluence — upstream mcp-atlassian from global-dev Artifactory, web-session auth |
| bitbucket | [bitbucket.md](bitbucket.md) | Bitbucket Server — uvx from Artifactory |
| dope | [dope.md](dope.md) | DevOps Platform Engineering tools — uvx from Artifactory |
| oci-mcp | [oci-mcp.md](oci-mcp.md) | OCI SDK API access — uvx from PyPI (`oracle.oci-cloud-mcp-server`) |
| oci-kb | [oci-kb.md](oci-kb.md) | OCI internal developer docs search — uvx from Artifactory (`oci-kb-mcp`) |
| ots | [ots.md](ots.md) | OTS ticket search/read — uvx from Artifactory with OCI profile auth |
| oci-ops | [oci-ops.md](oci-ops.md) | Internal OCI CLI for substrate/overlay ops — uvx from Artifactory |

## Failure modes

- **Artifactory index unreachable** — uvx-based servers will fail to resolve. Check network/VPN. Verify with `curl -s <index_url> | head -5`.
- **SSH key not unlocked** — clone commands will hang or fail. Verify SSH access before cloning: `ssh -T git@<host> 2>&1 | head -1`.
- **Node/Python version mismatch** — some servers require specific versions. Check the repo's README or package.json/pyproject.toml for version constraints.
- **Path mismatch between install and MCP config** — the server is installed but at a different path than the `command` expects. Compare the actual install path against the `command` field in the MCP JSON.
