---
name: refactor
description: '[Workflow] Behavior-preserving refactor workflow for improving design, readability, and maintainability.'
source_type: workflow
---

# Refactor Preferences

## Goal
- Improve design, readability, and maintainability without changing intended behavior.

## Workflow
1. Baseline:
- Identify target smells and set non-behavior-change intent.
2. Safety net:
- Ensure relevant tests exist or add them first.
3. Refactor in slices:
- Make small, mechanical, reviewable changes.
4. Validate:
- Run tests and static checks after each meaningful slice.

## Constraints
- No opportunistic feature changes in refactor-only tasks.
- Keep the diff understandable; preserve public contracts unless approved.

## External Rules
- Apply imported external rules using the canonical mapping in `AGENTS.md` (`Imported External Rules` section).

## Done Criteria
- Behavior preserved.
- Complexity and readability improved.
- Tests are green and coverage is not regressed for changed areas.
- Reusable refactor guidance captured in memory if learned.
