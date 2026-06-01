# Workflow

## 1. Intake

1. Parse the release link and record `project`, `flock`, and `release_id`.
2. Validate the required auth before any Shepherd or Lumberjack reads:
   - validate OCI session-backed auth before CLI or direct API calls
   - validate `OP_TOKEN` before direct DevOps or browser-replay log paths
   - if a required session or token is invalid and cannot be refreshed non-interactively, stop and tell the user exactly what must be refreshed before continuing
3. Fetch `get_shepherd_release`.
4. Fetch `get_shepherd_release_phases`.
5. Fetch the detailed execution-target view for the release.
6. Fetch phase-scoped `get_shepherd_release_changes` for each relevant phase before drilling into target-specific plan blobs or logs.

Goal:

- know the release scope
- know the phase order
- know which targets exist
- know which targets look normal or anomalous

## 2. Choose The Track

Pick the track from the user's question:

- `Release Review`
  Use when the user wants expected-vs-observed diff review, change analysis, rollout confidence, regional outlier detection, or deployment approval support.
- `Release Investigation`
  Use when the user wants failure cause, first bad target, concrete error evidence, or halted-step analysis.

If the request mixes both, do the review track first so the anomalous targets are obvious, then deepen only the suspicious targets with the investigation track.

## 3. Release Snapshot

Capture:

- release name
- release hash when available
- release status
- current phase and phase status
- whether the current phase is `pre-start`, `in-flight`, or `post-start`
- change type and change class
- created, started, completed timestamps
- artifacts and versions
- total execution target counts

Keep this section short. The deeper analysis belongs at the target level.

## 4. Phase and Target Map

Build a target matrix with one row per target:

- phase
- target name
- region
- `execution_target_id`
- `releaseTargetId`
- execution-target plan blob status: fetched, unavailable with reason, or not applicable with reason
- target status
- `actions` summary such as `Create`, `Delete`, `Update`
- phase-scoped resource change summary from `get_shepherd_release_changes`

This matrix is the backbone for both the diff summary and the timeline.

## 5. Diff Strategy

### Minimum required diff

Always produce a per-target or per-region diff summary from the data already available in Shepherd:

- phase-scoped `get_shepherd_release_changes` output
- target action counts
- target status
- artifact versions from release metadata
- validation posture and cached state
- target-specific deployment or exec state from `get_shepherd_execution_target_state_body`

This minimum summary is not enough by itself until you have attempted the deeper execution-target plan blob for every relevant execution target in the release. If plan blobs cannot be fetched, label the output clearly as `diff summary`, not `resource-level plan diff`, and record the unavailable plan-blob reason per affected target.

### Preferred release change view

Start the diff pass with `get_shepherd_release_changes`, usually one call per phase:

- this gives a release-scoped resource list plus action and `delta` details
- it is the default way to confirm what changed in each release wave
- it is usually easier to audit than a release-wide aggregate because the same resource may appear in multiple phases

Use this to answer:

- which resources changed in each phase
- which changes are shared across phases versus phase-local
- which updates are policy, alarm, property, or application changes
- whether a resource appears to be created, updated, or replaced in one wave but not others

### Required execution-target plan blob

For every release under review, fetch or explicitly attempt the current execution-target plan blob for every relevant execution target once `phase` and `execution_target_id` are resolved:

```text
/projects/<project>/flocks/<flock>/releases/<release_id>/phases/<phase>/executionTargets/<execution_target_id>/plan
```

Then diff that plan against the prior successful baseline for the same target.

Use plan blobs to inspect exact Terraform-style `resource_changes`, replacement semantics, and baseline comparison beyond what `get_shepherd_release_changes` already shows.

If the plan blob cannot be fetched, do not skip the step silently. Record:

- phase
- target
- `execution_target_id`
- unavailable reason, such as auth, API, retention, missing tool support, or not found
- fallback evidence used, such as phase-scoped release changes, action counts, artifacts, validations, cached state, or target state body

Treat unavailable plan blobs as evidence gaps in the decision label or recommendation when they could change scope, rollback, or CM-alignment confidence.

### Baseline selection

Choose the latest prior release that:

- belongs to the same flock
- targeted the same phase and execution target
- completed successfully or is the prior approved plan-only baseline

Prefer:

1. prior successful plan-only release for the same target when reviewing release scope
2. otherwise the latest successful roll-forward release that touched the same target

### Scope review questions

Answer these even when there is no failure:

- Which targets or regions have different action counts from the rest?
- Are all targets moving the same artifact or version?
- Does the release touch only the expected phases, targets, and regions?
- Is the observed scope aligned with the user's stated intent or CM description?
- Do the observed resource changes align with the CM's listed commits and implementation narrative when a CM is in scope?
- Are there deletes, replacements, or validation changes that increase rollback risk?

## 6. Release Review Track

Use this when the release is being reviewed before or during deployment.

1. Compare the target matrix against the expected scope from the user, ticket, or prior approved baseline.
2. Build a region or target diff matrix:
   - phase-scoped resource changes from `get_shepherd_release_changes`
   - execution-target plan blob diff status and any missing-plan evidence gaps
   - common changes shared by most targets
   - outlier targets or regions
   - version or artifact mismatches
   - deletes or replacements that increase risk
3. Inspect validations and cached state for each target:
   - confirm which targets only plan changes
   - identify which targets deploy artifacts
   - note whether validations, canaries, or policy gates differ by region
   - when a CM is in scope, note whether Shepherd evidence supports the CM's validation claims or exposes missing validation and bake-period evidence
4. If approval of the current phase depends on earlier rollout waves, inspect adjacent or sibling releases in the same flock and release family:
   - look for unresolved planning, deploy, validation, or policy failures
   - note whether the current phase is still pre-start because of human review versus because earlier waves already exposed a blocker
   - treat a live blocker in an earlier wave as an approval blocker unless the user explicitly wants a narrower review
5. Assess blast radius:
   - number of regions or targets affected
   - whether changes are homogeneous or skewed
   - whether a single outlier target could halt the whole rollout
6. Assess rollback posture:
   - identify the nearest baseline release
   - note whether rollback depends on a prior successful plan-only or roll-forward release
   - call out missing baseline evidence when rollback confidence is low
   - when a CM is in scope, report whether the release evidence identifies enough prior state for the CM rollback steps to be executable
   - when reviewing a linked rollback release for a CM, judge whether it matches the rollback purpose rather than whether it is approval-ready during CM review; pre-start or unapproved rollback-release state is context unless it blocks alignment review or conflicts with the ticket's execution state
7. Choose one explicit deployment-review decision:
   - `Hold`
     Use when sibling or current-wave evidence materially reduces confidence in the rollout as a whole, such as a shared dependency failure, unresolved earlier-wave blocker, unclear blast radius, or large evidence gaps while the current phase is still pre-start.
   - `Proceed with regional blocker`
     Use when the payload and broad diff shape look sound, but one region, target, or dependency path is unhealthy enough that approval should be conditional on excluding, retrying, or separately tracking that blocker.
   - `Review passes with noted sibling risk`
     Use when sibling issues are weakly related, clearly isolated, or already mitigated, so they should be documented but do not materially change approval confidence for the current phase.
8. Summarize:
   - expected scope vs observed scope
   - safe/common changes vs higher-risk changes
   - the chosen decision label and why it fits
   - approval blockers or follow-up checks

## 7. Release Investigation Track

Check target errors before reading long logs.

Always inspect adjacent or sibling releases for the same flock and failing target before finalizing the RCA.

Use the sibling-release comparison to answer:

- did the same target fail repeatedly or only once
- did the same `configId` later succeed on the same target
- does the evidence point to a transient dependency, a target-local issue, a persistent config problem, or a wider rollout issue

Classify the anomaly or failure:

- lock or concurrency wait
- artifact push failure
- planning failure
- Terraform apply failure
- ODO deployment failure
- exec or canary validation failure
- alarm or policy gate
- downstream service timeout or workflow stall

If the release is halted but target state shows successful ODO deployment, call that out explicitly and move the failure into the validation bucket.

Before reading long logs, inspect the phase-scoped release changes for the failing or suspicious phase:

- confirm whether the failing phase changed the resource family you suspect
- identify whether the anomaly aligns with policy, alarm, property, splat, or application changes
- call out when the failure appears unrelated to the changed resources, because that may indicate an environmental or downstream issue

## 8. Target Logs and Validations

Use `get_shepherd_release_target_logs` for the failing target.

Read the full raw target log at least once. Use the first terminal error to anchor the RCA, not as the stopping point for log review.

Read the log in this order:

1. lock waits
2. planning start
3. artifact push
4. deploy steps
5. validation or exec steps
6. first concrete error

Do not stop at Shepherd attribution summaries. Always read the raw target log lines through the first terminal Terraform, deploy, exec, or validation error even if the attribution block says no explicit signature was detected.

After the first terminal error, continue scanning the remaining target log for:

- retries, backoffs, and competing wrapper errors
- cleanup, rollback, or finalization activity
- downstream validation progress or skipped steps
- secondary warnings that materially change the RCA or rollout risk
- the last concrete progress marker before the target stopped

For successful or still-running targets, use the same full-log scan to capture milestone progress, timing gaps, and regional outliers even when there is no terminal error.

Then use `get_shepherd_execution_target_state_body` to confirm what actually happened:

- ODO deployment states and messages
- exec or canary `client_status`
- exec or canary `exit_status`
- output log URLs
- dependency ordering across deploy and validation resources

If Shepherd wraps the failure in a generic non-zero exit, prefer the exec or canary state body and the target log over the generic wrapper.

If the release also shows compiled-config warnings, exclusion flags, or stale config metadata:

- compare adjacent or sibling releases for the same flock, target, and `configId`
- check whether the same `configId` later succeeded on the same target
- only elevate the config warning or metadata issue to root cause when the failed raw log and sibling-release comparison both support that conclusion
- if the same `configId` succeeds nearby, anchor the RCA to the concrete runtime error instead and treat the config warning as background risk or stale metadata

For review mode, use the same evidence to confirm whether validation steps are present, regionally consistent, and proportionate to the release scope.

## 9. Timeline

Build a single ordered timeline using exact timestamps from:

- release creation and start
- phase approval and start
- lock waits ending
- planning start
- artifact push activity
- deployment completion
- validation start
- first failure event
- halt or final state creation

Use one line per event with:

- timestamp in UTC
- component
- target or region
- event
- why it matters

For review mode, include sequencing that matters for deployment confidence:

- phase ordering across regions
- whether target execution is parallel or staggered
- when validations begin relative to deployment completion
- when the first outlier or risk signal appears

## 10. Lumberjack Escalation

Escalate when:

- Shepherd only shows a generic exit code
- the failing step depends on a downstream workflow
- the target log points to a work request, workflow id, or service request id
- you need to prove whether a downstream system saw the request
- the release review depends on proving a downstream service actually received or rejected a change

Escalation order:

1. discover the right service or phonebook
2. get compartments by phonebook
3. get the real logging namespaces for the region and tenant
4. search exact ids in the smallest reasonable time window
5. if the wrapper path fails, retry the same exact query through direct Ibex or browser-authenticated replay when available
6. run one control query against a namespace you know is readable so you can distinguish empty results from a visibility or authorization boundary
7. if exact ids still fail, search nearby account, tenancy, order, or workflow identifiers from the same evidence set

Do not widen the search before you have exhausted the exact identifiers already present in Shepherd, the state body, or the downstream exec log.

If direct DevOps or Lumberjack replay is part of the escalation path, validate the required token or session first instead of using authorization failures as a proxy for downstream behavior.

If downstream namespaces return `NotAuthorizedOrNotFound` while a control query succeeds, report that as a service-side log visibility gap. Do not translate that into "the downstream service never saw the request" unless another evidence source proves that claim.

## 11. Finish Criteria

Every final review or investigation must include:

- resolved identifiers
- target matrix
- release resource changes by relevant phase
- diff summary for each relevant target or region
- timeline
- risks
- references
- recommendations

Add these for `Release Review`:

- expected scope vs observed scope
- outlier regions or targets
- blast radius and rollback posture
- validation coverage and approval blockers

Add these for `Release Investigation`:

- concrete errors with evidence
- first anomalous target or event
- what still succeeded vs what failed
