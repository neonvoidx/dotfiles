---
name: ocm-ops-triage
description: Use when triaging OCM/OCB incidents such as 5xx spikes, OTS tickets, or customer impact and you need OCM-specific mappings, telemetry context, and handoff queries.
metadata:
  owner: ocm
  last_updated: "2026-03-24"
  triggers: "triage,oncall,5xx,OTS,handoff"
---

## Purpose

Provide OCM oncall triage muscle-memory:

- the canonical service ↔ tenancy ↔ fleet ↔ grafana mappings
- the standard OTS queries
- a repeatable path to: “what happened?”, “who is impacted?”, “what do we hand off?”

## When to use

Use this skill when you need a fast, repeatable way to triage OCM/OCB operational issues, especially when you must:

- map a user-visible symptom (5xx spike, error burst, latency, stuck workflow) to the correct service/fleet/tenancy context
- pull the right OTS tickets quickly (handoff window first, then refine)
- confirm the correct telemetry source (dashboards/metrics) without guessing
- produce a clear on-call handoff note with evidence and next actions

## When not to use

Do not use this skill when:

- you are not doing incident triage (feature work, refactors, design discussions, or general Q&A)
- the task requires writing or changing mappings in this repo (use the appropriate authoring workflow and run validation)
- you cannot name a service/component yet and need discovery first (start by asking for the minimal identifiers: service name, region(s), time window, symptom)
- the incident is clearly outside OCM/OCB scope (route to the owning team rather than inventing mappings)

## Verify

Before you present conclusions in a triage output, perform these checks:

1. **Inputs are explicit**
   - Identify (or ask for) the minimal identifiers: service/component, region(s), environment, and incident window.
   - If you cannot name these, stop and request them (do not guess).
2. **Access is warm (read-only)**
   - Run the relevant warmups from: `skills/ocm-dev/access-warmups-detail.md`.
   - If you encounter 401/403 or empty results due to access, state the boundary and proceed with what is available.

3. **If you changed any runbooks content, run pack validation**
   - Run: `aipack doctor`
   - Do not share or merge changes unless validation passes.

## Failure modes

- **Missing identifiers (service/component/region/window)**
  - Recovery:
    - Stop and ask for the missing identifier(s) (service/component, region(s), environment, time window).

- **Auth/permission failures (cannot access OTS/Grafana/Jira, queries return empty due to access)**
  - Recovery:
    - State the exact access boundary (what you cannot read) and continue with what is available (public logs/metrics you do have, or a minimal handoff note).
    - Request the correct access through the standard on-call process and re-run the same queries once access is granted.

- **Validation failures after editing runbooks (`aipack doctor` fails)**
  - Recovery:
    - Fix the reported issue(s) before proceeding (common causes: invalid frontmatter, absolute paths, or secret-like strings).
    - Re-run `aipack doctor` until it exits 0.

## Canonical references (in this repo)

- Rules:
  - aipack-core: `pack-content-craft` skill (governance criteria in references/)
  - `skills/ocm-dev/access-warmups-detail.md`
  - `skills/ocm-dev/execution-baselines-detail.md`
- Agent: `agents/confluence-navigator.md` (for Confluence search/navigation)
- Handoff template: `skills/ocm-dev/handoff-template.md`

## Triage checklist

1. Identify: service, region(s), start time, current status.
2. Pull tickets:
   - Use the on-call handoff query (last 10h) first.
   - Then refine by component/service + region + incident window.
3. Validate telemetry:
   - Confirm the telemetry you are using matches the region(s) and incident window.
   - If you cannot validate scope, state the gap and what you used instead.
4. Customer impact (if asked):
   - Use evidence-backed identifiers (ticket references, logs/metrics, or explicit input from the incident commander).
   - If a mapping is required but unavailable, state that you cannot determine impact safely without it.
5. Produce handoff:
   - Use the handoff note workflow: `workflows/generate-handoff-note.md`.

## Guardrails

- Don’t guess mappings; cite a source of truth or ask for the missing context.
- Don’t paste secrets/tokens into chat.
- If a repeated triage need emerges, propose an evidence-backed, owned addition via the council process.
