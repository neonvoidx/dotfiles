# Layering model (portable)

Use the same mental model across Claude Code/OpenCode/Codex/Cline:

1) **Rules / instructions (AGENTS.md etc.)**
   - Defines behavior, boundaries, verification discipline.
2) **Skills**
   - Reusable knowledge/workflows loaded on demand.
   - Skills can also carry **code assets** (scripts/config templates) alongside the docs.
3) **Commands / workflows**
   - Repeatable macros; keep “heavy” steps off the main agent when possible.
4) **Tools / MCP**
   - Capability surface. This is the primary risk boundary.
5) **Hooks / guardrails**
   - Enforcement (formatting, validation, secret checks, policy).

Design principle: keep **repo truth** in repo `AGENTS.md` and keep **umbrella guidance** in skills.

## Bundling scripts with skills (local-only pattern)
- Put scripts under the skill (e.g., `skill-name/bin/` or `skill-name/tools/`).
- Prefer *thin wrappers* that call into a pinned local clone (so upstream logic stays in one place).
- Document:
  - required auth mode
  - blast radius
  - dry-run / validation steps
