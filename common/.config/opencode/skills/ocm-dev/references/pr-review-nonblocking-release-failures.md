# Non-Blocking Release Failures in PR Review

A failed release attached to a PR is not automatically actionable review evidence.

## Pattern: external service instability

Plan-only release failures frequently trace to transient external service errors (e.g., repeated `503 Service Unavailable` from downstream OCI services during Terraform planning) rather than anything in the PR's changed surface.

## Review guidance

When a PR has an attached failed release:
1. Inspect the actual failure payload.
2. Check whether the failure is in the changed surface.
3. If the evidence is repeated external-service instability, treat it as likely non-blocking for the code review.
4. Ask for rerun or retry rather than code changes when the failure mode is environmental.

## Why this matters

Without this check, release bot noise can incorrectly turn into blocking review feedback even when the diff only touches static config and the failure is elsewhere.
