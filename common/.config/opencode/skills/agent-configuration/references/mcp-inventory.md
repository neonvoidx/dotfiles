# MCP inventory + minimization

Goal: smallest viable tool surface per workflow.

## Documenting MCP servers

For each MCP server in your harness config, document:

| Field | Description |
|-------|-------------|
| Name | Server identifier as it appears in config |
| Command | How to start the server (e.g., `uvx <package>`, `npx <package>`) |
| Env vars | Required environment variables (use `{env:VAR}` placeholders, never raw values) |
| Metering | Is the API paid/metered? Document budget guardrails and approval thresholds. |

## Tool inventory snapshots

Maintain audit-friendly snapshots of available tools vs enabled subset:

- Snapshot the full tool list from each MCP server.
- Compare against your enforced allowlist.
- Flag tools that are available but not enabled (potential future enablement).
- Flag tools that are enabled but unused (candidates for removal).

Store snapshots alongside your harness config for diff-based auditing.
