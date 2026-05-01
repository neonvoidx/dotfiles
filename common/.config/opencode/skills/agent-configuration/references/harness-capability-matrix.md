# Harness Capability Matrix

Reference for how each harness supports pack capability vectors. Consult before making assumptions about what a harness can do.

## Support Matrix

| Vector | Claude Code | OpenCode | Codex | Cline |
|--------|-------------|----------|-------|-------|
| Rules | `.claude/rules/` individual files (frontmatter preserved) | `.opencode/rules/` individual files | `AGENTS.override.md` (flattened) | `.clinerules/` individual files |
| Agents | `.claude/agents/*.md` (frontmatter transformed) | `.opencode/agents/*.md` | `.agents/*.toml` (converted from markdown) | N/A |
| Workflows | `.claude/commands/*.md` | `.opencode/commands/*.md` | Promoted to skills during sync | `.clinerules/workflows/*.md` |
| Skills | `.claude/skills/<name>/` | `.opencode/skills/<name>/` + JSON `skills.paths` | `.agents/skills/<name>/` | `.clinerules/skills/<name>/`, `.cline/skills/`, `.claude/skills/` |
| MCP | `.mcp.json` (project), `~/.claude.json` (global) | `opencode.json` (JSON) | `config.toml` (`[mcp_servers]` TOML table) | `cline_mcp_settings.json` (**global only**) |
| Settings | `settings.local.json` (template + merge) | `opencode.json` (template + merge) | `config.toml` (template + merge) | **Not supported** |
| Hooks | `settings.json` hooks (25+ events, command/http/prompt/agent) | N/A | `hooks.json` (experimental, 5 events, command) | `.clinerules/hooks/` (8 events, script) |
| Plugins | `.mcp.json` (always generated) | `oh-my-opencode.json` (pure copy) | MCP-only via MergeMode | `cline_mcp_settings.json` (always generated) |

## Agent Frontmatter Transformation

Pack agent files use a harness-neutral markdown schema. Each harness transforms during sync:

| Field (pack) | Claude Code | OpenCode | Codex | Cline |
|--------------|-------------|----------|-------|-------|
| `name` | `name` (or from filename) | Pass-through | TOML key | N/A |
| `tools` (list) | `tools` (list) | Copies as-is | TOML array | N/A |
| `disallowed_tools` (list) | `disallowedTools` (list) | Copies as-is | TOML array | N/A |
| `skills` (list) | `skills` (list) | Pass-through | N/A | N/A |
| `mcp_servers` (list) | `mcpServers` (list) | Pass-through | N/A | N/A |

## MCP Tool Control

| Harness | Allow Format | Disable Support | `allow` Means | `deny` Means |
|---------|-------------|-----------------|---------------|-------------|
| Claude Code | `mcp__server__tool` patterns in settings | `mcp__server__tool` deny patterns | Auto-approve (still usable without, just prompts) | Block entirely |
| OpenCode | `server_toolname: true` (boolean map) | `server_*: false` wildcard | Enable tool | Wildcard disable |
| Codex | `enabled_tools: [...]` per server | `disabled_tools: [...]` | Restrict to listed | Block listed |
| Cline | `alwaysAllow: [...]` per server | **Not exposed** | Auto-approve | N/A |

## Scope Support

| Vector | Claude Code | OpenCode | Codex | Cline |
|--------|-------------|----------|-------|-------|
| Rules | Project + Global | Project + Global | Project + Global | Project + Global |
| MCP | Project + Global | Project + Global | Project + Global | **Global only** |
| Settings | Project | Project | Project | N/A |

## Environment Variable Expansion

| Harness | `{env:VAR}` becomes |
|---------|---------------------|
| Claude Code | `${VAR}` |
| OpenCode | `$VAR` |
| Codex | `$VAR` (shell-escaped) |
| Cline | `${VAR}` |

## Critical Constraints

1. **Cline: no project-level MCP** — only global scope
2. **Cline: no tool disabling** — `alwaysAllow` is allow-only
3. **Cline: no agent construct** — use rules and skills instead
4. **Codex: rules flatten to AGENTS.override.md** — no individual rule files
5. **Codex: agents are TOML** — aipack converts markdown agents to `.toml` at sync
6. **Codex: hooks are experimental** — behind `[features] codex_hooks = true`
7. **Plugins bypass `--skip-settings`** — always synced when present
8. **OpenCode: `tools` != `permission`** — `tools` (boolean map) = MCP; `permission` (strings) = native harness tools
9. **Claude Code: MCP config != tool permissions** — `.mcp.json` defines servers; `settings.json` controls access via `permissions.allow`/`permissions.deny`
10. **Claude Code: deny > allow** — deny always wins regardless of specificity; wildcard deny blocks per-tool allow
