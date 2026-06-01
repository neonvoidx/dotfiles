---
name: debugging
description: Root-cause-driven debugging workflow focused on fast isolation, minimal fixes, and recurrence prevention.
---

# Debugging Preferences

## Goal
- Find root cause quickly, apply the smallest correct fix, and prevent recurrence.

## Workflow
1. Reproduce:
- Capture exact failure signal (error text, steps, environment, frequency).
2. Isolate:
- Narrow to subsystem, commit range, or input class.
- Prefer fast experiments that falsify hypotheses.
- After rebases, if many `cannot find symbol` errors appear in tests, first check for stale tests targeting classes removed from the base branch.
3. Fix:
- Implement the minimal change that addresses root cause.
- Avoid broad refactors during active incident unless required.
4. Validate:
- Re-run the failing path and nearby regressions.
- Add or adjust tests when appropriate.

## Constraints
- Do not mask symptoms with silent retries or broad exception swallowing.
- Document assumptions when logs or telemetry are incomplete.

## Done Criteria
- Root cause explained.
- Fix validated on the failing scenario.
- Regression risk checked.
- Durable debugging learning captured in memory if reusable.
