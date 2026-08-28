---
name: create-module-knowledge-skills
description: Use when a repository needs module-specific Codex skills, repo AGENTS.md skill routing, or drift-maintained knowledge packs for codebase modules, architecture areas, services, packages, or Maven/Gradle/workspace submodules.
---

# Create Module Knowledge Skills

Use this skill to turn a repository into a lazy-loaded knowledge system: a thin repo `AGENTS.md` routes work, and each important module gets a focused skill with deeper references.

## Core Rule

Do not create module skills immediately after module discovery. First identify candidate modules, summarize why each one matters, and ask the user to confirm the final module list. Continue without confirmation only when the user explicitly supplied the module list.

## Workflow

1. **Discover repo shape**
   - Read repo rules: `AGENTS.md`, `.agents/skills`, `.clinerules`, `.cursor/rules`, build files, and existing docs.
   - Identify build modules, service folders, app packages, library packages, worker jobs, data layers, shared contracts, and generated clients.
   - Identify existing test, coverage, and validation tooling before writing test/coverage guidance.
   - Prefer `rg --files`, build manifests, package managers, and source-tree boundaries over directory names alone.

2. **Propose module list**
   - Group candidates into module-skill targets.
   - For each target, include path, responsibility hypothesis, key packages/files, and why a dedicated skill is useful.
   - Ask the user to confirm, remove, merge, or add modules before writing module skills unless the user already gave the exact list.

3. **Read confirmed modules deeply**
   - Trace entrypoints, dependency direction, data flow, class families, business processes, tests, configs, generated code, and runtime wiring.
   - Read current code before trusting existing docs or old skills.
   - Use existing class references as a map, not as a substitute for reading the actual module source.
   - For cross-module contracts, inspect both producer and consumers.
   - For API/controller/resource families, look for external/internal, v1/v2, generated/manual, public/admin, and sync/async variants so important siblings are not omitted.

4. **Create or update module skills**
   - Put repo-local skills under `.agents/skills/<repo-or-module-name>-module/` unless the repo has a different established layout.
   - Keep `SKILL.md` concise: trigger, load order, engineering workflow, guardrails.
   - Put detailed context in `references/overview.md`, `references/data-flow.md`, optional `references/classes.md`, and `references/business-processes.md` when those categories apply.
   - Use `references/module-skill-templates.md` for the concrete pack structure and content checklist.

5. **Create or update repo `AGENTS.md`**
   - Keep it as an always-loaded router, not a knowledge dump.
   - Add path-based routing, cross-module routing, test/coverage routing, and skill drift maintenance rules.
   - Route to skills instead of duplicating module details or testing policy.
   - Do not introduce new authoritative test/coverage paths that conflict with checked-in repo tooling.

6. **Validate**
   - Confirm every generated skill has valid frontmatter and referenced files.
   - Search for stale/deleted rule paths or duplicated always-loaded context.
   - Verify `AGENTS.md` routes to the skill names that actually exist.
   - Report whether validation was structural only or included code/test execution.

## Update Existing Module Skills

When the task is to update an existing module skill after code changes:

- Load the current skill and only the references relevant to the change.
- Compare skill text against current code, not memory or old summaries.
- Update skill references when structure, class responsibility, data flow, dependency direction, or critical business process behavior changed.
- Do not churn skill files for purely local implementation details.

## Guardrails

- Keep heavy module knowledge out of `AGENTS.md`.
- Keep detailed test policy in test-specific skills or references.
- Align generated test and coverage guidance with the repo's existing scripts, build reports, and CI workflow unless the user explicitly wants to change those contracts.
- Use one verification model across generated skills: run local validation when feasible; if blocked, too expensive, or delegated to CI/user, say so and require refreshed results before claiming success.
- Prefer one canonical source for each durable workflow rule; route to it from other skills instead of duplicating it.
- If current code and skill text disagree, current code wins and the skill should be repaired.
- Make module skills useful for future engineering work, not just architecture summaries.
