---
name: execute-plan
description: '[Workflow] Execute an implementation plan task by task with review checkpoints'
source_type: workflow
metadata:
    last_updated: 2026-03-11T00:00:00Z
    owner: shrug-labs
---

## Steps

1. **Locate the plan.** Find the plan in the current conversation, in a file path the user provides, or ask the user to supply it.

2. **Execute.** Invoke the `executing-plans` skill. If the harness supports subagents, invoke `subagent-driven-development` instead for parallel task execution.

3. **Finish the branch.** After all tasks complete, invoke the `finishing-a-development-branch` skill to clean up, verify, and prepare for review.

## Verify

- All plan tasks committed. Project test suite passes.
