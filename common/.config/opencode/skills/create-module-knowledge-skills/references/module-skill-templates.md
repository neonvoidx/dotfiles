# Module Knowledge Skill Templates

Use these templates and checklists when creating or updating repo-local module skills.

## Candidate Module Discovery Checklist

Look for:

- Build modules: Maven modules, Gradle projects, Bazel packages, npm/yarn workspaces, Python packages, Go modules.
- Runtime boundaries: API apps, workers, background jobs, CLIs, data-plane/control-plane services, frontend apps.
- Layer boundaries: API/resource layer, persistence/DAL layer, shared commons/contracts, worker/orchestrator layer, generated clients.
- Business boundaries: subscription, billing, tenancy, identity, workflow, replication, reporting, reconciliation, admin operations.
- Ownership boundaries: folders with separate tests, configs, package namespaces, generated artifacts, or release/deploy behavior.
- Tooling contracts: checked-in test scripts, coverage scripts, CI commands, report paths, lint/checkstyle/PMD commands, and generated-code refresh workflows.

For each candidate, capture:

```text
- Module:
- Paths:
- Responsibility hypothesis:
- Key entrypoints:
- Key dependencies:
- Why a dedicated skill is useful:
- Suggested merge/split decision:
```

Before writing skills, present the candidate list and ask the user to confirm the final module set unless the user already supplied it.

## Skill Directory Shape

Default repo-local layout:

```text
.agents/skills/<module-name>-module/
  SKILL.md
  references/
    overview.md
    data-flow.md
    classes.md              # optional; useful as a class-family map
    business-processes.md
```

Use fewer reference files when the module is genuinely small. `classes.md` is optional, but often a good starting reference for future module work when a module has many class families, entrypoints, workers, repositories, or shared contracts. Add extra references only for clearly separate critical processes or large domains.

## SKILL.md Template

```markdown
---
name: <module-name>-module
description: Use when working on <module> <specific triggers, packages, runtime areas, business flows>.
---

# <module-name>-module

Use this skill before changing or reviewing `<module>`. One sentence describing the module role.

## Load Order

1. Read `references/overview.md` for responsibility, source boundaries, and dependency direction.
2. Read `references/data-flow.md` when the task touches request/workflow/persistence/client/config flow.
3. Read `references/classes.md` when it exists and the task needs a class-family map, implementation-file selection, or responsibility review.
4. Read `references/business-processes.md` when critical business workflows are affected.
5. After using references to orient, read the actual module classes/source files needed for the task before implementing or reviewing code.

## Engineering Workflow

1. Start from the relevant entrypoint and follow the local dependency direction.
2. Keep shared contracts, converters, schemas, and generated/client models aligned across modules.
3. For async or background work, verify queue arguments, versioning, state, and worker execution.
4. For tests, route to the repo's test-writing or coverage skill rather than duplicating test policy here.

## Guardrails

- Preserve module ownership boundaries.
- Do not bypass validators, repositories, auth, transaction, or workflow gates when those are part of the module contract.
- If code and this skill disagree, trust current code and update the skill in the same branch.
```

## overview.md Content

Include:

- Module responsibility and what the module must not own.
- Source/package structure.
- Runtime/bootstrap/config/dependency direction.
- Important source hotspots.
- Testing context as pointers to test skills or established test bases.

Avoid:

- Exhaustive file lists.
- Business-process details that belong in `business-processes.md`.
- Class-by-class descriptions that belong in `classes.md`.

## data-flow.md Content

Use text diagrams where useful:

```text
External/API/Event
  -> entrypoint
  -> validator/orchestrator
  -> domain/DTO/contract
  -> repository/client/workflow
  -> persistence/downstream/side effect
```

Cover only flows that future code changes are likely to touch:

- Request to service to persistence.
- Workflow queue to worker execution.
- DTO/entity/model conversion.
- Replication, reconciliation, scheduler, backfill, or event ingestion.
- Client wrapper/auth/config wiring.

## classes.md Content

`classes.md` is optional. Use it when it will materially improve future engineering work by giving agents a fast class-family map. It is a starting point for code understanding, not a replacement for reading the module's actual classes.

Organize by class family, not raw directory order:

- Entrypoints/resources/controllers.
- Services/orchestrators.
- Validators/converters/mappers.
- Repositories/managers/entities.
- Workers/workflows/schedulers.
- Clients/wrappers/providers/config.
- Test bases/utilities if they shape future work.

For each family, explain responsibility, high-risk classes, extension points, and common change patterns.

When writing or updating `classes.md`, inspect the full relevant module class set first. Do not infer class responsibility only from filenames, package names, old docs, or generated summaries.

Completeness checks:

- For resource/controller families, search for sibling variants before finalizing: external/internal, public/admin, v1/v2, generated/manual, sync/async, read/write, regional/global.
- For worker families, include workflow definitions, worker implementations, schedulers/managed components, state/argument classes, and queue/work-request integration.
- For persistence families, include entity/schema classes, converters, store managers, repositories, indexes, pagination/token helpers, transaction boundaries, and replication hooks.
- For shared contracts, include DTOs/domain types, workflow arguments, client wrappers, auth/config helpers, feature flags, and every major consumer module.

Verbosity guidance:

- `SKILL.md` should stay concise.
- Reference files may be detailed when the detail is useful for future engineering work and only loaded on demand.
- If a reviewer says a reference is verbose, first check whether the content is lazy-loaded and actionable. Prefer reorganizing or summarizing repetitive detail over deleting critical context.

## Test and Coverage Policy Discovery

Before writing test or coverage guidance, inspect current repo tooling:

```bash
rg -n "jacoco|coverage|pmd|checkstyle|mvn test|gradle test|pytest|jest|go test|lcov" .
find . -maxdepth 3 -type f \( -iname "*coverage*" -o -iname "*test*" -o -iname "*checkstyle*" \)
```

Document only the report paths and commands that match the repo's existing tooling unless the user explicitly asks to change them.

When a repo has both detailed XML and summary CSV reports:

- Prefer XML or another structured detailed report for gap targeting when the repo produces it.
- Keep summary reports aligned with repo scripts when they are used for rollups.
- Do not declare a new source of truth that conflicts with checked-in scripts or CI docs.

Use one verification model across all generated skills:

- Run local validation when feasible and safe for the task.
- If local validation is blocked, too expensive, or intentionally delegated to CI/user, say that plainly.
- Never mix "agent must not run tests" with "agent must run tests" across references in the same skill pack.

## business-processes.md Content

Create separate sections for each critical process. For each process, include:

```text
Purpose:
Primary modules/classes:
Happy path:
Important branches:
State or persistence changes:
External calls or side effects:
Failure/retry/rollback behavior:
Test or verification hooks:
Skill drift triggers:
```

Prefer multiple focused process sections over one broad narrative.

## Repo AGENTS.md Routing Template

Keep the file short and route to skills:

```markdown
# <Repo> Agent Instructions

This file is the lightweight, always-loaded router for this repository. Keep durable module knowledge, class inventories, data flows, testing policy, and workflow details in `.agents/skills/**` so they load only when needed.

## Skill Routing

- `<module-path>/**` -> `<module-skill-name>`

For cross-module work, start with the entrypoint module skill, then load related module skills when DTOs, entities, converters, repositories, workflow arguments, clients, generated models, or runtime contracts cross module boundaries.

## Test and Coverage Routing

- Route test writing, test planning, and coverage analysis to the repo's test-specific skills.
- Keep detailed testing policy in test-skill references, not this always-loaded file.

## Module Skill Maintenance

When a code change affects a covered module, perform a skill drift check before finishing:

1. Identify touched module skills.
2. Load the relevant `SKILL.md`.
3. Load only references affected by the change.
4. Update skill references in the same branch when code changes make them stale.
5. If no update is needed, state that no module-skill update was required.

## Guardrails

- Current code beats stale skill text.
- Keep this file concise; route to skills instead of embedding details.
- Do not duplicate durable workflow rules across multiple skills.
```

## Validation Checklist

Run structural checks appropriate to the repo:

```bash
find .agents/skills -maxdepth 3 -name SKILL.md -print
rg -n "old-rule-path|deleted-path|placeholder-marker" AGENTS.md .agents/skills
rg -n "<module-skill-name>" AGENTS.md .agents/skills
```

Also verify:

- Every skill frontmatter has `name` and `description`.
- Every required reference named in a `SKILL.md` exists; optional references such as `classes.md` must be clearly marked optional when omitted.
- `AGENTS.md` references real skill names.
- Heavy context is in references, not always-loaded routing files.
- The final answer distinguishes structural validation from runtime/test validation.
