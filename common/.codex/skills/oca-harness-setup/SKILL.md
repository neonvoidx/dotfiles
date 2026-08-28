---
name: oca-harness-setup
description: Use when setting up a new OCA harness, resolving OCA-specific harness issues, comparing harness capabilities, or setting up Codex OTEL metrics — not for adding rules/skills/MCP to an existing harness
metadata:
  owner: platform_org
  last_updated: 2026-05-21
---

# OCA Harness Setup

Reference knowledge for configuring agent harnesses in an Oracle Code Assist environment.

## When to use

- Setting up a new harness for the first time
- Troubleshooting harness configuration (model not found, MCP not loading, wrong config path)
- Comparing harness capabilities to choose one

## References

This skill bundles reference files in `references/` — load them on demand:

| Reference | Use when |
|-----------|----------|
| oca-harness-catalog.md | Need to know which harnesses OCA supports, their variants, or AICODE page IDs |
| cline-variant-config-surfaces.md | Finding Cline config paths across VS Code, IntelliJ, and CLI variants |
| runtime-config-planes.md | Visible tools, MCP servers, rules, or models do not match the active aipack profile |
| codex-otel-skill-metrics.md | Setting up bundled Codex OTEL signals, explaining DBTools-default logs, local metrics, or interpreting `codex.skill.injected` |

## Quick reference

**Cline MCP paths diverge by variant:** VS Code uses `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`, IntelliJ and CLI use `~/.cline/mcp_settings.json`.

**Codex OTEL usage signals:** this pack renders DBTools-default logs and local-default metrics; `CODEX_OTEL_USER` is required for `x-codex-user`, localhost log testing requires overriding `CODEX_OTEL_LOGS_ENDPOINT`; keep prompt logging false and traces disabled.

**Deferred usage signal:** this starter pack no longer bundles mandatory self-reporting. Treat pack attribution, semantic outcomes, and self-report reconciliation as follow-on design work.

**Runtime-managed gateway:** if Codex shows an MCP gateway or Enterprise connector that `aipack trace` cannot find, load `runtime-config-planes.md` and identify the owning config plane before editing profiles or pack content.
