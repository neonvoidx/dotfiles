---
name: testing
description: '[Workflow] Test planning and validation workflow for reliable, maintainable coverage and regression confidence.'
source_type: workflow
---

# Testing Preferences

## Goal
- Deliver reliable, maintainable tests that increase confidence and catch regressions.

## Workflow
1. Plan first and review:
- Create a concise test plan (scope, test cases, files, key assertions).
- Get plan review or approval before writing tests.
2. Implement from approved plan:
- Follow the approved plan in small, traceable changes.
- If scope changes, pause and re-review the plan.
3. Validate and stabilize:
- Run new and affected tests after writing.
- If failures occur, investigate root cause across test and production code.
- Fix the right layer and re-run until stable.
4. Coverage and next phase:
- Check coverage for changed areas.
- Propose a concrete next iteration plan for highest-value gaps.

## Validation Baseline
- Use the project-default local repo or cache when writable; only override local cache paths if permission errors occur.
- For final validation, run the relevant module or project build gate for the changed area.
- If the project enforces static gates (for example Checkstyle, PMD, CPD, or SpotBugs), treat them as part of test-change completion.

## Coverage Reporting Rule
- When using JaCoCo XML counters, treat values as `missed` and `covered`.
- Report snapshots as `covered/total (percent)` where `total = missed + covered`.

## Mocking Policy
- Prefer real behavior, realistic fixtures, and integration at the unit boundary where feasible.
- Avoid mocks unless needed for isolation, determinism, or impractical external dependencies.
- When mocks are required, keep them minimal and document why.
- Prefer state or behavior assertions over interaction verification where possible.
- Reuse existing test utilities and helpers before adding local helper methods to avoid duplication.

## Parallelization
- For broad test scope, decompose by module or suite and execute in parallel via sub-agents.
- Keep a shared plan and consistent fixtures and assertion conventions.

## External Rules
- Apply imported external rules using the canonical mapping in `AGENTS.md` (`Imported External Rules` section).
- For test or build execution policy conflicts, follow `AGENTS.md` precedence rules.

## Done Criteria
- Approved plan followed.
- Tests pass locally.
- Coverage checked and next-phase plan documented.
- Coverage snapshots are reported in `covered/total (percent)` when shared.
- Durable learnings are captured in memory when new insights appear.
