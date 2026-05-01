# Construct Guide

Reference for pack content constructs. Which one to use, how to write each, what fails.

## Core Principle

LLMs are autoregressive. Pack constructs (rules, workflows, skills, agents, MCP) are mechanisms for getting the RIGHT context into the buffer at the RIGHT time. Specificity drives quality — ambiguity lets the model fill in blanks wrong.

## Token Budget

| Construct | Loaded When | Budget Pressure |
|-----------|-------------|-----------------|
| Rules | Always | HIGH — every token costs on every interaction |
| Workflows | Invoked by name | LOW — only loaded when triggered |
| Skills | Matched by description | LOW — only loaded when relevant |
| Agents | Spawned | NONE on parent context |

Rules must be ruthlessly concise. Skills and workflows can be detailed.

### What's in context at runtime

Only harness config locations (`~/.claude/rules/`, `.opencode/rules/`, etc.) are held in agent context — NOT the pack source at `~/.config/aipack/packs/`. When calculating always-on token budget, count the synced copies in harness locations, not the pack source. A rule that exists in both pack source and `~/.claude/rules/` is NOT duplicated in agent context.

## Instruction Files vs Pack Content

Instruction files (AGENTS.md and harness equivalents) and pack content (rules, skills, workflows) serve different audiences. Never mix them.

| Layer | Files | Audience | Content type |
|-------|-------|----------|-------------|
| Instruction | AGENTS.md (or harness equivalent) | Agents working on **source code** | Directives, constraints, directory maps |
| Pack rules | rules/*.md | Agents **using** the pack (synced to harnesses) | Operational governance |
| Pack skills/workflows | skills/, workflows/ | Agents **using** the pack (on-demand) | Methodology, processes |
| Docs | docs/**/*.md | Humans + on-demand agent reads | Reference material, specs |

**What belongs in instruction files:** imperatives ("do X", "never Y"), non-obvious constraints an agent can't discover from code or `--help`, directory maps, essential terminology.

**What does NOT belong:** discoverable info (build commands from Makefile, flags from `--help`), standard language conventions (gofmt, import groups), passive descriptions, operational rules (mutation gates, read-only defaults → these are pack rules).

**Key distinctions:**
- AGENTS.md belongs to the repo, not the pack — NOT in pack.json
- AGENTS.override.md is a managed artifact — never edit directly
- Operational rules (mutation gate, read-only default) go in `rules/*.md`, not instruction files

## Cross-Pack Independence

Content must work in isolation. A rule that ships to a team pack may not have its companion skill from a personal pack. Duplication across packs is acceptable when a construct may be used without its complement — partial coverage beats a broken reference.

## Composition Patterns

Content composes within and across packs. Three patterns:

### Intra-Pack: Rule Seed → Skill Detail

When a rule exceeds 60 lines, split into a concise always-on rule (the seed) and a detailed on-demand skill (the methodology). The rule states *what* must happen; the skill teaches *how*.

### Intra-Pack: Skill Chaining (Soft)

Skills name their terminal state and suggest what comes next. Chaining is advisory — the skill works without its successor. Format:

```markdown
## After [This Skill's Output]

- **[Condition A]** → If the [next-skill] skill is available, invoke it.
- **[Condition B]** → If the [other-skill] skill is available, invoke it.
- **[Terminal condition]** → Done.

Do not jump from [this phase] directly to [premature action].
```

### Cross-Pack: Layered Extension

A team skill extends a personal methodology with domain-specific routing. The team skill includes enough inline context to work standalone but gets better when the personal pack is present. Format:

```markdown
This extends the operational-triage methodology with [domain]-specific routing.
If the operational-triage skill is available, invoke it first for the general
framework, then apply the routing table below.
If not available, follow the general triage principles in this skill and apply
the routing table.
```

**The profile guarantees co-presence**, not the content. Soft references degrade gracefully — hard dependencies break when a pack is absent.

---

## Rules (Always-On Constraints)

**Quality test:** Remove the rule. Does the agent behave differently? If no, delete it.

**How to write:**
- Imperative voice: "Do X", "Never Y"
- Each line: trigger-action pair — "When [situation], do [specific thing]"
- Target: <60 lines, <2K tokens
- Two sections minimum: Do / Don't
- One Good/Bad example if the distinction isn't obvious

**Anti-patterns:**
- Restating model defaults ("be concise", "don't hallucinate")
- Inventory lists without action triggers ("Available tools: X, Y, Z")
- Hedging language ("consider doing", "you might want to")
- "(reinforces X)" — if it needs reinforcing, the original is weak
- Rules longer than 60 lines — split to rule seed + skill

**Example:**
```markdown
## Do
- Use SQLAlchemy 2.0 ORM for all database operations
- Use existing models — do not create new ones without approval

## Don't
- Use raw SQL strings
- Add inline comments when function names are self-explanatory
```
Every line changes behavior. No hedging. No prose.

---

## Skills (Load-on-Demand Knowledge)

**Quality test:** Is this needed on every interaction? → Rule. Is it a step-by-step process? → Workflow. Otherwise → Skill.

**Types:**
- **Technique:** Concrete method with steps (root-cause-tracing)
- **Pattern:** Way of thinking about problems (flatten-with-flags)
- **Reference:** API docs, syntax guides, tool documentation

**How to write:**
- Description (<100 tokens): ONLY triggering conditions. "Use when..."
- SKILL.md body: <500 lines. Split heavy reference to separate files.
- Never summarize methodology in description (causes shortcutting — see CSO in SKILL.md)

**Skill directory structure:**
```
my-skill/
├── SKILL.md          # Required: instructions + metadata
├── scripts/          # Optional: executable code
├── references/       # Optional: supporting data the skill needs at activation
└── assets/           # Optional: templates, resources
```

Reference data that a skill consumes at activation time (API patterns, checklists, inventories, specs) belongs in `references/`, not in external knowledge stores. Progressive disclosure means these files only load when the skill activates — zero token cost otherwise. If reference data exists outside a skill but is only useful when that skill is active, move it into the skill.

**Anti-patterns:**
- Skills that are really rules (always-needed guidance disguised as optional)
- Skills that are really workflows (step-by-step processes disguised as knowledge)
- Descriptions that summarize the skill's workflow (causes shortcutting)
- Vague descriptions that match too broadly or too narrowly
- Reference data stored in flat external directories when it belongs colocated with a specific skill

---

## Workflows (Executable Processes)

**Quality test:** Can an agent execute this without asking clarifying questions? If it has to guess, the workflow is incomplete.

**How to write:**
- Numbered steps. Each step: one action, one specific tool/command.
- Decision trees for ambiguity — never "or equivalent"
- Explicit tool invocations: exact command, MCP tool name, or clear instruction
- Mutation gates: stop-and-confirm before any state change
- Skills handle complex sub-tasks — don't embed methodology in workflow steps

**Anti-patterns:**
- "or language-appropriate test command" — hedging. Decision tree instead.
- Documentation prose between steps — workflow isn't a tutorial
- Steps that describe what to think about rather than what to DO
- Verification as aspiration ("ensure success") rather than check ("exits 0")

**Example:**
```markdown
1. **Run unit tests**
   ```bash
   make test
   ```
   All tests must pass before proceeding.

2. **Generate commit summary**
   Use the commit-summary skill. Present for approval.
   - Approved → step 3
   - Rejected → regenerate with feedback

3. **Commit**
   MUTATION: confirm before executing.
```

---

## Agents (Constrained Personas)

**Quality test:** Does this agent need fewer tools than the default? If same toolset, it's not an agent — it's a prompt.

**How to write:**
- Tool allowlist: ONLY the tools this agent needs
- Clear scope: what it does, what it doesn't
- Least privilege by default — start restrictive, add tools only when needed

**Domain specialist vs tool holder:**

An agent that doesn't know more than its tool list is just a tool filter. The value of the agent vector is **specialization** — domain knowledge that changes how the agent uses its tools, not which tools it has.

| Dimension | Tool holder (wrong) | Domain specialist (right) |
|-----------|---------------------|---------------------------|
| **Tools** | Filtered allowlist | Right tools for the domain (including cross-server) |
| **Knowledge** | None | Loaded skill/facet content as system context |
| **Output** | Unstructured | Contract — structured format the caller can use |

- If the agent has tools but no domain knowledge → it will fail on tasks requiring context it can't discover from tool output alone.
- If the agent has no output contract → the caller can't reliably use its results.

**Anti-patterns:**
- Agents with full tool access (no constraint = no value)
- Agent descriptions that are really system prompts (use rules instead)
- Agents without explicit tool restrictions

---

## MCP Servers (External Integrations)

**In pack context:** Configuration in pack MCP definitions. Usage in workflows and skills via `mcp__<server>__<tool>` invocations.

**Quality test:** Is the tool allowlist minimal? Are credentials handled via env placeholders?

For delivery pipeline, sync procedures, and harness behaviors, see the aipack-system skill.
