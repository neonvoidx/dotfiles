---
name: write-plan
description: '[Workflow] Create a detailed implementation plan from a spec or requirements'
source_type: workflow
metadata:
    last_updated: 2026-03-11T00:00:00Z
    owner: shrug-labs
---

## Steps

1. **Write the plan.** Invoke the `writing-plans` skill with the spec, requirements, or design document as input.

2. **Present for review.** Show the completed plan to the user. Incorporate feedback until approved.

3. **Offer execution.** After approval, offer to invoke the `executing-plans` skill to begin implementation.

## Verify

- Plan exists with file paths, verification commands, and commit steps for every task.
- User has explicitly approved the plan.
