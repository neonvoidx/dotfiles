---
name: agent-configuration
description: Use when understanding, adding, changing, or troubleshooting agent harness configuration (rules/skills/commands/tools/permissions) across Claude Code, OpenCode, Codex, or Cline
metadata:
  owner: shrug-labs
  last_updated: 2026-04-01
---

## Why this exists
Harness configuration is leverage: it determines what the agent can *see*, what it can *do*, and how safely it can operate (least privilege, auditability, predictable routing).

This skill is the umbrella index for:
- harness layers (instructions/rules, skills, commands/workflows, tools/MCP, hooks)
- allowlist governance (what’s enabled where, and why)
- validation checklists (prove the harness is configured correctly)

## When to use
- You need to understand why an agent behaved a certain way (e.g., missing context, refused a tool, used an unexpected tool, followed the “wrong” rule).
- You are adding or changing any of: rules/instructions, skills, commands/workflows, MCP servers, tool allowlists, or hook/guardrail behavior.
- You are troubleshooting harness drift across machines or repos (config precedence, discovery paths, routing differences).
- You need a repeatable, least-privilege workflow for enabling new capabilities without accidentally expanding tool access.

## When not to use
- You only need help with a single library/API or a small coding question; use the most relevant domain skill instead.
- You already have a known-good harness configuration and the issue is clearly in application code, data, or external service health.
- You are looking for “best possible” capability regardless of governance; this skill prioritizes least-privilege and auditability over maximum tool access.

## Verify
Run these checks after any harness or pack change, and whenever behavior is surprising. Use the introspection commands for your harness:

| Check | Claude Code | OpenCode | Codex | Cline |
|-------|-------------|----------|-------|-------|
| Config/paths | Inspect `~/.claude/rules/`, `~/.claude/skills/`, `.mcp.json` | `opencode debug paths` | Inspect `AGENTS.override.md`, `config.toml` | Check `.clinerules/`, MCP settings UI |
| Agent/tools | Review `.claude/agents/`, `settings.json` permissions | `opencode debug agent <name>` | Inspect `.agents/*.toml`, `config.toml` | MCP settings UI → server tool lists |
| MCP config | `cat .mcp.json` or `~/.claude.json` | `opencode debug paths` + `opencode debug agent <name>` | Inspect `config.toml` `[mcp_servers]` | MCP settings in GUI |

1) Confirm config/rules/skills locations match your expectation for the current repo and environment.
2) Confirm skill discovery — the paths containing this pack’s `skills/` directory are included.
3) Confirm the active agent’s tool surface reflects least privilege (no unexpected wildcard expansions; write tools only when explicitly required).
4) Confirm MCP servers — only intended servers enabled, tool set matches curated allowlist policy.
5) Run the pack validation gate: `aipack doctor` — exits 0 with no secrets or portability violations.

## Failure modes
Use the introspection commands from the Verify table above, adapted to your active harness.

### Skill not found / never triggers
**Symptoms**: the harness cannot locate `agent-configuration`, or your “use this skill” prompt has no effect.
**Recovery**: Check skill discovery paths. Confirm the pack’s `skills/` directory is included. If missing, fix the harness config and re-check.

### Agent uses unexpected rules or ignores repo-specific guidance
**Symptoms**: the agent follows global guidance when repo guidance should apply (or vice versa), or behaves inconsistently across repos.
**Recovery**: Check which rules files are loaded and from which locations. Adjust rule placement or glob configuration so the most specific rule for the repo is discoverable. Re-check after the change.

### Tool missing, denied, or “not allowed”
**Symptoms**: tool calls fail due to missing permissions/allowlist restrictions, or the wrong tool surface is available.
**Recovery**: Inspect the resolved tool list. If a required tool is missing, add it to the smallest-scope allowlist that satisfies the task. If too many tools are enabled, tighten the allowlist. Re-check after changes.

### MCP server enabled but tools don’t work as expected
**Symptoms**: the server appears configured, but calls fail or the harness does not expose the expected tools.
**Recovery**: Confirm the MCP config file being used is the one you edited. Confirm the agent is allowlisted for the intended server tools. Align allowlist entries to tool names reported by introspection.

## The layering model (portable across harnesses)
1) **AGENTS.md / rules / instructions**: how to behave (tone, boundaries, verification discipline)
2) **Skills**: reusable workflows/knowledge (loaded on demand)
3) **Commands / workflows**: repeatable macros (subagent execution to keep context lean)
4) **Tools / MCP servers**: capability surface (must be least-privilege and auditable)
5) **Hooks / guardrails**: policy enforcement (formatting, validation, secret checks)

## What to load

This is an umbrella skill. Load only the reference you need.

| If you need to... | Load |
|---|---|
| Change tool access / MCP allowlists | `references/mcp-governance.md` |
| Understand a specific harness | `references/harness-claudecode.md`, `harness-opencode.md`, `harness-codex.md`, or `harness-cline.md` |
| Map pack frontmatter to harness fields | `references/frontmatter-mapping.md` |
| Document MCP server inventory | `references/mcp-inventory.md` |
| Verify changes took effect | `references/validation-checklist.md` |
| Design portable multi-harness setup | `references/layering-model.md` |

### MCP governance (non-negotiables)
- Keep MCP tools least-privilege and auditable.
- Route sensitive operations through purpose-built ops agents.
- Treat inventories/snapshots as evidence; treat enforced config as truth.
- See: `references/mcp-governance.md`

## Validation checklist (run after any harness change)
1) Confirm the harness loads the right rules/instructions.
2) Confirm skills are discoverable (skill index lists expected skills).
3) Confirm MCP servers are registered and visible in the client.
4) Confirm tool surface is least-privilege:
   - global deny in place
   - ops agents own enterprise tools
   - write tools remain disabled unless explicitly required
5) Record deltas as links + TODOs (no speculation).

## Related skills (if available in co-distributed packs)
- Domain-specific packs may provide their own dev/ops skills that extend this framework with org-specific MCP routing, domain workflows, and internal anchors.

## Canonical docs anchors (external)

Claude Code: https://code.claude.com/docs/en/overview

OpenCode: https://opencode.ai/docs/config/

Codex: https://developers.openai.com/codex/config-reference/

Cline: https://docs.cline.bot/

Per-harness reference files in `references/` carry full doc link sets.

