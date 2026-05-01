---
name: ocm-migration-triage
description: '[Workflow] Execution-first workflow for triaging stuck/failed OCM migrations (read-only by default)'
source_type: workflow
metadata:
    last_updated: 2026-02-23T00:00:00Z
    owner: ocm
---

# OCM migration triage (stuck/failed) — execution-first, read-only by default

## Scope

- This workflow applies to triaging **stuck or failed OCM migrations**.
- This workflow is **read-only by default**.
- This workflow does **not** grant permission to mutate any system.
  - Any status update, retry, cancel, restart, ticket transition, comment, or operational change is **MUTATION** and must be gated (see Mutation gate).

## Purpose

You must use this workflow to quickly produce an operator-quality triage summary:

- what state the migration is in (and since when)
- what evidence supports the current hypothesis
- which prerequisite/workflow stage is likely blocking
- the recommended next actions (read-only first; mutations gated)

## When to use

- You must use this workflow when a migration is:
  - not progressing for longer than expected, or
  - in a failed state, or
  - repeatedly retrying / oscillating, or
  - reported as “stuck” by a customer/operator without clear error context.

## When not to use

- You must not use this workflow to execute changes (retries, cancels, resets, policy updates, resource edits) without an explicit mutation gate.
- You must not use this workflow if you do not have enough scope inputs (see Inputs).

## Prerequisites (governance)

- You must follow:
  - Execution baselines (evidence + mutation gate): `skills/ocm-dev/execution-baselines-detail.md`
  - Access warmups (read-only preflight before multi-call work): `skills/ocm-dev/access-warmups-detail.md`

## Inputs

### Required

- **Tenancy**: name/alias (no secrets)
- **Region(s)**: one or more regions involved (source + target if applicable)
- **Time window**:
  - “Observed stuck since” timestamp (or approximate)
  - last known good milestone timestamp (if known)
- **Symptom**: one sentence (what is stuck/failing, and where you saw it)
- **One identifier** (at least one):
  - `migrationId`, or
  - `migrationPlanId`

### Optional (high value)

- Console URL(s) or screenshot(s) (sanitize as needed)
- Work request ID(s) (if the UI/API exposes them)
- Known workflow stage (discovery / prereqs / cutover / validation / cleanup)
- Any recent change context (deployment, policy change, network change)
- Ticket/incident link (Jira) for continuity

## Output contract (what you must produce)

You must produce a single triage report with this shape (copy/paste and fill):

```markdown
## OCM migration triage report

### Inputs
- Tenancy:
- Region(s):
- Time window:
- Symptom:
- Identifiers: migrationId= / migrationPlanId=

### Current state (evidence-backed)
- Lifecycle/state:
- Last progress timestamp:
- Blocking stage hypothesis:

### Evidence captured (sanitized)
- Migration details: <link/id + key fields>
- Work requests: <id(s) + status>
- Logs: <where + time range + key error snippets>
- Related resources: <names/ids + states>

### Prerequisite/stage mapping
- Prereq/stage that appears violated:
- Which prerequisite page section(s) to verify:

### Next actions
- Read-only next checks (in priority order):
1)
2)

- MUTATION candidates (require explicit confirmation + rollback story):
1)
2)

### Escalation / handoff
- Owner(s):
- What to send to escalation (links/ids/time window):
```

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

### 1) Confirm execution mode and warm access (read-only)

1) Declare execution mode as **read-only triage**.
2) If you will use any tool surface that may require authentication (OCI Console/API tooling, Atlassian, CLI wrappers), you must run the relevant warmup workflows first (do not parallelize warmups):
   - See `skills/ocm-dev/access-warmups-detail.md` (warmup workflows are the execution steps).

### 2) Identify the migration’s current state (do not assume)

1) Locate the migration object using the identifier you have (`migrationId` or `migrationPlanId`).
2) Record (as evidence):
   - lifecycle/state
   - last update timestamp(s)
   - any explicit error code/message fields
   - any linked work request IDs (if exposed)

**Evidence capture (minimum):**

- a screenshot or text snippet containing state + timestamp + error (if present)
- the exact time range you will use for logs in Step 3

### 3) Gather supporting evidence (logs + work requests + related resources)

1) If there are work requests or job records, capture:
   - ID, status, percent complete, start/end timestamps, and any error message
2) Gather logs/telemetry for the **same time window**:
   - Migration service logs (if available)
   - Worker/agent logs (if applicable)
   - Any “prereq execution” logs (if applicable)
3) Identify and record the state of the minimal set of related resources that commonly gate progress (read-only):
   - network reachability dependencies (VCN/subnet/NSGs as applicable)
   - compute/agent instances (health/running)
   - object storage buckets/objects used by the workflow (existence/access)
   - IAM/policy boundary indicators (authz failures)

**Stop condition:** if you cannot identify where logs live for this migration, skip ahead to Step 6 (escalation) with the evidence you do have.

### 4) Map evidence to a prerequisite or workflow stage

1) Based on the error(s) and last progress milestone, classify the block into one bucket:
   - **Prerequisites not satisfied** (IAM/network/quota/dependencies)
   - **Transient service failure** (retryable; capacity; timeout)
   - **Worker/agent health** (process down, cannot reach endpoints)
   - **Bad input / plan drift** (plan references missing/changed resources)
   - **Unknown** (insufficient signals)
2) For the “prerequisites not satisfied” bucket, you must cross-check against the canonical prerequisites guidance:
    - Creating Migration Prerequisites v2.3 (pageId=19254551310)
3) Record exactly which prerequisite(s) or section(s) appear violated, and which evidence supports that.

### 5) Propose next actions (read-only first)

1) List **read-only** next checks in priority order.
   - Each check must specify: target, time window, and what outcome would confirm/deny a hypothesis.
2) List any **mutation candidates** that would unblock progress (retry, rerun prereqs, cancel/recreate, policy change, restart worker, etc.).

#### MUTATION (stop + confirm)

If you (or the workflow consumer) want to execute any mutation candidate, you must stop and apply the mutation gate from:

- `skills/ocm-dev/execution-baselines-detail.md`

Your confirmation request must include:

- exact target(s) (tenancy/region/migrationId/resources)
- exact action(s)
- expected outcome
- rollback story
- evidence you will capture (sanitized)

### 6) Produce the triage report and decide escalation path

1) Fill the triage report template (see Output contract).
2) If escalation is required, include:
   - what you already checked
   - the minimal evidence set (ids + timestamps + error snippets)
   - what you need from the next team (specific missing signal)
3) If this affects oncall continuity, generate a handoff note:
   - `workflows/generate-handoff-note.md`

## Verify

You must verify success by confirming all are true:

- A triage report exists and is internally consistent (same tenancy/regions/time window across evidence).
- The report includes at least one concrete hypothesis and at least two read-only next checks.
- Any proposed mutation is explicitly labeled **MUTATION** and defers to the mutation gate in `skills/ocm-dev/execution-baselines-detail.md`.
- Evidence is sanitized (no secrets; no forbidden identifiers) and minimal.

## Done when

- The migration’s current state is recorded with a timestamp.
- Evidence is captured for the declared time window (work request status and/or logs).
- The block is mapped to a prerequisite or workflow stage (or explicitly marked unknown with a data request).
- Next actions are listed with read-only checks first.
- Any mutation is gated (explicit stop + confirm + rollback story).

## Failure modes

- **Missing identifiers (no migrationId/planId).**
  - Recovery: obtain at least one identifier from the UI/ticket; if unavailable, capture tenancy/region/time window and escalate with the symptom and screenshot.

- **Auth/permission failures while gathering evidence (401/403 or “not authorized”).**
  - Recovery: run the relevant warmup workflow(s) from `skills/ocm-dev/access-warmups-detail.md`; confirm you are in the intended tenancy/region; re-run the read-only query.

- **Evidence is too sensitive to store.**
  - Recovery: do not store it; capture only non-sensitive shapes (IDs + timestamps + error codes) and keep full logs in the source system.

## References

- Execution baselines (mutation gate + evidence expectations): `skills/ocm-dev/execution-baselines-detail.md`
- Access warmups governance (execution steps in linked workflows): `skills/ocm-dev/access-warmups-detail.md`
- Handoff note workflow: `workflows/generate-handoff-note.md`
- Creating Migration Prerequisites v2.3 (pageId=19254551310): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19254551310
