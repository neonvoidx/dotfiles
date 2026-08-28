# CM Review Checklist

## Intake Evidence Before Plan

- Ticket summary
- Description
- `Business Justification`
- Deployment or implementation plan
- Validation actions
- Rollback plan
- Test results
- Structured release-link fields
- A structured field sweep for release evidence: inspect all structured, named, custom, and Implementation-tab fields whose names contain release, plan, rollback, test, validation, implementation, or deployment before relying on description prose
- Implementation tab or implementation-field release links, including labels such as `Non-Prod Test Release Link`, `Plan only release Link`, `Rollback release Link`, and `Prod release link`
- Release links in the ticket description, validation actions, test results, HERDS/non-prod evidence, deployment plan, and rollback plan
- Release-link source context for every discovered link, including the field or section name and nearby label used to classify the link
- Labels or scope tags
- Team or service identity signals, such as labels, components, or repo links
- Exact target identifiers, such as hosts, pools, tenancy OCIDs, subscriptions, realms, regions, or API resources
- Change locations the CM intends to authorize, such as realms, regions, ADs, phases, stages, execution targets, release targets, and explicit exclusions
- Jira structured location fields, preferring `Change Location(s)` as the authoritative CM location field when present. Use `Change Location`, `Location`, `Region`, `Realm`, labels, title text, and prose only as fallback or supporting scope signals. Do not report a missing structured location until all field names containing location, region, or realm have been checked.
- Explicit approval gates, prerequisites, and abort conditions when the CM is manual or operational
- The `Why this manual change is required?` section when the CM is manual, runbook-backed, or operational
- Code-change section, commit hashes, commit tables, Bitbucket compare links, SCM links, or PR links
- Runbook references named directly in the ticket
- CHANGE process hygiene signals visible in the ticket body or structured fields, such as clone indicators, template leftovers, automation rejection state, or missing required CM template fields

Use only this intake set before the human review-plan approval pause. Intake evidence is enough to classify the review mode, identify likely evidence sources, and state the questions to verify. Do not fetch remote Shepherd details, remote commit diffs, runbooks, SLAPS results, logs, or execution artifacts before approval unless the user explicitly asks for unattended automation.

## Broad Evidence After Approval

- Execution update expectations, such as where the executor will record inputs, outputs, screenshots, logs, release links, dashboard links, and other evidence during the change
- Runbook source and selected runbook when the ticket is runbook-backed or hybrid
- Explicit note when a manual CM has no existing runbook covering the process
- Current CM release delta, derived from artifact names and versions, flock/config hashes, linked Shepherd release artifacts, release resource changes, implementation targets, and rollback targets
- Current CM release target slice for shared releases, mapping the CM's intended locations to the matching Shepherd phases, stages, regions, realms, execution targets, and release targets
- Candidate commit source list when the commit-diff validation matrix is required or manually requested
- Candidate commit scope decision for broad compare ranges when the commit-diff validation matrix is required or manually requested, including which commits are in the current CM release delta and which are compare-only or out of scope
- Remote commit metadata when the commit-diff validation matrix is required or manually requested, including commit id, title, PR id when available, author, and date
- Changed files and patch diff summary when the commit-diff validation matrix is required or manually requested, fetched through `bitbucket-pr` or `scm-pr` rather than a local repository checkout when the CM provides remote links
- Per-commit validation mapping when the commit-diff validation matrix is required or manually requested
- Per-commit validation relevance classification when the commit-diff validation matrix is required or manually requested, such as deployment-affecting, config-only, security-affecting, dependency-affecting, validation-only test change, docs-only, or tooling-only
- Commit-diff validation matrix analysis status when required or manually requested, following the canonical rule in `SKILL.md`
- Artifact version table or flock config hashes
- Per-artifact SLAPS approval result from the live SLAPS call when application artifacts are deployed to ONSR realms `OC5`, `OC6`, or `OC11`, or GOV realms `OC2`, `OC3`, `OC4`, or `OC23`; SLAPS is always from the live call, while CM-attached screenshots, release prose, `latestApprovedVersion`, or copied scan output are supporting context only
- `Release Check` output for each linked Shepherd release
- A Release Check coverage note for every linked Shepherd release, including release id, decision label, important blockers or evidence gaps, rollback concerns, and any auth or visibility boundary
- A release-link classification table or summary that separates production execution releases, plan-only releases, non-prod or test releases, rollback-test evidence releases, actual rollback execution releases, dual-purpose rollback releases, and ambiguous release links

## Description Checks

- Confirm the CM is usable as the single operational source of truth: what changes, why it changes, when it can run, how success is proven, and how recovery works.
- Confirm an operator with no service context could follow the CM without hidden tribal knowledge, especially for changes that may run in restricted realms or through delegated operators.
- For manual, runbook-backed, or operational CMs, confirm the ticket includes a section titled exactly `Why this manual change is required?` and that it explains the need for a manual change beyond generic business justification.
- Confirm the documented change type matches the linked release change type.
- Confirm the documented scope matches the linked release scope, labels, and execution targets.
- Confirm the populated `Change Location(s)` values, when present, match the linked release phases, stages, regions, realms, and execution targets before using any fallback location field.
- If a linked release is shared across multiple CMs, confirm the CM says so and identifies the exact phase, stage, regions, realms, execution targets, or release targets this CM covers.
- For shared releases, compare the CM to the matching target slice rather than the entire release inventory. Treat extra release targets as context when they are outside this CM's stated scope and remain separately gated or pre-start.
- Confirm Release Check evidence reflects the same changes described by the CM commit list and implementation steps.
- When Release Check shows different action counts across regions, confirm whether the difference is explained by 3-AD versus 1-AD topology for AD-scoped resources before treating it as scope drift.
- For runbook-backed changes, confirm the documented scope matches the selected runbook's intended procedure and target type.
- For manual changes with no runbook, call out the absence of an existing runbook as a process and validation risk.
- Confirm each linked release has a Release Check result or an explicit final-summary blocker before claiming linked-release coverage.
- Confirm Release Check decision labels, blockers, outliers, rollback concerns, validation gaps, and unresolved evidence gaps are carried into CM findings when they affect approval confidence.
- Note missing or misleading release links, scope tags, phases, runbook references, or version details.
- Confirm release links are classified from source section, field label, surrounding CM prose, and Shepherd metadata. Treat `PlanOnly` metadata as plan evidence, `RollForward` metadata in prod context as forward execution evidence, and non-prod/test-result context as validation evidence unless the CM explicitly says otherwise. Because `Rollback release Link` usage is not consistent across teams, classify it as rollback-test evidence, actual rollback execution evidence, dual-purpose rollback evidence, or ambiguous based on the CM context; do not assume a single default meaning from the field name alone.
- Check CHANGE process hygiene before treating the ticket as approvable. The official OCI Change Management process prohibits cloned CHANGE tickets because key fields, workflows, and guardrails can be omitted; cloned-ticket indicators, auto-reject state, unresolved template leftovers, or missing required CM template fields should be called out as process hygiene risk.

## Implementation Checks

- Confirm the steps are executable, ordered, and match the documented change.
- Confirm the steps identify exact inputs, release links, phases, targets, realms, regions, commands, pages, and expected operator decisions when those are needed.
- Call out template leftovers such as `TODO`, placeholder text, or generic instructions that do not fit the ticket.
- Check whether the documented execution flow matches the actual release type and scope.
- For each linked release, confirm the release phase, stage, regions, realms, and execution targets that match the CM's intended change locations are in a status consistent with CM review, such as under review or pre-start, unless the CM is already approved or executing.
- Do not require `cmUrl` for under-review or pre-start releases. Note `cmUrl` only as a traceability finding when the CM is already implementing, completed, post-approval, or release state proves the CM URL should already be attached.
- For runbook-backed changes, confirm the implementation sequence matches the selected runbook's prerequisites, target handling, and execution order.
- For host actions, require exact hostname, pool, region, or AD scope when the runbook expects them.
- For data fixes, require exact resource identifiers and bounded mutation steps when the runbook expects them.
- When reporting linked Shepherd release status, include both release `status` and `currentPhaseStatus`; use the `Accepted Shepherd Status For CM Review` section in `../SKILL.md` to interpret forward and rollback release-link status.
- Note traceability gaps when the release metadata does not carry the CM URL or status alignment expected by the ticket, but do not flag `cmUrl=null` for releases still under review, pre-start, or waiting for CM execution to provide the CM URL.

## Validation Checks

- Confirm the validation section covers the actual deployed scope.
- For shared releases, validate only the target slice covered by this CM, and carry unclear target-to-CM mapping as a reviewability finding instead of assuming the whole release is authorized by this CM.
- Confirm every listed commit or major change has a corresponding automated or manual validation method.
- Confirm required remote commit evidence was collected through the Bitbucket or SCM evidence path when the commit-diff matrix is required.
- Confirm the current CM release delta is derived from artifact versions, config hashes, linked Shepherd release artifacts, release resource changes, implementation targets, and rollback targets before judging validation coverage.
- Confirm candidate commits are classified as in-scope, supporting evidence only, compare-only/out of scope, or blocked before judging validation coverage.
- Confirm each in-scope diff is classified by deployed-behavior or rollout-risk impact. Runtime code, API/spec behavior, config, Terraform, policy, security, dependency, logging, artifact, Shepherd, and rollback changes require CM validation evidence. Test-only, docs-only, generated validation-output-only, or developer-tooling-only changes usually do not require separate CM validation; record the rationale instead of creating a validation gap.
- Infer required validation from deployment-affecting changed files and patch intent, such as API/resource tests, model converter tests, DAL store/converter tests, worker workflow tests, spec validation output, Shepherd or Terraform plan evidence, security tests, log-redaction checks, SLAPS results from the live call when SLAPS applies, canaries, alarms, or manual validation steps.
- Compare each deployment-affecting inferred validation requirement with the CM validation actions, test results, Shepherd validation evidence, HERDS or pre-prod evidence, and release evidence.
- Count generic HERDS, canary, alarm, dashboard, pre-prod, screenshot, no-SEV, or Shepherd-success evidence as `covered` only when the CM shows that the evidence exercises or verifies the commit's specific changed surface, target scope, artifact/config version, and risk. Otherwise classify it as `generic only` or `missing`.
- Call out a finding for every deployment-affecting commit whose required validation is absent, only generic, placeholder-filled, or not tied to the changed surface. `generic only` is a validation gap unless the CM makes the changed-surface coverage explicit and defensible.
- Do not call out a CM validation gap for a commit that only adds or improves unit tests, test fixtures, docs, local developer tooling, or skill metadata unless the diff also changes production code, runtime config, build dependencies, release artifacts, security posture, or operational behavior.
- For deployment CMs that include ONSR or GOV scope and ship application artifacts, confirm the review captures a SLAPS approval result from the live SLAPS call for each exact application artifact in scope, not just an aggregate release-level statement. Do not require SLAPS for other realms or non-application/non-artifact changes.
- Fetch artifact-level SLAPS details from the live SLAPS call after the approval pause when SLAPS applies, and record the current compliance state for each exact artifact version.
- Do not treat CM-attached screenshots, release prose, `latestApprovedVersion`, or copied scan output as SLAPS or as equivalent to the current SLAPS compliance result.
- Treat missing, blocked, stale, warning, failed, or artifact-ambiguous SLAPS results from the live call as a validation and approval-gap finding for those ONSR or GOV application deployments.
- Treat warning-state SLAPS artifacts as residual approval risk that should be called out explicitly. Treat explicitly failed or blocked SLAPS artifacts as approval-blocking findings.
- Challenge missing evidence when Herds, pre-prod, or successful release links are still placeholders.
- Call out generic validation steps that do not prove the specific change.
- Do not accept "canaries will catch regressions" as complete validation unless the CM explains that canaries cover the full changed surface and the bake period includes the full canary cadence plus review of results.
- When the CM relies on canary validation between stages, regions, or realms, compare the documented bake window with the canary cadence and actual post-deploy canary timestamps. A stage or region promoted after a 2-hour bake is not covered by an 8-hour canary cadence unless at least one post-deploy canary run completed and was reviewed before promotion, or the CM documents an on-demand canary or alternate validation that covers the changed surface.
- Treat a bake window shorter than the claimed validation signal's cadence as a validation evidence gap. Escalate severity when canary validation is the primary safety gate, the rollout has broad or restricted-realm blast radius, or later-stage approval depends on that signal.
- If manual validation is used, require exact commands, pages, inputs, expected outputs, pass or fail criteria, and where the executor should capture evidence.
- For runbook-backed changes, call out validation that proves only task completion instead of service recovery or expected post-change state.
- For manual changes with no runbook, call out that validation expectations are weaker because there is no approved process reference to validate against.
- For host actions, require health checks that prove the affected service or pool recovered cleanly.
- For data fixes, require post-change reads, API checks, or equivalent state verification.
- Treat unresolved structured release-link fields as missing evidence.
- Treat `Release Check` validation gaps, blocked targets, or unresolved evidence gaps as CM review findings, not just release-side observations.

## Rollback Checks

- Confirm the rollback restores the previous known-good state, not just a generic earlier version.
- Confirm the rollback accounts for each major implementation section, normally in reverse order, and says which intermediate changes are reversed or intentionally left in place.
- For application changes, verify rollback artifact versions are explicit.
- For CM `Rollback release Link` fields, first determine whether the CM is using the link as rollback-test evidence, actual production rollback execution evidence, or both. Use the accepted rollback-linked status rule in `../SKILL.md` before making status a finding.
- For rollback-test evidence, review artifact versions, target scope, and whether the release tested rollback for the artifacts planned for deployment.
- For actual production rollback execution evidence, review artifact versions, config hash, target scope, prior known-good baseline, and whether the release would restore the state claimed by the CM.
- If the same release is used for both purposes, verify both rollback testing coverage and production rollback restoration alignment. If the CM does not make the purpose clear, report an ambiguity gap instead of assuming.
- For infrastructure changes, require an explicit prior config, release, or state target.
- For runbook-backed changes, require a concrete safe-restoration or containment path that matches the selected runbook.
- For manual changes with no runbook, call out that rollback confidence is reduced because no existing runbook defines the expected restoration path.
- For host actions, require abort or escalation conditions and a plan for degraded recovery if the host does not return cleanly.
- For data fixes, require either prior-state restoration or a clearly bounded containment plan when restoration is not feasible.
- If rollback is claimed to be unsafe or not applicable, require a concrete justification and a safe restoration path.

## Commit And Version Checks

- If a `release-backed` or `hybrid` CM lists commits, commit tables, Bitbucket compare links, SCM links, or PR links, confirm the release or state diff matches the commit intent. For pure `runbook-backed` CMs, commit-diff validation is optional/manual unless the user asks for it or the CM also includes release, artifact, repo, or config evidence that makes code changes part of the reviewed scope.
- Confirm the CM-related commit set is defined from the actual release delta. The matrix should focus only on commits related to the current CM release; broad-compare-only commits belong in an excluded-commit note, not as validation-gap rows.
- For each CM-related commit, record:
  - commit id and title
  - source, such as CM commit table, Bitbucket compare, SCM PR, or explicit hash
  - why the commit is related to the current CM release delta
  - changed-file categories, such as API, worker, DAL, spec, config, Terraform, security, dependency, or docs-only
  - validation relevance, such as requires CM validation, CI/test evidence only, no runtime validation required, or blocked
  - required tests or evidence inferred from the diff
  - CM validation, test result, Shepherd, HERDS, SLAPS result from the live call when applicable, or manual evidence that covers it
  - why the evidence is specific enough to cover the changed surface, or why it remains generic only
  - gap status, such as covered, partially covered, generic only, missing, or remote evidence blocked
- Treat test-only, docs-only, tooling-only, or skill-only commits separately from product-runtime commits, but still record why no CM runtime validation is required.
- If the ticket lists artifact versions, verify them against the linked Shepherd release artifacts.
- If the CM uses an ops repo or provider-based implementation, verify the repo path, PR, or config artifact aligns with the selected runbook and intended targets.
- If only config hashes are present, limit the conclusion to config or release alignment and say commit-level verification is not available.

- When the commit-diff validation matrix is required or manually requested, use `commit-matrix.md` for release-delta inputs, candidate relation labels, validation relevance labels, required validation by changed surface, outcome labels, excluded-commit handling, and finding rules.

## Timing And Execution Evidence Checks

- Challenge planned execution during freezes, Fridays, weekends, holidays, or the day before holidays unless the CM includes the required extra approval and justification.
- Confirm the CM tells the executor what evidence to add during execution, such as step inputs, outputs, screenshots, logs, release links, dashboard links, validation results, and ticket updates.
- Treat missing evidence-capture instructions as a reviewability finding when the change is high risk, delegated, or likely to be audited.

## Final Coverage

- Findings are first and ordered by severity.
- Linked Shepherd release coverage is explicit, including any inaccessible release or blocked Release Check evidence.
- Shared-release target mapping is explicit when applicable, including the CM-authorized phase, stage, regions, realms, execution targets, release targets, and any extra release inventory treated as separately gated context.
- Scoped SLAPS outcome is included only when ONSR/GOV application artifacts are in scope.
- Commit-diff matrix status is included when required, including blocked remote evidence, local-checkout fallback, and excluded compare-only commits when applicable.
- Runbook alignment is included for `runbook-backed` and `hybrid` reviews, including missing-runbook risk when applicable.
- CHANGE process hygiene is included when visible ticket fields show cloning, auto-rejection, template, or required-field issues.
- Manual-CM justification status is included for runbook-backed, operational, or otherwise manual changes, including whether the required `Why this manual change is required?` section was present and specific enough.
- Positive verification is separated from findings.
- Residual risk or assumptions are stated explicitly.

## Severity Hints

- `High`
  Use when the issue can make the CM unsafe or materially wrong to approve or run. Examples include scope drift, a shared release phase that can approve or has executed regions or realms outside this CM's intended scope without a separate clear gate, wrong change type, cloned or auto-rejected CHANGE ticket state that invalidates approval, rollback that would not restore service, undocumented high-risk regional diffs, host or data-fix procedures that target the wrong resources, or linked release findings that cause `Release Check` to recommend `Hold`.
- `Medium`
  Use when the CM may still be runnable, but evidence, traceability, or reviewability is materially weak. Examples include missing validation evidence, missing per-commit validation mapping, unclear shared-release target mapping, traceability gaps, unresolved template/process hygiene issues that do not invalidate the ticket, missing or generic `Why this manual change is required?` section for a manual CM, generic implementation instructions that materially weaken reviewability, missing runbook alignment, manual CM processes with no existing runbook, weak execution evidence-capture instructions, or linked release findings that result in `Proceed with regional blocker` or meaningful unresolved release risk.
- `Low`
  Use for cleanup that does not materially affect execution risk, such as unclear wording with obvious intent, minor documentation inconsistency, or secondary formatting/template cleanup.

Rule of thumb: `High` blocks approval or safe execution; `Medium` weakens confidence and should be fixed before approval when practical; `Low` improves clarity but does not change the risk decision.
