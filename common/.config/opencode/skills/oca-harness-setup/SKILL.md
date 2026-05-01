---
name: oca-harness-setup
description: Use when setting up a new OCA harness from scratch, resolving OCA-specific issues (model prefix, variant config paths), or comparing harness capabilities — not for adding rules/skills/MCP to an existing harness (use agent-configuration for that)
metadata:
  owner: platform_org
  last_updated: 2026-03-31
---

# OCA Harness Setup

Reference knowledge for configuring agent harnesses in an Oracle Code Assist environment.

## When to use

- Setting up a new harness for the first time
- Troubleshooting harness configuration (model not found, MCP not loading, wrong config path)
- Comparing harness capabilities to choose one
- Configuring Codex with OCA model prefixes

## References

This skill bundles reference files in `references/` — load them on demand:

| Reference | Use when |
|-----------|----------|
| oca-harness-catalog.md | Need to know which harnesses OCA supports, their variants, or AICODE page IDs |
| oca-codex-config.md | Configuring Codex config.toml with OCA model prefix (`oca/`) and settings |
| cline-variant-config-surfaces.md | Finding Cline config paths across VS Code, IntelliJ, and CLI variants |
| codex-capabilities.md | Understanding Codex configuration surfaces (rules, skills, MCP, settings) |
| codex-variant-config-surfaces.md | Checking if Codex Desktop/IDE differ from CLI (they don't — all share config.toml) |

## Quick reference

**Codex model prefix:** All OCA model names require `oca/` prefix in config.toml (e.g., `oca/o4-mini`).

**Codex config location:** `~/.codex/config.toml` — shared across CLI, Desktop, and IDE variants.

**Cline MCP paths diverge by variant:** VS Code uses `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`, IntelliJ and CLI use `~/.cline/mcp_settings.json`.
