# OpenCode harness

## Where config lives

| Scope | Location |
|---|---|
| Global | `~/.config/opencode/opencode.json` |
| Global TUI | `~/.config/opencode/tui.json` |
| Project | `./opencode.json` or `.opencode/` |
| Remote | `.well-known/opencode` endpoint |
| Inline | `OPENCODE_CONFIG_CONTENT` env var |

Override paths: `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, `OPENCODE_TUI_CONFIG` env vars.

Precedence: Remote > Global > Custom > Project > .opencode > Inline. Configs are merged, not replaced.

Variable substitution in config values: `{env:VAR}`, `{file:path/to/file}`.

## Rules / instructions

- Global: `~/.config/opencode/AGENTS.md`
- Project: `AGENTS.md` at project root
- Legacy: reads `CLAUDE.md` (project and `~/.claude/CLAUDE.md`) if no AGENTS.md exists
- Additional: `instructions` array in `opencode.json` (file paths, globs, remote URLs)

## Agents

- Global: `~/.config/opencode/agents/*.md`
- Project: `.opencode/agents/*.md`
- Any `*.md` under `agents/` is treated as an agent definition — keep docs elsewhere
- `description` is required; missing descriptions make agents disappear from listings
- Key fields: `tools` + `permission` (ask/allow/deny), `model`, `mode` (`primary`/`subagent`/`all`), `steps`, `temperature`

## Skills

- Global: `~/.config/opencode/skills/`, `~/.agents/skills/`
- Project: `.opencode/skills/`
- `skills.paths` in `opencode.json` includes additional skill directories
- Built-in `skill` tool for invocation

## Commands (workflows)

- Global: `~/.config/opencode/commands/`
- Project: `.opencode/commands/`
- Filename becomes command name (e.g., `test.md` → `/test`)
- Frontmatter: `description`, `agent`, `subtask`, `model`
- Template features: `$ARGUMENTS`, `$1`..., `@path/to/file`, `` !`shell command` ``

## MCP

Configured in `opencode.json`. Tool control via per-agent `tools` (boolean map, deprecated) or `permission` (per-tool allow/deny).

## Plugins

Configured via `plugin` array in `opencode.json`.

## Introspection (CLI)

- `opencode debug paths` — resolved config/data/cache/log/state roots
- `opencode debug scrap` — known projects/worktrees
- `opencode debug agent <name>` — resolved agent config
- `opencode session list` — project-scoped sessions
- `opencode export <id>` / `opencode import <file>` — session portability

## Built-in tools

bash, edit, write, read, grep, glob, list, lsp (experimental), apply_patch, skill, todowrite, webfetch, websearch, question.

## Authoritative docs
- Config: https://opencode.ai/docs/config/
- Tools: https://opencode.ai/docs/tools/
- Agents: https://opencode.ai/docs/agents/
- Rules: https://opencode.ai/docs/rules/
- Commands: https://opencode.ai/docs/commands/
- Config schema: https://opencode.ai/config.json
