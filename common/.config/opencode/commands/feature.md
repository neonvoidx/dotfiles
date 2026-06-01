---
name: feature
description: Feature delivery workflow for scoped implementation, validation, and safe rollout.
---

# Feature Delivery Preferences

## Goal
- Deliver user-visible value with clear scope, verification, and safe rollout.

## Workflow
1. Define scope:
- Clarify acceptance criteria, non-goals, and constraints.
2. Plan:
- Break into small milestones with validation checkpoints.
3. Implement:
- Build incrementally and keep behavior observable.
4. Verify:
- Validate against acceptance criteria and run relevant tests.
5. Finalize:
- Note tradeoffs, risks, and follow-up opportunities.

## Constraints
- Avoid hidden scope expansion without explicit approval.
- Prefer backward-compatible changes unless breakage is approved.

## External Rules
- Apply imported external rules using the canonical mapping in `AGENTS.md` (`Imported External Rules` section).

## Done Criteria
- Acceptance criteria met.
- Tests and validations complete.
- Risks and follow-ups documented.
- Reusable lessons captured in memory.
