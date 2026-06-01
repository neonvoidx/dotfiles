---
name: planning
description: Planning workflow for implementation strategy, task breakdowns, sequencing, and validation checkpoints.
---

# Planning Preferences

## Goal
- Produce concrete, execution-ready plans with clear scope, assumptions, risks, dependencies, and validation checkpoints.

## Workflow
1. Frame the request:
- Identify the objective, success criteria, constraints, non-goals, and known sources of truth.
2. Gather only needed context:
- Inspect code, tests, docs, configs, tickets, logs, or prior memory that materially affect the plan.
3. Design the sequence:
- Break work into ordered steps with ownership boundaries, dependencies, edge cases, and rollback or recovery considerations when relevant.
4. Define validation:
- Specify the checks, tests, review gates, or evidence needed to prove each meaningful milestone.
5. Call out uncertainty:
- Mark assumptions, unresolved questions, and risks that should be verified before or during execution.

## Constraints
- Do not present guesses as facts; tie recommendations to current evidence or label them as assumptions.
- Keep plans proportional to the task size and avoid introducing abstractions or phases that do not reduce risk.
- When implementation will follow immediately, make the plan specific enough to execute without re-discovering the same context.
- When the user asks for plan-only output, do not make code or config edits unless they explicitly approve execution.

## External Rules
- Apply imported external rules using the canonical mapping in `AGENTS.md` (`Imported External Rules` section) when the plan is for feature, refactor, testing, or release work.

## Done Criteria
- Objective, scope, and non-goals are clear.
- Steps are ordered and actionable.
- Dependencies, risks, and edge cases are identified.
- Validation checkpoints are explicit.
- Open questions are separated from confirmed facts.
