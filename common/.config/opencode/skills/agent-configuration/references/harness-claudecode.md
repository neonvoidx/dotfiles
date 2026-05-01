# Claude Code harness

## Where config lives

| Scope | Location |
|---|---|
| Managed settings | `managed-settings.json`, MDM/plist, registry, `managed-settings.d/` |
| User settings | `~/.claude/settings.json` |
| Project settings | `.claude/settings.json` |
| Local settings | `.claude/settings.local.json` (gitignored, project-scoped) |
| User rules | `~/.claude/CLAUDE.md` + `~/.claude/rules/*.md` |
| Project rules | `CLAUDE.md` at repo root (always loaded), `.claude/rules/*.md` |
| Conditional rules | `.claude/rules/*.md` with `paths` glob frontmatter for file-scoped activation |

Settings merge: managed > user > project > local. Project layers on top of user.

Claude Code reads `CLAUDE.md` natively. It does NOT auto-discover `AGENTS.md` — to use AGENTS.md content, import it from within CLAUDE.md via `@AGENTS.md`.

## MCP configuration

- Global: `~/.claude.json` under `mcpServers` key
- Project: `.mcp.json` at repo root
- Managed: `managed-mcp.json` (enterprise, MDM-deployed)
- Each server entry: `command`, `args`, `env` (use env var placeholders, not raw secrets)

Tool permissions are in `settings.json`, not in MCP config:
- `permissions.allow` — auto-approve (tool runs without prompting)
- `permissions.deny` — block entirely (deny always wins over allow)
- Patterns use `mcp__server__tool` format

## Agents

- User: `~/.claude/agents/*.md`
- Project: `.claude/agents/*.md`
- Frontmatter: `name`, `description` (required), plus optional `skills`, `mcpServers`, `disallowedTools`, `permissionMode`, `maxTurns`, `model`, `memory`, `isolation`, `hooks`
- Invocation: `@"agent-name (agent)"` in chat, or `--agent <name>` CLI flag
- Subagent memory: `memory` field (`user`/`project`/`local`) enables persistent cross-session learning at `~/.claude/agent-memory/<name>/`
- Subagent isolation: `isolation: worktree` runs in a temporary git worktree

## Skills

- Location: `.claude/skills/<name>/SKILL.md` (synced from pack source)
- Loaded via the Skill tool at invocation time, not pre-loaded
- Trigger matching uses frontmatter `name` + `description`
- User invocation: `/<skill-name>` routes through Skill tool

## Commands (workflows)

- Location: `.claude/commands/*.md`
- Invoked as `/<command-name>` (user-facing slash commands)
- Frontmatter: `description`, `argument-hint`, `agent`, `model`, `context` (`fork`), `allowed-tools`, `user-invocable`, `disable-model-invocation`

## Hooks

Defined in `settings.json` under `hooks` key. Each hook specifies a handler (`command`, `http`, `prompt`, or `agent` type), optional `matcher` (tool name pattern), and `timeout`.

Hook events: `SessionStart`, `SessionEnd`, `InstructionsLoaded`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PermissionDenied`, `PostToolUse`, `PostToolUseFailure`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`, `TeammateIdle`, `Stop`, `StopFailure`, `Notification`, `CwdChanged`, `FileChanged`, `ConfigChange`, `PreCompact`, `PostCompact`, `WorktreeCreate`, `WorktreeRemove`, `Elicitation`, `ElicitationResult`.

## Auto-memory

- Location: `~/.claude/projects/<project>/memory/MEMORY.md`
- Controlled by `autoMemoryEnabled` and `autoMemoryDirectory` settings
- Agent writes observations to memory files that persist across sessions

## Plugins

Claude Code has a plugin system with marketplace discovery. Plugins can provide MCP servers, agents, and hooks. Managed marketplace restrictions available via enterprise settings.

## Key differences from other harnesses

- Conversation forking: any message can be forked into a new branch
- Agent teams: `--agent-teams` flag coordinates independent agent sessions
- `paths` glob on rules enables conditional loading per file touched
- MCP config (server definitions) lives in `.mcp.json`/`~/.claude.json`, separate from tool permissions in `settings.json`

## Authoritative docs
- https://code.claude.com/docs/en/overview
