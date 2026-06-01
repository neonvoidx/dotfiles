---
name: cm-review
description: Review change-management tickets such as Jira CHANGE or CM requests for deployment readiness, scope drift, documentation quality, and runbook adherence. Use when Codex needs to assess implementation steps, validation evidence, rollback clarity, Shepherd release scope and plan diffs, regional outliers, manual data-fix or host-maintenance procedures, team-specific runbook alignment, and commit or artifact-version alignment, and optionally write findings back to the ticket.
---

# CM Review

Current skill version: `1.5.0`.

This is the source of truth for the CM Review skill version. A change to any file under `skills/cm-review/` is incomplete unless this version is incremented in the same change. Use semantic versioning: patch for wording, minor for workflow or writeback behavior changes, and major for intentionally incompatible review-contract changes.

Use this skill for peer review of change tickets before or during execution. Treat the CM as the single operational source of truth for the change: what is changing, why it is changing, when it can run, how success is proven, and how recovery works.

Ignore ticket comments by default. Only read or reference comments when the user explicitly asks to include them.

For human-driven reviews, present a concise pre-execution review plan after ticket intake and wait for explicit approval before broad evidence gathering. In unattended automation, derive and follow the same plan internally without pausing.

## Review Modes

- `release-backed`
  Use when the CM is primarily implemented through linked Shepherd releases.
- `runbook-backed`
  Use when the CM is primarily a manual or service-operator procedure, such as a data fix, host restart, host replacement, host reprovision, or maintenance step.
- `hybrid`
  Use when the CM combines manual operator steps with a release-backed change.

## Must Do

- Read only intake evidence from the ticket body and structured fields before planning the review. Use `references/checklist.md` to keep the intake-vs-broad-evidence boundary clear.
- When extracting CM target locations from Jira structured fields, prefer the exact field `Change Location(s)`. Treat `Change Location`, `Location`, `Region`, `Realm`, labels, title text, and prose as fallback or supporting signals only. Before reporting a missing structured location, inspect all field names containing location, region, or realm and prefer the populated CM-specific field.
- Discover Shepherd release links from every ticket-owned release surface before classifying release coverage. First sweep all structured, named, custom, and Implementation-tab fields whose names contain release, plan, rollback, test, validation, implementation, or deployment; then inspect the deployment or implementation plan, ticket description, validation or test results, and rollback plan. Preserve each link's source field or section and nearby label, such as `Non-Prod Test Release Link`, `Plan only release Link`, `Rollback release Link`, or `Prod release link`.
- Classify rollback-related links by source and purpose. Because teams use the CM `Rollback release Link` field inconsistently, do not assign it a single default meaning. It can be rollback-test evidence, the production rollback execution release, or both. Use the field label, source section, surrounding CM prose, and Shepherd metadata to classify the link, and carry an ambiguity finding when the CM does not make the intended purpose clear enough to review.
- Classify the review mode in the review plan.
- Check CHANGE process hygiene from visible ticket fields, including clone indicators, template leftovers, automation rejection state, or missing required CM template fields.
- For runbook-backed or other manual CMs, require a ticket section titled `Why this manual change is required?`. If it is missing, empty, or only repeats generic business justification, treat it as a manual-CM reviewability finding and include a request for that exact section whenever writing back to Jira.
- After approval, collect broad evidence from the relevant reference workflows.
- Treat CM prose, structured fields, explicitly included comments, and release tables as claims to verify, not proof.
- Use `Release Check` as the canonical Shepherd-analysis workflow for every linked release. Start with `Release Review`; extend into `Release Investigation` only for anomalous releases or targets.
- If a linked release cannot be accessed or Release Check is otherwise blocked, call out that release and the exact blocker in the final review summary.
- When a linked release is shared across multiple CMs, compare the CM against the phase, stage, regions, realms, and execution targets that are approvable under this CM, not against the entire shared release inventory. Require the CM to explain that the release is shared and to identify exactly which phase, targets, regions, or realms this CM covers.
- When folding Release Check resource-diff evidence into CM risk, distinguish real drift from topology-normalized action counts. A 3-AD region can legitimately have more actions than a 1-AD region for AD-scoped resources when the resource pattern, resource families, artifact versions, and regional or global resources still match the CM intent.
- For ONSR or GOV application deployments only, fetch the artifact-level SLAPS approval result from the live SLAPS call after the approval pause and before treating the CM as approval-ready. ONSR/GOV scope means `OC5`, `OC6`, `OC11`, `OC2`, `OC3`, `OC4`, or `OC23`; do not require SLAPS for other realms or non-application/non-artifact changes. In CM Review, SLAPS is always from the live call; CM-attached screenshots, release prose, or copied scan output are supporting context only.
- For runbook-backed or hybrid changes, identify the likely service and runbook source before approval, but do not fetch or select runbooks until after approval.
- For `release-backed` or `hybrid` CMs with release evidence plus Bitbucket/SCM diff information, commit tables, PR links, or explicit commit hashes, follow `references/workflow.md` for matrix timing and `references/commit-matrix.md` for matrix details.
- Return findings first, ordered by severity, followed by positive verification and residual risk.
- Keep ticket writeback opt-in. Jira writeback must use Jira wiki markup, the required `[codex-gpt-5.5]` prefix, and the active CM Review skill version.

## Must Not Do

- Do not read or reference ticket comments by default.
- Do not skip the plan-first approval pause for human-driven reviews.
- Do not fetch remote Shepherd details, remote commit diffs, runbooks, SLAPS results, logs, or execution artifacts before approval unless the user explicitly asks for unattended automation.
- Do not claim full linked-release coverage unless every linked release has a Release Check result, or inaccessible release evidence is explicitly reported as blocked in the final review summary.
- Do not confuse validation-only release links with execution releases. Non-prod, HERDS, test-result, or rollback-test releases support validation evidence; they do not define production CM scope unless the CM explicitly identifies them as the production execution release. Do not assume the CM `Rollback release Link` field is validation-only or execution-only; classify it from the CM context and call out ambiguity when the purpose is unclear.
- Do not treat extra regions, realms, phases, or targets in a shared release as CM scope drift by themselves when they are outside the current CM's stated target slice and are gated by separate CM records or are still pre-start.
- Do not treat raw action-count differences between 3-AD and 1-AD regions as CM scope drift until the Release Check evidence shows the difference is not explained by AD-scoped resource multiplicity.
- Do not label CM-provided screenshots, release text, copied scan output, or `latestApprovedVersion` as SLAPS or treat them as a proxy for current SLAPS compliance, and do not collapse mixed SLAPS states into a single pass.
- Do not force release-review logic onto manual, operational, data-fix, host, or maintenance CMs when a runbook-backed review is required.
- Do not use a local repository checkout as the default source for CM commit diffs when the CM provides Bitbucket or SCM links. Use remote PR or compare evidence first; label any local-checkout fallback as a limitation.
- Do not require CM validation evidence for compare-only commits that are outside the current CM release delta.
- Do not post comments or update the ticket unless the user explicitly asks for writeback.

## Accepted Shepherd Status For CM Review

Accepted status here means normal CM-review context, not proof that the release is approved, started, or safe by itself. Always report Shepherd state as the exact `release.status / currentPhaseStatus` pair.

Forward release links are normal pre-approval context when the CM itself is not post-approval, implementing, or completed, including `Halted / Reviewing`, `Reviewing / Reviewing`, or other pre-start review pairs where the phase has no approval/start evidence and checked execution targets remain `Reviewing`. For shared releases, this normal status interpretation applies to the phase, stage, regions, realms, and execution targets mapped to the current CM, not necessarily to every target in the release. Treat status as a finding when the pair or target evidence shows planning, apply, validation, or execution failure; conflicts with the CM execution state; starts, approves, or completes targets outside the current CM scope without a separate clear gate; or materially reduces approval confidence.

Do not require `cmUrl` during pre-review. Missing `cmUrl` is expected when a release or target is still under review, pre-start, or waiting for CM execution to attach the CM URL. Treat missing or mismatched `cmUrl` as a finding only when the CM is already implementing, completed, post-approval, or release state proves the CM URL should already be attached.

Rollback-linked release status must be interpreted by classified purpose. For rollback-test evidence, status is a finding when it blocks judging whether rollback testing covered the artifacts planned for deployment, conflicts with the CM validation claim, points to the wrong artifact or target, or shows rollback-test execution failure. For a production rollback execution release, unapproved, pre-start, halted-before-start, or `cmUrl=null` states are normal review context before rollback is needed; status is a finding when it blocks judging rollback-purpose alignment, conflicts with the CM execution state, points to the wrong artifact/config/target/prior-good baseline, shows execution failure, or would not restore the state claimed by the CM. For a dual-purpose rollback link, apply both sets of checks.

## Fast Path

1. Read the ticket body and structured fields only.
2. Extract only the intake evidence listed in `references/checklist.md`.
3. Determine and state the review mode.
4. Present the review plan with evidence sources, validation questions, rollback questions, and obvious ambiguities.
5. For human-driven reviews, pause for approval before broad evidence gathering.
6. After approval, run the relevant workflows:
   - linked Shepherd release: `Release Check`, then fold output through `references/workflow.md`
   - runbook-backed or hybrid: `references/change-classes.md`, `references/runbook-workflow.md`, and `references/configuration.md`
   - release-backed or hybrid with release-plus-diff evidence: commit matrix timing in `references/workflow.md`, details in `references/commit-matrix.md`
7. If the user asks to post findings back to the ticket, read `references/writeback.md` first.

## References

- `references/checklist.md`
  Evidence boundary and acceptance checks for description, implementation, validation, rollback, and commit/version verification.
- `references/workflow.md`
  Release-backed review, Release Check handoff, and commit-diff validation matrix.
- `references/commit-matrix.md`
  Commit-diff validation matrix fields, labels, evidence specificity, and finding rules.
- `references/change-classes.md`
  Manual or ambiguous CM class selection.
- `references/runbook-workflow.md`
  Runbook-backed evidence resolution and normalized runbook checks.
- `references/configuration.md`
  Team/runbook config schema and pre-approval vs post-approval runbook handling.
- `skills/release-check/SKILL.md`
  Required sub-workflow whenever the ticket includes Shepherd release links.
- `references/writeback.md`
  Jira-only writeback format, prefix, and active-version requirement.
