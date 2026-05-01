# Cline harness

## Rules

| Scope | Location |
|---|---|
| Project | `.clinerules/*.md` (or `.txt`) |
| Global | `~/Documents/Cline/Rules/` |

Optional YAML frontmatter with `paths` (glob array) for conditional activation. Rules without frontmatter are always active. Empty `paths: []` disables a rule.

Cline also auto-detects `.cursorrules`, `.windsurfrules`, and `AGENTS.md` in the project root (displayed in rules panel with individual toggles).

Workspace rules override global rules on conflict.

## Skills

| Scope | Location |
|---|---|
| Project | `.cline/skills/`, `.clinerules/skills/`, `.claude/skills/` (all recognized) |
| Global | `~/.cline/skills/`, `~/.agents/skills/` |

Each skill is a directory with `SKILL.md`. Frontmatter `name` must match dir name, `description` max 1024 chars. Optional subdirs: `docs/`, `templates/`, `scripts/`. Progressive loading: metadata at startup (~100 tokens), full SKILL.md on trigger.

Global skills take precedence over project skills (opposite of rules).

## Workflows

| Scope | Location |
|---|---|
| Project | `.clinerules/workflows/` |
| Global | `~/Documents/Cline/Workflows/` |

Filename becomes slash command (e.g., `release-prep.md` → `/release-prep`). Workspace overrides global on name collision.

## Hooks

| Scope | Location |
|---|---|
| Project | `.clinerules/hooks/` |
| Global | `~/Documents/Cline/Hooks/` |

Events: `TaskStart`, `TaskResume`, `TaskCancel`, `TaskComplete`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `PreCompact`. Hooks are executable scripts receiving JSON on stdin, returning JSON on stdout with optional `cancel`, `contextModification`, `errorMessage` fields. Global hooks execute first, then workspace.

## MCP configuration

File: `cline_mcp_settings.json` (managed through extension UI).

**Scope: global only** — no project-level MCP config.

Path varies by variant:
- VS Code: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (macOS)
- IntelliJ / CLI: `~/.cline/data/settings/cline_mcp_settings.json`

Transports: STDIO and SSE. Tool control: `alwaysAllow` is allow-only (auto-approve). No tool disable/deny mechanism.

## CLI

Cline CLI exists (`cline` command) with interactive and headless (`-y`/`--yolo`) modes. Config via `cline auth`, `cline config`. Data at `~/.cline/`.

## Authoritative docs
- https://docs.cline.bot/
- MCP: https://docs.cline.bot/mcp/configuring-mcp-servers
