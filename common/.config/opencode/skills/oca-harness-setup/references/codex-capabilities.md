# Codex CLI Capabilities Reference

## Configuration Surface (as of 2026-03)

| Vector | Mechanism | Location |
|--------|-----------|----------|
| Rules | `AGENTS.md` / `AGENTS.override.md` discovery chain | Project + `~/.codex/` |
| Skills | `SKILL.md` directories (progressive disclosure) | `.agents/skills/` (project), `~/.agents/skills/` (global) |
| MCP Servers | `config.toml` `[mcp_servers.*]` tables | `.codex/config.toml` (project), `~/.codex/config.toml` (global) |
| Custom Prompts | **DEPRECATED** — markdown files in `~/.codex/prompts/` | Global only, no project scope |
| Settings | `config.toml` (TOML format) | `.codex/config.toml` + `~/.codex/config.toml` |

## Key Properties

- **Skills use progressive disclosure**: only name+description loaded at startup; full SKILL.md loaded on-demand when the model selects the skill. This is the primary token-saving mechanism.
- **Custom prompts are deprecated** (late 2025). OpenAI guidance: migrate to skills. No further development.
- **Skills are project-scopeable** (`.agents/skills/` in repo). Custom prompts were global-only.
- **Skills support implicit invocation** — model auto-selects based on description match. Custom prompts required explicit `/prompts:<name>`.
- **MCP transport**: only stdio supported. SSE/WebSocket skipped with warnings.
- **AGENTS.md discovery**: walks project root → cwd, reads first non-empty file at each level. `AGENTS.override.md` takes precedence.

## Sync Engine Implications

The Codex harness adapter (as of 2026-03-10) promotes workflows and agents to skills during sync, rather than inlining them in AGENTS.override.md. This leverages progressive disclosure for token savings.

## Sources

- https://developers.openai.com/codex/skills/
- https://developers.openai.com/codex/custom-prompts (deprecated)
- https://developers.openai.com/codex/guides/agents-md/
- https://developers.openai.com/codex/config-reference/
