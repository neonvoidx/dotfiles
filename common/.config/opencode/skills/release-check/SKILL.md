---
name: release-check
description: Review or investigate OCI Shepherd release links for rollout scope, phase and target status, expected and observed diffs, per-region changes, execution errors, target logs, validations, timelines, and follow-up recommendations. Use when Codex is given a Shepherd release URL or release identifiers and needs to confirm whether a deployment looks correct, analyze what a release will change, compare target-region diffs, inspect release or target logs, identify failing execution targets or release targets, or summarize risks and next steps.
---

# Release Check

Use this skill for read-heavy Shepherd release review, investigation, and release-audit writeups. Default to a release-audit mindset: establish identifiers first, then move from release metadata into target evidence, then escalate into service logs only when Shepherd evidence is insufficient.

## Must Do

- Resolve stable Shepherd identifiers first, then follow `references/workflow.md` for the ordered release evidence pass.
- Fetch release summary, phases, detailed execution targets, and phase-scoped resource changes before concluding scope or risk.
- Choose `Release Review` for scope, diff, rollout-confidence, outlier, and approval questions. Choose `Release Investigation` for failures, stalls, halted phases, first-bad-target analysis, and concrete error evidence.
- Attempt required execution-target plan blobs and carry unavailable blobs as evidence gaps using the rules in `references/workflow.md`.
- Build the target matrix, timeline, scope review, findings, risks, references, and recommendations using `references/reporting.md`.
- In deployment review mode, end with exactly one decision label: `Hold`, `Proceed with regional blocker`, or `Review passes with noted sibling risk`.
- When used inside CM Review, report whether Shepherd plan and resource changes match the CM's commits, implementation steps, targets, validation claims, and rollback claims.
- When reviewing a linked rollback release for CM Review, report whether it matches the rollback purpose, including artifact versions, config hash, target scope, and prior-state baseline, instead of judging whether the rollback release is approval-ready during CM review.
- When used inside CM Review for ONSR or GOV application deployments, include artifact-level SLAPS evidence when Shepherd exposes it and carry missing or ambiguous evidence back as a CM approval gap.
- Escalate to Lumberjack only after Shepherd release metadata, resource changes, target logs, errors, and state no longer answer the question.

## Must Not Do

- Do not rely on release tables, target action counts, compiled config, or artifact lists alone as proof of actual deployed state.
- Do not treat target action counts as sufficient evidence before checking phase-scoped Shepherd resource changes.
- Do not silently downgrade a missing execution-target plan blob to an action-count-only review.
- Do not describe a `Halted` or `Reviewing` release as a partial deployment when the current phase has no approval or start timestamp and all execution targets are still `Reviewing`; classify it as `pre-start`.
- Do not treat normal pre-approval `Reviewing` state as a finding unless it conflicts with the ticket's declared execution state, follows an unresolved earlier-wave blocker, or leaves approval-critical evidence unresolved.
- Do not call a linked rollback release "not approval-ready" merely because it is pre-start, unapproved, or waiting for CM review; call out rollback status only when it blocks rollback-purpose alignment review or conflicts with the ticket execution state.
- Do not treat `cmUrl=null` as a finding for a release that is under review, pre-start, or waiting for CM execution to supply the CM URL; call it out only when the ticket or release state proves the CM URL should already be attached.
- Do not decide CM sufficiency from Shepherd success alone.
- Do not collapse deploy failures and validation failures into one bucket.
- Do not ignore sibling or adjacent rollout-wave blockers when they affect approval confidence for the current phase.
- Do not claim there were no downstream logs when Lumberjack returns `NotAuthorizedOrNotFound`; verify with a known-readable control query and report the visibility boundary.
- Do not widen log searches before exhausting exact Shepherd identifiers from the release, target state, logs, workflow ids, work requests, or downstream request ids.

## Modes

- `Release Review`
  Use when the user wants to understand what a release will change, confirm diffs are expected, review rollout scope during deployment, compare regions or targets, or assess risk before approving next steps.
- `Release Investigation`
  Use when the user wants to know why a release or target failed, stalled, or halted, or when they need an auditable timeline with concrete error evidence.

If the user does not name a mode explicitly, infer it from intent:

- questions like "what will this release change?" or "are these diffs expected?" mean `Release Review`
- questions like "why did this fail?" or "which target broke first?" mean `Release Investigation`
- if the user wants both, do the review path first, then the investigation path for anomalous targets

## Fast Path

1. Parse the release link with `scripts/parse_release_link.py` or the regex in `references/tool-map.md`.
2. Validate the required auth before any Shepherd or Lumberjack reads:
   - check session-backed auth before CLI or direct API calls that read Shepherd or DevOps state
   - check token-backed auth such as `OP_TOKEN` before direct DevOps or log-replay paths
   - if a required session or token is invalid and cannot be refreshed non-interactively, stop and tell the user exactly what to refresh before continuing
3. Fetch the release summary, phase list, and detailed execution-target view.
4. Resolve and record `project`, `flock`, `release_id`, `phase`, `execution_target_id`, `releaseTargetId`, target name, and region for every relevant target.
5. Choose the mode:
   - `Release Review`: focus on expected scope, region diffs, outliers, validations, and rollback posture
   - `Release Investigation`: focus on the first anomalous target, concrete errors, target logs, and halted validations
6. Review evidence in this order:
   - release summary
   - phases
   - execution targets
   - phase-scoped release resource changes
   - execution-target plan blobs
   - plan diff and action counts
   - validations and cached state
   - target errors
   - full target logs
   - Lumberjack escalation when Shepherd is not enough
7. Build a per-target matrix and a timestamped timeline.
8. Write the conclusion using `references/reporting.md`.

## Working Rules

- Prefer exact identifiers from the release before reading logs.
- Validate any required session- or token-based auth before the first Shepherd, DevOps, or Lumberjack read instead of discovering auth failures midway through the review.
- If the workflow needs direct CLI or API access, prefer the shared `python3 skills/codex-bootstrap/scripts/refresh_auth.py oci-session ...` helper for OCI session validation or repair.
- If `OP_TOKEN` or another required token is invalid and cannot be refreshed automatically, stop and report the auth blocker instead of treating empty or unauthorized results as release evidence.
- Use absolute timestamps like `2026-04-01T16:47:57Z` in the final report.
- If a release is `Halted` or `Reviewing` but the current phase has no approval or start timestamp and all execution targets are still `Reviewing`, classify it as `pre-start`; do not describe it as a partial deployment.
- In `Release Review`, normal pre-approval `Reviewing` state is context, not a finding. Escalate it only when it conflicts with the ticket's declared execution state, follows an unresolved earlier-wave blocker, or leaves approval-critical evidence unresolved.
- In `Release Review`, compare expected scope against observed target behavior before assuming a diff is safe.
- In both `Release Review` and `Release Investigation`, check release resource changes by phase with Shepherd before treating target action counts as sufficient evidence.
- For every release under review, fetch or explicitly attempt the deeper execution-target plan blob for every relevant execution target after exact `phase` and `execution_target_id` values are known. Action counts are not a substitute for this attempt.
- If a required execution-target plan blob is unavailable because of auth, API, retention, or tool limits, record the target, reason, and fallback evidence used. Treat that as an evidence gap in the final recommendation instead of silently downgrading to action counts.
- When Release Check is used inside a CM review, report whether the Shepherd plan/resource changes match the CM's stated commits, implementation steps, targets, and validation or rollback claims. Do not decide CM sufficiency from Shepherd success alone.
- When Release Check is used inside a CM review, treat `cmUrl=null` as expected for pre-start or under-review releases waiting for CM execution to attach the URL. Report it only when the ticket is already implementing, completed, post-approval, or release state proves the CM URL should already exist.
- When approval depends on an earlier rollout wave, inspect adjacent or sibling releases in the same flock and release family before recommending approval for the current phase.
- In deployment review mode, always end with one explicit decision label:
  - `Hold`
  - `Proceed with regional blocker`
  - `Review passes with noted sibling risk`
- Separate deploy failures from validation failures. Many halted releases successfully deploy artifacts and only fail in later exec or canary steps.
- Treat compiled config and artifacts as intended scope, not proof of actual deployed state. Use execution-target state when the question is "what is running now?"
- For target-log review, use the first terminal error as the RCA anchor, but do not stop there. Continue through the remaining raw log to capture milestone progress, retries, cleanup or rollback behavior, wrapper errors, and secondary warnings that change the investigation or approval posture.
- When resource-level plan blobs are unavailable after the required attempt, still produce a region diff matrix using target action counts, artifact or version changes, validation posture, and target-specific errors, and label the plan-blob gap clearly.
- Call out outlier regions or targets explicitly when one target's actions, versions, validations, or errors differ from the rest of the release.
- If the user is reviewing a deployment, include potential blast radius, rollback implications, validation coverage or bake-period gaps, and evidence gaps that could affect approval.
- If downstream Lumberjack queries return `NotAuthorizedOrNotFound`, verify the path with a known-readable control query. If the control succeeds, report a log-visibility boundary and keep conclusions anchored to Shepherd evidence instead of claiming there were no downstream logs.
- Escalate to Lumberjack only after Shepherd logs, errors, and target state stop answering the question.

## Read Next

- `references/tool-map.md`
  Read first for URL parsing, identifier resolution, and the Shepherd or Lumberjack tool map.
- `references/workflow.md`
  Read for the ordered investigation flow, diff strategy, log analysis, validation checks, and timeline construction.
- `references/reporting.md`
  Read before writing the final summary so findings, risks, timeline, references, and recommendations stay consistent.
