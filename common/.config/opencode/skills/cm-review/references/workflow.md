# Release-Backed Review Workflow

Use this workflow when the CM is `release-backed` or `hybrid`.

## 1. Repository Version Preflight

Before reading CM evidence, use `repository-version-preflight` with `../SKILL.md` as the caller.

- Do not restate or override the configured source, raw-file read method, comparison rule, or warning-only behavior here.
- Carry the preflight status into the final review and any Jira writeback.

## 2. Intake The Ticket

- Read the ticket body and structured fields.
- Ignore comments unless the user explicitly asks to include them.
- Extract only the intake evidence listed in `checklist.md`.
- Resolve intended CM locations from structured fields by checking `Change Location(s)` first. If it is absent or empty, inspect other populated fields whose names contain location, region, or realm before falling back to labels, title text, or prose.
- Discover release links across all ticket-owned surfaces. First sweep structured, named, custom, and Implementation-tab fields whose names contain release, plan, rollback, test, validation, implementation, or deployment; record each field name even when the value is empty or unresolved. Then inspect the deployment or implementation plan, ticket description, validation or test results, HERDS/non-prod evidence, and rollback plan. Preserve source field or section and nearby labels for classification.
- Do not fetch remote Shepherd release details, remote commit diffs, runbooks, SLAPS results, logs, or execution artifacts before the human approval pause unless the user explicitly asks for unattended automation.

## 3. Classify Release Links

Classify every discovered Shepherd release link before deciding which links define CM execution scope.

- `prod execution release`
  Use for links labeled `Prod release link`, `Release`, production release, deployment release, or equivalent production-forward context. After approval, confirm Shepherd metadata is `RollForward`, artifact/version matches the CM, and target regions match `Change Location(s)`.
- `plan-only release`
  Use for links labeled `Plan only release Link`, `Plan only release`, or Shepherd metadata `PlanOnly`. These provide expected plan/resource-diff evidence, not execution evidence.
- `non-prod test release`
  Use for links labeled `Non-Prod Test Release Link`, HERDS, R1/OC16 bake, validation, test results, or non-prod context. These support validation evidence and do not define production CM scope unless the CM explicitly says they are the production execution release.
- `rollback-test evidence release`
  Use for rollback links under Test Results, validation, HERDS, non-prod context, or CM `Rollback release Link` fields whose surrounding text says the release was used to test rollback for the artifacts planned for deployment.
- `actual rollback release`
  Use for rollback links, including CM `Rollback release Link` fields, whose surrounding text says the release would be executed in production if rollback is needed. Review actual rollback execution evidence against artifact versions, config hash, target scope, and prior known-good baseline.
- `dual-purpose rollback release`
  Use when the CM clearly uses the same rollback release link for both rollback testing and production rollback execution. Apply both rollback-test evidence checks and actual rollback execution checks.
- `ambiguous release link`
  Use when the label or section does not identify purpose. After approval, use Shepherd metadata and target/artifact context to classify it. Carry ambiguity as a reviewability gap when the CM still does not make the purpose clear.

If a release link's section context, CM prose, and Shepherd metadata conflict, report the conflict instead of silently reclassifying it. Example: a `Rollback release Link` with `RollBack` metadata may be rollback-test evidence, actual rollback execution, or both; choose the classification only when the CM context supports it, otherwise carry it as ambiguous.

## 4. Present The Review Plan

- Summarize the release-backed evidence you plan to inspect before gathering it broadly.
- State:
  - the linked releases you expect to review
  - the release-link classification you inferred from structured fields, Implementation tab labels, description sections, test results, and rollback sections
  - the CM's intended change locations, such as realms, regions, ADs, phases, stages, execution targets, release targets, and explicit exclusions
  - whether any linked release appears to be shared across multiple CMs, and which target slice this CM appears to cover
  - whether you expect `Release Review` only or likely `Release Investigation`
  - the commit sources you found in the CM, such as Bitbucket compare links, SCM links, commit tables, or explicit hashes
  - whether the CM has both release evidence and diff information, which triggers the commit-diff validation matrix rule in `SKILL.md`
  - that commit diffs will be fetched from Bitbucket or SCM evidence paths before using any local checkout fallback
  - which validation and rollback claims in the CM you intend to verify
  - whether the CM appears executable by an operator with no service context
  - whether listed commits appear to have matching validation coverage
  - any obvious ambiguity or risk areas from intake alone
- In human-driven reviews, stop after presenting this plan and wait for explicit user approval.
- In unattended automation, continue without pausing.

## 5. Collect Commit Candidates

Use this step for `release-backed` or `hybrid` CMs when release evidence plus Bitbucket compare links, SCM links, PR links, commit tables, explicit commit hashes, or artifact-version evidence point to code changes.

For pure `runbook-backed` CMs, commit-diff validation is optional/manual. Do it only when the user asks for commit validation or when the runbook-backed change also includes a release, artifact, repo, or config delta that makes code evidence part of the CM scope.

Before Release Check output is available, collect candidate commit evidence only. Do not make final in-scope, compare-only, validation-gap, or coverage decisions until the linked release evidence has established the current CM release delta.

1. Extract commit sources from the CM:
   - Bitbucket compare URLs and their source or target hashes
   - SCM PR links or repository identifiers
   - CM-generated commit tables
   - explicit commit hashes in description, implementation, test results, or release details
   - artifact version deltas that imply a commit range
2. Fetch candidate commit metadata from the remote source:
   - use `bitbucket-pr` for Bitbucket compare, commit, and PR evidence
   - use `scm-pr` for OCI DevOps SCM PR or repository evidence
   - avoid local repository lookup as the default source when remote links are present
   - if remote evidence is unavailable and a local checkout is used as fallback, label the fallback and do not present it as Bitbucket or SCM readback
3. When useful for later classification, fetch candidate changed files or patch summaries from the remote source, but keep them as candidate evidence until Release Check establishes the release delta.

## 6. Correlate The Linked Releases

For each linked Shepherd release:

- Run the `Release Review` process from `Release Check` first. This is the canonical release-verification path for CM review.
- Do not re-implement the Shepherd evidence walk here. Use the Release Check workflow to supply release scope, status, validation state, rollback posture, artifact details, SLAPS results from the live call, and any required plan or state details.
- Record the Release Check output needed for CM judgment:
  - release-link classification and source section, such as prod execution, plan-only, non-prod test, rollback-test evidence, actual rollback execution, dual-purpose rollback, or ambiguous
  - release id and phase or target scope
  - the phase, stage, regions, realms, execution targets, and release targets that match the CM's stated change locations
  - any extra regions, realms, phases, stages, or targets that appear to belong to a different CM or remain separately gated context
  - release `status` and `currentPhaseStatus` when relevant to CM state alignment
  - `Release Check` decision label
  - blockers, outliers, validation gaps, rollback concerns, and unresolved evidence gaps
  - artifact findings and SLAPS results from the live call that affect CM approval confidence; SLAPS applies only to application artifacts deployed to ONSR/GOV realms
  - coverage status or blocker for that linked release

If `Release Review` shows failed, halted, blocked, or anomalous phases or targets, extend that same release with `Release Investigation` before concluding CM risk.

Compare those results to the ticket's declared release details, scope, and implementation narrative. For a shared all-region or all-realm release, do not compare the CM against the entire release inventory as if this CM authorized every target. First identify the CM-authorized target slice, then compare only that slice for scope and status drift while carrying the broader release inventory as shared-release context.

The CM should explicitly say when it uses a shared release with multiple CM records and should name the exact phase, stage, targets, regions, or realms this CM covers. If that mapping is missing or ambiguous, treat it as a CM reviewability and traceability gap. Escalate it to scope drift only when this CM can approve, start, or has already executed targets outside its stated locations without a separate clear gate.

Before producing findings, enumerate every linked release and verify it has a Release Check result or an explicit blocker. If any linked release is inaccessible or lacks Release Check coverage, the review is incomplete and the final answer must say which release was not reviewed and why.

If ONSR or GOV application artifacts are in scope, apply the SLAPS acceptance gate in `checklist.md` after release correlation identifies the exact artifact versions.

## 7. Fold Release Check Output Into CM Risk

- Use Release Check's common-diff, outlier, blocker, validation-gap, and decision-label output instead of rebuilding those calculations inside CM Review.
- For shared releases, fold risk back to the CM-authorized target slice. Extra targets in the same release are not drift by themselves when they are outside this CM's stated locations and remain under review, pre-start, or separately gated by other CM records.
- Treat matched CM locations as expected pre-approval context when their release status is under review or pre-start, such as `Reviewing / Reviewing`, unless the CM says execution has already started or the target evidence shows failure, blocked planning, apply, validation, or policy state.
- Do not require `cmUrl` as part of pre-review. Carry `cmUrl=null` only as a traceability issue when the release has started, the CM is already implementing or completed, or target state proves the CM URL should already be attached.
- When Release Check reports action-count differences, preserve its topology judgment. Treat expected 3-AD versus 1-AD multiplicity for AD-scoped resources as an explanation, not a CM drift finding, when the per-AD pattern, resource families, artifact versions, and regional or global resources still match the CM intent.
- Escalate the difference as CM risk when Release Check shows unexpected regional or global resources, mismatched resource families, deletes, replacements, artifact or version drift, validation differences, or target-specific errors.
- Carry canary and bake-period cadence mismatches from Release Check into CM risk. If the CM claims canary validation but the stage, region, or realm promotion window is shorter than the canary cadence and no completed post-deploy canary or alternate changed-surface validation exists before promotion, report it as a CM validation gap.
- Explain why each relevant Release Check risk matters for the CM's implementation, validation, rollback, or approval decision.
- If Release Check evidence is blocked, carry the exact blocker into the CM review rather than silently downgrading the review to ticket-only evidence.

## 8. Build The Commit-Diff Validation Matrix

Build the matrix after linked release correlation so the current CM release delta can be derived from Release Check evidence plus ticket scope. Follow the canonical commit-diff validation matrix rule from `SKILL.md`.

1. Resolve the current CM release delta from Release Check output, ticket scope, artifact or config versions, rollback target scope, and runbook or provider repo scope when relevant.
2. Treat Bitbucket or SCM compare ranges as candidate sources, not authoritative deployment scope, when narrower release evidence identifies the actual CM delta.
3. Classify candidate commits as in-scope, supporting evidence only, compare-only/out of scope, or blocked.
4. For in-scope or blocked commits, ensure remote changed-file and patch-summary evidence is available, or record the remote-evidence blocker.
5. Use `checklist.md` for the matrix fields, validation relevance classes, required evidence, outcome labels, excluded-commit notes, and finding criteria.
6. If both broad compare evidence and narrower release evidence are present, report the mismatch and explain which evidence defines the CM release delta.

## 9. Review Rollback Against The Real Change

- For application releases, verify rollback artifact versions correspond to the currently deployed versions that would need restoration.
- For infrastructure releases, confirm the rollback path identifies the prior known-good config, release, or state for the affected phase or region.
- For CM `Rollback release Link` fields and other rollback links, first classify the purpose from field label, source section, surrounding CM prose, and Shepherd metadata.
- If the link is rollback-test evidence, review whether rollback testing covered the artifacts planned for deployment.
- If the link is actual production rollback execution evidence, review whether it would restore the expected prior-good artifact, config, target scope, or state.
- If the same link is dual-purpose, perform both reviews. If the purpose remains ambiguous, report a rollback reviewability gap rather than assuming either meaning.
- Use the `Accepted Shepherd Status For CM Review` section in `../SKILL.md` before turning rollback release state into a finding.
- Challenge rollback plans that only say to "roll forward with caution" unless they also identify the exact safe restoration target.

## 10. Produce The Review

Return findings first, ordered by severity.

Use `checklist.md` to verify final coverage for description, implementation, validation, rollback, linked releases, scoped SLAPS results from the live call, commit or version verification, operator executability, positive verification, and residual risk.

## CM-Purpose Review Anchors

For release-backed CMs, fold the release evidence back into the broader CM purpose. The ticket should be the single operational source of truth for an executor, approver, incident responder, or auditor. These anchors intentionally cover the CM quality expectations from [CM Writeup](https://confluence.oraclecorp.com/confluence/display/~mead/CM+Writeup).

Check whether the CM:

- explains what is changing and why
- says when the change is allowed to run, including freeze or holiday exceptions when relevant
- gives implementation steps that an operator with no service context can execute
- maps every listed commit or major change to an automated or manual validation method
- maps every remotely fetched commit diff to the required automated or manual validation evidence
- uses Release Check evidence to prove the Shepherd scope matches the commit list and implementation narrative
- explains when a linked release is shared across multiple CMs and maps this CM to the exact covered phase, stage, targets, regions, or realms
- avoids relying on canaries alone unless canary coverage, cadence, post-deploy completion, and review-before-promotion prove the full changed surface
- does not claim a short inter-stage bake, such as 2 hours, is canary-validated by a longer canary cadence, such as 8 hours, unless an on-demand or completed post-deploy canary result exists before the next stage, region, or realm starts
- gives manual validation with exact commands, pages, inputs, expected outputs, pass or fail criteria, and evidence-capture location
- gives rollback steps for each major implementation section, normally in reverse order, including any intermediate changes intentionally left in place
- tells the executor what evidence to add while running the CM: inputs, outputs, screenshots, logs, release links, dashboard links, validation results, and ticket updates

## CM Writeup Traceability Map

This map is documentation-only. It explains how existing CM Review checks align to [CM Writeup](https://confluence.oraclecorp.com/confluence/display/~mead/CM+Writeup) and does not add new review requirements.

| CM Writeup point | Skill coverage |
| --- | --- |
| CM is the single place to understand what changes, why, when it can run, validation, and recovery | `SKILL.md` > opening review contract; `references/checklist.md` > `Description Checks`; this file > `CM-Purpose Review Anchors` |
| Operator with no service context can execute and validate, including delegated restricted-realm execution | this file > `Present The Review Plan`; `references/checklist.md` > `Description Checks` and `Implementation Checks` |
| Every listed code commit has automated or manual validation | this file > `Collect Commit Candidates` and `Build The Commit-Diff Validation Matrix`; `references/checklist.md` > `Validation Checks` and `Commit And Version Checks`; `references/commit-matrix.md` > `Matrix Record` |
| Shepherd release plan reflects the same changes as the commit list and implementation steps | `SKILL.md` > `Must Do` Release Check handoff; this file > `Correlate The Linked Releases`, `Fold Release Check Output Into CM Risk`, and `Build The Commit-Diff Validation Matrix`; `references/checklist.md` > `Description Checks` |
| Canaries alone are not complete validation unless full-surface coverage, cadence, bake, and result review are shown | `references/checklist.md` > `Validation Checks`; this file > `CM-Purpose Review Anchors` |
| Manual validation includes exact commands, pages, inputs, expected outputs, pass/fail criteria, and evidence location | `references/checklist.md` > `Validation Checks`; this file > `CM-Purpose Review Anchors` |
| Rollback is explicit and normally reverses implementation sections in order | this file > `Review Rollback Against The Real Change`; `references/checklist.md` > `Rollback Checks` |
| Avoid freezes, Fridays, weekends, holidays, and pre-holiday execution without extra approval and justification | `references/checklist.md` > `Timing And Execution Evidence Checks`; this file > `CM-Purpose Review Anchors` |
| Executor records inputs, outputs, screenshots, logs, release links, dashboard links, and step evidence during execution | `references/checklist.md` > `Broad Evidence After Approval` and `Timing And Execution Evidence Checks`; this file > `CM-Purpose Review Anchors` |
