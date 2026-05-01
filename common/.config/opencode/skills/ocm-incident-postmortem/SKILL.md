---
name: ocm-incident-postmortem
description: '[Workflow] Execution-first postmortem workflow (timeline, impact, fixes, action items) with evidence requirements and mutation gating'
source_type: workflow
metadata:
    last_updated: 2026-02-23T00:00:00Z
    owner: ocm
---

# OCM incident postmortem (execution-first)

## Purpose

You must use this workflow to produce a complete, execution-ready postmortem package for an OCM incident: **timeline**, **impact**, **root cause**, **mitigations**, and **action items**, with explicit evidence expectations.

## Scope

- This workflow applies to incidents affecting **OCM services** (including dependent components) in any environment.
- This workflow is **read-only by default** (discovery + drafting). Publishing updates is gated (see **Mutation**).

## When to use

- You must use this workflow after any incident that required operator intervention, caused customer impact, triggered oncall paging, or exposed a meaningful reliability gap.

## When not to use

- You must not use this workflow for routine, non-impacting alerts with no customer/user effect and no operational learnings (use a short handoff note instead).
- You must not use this workflow to execute production changes (use the relevant deploy/release workflow).

## Inputs

- **Incident id**: the canonical identifier (ticket key / incident number / war-room id).
- **Time window**: start/end timestamps (include timezone).
- **Impacted services/components**: list the OCM service(s), region(s)/realm(s), and any key dependencies.
- **Evidence sources** (at least 2):
  - incident/ticket system record
  - dashboards/metrics
  - logs
  - alarms/pages
  - deploy/change records (release, work request, rollout, etc.)
  - incident comms (war-room notes) 
  - customer reports/support tickets

## Defaults

- Use **UTC** for the canonical timeline timestamps. If you also include local time, include both.
- Prefer **one postmortem document** with links to supporting evidence, rather than scattering facts across multiple notes.
- Keep evidence **sanitized** and shareable (no secrets, no credentials, no restricted customer data).

## Outputs (what you must produce)

1) A postmortem draft containing:
   - Incident summary
   - Customer impact (what/where/how many/how long)
   - Timeline (UTC)
   - Root cause (and contributing factors)
   - Mitigations (what reduced impact) and recovery steps
   - Corrective and preventive actions (with owners and due dates)
2) A minimal evidence bundle (sanitized) sufficient to justify the claims in the postmortem.

## Evidence requirements (sanitized)

You must capture enough evidence to support each of these claims:

- **Detection**: what signal(s) first indicated the issue.
  - Evidence examples: alarm name + fired timestamp; dashboard screenshot; log query output snippet.
- **Impact**: what users/customers experienced, scope, duration.
  - Evidence examples: error-rate graph; request counts; support ticket timestamps; affected region list.
- **Change correlation** (when applicable): what changed before onset.
  - Evidence examples: deployment record; change ticket; PR/commit link; rollout timeline.
- **Mitigation effectiveness**: what reduced impact and when.
  - Evidence examples: metric inflection after mitigation; rollback completion time.
- **Root cause**: why the system behaved that way.
  - Evidence examples: logs showing failing component; config diff; dependency outage evidence.

You must store local-only evidence (when needed) under the execution baseline’s evidence path and keep it portable:

- Reference: `skills/ocm-dev/execution-baselines-detail.md` (Evidence path)
- Path pattern (local-only; never commit): `.generated/evidence/ocm-ai-pack/<YYYY-MM-DD>/`

## Mutation (publish/update gate)

This workflow is read-only by default.

If you propose any mutation (for example: updating the incident record, posting the postmortem to Confluence, commenting on tickets, changing action-item status), you must stop and apply the mutation gate:

- Reference: `skills/ocm-dev/execution-baselines-detail.md` (Mutation gate)

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

1) Confirm the inputs.
   - Record the incident id, time window, impacted services, and evidence sources.
   - If any input is missing, you must stop and ask for it.

2) Collect the minimum facts (read-only).
   - Capture: detection time, first mitigation time, recovery time, and “all clear” time.
   - Capture: customer-visible symptoms (what broke), blast radius, and duration.
   - Capture: what changed in the environment in the lookback window (deploys/config changes/dependency changes).

3) Build the canonical timeline (UTC).
   - Create a single timeline table with these columns:
     - Time (UTC)
     - Event
     - Evidence link/snippet pointer
     - Notes (optional)
   - Include at minimum:
     - T0 detection
     - Triage start
     - Primary mitigation(s) start/end
     - Recovery milestone(s)
     - Incident close / “all clear”

4) Write impact (customer-first).
   - State impact in plain language first.
   - Then quantify:
     - who/what was impacted
     - where (regions/realms)
     - how long
     - severity (use your incident program’s definition)
   - Link each quantitative claim to evidence.

5) Derive root cause and contributing factors.
   - Write the root cause as a short causal chain:
     - Trigger → Fault → Propagation → Customer symptom
   - Separate:
     - **Root cause** (the primary technical cause)
     - **Contributing factors** (process, tooling, design, or dependency issues)
   - If root cause is not yet proven, you must label it **hypothesis** and list the remaining validation steps.

6) Document mitigations and what worked.
   - For each mitigation:
     - what was done
     - when it started
     - what it changed
     - how you verified improvement (evidence)
   - Explicitly call out any mitigations that were attempted but ineffective (and why).

7) Create action items (corrective + preventive).
   - Use action items to close gaps in:
     - Prevention (reduce likelihood)
     - Detection (reduce time-to-detect)
     - Response (reduce time-to-mitigate)
     - Recovery (reduce time-to-recover)
   - For each action item, you must capture:
     - title (verb-first)
     - owner
     - due date (or target sprint/milestone)
     - priority
     - success metric / verification
     - link to the evidence or symptom it addresses

8) Produce continuity artifacts (when applicable).
   - If the incident spans shifts or has follow-up execution work, you must produce a handoff note:
     - Reference: `workflows/generate-handoff-note.md`

9) (MUTATION; stop + confirm) Publish the postmortem and update incident records.
   - Only do this after explicit confirmation per the mutation gate.
   - Your confirmation request must include:
     - exact target(s) (page/ticket ids)
     - exact content you will post (or a link to the final draft)
     - rollback story (how to revert/undo)
     - evidence you will capture (sanitized)

## Verify

You must verify the postmortem package meets all of the following:

- The document includes: **Inputs**, **Outputs**, **Evidence requirements**, **Steps**, **Verify**, **Done when**.
- Timeline is in **UTC** and includes T0 detection, mitigation start, recovery, and close.
- Every major claim (impact, mitigation effectiveness, root cause) has an evidence pointer.
- Action items have owner + due date + verification criteria.
- Mutation steps (publishing/updates) are gated by `skills/ocm-dev/execution-baselines-detail.md`.

## Done when

- A complete postmortem draft exists and is internally consistent (timeline ⇄ impact ⇄ mitigations ⇄ root cause).
- Evidence pointers exist for all major claims and are sanitized.
- Action items are created with owners, due dates, and verification criteria.
- If publishing was required, it was performed only after explicit mutation confirmation, and the final link(s) are recorded.

## Failure modes

- **Missing or conflicting timestamps.**
  - Recovery: choose one canonical time source (incident record or alert history), convert to UTC, and mark uncertain times explicitly.

- **Root cause not yet proven.**
  - Recovery: label as hypothesis, list validation steps, and ensure action items include “prove/disprove root cause” work.

- **Impact cannot be quantified.**
  - Recovery: state qualitative impact, list what telemetry is missing, and add action items to close measurement gaps.

## References

- OCM execution governance (mutation gate + evidence path): `skills/ocm-dev/execution-baselines-detail.md`
- Handoff continuity: `workflows/generate-handoff-note.md`
- Confluence: OCM Customer Incidents (pageId=17481648649): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=17481648649
- Confluence: OCI incident management baseline (pageId=15136826972): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=15136826972
