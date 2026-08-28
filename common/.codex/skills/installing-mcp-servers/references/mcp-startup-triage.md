---
name: mcp-startup-triage
description: Triage reference for MCP startup, zero-tool, package-source, and auth failures in OCI starter profiles
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# MCP Startup Triage

Use this before reinstalling a server. Most failures are profile rendering, package source, process environment, or auth state; reinstall only fixes missing binaries or unreachable packages.

## Failure Classes

| Failure class | Action |
|---|---|
| `mcp-install-startup` | Continue in `installing-mcp-servers`; check binary/package/local path, package source, `uvx`, language runtime, and startup logs. |
| `missing-param` | Report `aipack profile set-param <profile> <key> <value>` shape; require approval before running it. |
| `missing-env` | Report `aipack config env set <key> <value>` shape or shell env key name; do not collect values in chat. |
| `mcp-auth-api` | Use the server recipe's Auth section and the API error; do not reinstall unless startup also fails. |
| `mcp-zero-tools` | Treat as auth/config/profile gating until package evidence proves otherwise. |
| `pack-profile-sync` | Route to `aipack-system`, sync dry-run, and trace diagnostics. |
| `harness-loading` | Route to `oca-harness-setup`. |
| `runtime-config-plane` | Route to `oca-harness-setup` with `runtime-config-planes.md`. |

## Decision Tree

1. Start from supplied `/onboard` evidence: status summary, refs summary, setup/doctor snippets, inventory listing, named-server probe, and redacted logs.
2. Run missing evidence commands only when the handoff lacks them.
3. If the server is absent from rendered config, classify `pack-profile-sync`.
4. Probe only the failing server by name: `aipack mcp inspect-tools <server> --profile <profile>`.
5. Do not run `aipack mcp inspect-tools --all` during onboarding unless the user asks for a broad live probe.
6. If the command cannot start, read the server recipe and classify `mcp-install-startup`.
7. If the server starts but reports zero tools or tool calls fail immediately, classify `mcp-zero-tools` or `mcp-auth-api`.
8. If a harness loads different tools than `aipack mcp inspect-tools`, classify `harness-loading` or `runtime-config-plane`.

## Codex Log Scan

For Codex, startup failures usually land in the TUI log:

```bash
rg -n "MCP server stderr|Traceback|No such file or directory|AttributeError|failed" ~/.codex/log/codex-tui.log -S | tail -n 80
```

Use the log excerpt to classify the failure. Do not reinstall when the error is missing env, expired auth, an HTTP 401/403, or a profile param that did not resolve.

Keep evidence packets value-free: unresolved command from the pack JSON, env key names, auth model, static `available_tools`, failure class, and redacted log excerpt. Do not include resolved token values or env-file contents.

## Server Recipes

Use the server recipe as the source of truth for package source, auth model, verification command, and server-specific traps:

- [jira.md](../jira.md)
- [jira-sd.md](../jira-sd.md)
- [confluence.md](../confluence.md)
- [bitbucket.md](../bitbucket.md)
- [dope.md](../dope.md)
- [oci-mcp.md](../oci-mcp.md)
- [oci-kb.md](../oci-kb.md)
- [ots.md](../ots.md)
- [oci-ops.md](../oci-ops.md)

## Zero Tools

`tools/list` returning no useful tools is not the same as a startup crash.

- Check auth first: env vars, env files, browser session, OCI profile, or PAT host.
- Check profile-level `allowed_tools` if a server is connected but expected tools are hidden.
- Check package source only when the log shows import errors, missing modules, or an unexpected server implementation.
- For Jira and Jira-SD, zero or unusable tools usually means missing/wrong PAT, wrong host, or read-only/profile gating.
- For Confluence, zero or unusable tools usually means expired browser SSO or the wrong `mcp-atlassian` build.

## Safe Credential Checks

Use value-free checks:

```bash
test -n "$JIRA_PAT" && echo "JIRA_PAT set" || echo "JIRA_PAT missing"
test -n "$JIRA_SD_PAT" && echo "JIRA_SD_PAT set" || echo "JIRA_SD_PAT missing"
test -n "$DOPE_ENV_FILE" && test -f "$DOPE_ENV_FILE" && echo "DOPE env file present" || echo "DOPE env file missing"
```

Never print token values or env-file contents into chat or logs.
