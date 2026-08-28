# Reporting

Use this structure for the final writeup.

## 1. Release Summary

Include:

- release link
- investigation mode: `Release Review`, `Release Investigation`, or `Combined`
- `project`, `flock`, `release_id`
- release name
- release hash when available
- release status
- current phase
- release posture: `pre-start`, `in-flight`, or `post-start`
- decision label for deployment review when applicable:
  - `Hold`
  - `Proceed with regional blocker`
  - `Review passes with noted sibling risk`
- change type and class
- start and end status in exact timestamps

## 2. Target Matrix

Include one row per relevant target with:

| phase | target | region | execution target id | release target id | plan blob | status | diff summary |
| --- | --- | --- | --- | --- | --- | --- | --- |

`diff summary` should contain either:

- a short phase-scoped change summary from `get_shepherd_release_changes`
- action counts such as `Create 6 / Delete 6`
- or a short resource-level diff summary from the required execution-target plan blob

`plan blob` should say `fetched`, or give the explicit unavailable reason and fallback evidence. Do not omit this column for release reviews.

## 3. Scope Review

Always include:

- release resource changes by relevant phase
- execution-target plan blob coverage for every relevant target
- expected scope vs observed scope
- common changes shared across targets or regions
- outlier regions or targets
- artifact or version alignment
- validation or policy-gate differences
- CM alignment when a CM is in scope: whether the plan/resource changes match the CM commits, implementation steps, and validation or rollback claims
- adjacent or sibling rollout-wave health when it affects approval of the current phase

For deployment review, also include:

- likely blast radius
- rollback posture and baseline confidence
- rollback-release purpose alignment when a rollback release is linked, without treating normal pre-start or unapproved rollback-release state as an approval-readiness defect
- validation coverage, canary or bake-period gaps, and evidence-capture gaps visible from release data
- approval blockers or follow-up checks
- why the selected decision label fits better than the other two outcomes

## 4. Findings

Order findings by importance:

- what changed
- what looks normal
- what looks risky or unexpected
- what failed
- what still succeeded
- what remains uncertain

When the release has multiple phases, group `what changed` first by phase and then by resource family so reviewers can audit rollout waves cleanly.

Clearly separate:

- confirmed evidence
- reasonable inference
- open gap

## 5. Errors And Anomalies

For each failing or suspicious target, include:

- target name
- anomaly or error class
- first concrete error or suspicious signal
- exact timestamp when available
- supporting log, diff, or state evidence

If there are no failures, say that explicitly and keep this section focused on unexpected deltas or missing evidence instead.

## 6. Timeline

List the important sequence in UTC with one line per event:

- release created
- phase approved
- planning started
- deploy completed
- validations started
- first error
- release halted

Keep the timeline auditable rather than chatty.

For release review, include rollout sequencing that affects confidence, such as region ordering, staggered execution, or validations beginning later than expected.

## 7. Risks

Call out:

- scope drift risk
- unexpected diff risk
- partial deploy risk
- validation-only failure risk
- rollback complexity
- blast radius
- unknown downstream state
- evidence gaps that could change the conclusion

## 8. References

List the identifiers and artifacts someone else would need to audit the same release:

- release id
- related or sibling release ids that materially affected the conclusion
- phase name
- execution target id
- release target id
- work request ids
- workflow ids
- target log sources
- relevant namespaces when Lumberjack was used
- blocked namespaces or control queries when Lumberjack evidence was limited by visibility

## 9. Recommendations

Give the next actions in priority order, for example:

- approve or hold the rollout
- proceed while excluding or separately tracking a regional blocker
- confirm an outlier diff with the owner
- retry target
- inspect downstream service owner
- fetch deeper plan blob diff
- verify deployed cached state
- open a follow-up ticket

When a recommendation depends on incomplete evidence, say so explicitly.
