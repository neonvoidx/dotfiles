---
name: ocm-release-readiness
description: '[Workflow] Execution-first OCM release readiness checklist (read-only by default)'
source_type: workflow
metadata:
    last_updated: 2026-02-23T00:00:00Z
    owner: ocm
---

# OCM release readiness (execution-first)

## Purpose

You must use this workflow to decide **GO / NO-GO** for an OCM release using a repeatable, evidence-backed checklist.

## When to use

- You must use this workflow before starting a release rollout (or approving a release to start).
- You should use this workflow whenever the scope/plan changed since the last readiness check.

## When not to use

- You must not use this workflow as a deployment runbook.
  - Use the release execution/deploy workflow for the actual rollout.

## Inputs

### Required

- **Release identifier**: release name + train (or equivalent) (example: `R2026.02 / Train-3`).
- **Target scope**: realm(s), region(s), environment(s), and service(s) included in this release.
- **CM ticket link**: the change-management ticket URL.
- **Approvals required**: named approver roles (not people) and where approval is recorded (CM ticket / email / Slack thread link).
- **Evidence path** (sanitized, local-only): a relative folder where you will store proof of verification.
- Preferred (local-only; never commit): `.generated/evidence/ocm-ai-pack/<YYYY-MM-DD>/ocm-release-readiness/<release-id>/`

### Optional

- **Deployment window**: planned start/end time window (with timezone).
- **Rollback window + owner**: who can execute rollback, and the expected max time-to-restore.
- **Known exceptions**: explicitly accepted risks with a link to the approval.

## Defaults (safety posture)

- Treat this workflow as **read-only** discovery by default.
- If any step would update a ticket, approve a CM, start a deployment, push/merge/tag, or otherwise change state:
  - You must stop and apply the **Mutation gate** from `skills/ocm-dev/execution-baselines-detail.md`.

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

### 1) Preflight (read-only)

1) Confirm execution mode is **read-only** for readiness.
2) If you will make multiple external calls (Jira/Confluence/SCM/DevOps), you must run the relevant access warmup(s) first:
   - Governance: `skills/ocm-dev/access-warmups-detail.md`

### 2) Load the canonical plan context (read-only)

1) Open and review the **Deployment plan** (Confluence):
   - https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
2) Open and review the **Realm Build Runbook** (Confluence):
   - https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
3) Extract (into your readiness report):
   - planned release name/train
   - intended scope (realm/region/env/services)
   - required sequencing/constraints (if any)

### 3) CM ticket completeness check (blocking)

From the CM ticket, confirm all required evidence exists and is consistent with the deployment plan.

- [ ] CM ticket exists and is accessible to operators executing the release.
- [ ] Summary describes **what changes** and **why** (release intent).
- [ ] Scope matches the deployment plan (realm/region/env/services).
- [ ] Risk assessment is present (customer impact + blast radius).
- [ ] Rollback story is present (what rollback means, who executes it, time-to-restore target).
- [ ] Validation plan is present (what checks prove success).
- [ ] Required approvals are listed and recorded (links or ticket fields).

**Blocking criteria:** if any checkbox above is unchecked, you must mark the release as **NO-GO** until resolved.

### 4) Artifacts checklist (blocking)

You must verify the release has the minimum artifacts needed for safe execution.

#### 4.1 Release artifacts (evidence required)

- [ ] Release notes exist (what changed, operator-relevant callouts).
- [ ] Change list exists (what repos/components are included).
- [ ] Version identifiers are pinned (image tags/digests, package versions, or commit SHAs as applicable).
- [ ] Deployment sequence is documented (high-level order + dependencies).
- [ ] Rollback procedure is documented and matches the CM rollback story.

#### 4.2 Quality gates (evidence required)

- [ ] CI/build verification is complete for all in-scope components (link to results).
- [ ] Smoke/regression verification plan is defined (and run if required by your process).
- [ ] No known release-blocking failures are open without an explicit exception approval.

#### 4.3 Operational readiness (evidence required)

- [ ] Monitoring/alerting is in place for affected services (dashboards/alarms identified).
- [ ] On-call / execution roles are identified (who drives, who watches, who can rollback).
- [ ] Operator communication plan exists (where announcements/updates will be posted).

**Blocking criteria:** if any required artifact is missing, you must mark **NO-GO** until the artifact exists or an explicit exception is approved and recorded.

### 5) Release blockers and exception handling (blocking)

1) List current **known blockers** (tickets/incidents) that would make the release unsafe.
2) For each exception you intend to accept, you must capture:
   - what is being accepted
   - why it is acceptable
   - who approved it
   - where the approval is recorded

**Blocking criteria:** any unresolved critical blocker without explicit approval is **NO-GO**.

### 6) Produce a readiness report (output contract)

You must produce a single readiness report with the headings below (verbatim) and store it in one of:

- the CM ticket (preferred), or
- your local evidence path (sanitized, local-only).

```text
Release readiness report

Release
- Identifier:
- Scope (realm/region/env/services):
- Deployment window:

Links
- CM ticket:
- Deployment plan (Confluence):
- Realm Build Runbook (Confluence):

Approvals
- Required approvals:
- Approval evidence:

Artifacts checklist
- Missing artifacts (if any):

Blocking criteria
- Active blockers (if any):
- Exceptions (if any):

Decision
- GO / NO-GO:
- Decision owner (role) + timestamp:
```

### 7) MUTATION (stop + confirm)

If the next action is to update the CM ticket (status/fields/comments), approve the change, or start the rollout, you must:

1) Stop.
2) Follow the Mutation gate requirements in `skills/ocm-dev/execution-baselines-detail.md`.
3) Proceed only after you have explicit confirmation.

## Verify

- The readiness report exists and includes all required sections.
- All blocking checklists (CM completeness, artifacts, blockers) have **no unresolved items**, or exceptions are explicitly approved and linked.
- The deployment plan and CM ticket scopes match (realm/region/env/services).

## Done when

- A single readiness report exists (CM ticket or local evidence) with a clear **GO / NO-GO** decision.
- If **GO**, the next-step workflow is identified (deployment execution workflow) and any mutation is gated per the execution baselines.

## Failure modes

- **CM ticket missing required fields/evidence.**
  - Recovery: stop; request missing information; do not start the rollout.
- **Scope mismatch between CM ticket and deployment plan.**
  - Recovery: stop; reconcile scope; update the authoritative source (MUTATION gate applies).
- **Auth/access failures slow readiness checks.**
  - Recovery: run the relevant warmup(s) per `skills/ocm-dev/access-warmups-detail.md` and re-try.

## References

- Execution baselines (mutation gate + evidence expectations): `skills/ocm-dev/execution-baselines-detail.md`
- Access warmups governance: `skills/ocm-dev/access-warmups-detail.md`
- Handoff note workflow (if you need continuity evidence): `workflows/generate-handoff-note.md`
- Confluence anchors:
  - Deployment plan: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
  - Realm Build Runbook: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
