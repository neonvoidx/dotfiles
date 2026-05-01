# Quality Dimensions

Review lens for evaluating pack content. Four core dimensions apply to all vectors; two specialized dimensions per vector.

## Core dimensions (0-5 scale)

### 1. Determinism & actionability

- 5: All actions explicit, reproducible, commands use env placeholders, examples include machine-checkable outcomes.
- 4: Mostly explicit; one minor action omitted.
- 3: Some actionable items but steps require human judgment or unspecified inputs.
- 2: Ambiguous or relies on unstated environment assumptions.
- 1: Non-actionable narrative only.
- 0: Misleading/contradictory instructions.

### 2. Verification & evidence

- 5: Deterministic verification steps, sample outputs or tests, clearly referenced artifacts.
- 4: Verification present but lacking sample output or full determinism.
- 3: Manual checks documented but no automated assertions.
- 2: Statements of success without checks.
- 1: No verification guidance.
- 0: Advice discouraging verification or impossible to verify.

### 3. Safety & least privilege

- 5: Explicit least-privilege defaults, no secrets, scoped tool allowlists.
- 4: Mostly least-privilege; minor permissive examples.
- 3: Privileged operations shown without least-privilege alternatives.
- 2: Unsafe examples present but flagged optional.
- 1: Dangerous by default.
- 0: Contains secrets or direct credentials (hard gate).

### 4. Portability & reproducibility

- 5: No user-specific paths, env expanded via placeholders, platform-agnostic.
- 4: Minor path/platform assumptions that are documented.
- 3: Some portability issues requiring local edit.
- 2: Multiple portability blockers.
- 1: Tied to a specific workstation/setup.
- 0: Contains user-specific credentials or absolute paths (hard gate).

## Specialized dimensions (per vector)

### Agents

- **Tool/permission scoping** (0-5): Are required tools and permission boundaries explicit? 5 = complete tool list + minimal permissions; 0 = missing or dangerous.
- **Operator UX** (0-5): Command ergonomics, error messages, helpful defaults.

### Rules

- **Scope/precedence/activation** (0-5): Are rule triggers and precedence explicit and testable?
- **Consistency** (0-5): Do rule examples match actual rule language and examples?

### Skills

- **Packaging/progressive disclosure** (0-5): Does SKILL.md have proper frontmatter? Is bin packaging clear?
- **Examples & edge cases** (0-5): Are edge cases and failure modes described with examples?

### Workflows

- **Interface contract** (0-5): Input/output contracts clear, stable parameters documented.
- **Integration references** (0-5): External integrations documented and mocked/tested where possible.

### MCP configs

- **Inventory correctness** (0-5): Valid JSON, required fields present, tool lists accurate.
- **Auth/env contract** (0-5): Use of env placeholders, no embedded secrets, documented auth expectations.

### Docs

- **Information architecture** (0-5): Clear sections, expected reader persona mapping.
- **Link/reference quality** (0-5): Links valid, references resolvable.

## Composition & independence

### Standalone survivability

Before trimming a rule for overlap with companion rules (e.g., removing "Verify with Commands" from anti-slop because verification-before-completion covers it), ask: **does this rule need to work without its companions?**

- If the rule may ship outside its pack, be loaded in isolation, or be used by operators with a subset of the ecosystem → keep the overlap.
- If the rule is always co-loaded with its companion (same pack, same profile tier) → trim safely.

Rules confirmed as standalone-survivable: any rule in a team pack that operators may cherry-pick individually.

### Co-distributed pack composition

When multiple packs are always shipped together (same profile, same registry), soft cross-pack references between them are acceptable:
- Skills referencing skills in a sibling pack ("if the deep-research skill is available, invoke it")
- Rules referencing skills in a sibling pack for detail

Only flag cross-pack references as issues when the referenced pack is NOT co-distributed with the referencing pack. If co-distribution is profile-guaranteed, the reference degrades gracefully — it's not a hard dependency.

## Hard gates (fail immediately)

- Secrets: tokens, passwords, private keys, credential material.
- Forbidden paths: absolute paths (`/Users/...`, `/home/...`).
- Missing frontmatter on pack markdown files.

## How to use

When reviewing pack content, evaluate each applicable dimension on the 0-5 scale. Use the per-vector specialized dimensions to focus on what matters most for that content type. Hard gates take precedence -- check them first.
