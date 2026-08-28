---
name: runtime-config-planes
description: Reference for distinguishing aipack-rendered harness config from Oracle-managed Codex, ORA, Codex Enterprise, and gateway runtime config
metadata:
  owner: platform_org
  last_updated: 2026-05-20
---

# Runtime Config Planes

Use this when a harness shows tools, rules, models, or MCP servers that do not line up with the active aipack profile. Do not assume every visible MCP server came from `oci-dev-starter-pack`.

## Planes To Separate

| Plane | What Owns It | What To Check |
|---|---|---|
| AIPack profile | User or team pack composition | `aipack status --profile <profile> --json`, `aipack profile refs <profile> --json` |
| AIPack render target | Harness files written by `aipack sync` | `aipack sync --profile <profile> --harness <harness> --scope <scope> --dry-run`, `aipack trace <kind> <name>` |
| Harness user config | The local harness client | Harness-specific config path and startup logs |
| Managed Codex config | Enterprise/EMP/runtime install | `/etc/codex/managed_config.toml` when present |
| ORA/Codex sandbox | ORA workspace runtime | ORA workspace config and mounted project files |
| Codex Enterprise apps/connectors | Enterprise workspace and Oracle-approved app catalog | `https://chatgpt.com/apps` and connector list exposed by the Enterprise environment |
| MCP Gateway | Runtime-managed tool access plane | Gateway docs, `codex mcp list`, and owner-provided status |

## Detection

For Codex, compare aipack output with the running client:

```bash
aipack status --profile <profile> --json
aipack profile refs <profile> --json
aipack mcp inspect-tools --profile <profile>
codex mcp list
rg -n "mcp|gateway|otel|log_user_prompt" /etc/codex/managed_config.toml 2>/dev/null
rg -n "MCP server stderr|failed|Traceback" ~/.codex/log/codex-tui.log -S | tail -n 80
```

If `/etc/codex/managed_config.toml` exists, treat it as runtime-managed until the owner says otherwise. Use it only to explain why visible Codex behavior differs from aipack-rendered config.

Do not remediate, delete, or tune managed Codex files from this starter-pack workflow. Do not use `aipack profile show --json` in diagnostic transcripts; it fully resolves environment-backed MCP values. If a diagnostic command emits resolved env values, redact them before summarizing.

## Routing

- If aipack should have rendered a resource and did not, use `aipack-system`, `aipack trace`, and sync dry-run diagnostics.
- If the runtime exposes an MCP gateway that the pack did not render, do not duplicate the gateway in this pack.
- If gateway-backed tools are missing or unhealthy, route to the gateway/runtime setup path, not MCP package installation.
- If ORA sees project rules or skills but not global Codex MCP/settings, treat that as a config-plane mismatch and inspect the ORA workspace path.
- If Codex Enterprise exposes apps/connectors such as Slack, Outlook, or other Oracle-approved catalog entries, treat pack MCP servers as adjacent local tool wiring, not replacements for those connectors.
- If telemetry or prompt logging appears in managed config, report the source plane separately from pack-rendered OTEL settings.
