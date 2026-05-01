---
name: ocm-docs-drift-check
description: '[Workflow] Execution-first docs drift check: map product/ops changes to required documentation updates with evidence'
source_type: workflow
metadata:
    last_updated: 2026-03-09T00:00:00Z
    owner: ocm
---

# OCM docs drift check (product/ops → documentation)

## Scope

- This workflow applies to **documentation drift checks**: mapping a concrete product/ops change to the documentation that must be updated.
- This workflow is **read-only by default**. Use the Confluence UI (and repo browsing) for discovery.
- Any publishing (Confluence edits, PR push/merge, ticket transitions/comments) is **MUTATION** and must be gated (see Mutation gate reference below).

## When to use

- You must use this workflow when:
  - A change shipped (or is planned) and you need to prove docs are still accurate.
  - Oncall / operators report “the runbook is wrong” or “the UI changed”.
  - A release, incident, or migration outcome suggests guidance needs correction.

## When not to use

- You must not use this workflow for “docs improvement” with no triggering change or evidence.
- You must not publish updates during discovery-only execution.

## Prerequisites

### Inputs (required)

- **Change summary**: what changed, when, and why (release note, PR links, incident ID, or internal announcement).
- **Affected services/components**: list the OCM service(s) and any adjacent dependencies.
- **Doc targets**: initial guess list of pages/docs that might be impacted (Confluence pages, READMEs, runbooks, public docs).
- **Evidence path (sanitized, local-only)**: where you will store drift evidence and the drift report.
- Recommended (local-only; never commit): `.generated/evidence/ocm-ai-pack/<YYYY-MM-DD>/ocm-docs-drift-check/<change-id>/`

### Inputs (optional)

- **Owner routing hints**: known owner(s), Slack channel(s), or team alias.
- **Time window**: start/end timestamps for the change and observed behavior.

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

1) **Create an evidence folder and start a drift report.**
   - In the evidence path, create a file named `drift-report.md`.
   - You must record at the top:
     - change summary (1–3 bullets)
     - affected services/components
     - initial doc targets
     - execution mode: `read-only` (default)

2) **Identify doc targets (expand the target set).**
   - Start from these canonical routing anchors:
     - OCM Jump Page (pageId=12404907434)
     - Technical Content dashboard (pageId=12404907423)
   - For each affected service/component, you must add candidate targets in `drift-report.md`:
     - primary Confluence page(s)
     - runbooks / operator docs
     - any “must-link” child pages or dashboards that operators rely on

3) **Assess staleness for each doc target (read-only).**
   - For each target, you must capture staleness evidence in `drift-report.md`:
     - “What the doc claims” (quote a short excerpt)
     - “What reality is now” (your observed behavior, release note excerpt, or code/config evidence)
     - last-updated metadata (last updated date + last updated by)
   - You must assign one status per target:
     - `OK` (still correct)
     - `STALE` (must update)
     - `OBSOLETE` (should be retired or replaced)
     - `UNKNOWN` (needs an owner response)

4) **Draft updates (do not publish).**
   - For each `STALE` or `OBSOLETE` target, you must draft:
     - proposed new text (or a replacement outline)
     - link fixes (add/remove/redirect)
     - owner/contact for review
   - You must keep the draft in a shareable place:
     - For Confluence updates: draft text in `drift-report.md` (or a separate `draft-<pageId>.md`).
     - For repo docs: prepare a local diff/branch, but **do not push**.

5) **Verify links and references (read-only).**
   - You must verify that:
     - each Confluence URL resolves and points to the intended page
     - any referenced runbooks/READMEs exist and are reachable
     - your drift report contains a status and an evidence snippet for every target

6) **MUTATION (stop + confirm): publish updates.**
   - If you will publish any update (Confluence edit, PR push, PR merge, comment, ticket change), you must apply the mutation gate from:
     - `skills/ocm-dev/execution-baselines-detail.md#mutation-gate-explicit-stop`
   - You must not proceed until you have explicit approval (“yes”) that includes targets, actions, expected outcome, rollback story, and evidence capture plan.

## Verify

- You must verify success by confirming these files exist under the evidence path:
  - `drift-report.md`
- Pass criteria:
  - The drift report includes: change summary, affected services/components, doc targets, status per target, and staleness evidence per target.
  - All Confluence anchors used for routing are recorded as links in the report.
  - No mutation was performed unless explicitly approved via the mutation gate.

## Done when

- Every doc target is categorized as `OK`, `STALE`, `OBSOLETE`, or `UNKNOWN` with evidence.
- Draft text exists for every `STALE`/`OBSOLETE` target.
- A publish plan exists (or a recorded decision not to publish), and any mutation is gated per the execution baselines.

## Failure modes

- **You cannot find the right doc owner / canonical page.**
  - Recovery: start from the Technical Content dashboard, identify the nearest owning group, and record `UNKNOWN` with a concrete “who/what question” in the drift report.

- **The change is real but evidence is not shareable (contains secrets or forbidden identifiers).**
  - Recovery: do not store the raw output. Summarize the evidence at a higher level (what you observed + where it was observed) and record the limitation.

## References

- Governance (mutation gate, evidence expectations): `skills/ocm-dev/execution-baselines-detail.md`
- OCM Jump Page (canonical routing): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907434
- Technical Content dashboard (doc ownership routing): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907423
