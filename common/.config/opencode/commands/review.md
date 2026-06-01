---
name: review
description: Evidence-first code review workflow that prioritizes correctness, regressions, and test gaps.
---

# Code Review Preferences

## Goal
- Surface meaningful risks early: correctness, regressions, missing tests, and operational impact.

## Workflow
1. Triage by severity:
- Prioritize correctness and security issues, then reliability and maintainability.
2. Evidence-first findings:
- Reference concrete files or lines and explain impact.
3. Evaluate feedback quality:
- Do not assume every reviewer comment or suggestion is correct.
- Check whether the feedback is supported by code, behavior, tests, architecture, or stated requirements before accepting it.
- When feedback is weak, preference-driven, or contradicted by evidence, push back clearly and politely with rationale.
- When a reviewer is pointing at a real problem but the proposed fix is weak, acknowledge the problem and offer a better direction.
4. Test gaps:
- Call out missing or weak tests for risky paths.
5. Residual risk:
- State remaining uncertainty or unverified assumptions.

## Constraints
- Avoid style-only feedback unless it impacts correctness or long-term maintenance.
- Do not block on preference when behavior is safe and clear.
- Do not accept, implement, or repeat reviewer suggestions blindly.
- Prefer explaining tradeoffs and alternatives over arguing from authority or taste.

## External Rules
- Apply imported external rules using the canonical mapping in `AGENTS.md` (`Imported External Rules` section).

## Done Criteria
- Findings listed in severity order.
- Each finding includes why it matters and suggested direction.
- Responses to reviewer feedback distinguish between valid issues, partially valid issues, and unsupported suggestions when that distinction matters.
- If no findings, explicitly state that and note residual risks or testing gaps.
