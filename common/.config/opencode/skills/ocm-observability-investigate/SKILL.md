---
name: ocm-observability-investigate
description: '[Workflow] Investigate OCM service symptoms using dashboards, logs, and metrics.'
source_type: workflow
metadata:
    last_updated: 2026-03-09T00:00:00Z
    owner: ocm
---

# OCM observability investigation (dashboards, logs, metrics)

## Purpose

You must use this workflow to investigate OCM service symptoms using dashboards/logs/metrics in an execution-first, evidence-capturing way.

## Scope

- This workflow is **read-only by default**.
- Any annotation, comment, ticket update, or other write action is **MUTATION** and must follow the mutation gate in: `skills/ocm-dev/execution-baselines-detail.md`.
- This workflow does not replace the canonical on-call procedure. You must follow the OCM on-call guide for incident process and comms.

## When to use

- You have an alert/page or user-reported symptom and need to rapidly determine **what is broken**, **where**, **since when**, and **how big**.

## When not to use

- You already have a confirmed root cause and are executing a change/deploy/rollback (use the relevant execution workflow).
- You need to change dashboards, alert rules, or add annotations immediately without time to gate mutation (stop and follow the mutation gate first).

## Prerequisites

- You must follow the execution governance:
  - `skills/ocm-dev/execution-baselines-detail.md`
  - `skills/ocm-dev/access-warmups-detail.md` (run warmups if you will make multiple tool/UI calls)
- You must use the canonical service-to-observability mappings (do not invent IDs): `rules/ocm-team.md`.

## Inputs

- Required:
  - **Service / component** (example: `ocm-migration` API)
  - **Region(s)** (one or more)
  - **Time window** (start/end or “last N minutes/hours”), including timezone
  - **Symptom** (what you saw: 5xx spike, latency, error message, job backlog, etc.)
  - **Dashboards / log sources you can access** (names/URLs at a minimum)
- Optional:
  - Alert name / alarm id
  - Request id / migration id / tenant id / compartment id (only if safe to handle)
  - Recent change candidates (deployments, config flips, infra events)
  - Known-good baseline window (for compare)

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

1) **Set execution mode and evidence plan (read-only first).**
   - Declare execution mode as **read-only execution**.
   - Choose a local-only evidence folder as described in `skills/ocm-dev/execution-baselines-detail.md`.
   - Do not store secrets or sensitive identifiers in evidence.

2) **Normalize the symptom into a single investigation statement.**
   - Write one sentence that includes: service/component + regions + time window + symptom.
   - Example template:
     - "<service>/<component> in <regions> has <symptom> since <timestamp>; investigating impact and likely causes."

3) **Resolve the service mapping (do not guess).**
   - In `rules/ocm-team.md`, look up the service mapping needed for observability navigation:
     - service tenancy name / project / fleet identifiers
     - Grafana panel IDs for 5xx (if relevant)
     - Grafana annotation conventions (dashboard id + tag/comment)
   - Record the mapping values you will use in your notes (not in committed files).

4) **Pick the starting dashboard and establish the “shape of the incident”.**
   - Open the primary service dashboard for the service/component and region(s).
   - Set the time window to cover:
     - the reported window, and
     - at least one compare window (same duration earlier) when possible.
   - Capture evidence:
     - a link to the dashboard with the time range encoded (preferred), or
     - a screenshot showing the time picker, region filters, and the anomalous panel(s).

5) **Check the “golden signals” in a consistent order.**
   - Errors:
     - If this is a 5xx-type symptom, use the canonical 5xx metric mapping from `rules/ocm-team.md`.
     - Compare across regions and identify whether the issue is global or isolated.
   - Latency:
     - Identify whether latency degradation precedes or follows error spikes.
   - Traffic:
     - Confirm if traffic dropped (client-side impact) or stayed constant (server-side issue).
   - Saturation:
     - Check CPU/memory/threadpool/queue/backlog signals relevant to the component.
   - Capture evidence for each signal: at least one panel link/screenshot per signal that supports your claim.

6) **Switch to logs with a tight query and expand carefully.**
   - Start with a narrow query for the time window + region + service/component.
   - Query patterns (choose what matches your tooling):
     - filter by severity (`ERROR`/`WARN`) and service/component name
     - filter by HTTP status class (5xx) or known exception name
     - filter by request id / migration id if you have one
   - Expand only after you have an initial top error signature:
     - group/count by exception or error message
     - sample 3–5 representative log lines (sanitized)
   - Capture evidence:
     - the log query text
     - a screenshot/export snippet that shows timestamped occurrences of the signature (sanitized)

7) **Correlate metrics ↔ logs to identify likely blast radius and candidate causes.**
   - Blast radius:
     - Which regions are affected?
     - Which endpoints/operations are affected (if visible)?
     - Is the impact partial (some AZs/fleets) or total?
   - Candidate causes (do not overfit):
     - dependency failures (DB, queue, upstream service)
     - resource saturation
     - rollout/change correlation (if you have reliable timestamps)
   - Capture a short “impact + hypothesis” note supported by the evidence you saved.

8) **Decide the next action and the escalation target.**
   - If impact is user-visible or sustained, follow the on-call guide for escalation/incident mechanics.
   - Use `rules/ocm-team.md` mappings to route to the right service context (do not guess ownership from names).

9) **(Optional) MUTATION: add a Grafana annotation for the incident window.**
   - This is a write action. You must stop and apply the mutation gate in: `skills/ocm-dev/execution-baselines-detail.md`.
   - Your confirmation request must include:
     - the exact dashboard/target you will annotate (use the canonical dashboard id from `rules/ocm-team.md`)
     - the exact annotation tags/comment convention (from `rules/ocm-team.md`)
     - the exact time window
     - rollback story: delete the annotation if incorrect
     - evidence to capture: link/screenshot of the annotation in place

## Verify

- You must be able to show, using captured evidence, all of the following:
  - The selected dashboard(s) and time window are correct for the symptom.
  - At least one metric view supports the symptom (errors/latency/traffic/saturation).
  - At least one log view supports the symptom (error signature over time), or you documented why logs were unavailable.
  - The impact statement is explicit: affected region(s), timeframe, and approximate severity.
- If you performed any annotation/update, you must have an explicit mutation gate “yes” recorded (per `skills/ocm-dev/execution-baselines-detail.md`).

## Done when

- You produced a one-paragraph investigation summary:
  - what happened (symptom + window)
  - where (regions/components)
  - impact (blast radius)
  - top 1–3 hypotheses with supporting evidence references
  - next action / escalation target
- Evidence is captured in a local-only folder (sanitized) and is sufficient for a handoff.

## Failure modes

- **Dashboards are missing or you cannot find the right service context.**
  - Recovery: use `rules/ocm-team.md` to resolve the service mapping (project/fleet/panel ids). If the mapping is missing, stop and escalate to the owning on-call channel; do not invent IDs.

- **Logs are noisy or do not correlate with the metric symptom.**
  - Recovery: narrow by region/time window first; then pivot from the most anomalous metric to its closest corresponding operation (endpoint/worker/job) and re-query.

- **You need to write an annotation/update quickly.**
  - Recovery: stop, declare mutation intent, and apply the mutation gate in `skills/ocm-dev/execution-baselines-detail.md` before writing anything.

## References

- Governance:
  - `skills/ocm-dev/execution-baselines-detail.md` (mutation gate + evidence expectations)
  - `skills/ocm-dev/access-warmups-detail.md`
- Canonical OCM mappings (service/project/fleet/panels/annotation conventions):
  - `rules/ocm-team.md`
- Canonical on-call procedure:
  - OCM on-call guide (plugin deployment & development): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19047080351
