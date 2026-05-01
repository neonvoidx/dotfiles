# Frontmatter Mapping: Pack Canonical → Harness Native

How aipack frontmatter fields map to each supported harness at sync time.

## Pack canonical schema (portable minimum)

All constructs share:

| Field | Type | Required |
|---|---|---|
| `name` | string (kebab-case) | Yes |
| `description` | string | Yes |
| `metadata.owner` | string | Yes |
| `metadata.last_updated` | string (YYYY-MM-DD) | Yes |
| `metadata.harnesses` | string[] | No (informational) |

Construct-specific:

| Field | Constructs | Type |
|---|---|---|
| `paths` | Rules | string[] (globs) |
| `skills` | Agents | string[] |
| `mcp_servers` | Agents | string[] |
| `disallowed_tools` | Agents | string[] |

## Harness mapping tables

### Rules

| Pack field | Claude Code | OpenCode | Codex | Cline |
|---|---|---|---|---|
| `name` | filename | filename | N/A (Starlark) | filename |
| `description` | stripped (not parsed) | stripped (no FM) | N/A | stripped (not parsed) |
| `paths` | **honored** (conditional loading) | stripped (no FM support) | N/A | **honored** (conditional activation) |
| `metadata` | stripped | stripped | N/A | stripped |

Destination: `.claude/rules/*.md` | `.opencode/rules/*.md` | `AGENTS.override.md` (flattened) | `.clinerules/*.md`

CC `paths` known bugs: may load globally regardless (#16299), only triggers on Read not Write/Edit (#23478), ignored in user-level rules (#21858).

### Skills (SKILL.md)

| Pack field | Claude Code | OpenCode | Codex | Cline |
|---|---|---|---|---|
| `name` | **parsed** (Agent Skills standard) | **required**, validated (`^[a-z0-9]+(-[a-z0-9]+)*$`) | **required**, validated | **required**, must match dir name |
| `description` | **parsed** (trigger matching) | **required** (trigger matching) | **required** (Level 1 metadata) | **required** (trigger matching) |
| `metadata` | accepted, ignored at runtime | accepted, discarded at runtime | accepted via standard | not documented |

All 4 harnesses use the Agent Skills standard. `name` + `description` are the only fields with runtime effect across all harnesses.

Additional standard fields (`license`, `compatibility`) are accepted but have no runtime effect in any harness.

Destination: `.claude/skills/<name>/SKILL.md` | `.opencode/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` | `.clinerules/skills/<name>/SKILL.md`

### Agents

| Pack field | Claude Code | OpenCode | Codex | Cline |
|---|---|---|---|---|
| `name` | **required** | derived from filename | TOML key (filename) | N/A |
| `description` | **required** | recommended | TOML `description` | N/A |
| `skills` | `skills:` (YAML list) | not supported | not supported | N/A |
| `mcp_servers` | `mcpServers:` (camelCase) | not supported natively | not supported | N/A |
| `disallowed_tools` | `disallowedTools:` (camelCase, comma string) | mapped to `permission` deny rules | TOML array | N/A |
| `metadata` | stripped | stripped | stripped | N/A |

Destination: `.claude/agents/*.md` | `.opencode/agents/*.md` | `.agents/*.toml` (converted from markdown) | N/A

Cline has no agent construct. Codex agents are TOML files — aipack converts markdown agent definitions to `.toml` format at sync time.

#### Harness-specific agent fields (not in portable schema)

These are set per-harness via sync transforms, not in pack source:

| Field | Claude Code | OpenCode |
|---|---|---|
| `tools` (allowlist) | comma-separated string | `Record<string, boolean>` (deprecated, use `permission`) |
| `model` | `sonnet`/`opus`/`haiku`/`inherit` | `provider/model-id` |
| `permission` | `permissionMode` (string enum) | structured object (per-tool allow/deny) |
| Turn limit | `maxTurns` (number) | `steps` (number) |
| Execution mode | N/A | `mode` (`primary`/`subagent`/`all`) |
| Temperature | N/A | `temperature` (0.0-1.0) |
| Memory | `memory` (`user`/`project`/`local`) | N/A |
| Isolation | `isolation` (`worktree`) | N/A |
| Hooks | `hooks` (object) | N/A |

### Workflows

| Pack field | Claude Code | OpenCode | Codex | Cline |
|---|---|---|---|---|
| `name` | filename → `/command-name` | filename → `/command-name` | N/A | filename → `/workflow.md` |
| `description` | `description:` (skill FM) | `description:` (command FM) | N/A | not parsed |
| `metadata` | stripped | stripped | N/A | stripped |

Destination: `.claude/commands/*.md` | `.opencode/commands/*.md` | N/A (no workflow construct) | `.clinerules/workflows/*.md`

CC commands also support: `argument-hint`, `disable-model-invocation`, `user-invocable`, `model`, `context` (`fork`), `agent`, `allowed-tools`. OC commands also support: `agent`, `model`, `subtask`. These are harness-specific and not in the portable schema.

## Sync transform summary

| Transform | Key behavior |
|---|---|
| Claude Code | snake_case → camelCase, tools list → comma string, PascalCase tool names |
| OpenCode | tools list → bool map (deprecated path), preserves snake_case |
| Codex | Rules flattened into `AGENTS.override.md`, agents converted to `.agents/*.toml`, MCP into `config.toml` TOML tables |
| Cline | harness-neutral format, MCP into `cline_mcp_settings.json` |

## What `metadata` contains

`metadata` is a free-form `map[string]string` in the pack canonical schema. Convention:

| Key | Purpose | Example |
|---|---|---|
| `owner` | DRI for the content | `myteam/jdoe` |
| `last_updated` | Last meaningful edit date | `2026-03-09` |
| `harnesses` | Harnesses tested with (informational) | `claudecode, opencode` |

All `metadata` fields are stripped at sync time. No harness reads them. They exist for humans, pack tooling, and governance (tier reviews per governance-criteria in pack-content-craft).
