---
name: ocm-shepherd-deploy
description: '[Workflow] Execution workflow for OCM Shepherd deployments (read-only by default; explicit mutation gate)'
source_type: workflow
metadata:
    last_updated: 2026-02-23T00:00:00Z
    owner: ocm
---

# OCM Shepherd deploy (execution workflow)

## Purpose

You must use this workflow to execute an OCM Shepherd deployment with a safe default posture:

- preflight and guardrails checks are **read-only**
- rollout requires an explicit **MUTATION gate** before any state change
- rollback is defined up-front and includes explicit **rollback verification**

## When to use

- You must use this workflow after a release is declared **GO** (see References).
- You must use this workflow when you need a repeatable rollout + rollback path for Shepherd-driven deployments.

## When not to use

- You must not use this workflow to decide release readiness.
  - Use: `workflows/ocm-release-readiness.md`
- You must not use this workflow for plugin deployment on-call procedures.
  - Use the canonical on-call guide (Confluence anchor in References).

## Inputs

### Required

- **Release identifier**: release name + train (or equivalent) (example: `R2026.02 / Train-3`).
- **Target scope**: realm(s), region(s), environment(s), and service(s) to deploy.
- **Shepherd artifacts** (links/locations; no secrets):
  - release notes / operator callouts
  - change list (repos/components included)
  - pinned versions (image tags/digests, package versions, or commit SHAs)
  - rollout plan (sequence + any required canary/bake steps)
  - rollback plan (what “rollback” means for this release)
- **Approvals**:
  - required approver roles
  - where approval is recorded (CM ticket / email / chat thread link)
- **Rollback owner (role)**: who is authorized and available to execute rollback if needed.

### Optional (recommended)

- **Deployment window**: start/end time window (with timezone).
- **Communication channels**: where status updates will be posted.
- **Evidence path** (sanitized, local-only):
- Preferred (local-only; never commit): `.generated/evidence/ocm-ai-pack/<YYYY-MM-DD>/ocm-shepherd-deploy/<release-id>/`

## Defaults (safety posture)

- This workflow is **read-only** by default.
- Treat this workflow as **read-only** until you pass the explicit MUTATION gate.
- If any step would update a ticket, approve a CM, start a deployment, push/merge/tag, or otherwise change state:
  - you must stop and apply the **Mutation gate** from `skills/ocm-dev/execution-baselines-detail.md`.

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

### 1) Preflight (read-only)

1) Confirm execution mode is **read-only** for preflight.
2) Confirm a release readiness decision exists:
   - You must have a **GO** readiness report produced by: `workflows/ocm-release-readiness.md`
3) Load the canonical plan context:
   - Deployment plan: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
   - Realm Build Runbook: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
4) If you will make multiple external calls (Jira/Confluence/SCM/DevOps), you must run the relevant access warmup(s) first:
   - Governance: `skills/ocm-dev/access-warmups-detail.md`

### 2) Guardrails check (read-only)

You must not start a rollout until the guardrails below pass.

1) Confirm scope is frozen and unambiguous:
   - target realm(s)/region(s)/env(s)/services are explicitly listed
   - the scope matches the deployment plan and the readiness report
2) Confirm artifacts are sufficient to execute safely:
   - release identifier and pinned versions are available
   - rollout sequence is documented (including any canary/bake expectations)
   - rollback procedure exists and is consistent with the CM rollback story
3) Confirm roles and approvals are in place:
   - required approvals are recorded in the declared system of record
   - rollout driver (role), observers (role), and rollback owner (role) are identified and available
4) Define stop conditions (operator guardrails):
   - what signals will pause/stop expansion (error rate, latency, alarms, customer impact)
   - how you will declare “hold” vs “rollback”
5) Confirm observability readiness:
   - dashboards/alarms/log views for in-scope services are identified before starting
   - you can distinguish “expected change noise” from true degradation

### 3) Rollback plan (read-only; required before rollout)

1) Identify the rollback target:
   - prior known-good release id/train (or equivalent)
   - scope for rollback (same as rollout, unless explicitly reduced)
2) Confirm rollback execution authority and timing:
   - rollback owner (role) is on-call/available during the window
   - expected max time-to-restore is defined
3) Prepare a rollback verification checklist (verbatim headings):

```text
Rollback verification checklist

Rollback
- Target release/version:
- Scope (realm/region/env/services):
- Rollback owner (role):

Verification
- Deployment system reports target version is active:
- Service health checks are green (as defined for this release):
- Error rate/latency returned to pre-change baseline (or within agreed SLO):
- No new critical alarms firing after rollback completes:
- Operator announcement posted + CM/ticket updated (if required):
```

### 4) MUTATION (stop + confirm) — starting the rollout

If the next action is to start a Shepherd rollout (or change any external state), you must:

1) Stop.
2) Follow the Mutation gate requirements in `skills/ocm-dev/execution-baselines-detail.md`.
3) In your confirmation request, you must include:
   - release identifier + pinned versions
   - exact target scope
   - approvals evidence (where recorded)
   - stop conditions
   - rollback target + rollback owner (role)
   - what evidence you will capture (sanitized)
4) Proceed only after you have explicit confirmation.

### 5) Rollout (MUTATION)

You must execute the rollout using the canonical Shepherd/realm build procedures (do not invent new deployment mechanics here):

- Realm Build Runbook (canonical sequencing): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
- Deployment plan (release-cycle tracker): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
- Repo-specific truth (commands/flags) must come from the Shepherd repo:
  - `ocm-shepherd/AGENTS.md`

During the rollout, you must checkpoint the deployment in stages and verify between stages:

1) Start the rollout for the smallest safe initial slice (for example: canary or a single region/env slice).
2) Verify slice health before expanding:
   - deployment system reports the intended target version for the slice
   - service health checks are green
   - no critical alarms attributable to the change
3) Expand to the next slice only if the previous slice passes your stop conditions.
4) If stop conditions trigger, you must choose one:
   - HOLD: pause expansion and investigate (read-only triage)
   - ROLLBACK: execute rollback (see Step 6)
5) Post operator status updates per your communication plan (MUTATION gate applies if posting updates to a system of record is considered state change in your process).

### 6) Rollback (MUTATION; conditional) + rollback verification

If you decide to rollback (or rollback is required by your process), you must:

1) Stop and re-apply the Mutation gate:
   - state the rollback target release/version and exact rollback scope
   - confirm rollback owner (role) is executing
2) Execute rollback using the canonical Shepherd/realm build rollback procedure (source of truth in the Realm Build Runbook and Shepherd repo).
3) Perform rollback verification using the checklist you prepared in Step 3.
4) Capture minimal sanitized evidence that rollback completed and health recovered (for example: timestamps + the “version active” signal + a summary of health state).
5) Produce a handoff note if the rollback requires continuity across shifts:
   - `workflows/generate-handoff-note.md`

## Verify

Pass criteria (all must be true):

- A **GO** readiness report exists for the release and matches the deployment plan scope.
- Guardrails check passed (scope frozen, approvals recorded, stop conditions defined, rollback owner identified).
- If rollout executed:
  - the deployment system reports the intended target version active across the declared scope
  - service health is green and no new critical alarms attributable to the change persist beyond the agreed window
- If rollback executed:
  - rollback verification checklist is completed and all items pass

## Done when

- The target scope is running the intended release/version, verified by the agreed health signals.
- A rollback story exists and is executable (rollback target + rollback owner (role) + verification checklist).
- If a rollback occurred, rollback verification is complete and a continuity artifact exists (handoff note or structured triage report).

## Failure modes

- **Scope drift (deployment plan, CM ticket, and execution targets disagree).**
  - Recovery: stop; reconcile scope; update the authoritative source (MUTATION gate applies).
- **Missing approvals or unclear execution roles.**
  - Recovery: stop; obtain/record approvals; confirm rollout driver + rollback owner (roles) before proceeding.
- **Rollout health degrades at a slice checkpoint.**
  - Recovery: hold expansion; investigate read-only; rollback if stop conditions require it.
- **Rollback completes but health does not recover.**
  - Recovery: treat as incident; capture evidence; escalate per on-call guidance; produce a handoff note.

## References

- Execution baselines (mutation gate + evidence expectations): `skills/ocm-dev/execution-baselines-detail.md`
- Access warmups governance: `skills/ocm-dev/access-warmups-detail.md`
- Release readiness workflow (do this first): `workflows/ocm-release-readiness.md`
- Handoff note workflow (continuity evidence): `workflows/generate-handoff-note.md`
- Shepherd anchors:
  - Deployment plan: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19083594114
  - Realm Build Runbook: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12075203796
  - OCM on-call: plugin deployment: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19047080351
