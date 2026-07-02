---
name: console-ui-implementation-plans
description: Create or update implementation plans for the console-ui-testing-agent repository. Use when Codex is asked to write an implementation plan, planning doc, ticket plan, or scoped work plan for this repo; plans must live under docs/implementation-plans and the filename must include the ticket number, asking the user for the ticket number when it is not known.
---

# Console UI Implementation Plans

## Workflow

1. Confirm the ticket number before writing a plan.
   - Extract it from a Jira key or URL when present, such as `RWMIGENG-7749`.
   - If no ticket number is known, ask one concise question for the ticket number and do not create the file yet.
2. Review `mvp-goal.md` before writing.
3. Review `docs/architecture.md` when the plan touches project structure, contracts, adapters, scenario flow, commands, runner behavior, or verification workflow.
4. Treat existing `docs/implementation-plans/` files as style/history only. Do not use them as source of truth unless the user specifically asks.
5. Create the plan under `docs/implementation-plans/`.
6. Include the lowercased ticket number in the filename:

```text
docs/implementation-plans/<ticket-number>-<short-topic-slug>.md
```

Example:

```text
docs/implementation-plans/rwmigeng-7749-maui-form-default-actions.md
```

Use a short, readable slug. Avoid dates unless the user asks for them.

## Plan Content

Keep plans concrete and ticket-scoped. Prefer these sections when applicable:

- `Goal`
- `Current Gap`
- `In Scope`
- `Out Of Scope` or `Non-Goals`
- `Proposed Model` or `Proposed Code Shape`
- `Implementation Steps`
- `Tests`
- `Success Criteria`
- `Deferred`

Include the ticket key near the top, usually in a `Related tracking` or `Ticket` line.

For this repo, plans should preserve these ownership boundaries:

- `mvp-goal.md` is the source of truth for MVP direction.
- `TestPlan` owns adapter-neutral acceptance intent.
- `AuthoringContext` owns generated artifact metadata, builders, concrete fields, actions, options, defaults, and source/provenance metadata.
- Adapters own rendering details, locators, imports, harness setup, output paths, and runner behavior.
- Field/component builders should own field-specific assertion and interaction rendering.
- Form-level actions should not be forced through field builders unless a later adapter explicitly chooses that architecture.

## Editing And Verification

Use `apply_patch` for creating or editing the plan file.

For docs-only plan creation, do not run `yarn test` unless the user asks. If the task also changes code, contracts, commands, adapters, scenarios, or tests, follow the repo guide and run `yarn test`.

If the plan proposes a future architecture change but does not implement it, do not update `docs/architecture.md`; update architecture only after actual code or command-flow changes.
