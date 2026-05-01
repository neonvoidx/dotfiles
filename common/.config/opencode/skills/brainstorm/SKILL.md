---
name: brainstorm
description: '[Workflow] Explore an idea and design a solution before implementing'
source_type: workflow
metadata:
    last_updated: 2026-03-11T00:00:00Z
    owner: shrug-labs
---

## Steps

1. **Explore the idea.** Invoke the `brainstorming` skill with the user's problem or idea as input. Collaborate until a design direction is agreed upon.

2. **Write the plan.** Once the user approves the design direction, invoke the `writing-plans` skill. Pass the agreed design as context.

3. **Present for review.** Show the completed plan to the user. Offer to refine or proceed to execution.

## Verify

- User has explicitly approved the design direction and a written plan exists.
