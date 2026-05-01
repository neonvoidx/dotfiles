# Codex harness (CLI/Desktop/IDE)

## Where config lives

| Scope | Location |
|---|---|
| System | `/etc/codex/config.toml` |
| User | `~/.codex/config.toml` |
| Project | `.codex/config.toml` (loaded only when trusted) |
| Enterprise | `requirements.toml` |

Precedence: CLI flags > profiles > project > user > system > defaults. Custom home via `CODEX_HOME` env var.

All three variants (CLI, Desktop App, IDE extension) share `~/.codex/config.toml`.

## Rules / instructions

- `AGENTS.override.md` takes precedence over `AGENTS.md`
- Discovery: walks from git root toward cwd, reads first non-empty file at each level, concatenates root-down
- Both global (`~/.codex/`) and project scope
- Max size: `project_doc_max_bytes` (default 32KB)

## Skills

- Project: `.agents/skills/<name>/SKILL.md`
- Global: `~/.agents/skills/<name>/SKILL.md`
- Progressive disclosure: only name + description loaded at startup, full SKILL.md on demand
- Implicit invocation — model auto-selects based on description match

## MCP servers

Configured in `config.toml` under `[mcp_servers.<name>]` tables:
- STDIO: `command`, `args`, `env`, `env_vars`, `cwd`
- Streamable HTTP: `url`, `bearer_token_env_var`, `http_headers`, `env_http_headers`
- Tool control: `enabled_tools` (restrict to listed), `disabled_tools` (block listed)
- Per-server: `enabled`, `required`, `startup_timeout_sec`, `tool_timeout_sec`

## Agents

- Defined as TOML files: `.agents/*.toml` (project), `~/.agents/*.toml` (global)
- Also configurable via `[agents.<name>]` tables in `config.toml`
- Subagents: behind `multi_agent` feature flag. Primary agent can spawn subagents for parallel or delegated work.
- aipack converts pack agent definitions (markdown) to Codex TOML format at sync time

## Hooks (experimental)

Behind `[features] codex_hooks = true`:
- User: `~/.codex/hooks.json`
- Project: `.codex/hooks.json`
- Events: `SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`
- Command-only handler type

## Security posture

- `approval_policy`: `untrusted` (approve everything), `on-request` (approve writes), `never` (full auto)
- `sandbox_mode`: controls filesystem write boundary
- Project config requires explicit trust before loading

## Feature flags

`[features]` table: `shell_snapshot`, `multi_agent`, `personality`, `web_search`, `smart_approvals`, `undo`, `unified_exec`, `codex_hooks`.

## Authoritative docs
- Config basics: https://developers.openai.com/codex/local-config/
- Config reference: https://developers.openai.com/codex/config-reference/
- Advanced config: https://developers.openai.com/codex/config-advanced/
- Security: https://developers.openai.com/codex/security/
- CLI flags: https://developers.openai.com/codex/cli/reference/
- Skills: https://developers.openai.com/codex/skills/
- AGENTS.md: https://developers.openai.com/codex/guides/agents-md/
