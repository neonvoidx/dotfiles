---
name: release
description: '[Workflow] Release workflow for readiness checks, risk review, execution, and post-release validation.'
source_type: workflow
---

# Release Preferences

## Goal
- Ship safely with clear readiness criteria and rollback confidence.

## Workflow
1. Readiness check:
- Confirm scope, change log, test status, and dependencies.
2. Risk review:
- Identify high-risk components and mitigation steps.
3. Execute release:
- Follow the release sequence and verify critical health signals.
4. Post-release:
- Confirm success criteria, monitor, and document outcomes.

## Constraints
- Do not release with unknown failing checks unless explicitly approved.
- Ensure the rollback path is known before proceeding.

## Done Criteria
- Release status and evidence recorded.
- Known risks and rollback notes documented.
- Durable release lessons captured in memory when new.
