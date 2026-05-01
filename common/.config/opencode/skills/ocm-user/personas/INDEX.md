# Personas (Target Persona + user model)

Canonical Confluence anchors (OCIMigrationDR):
- Target Persona: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907494
- OCI Migrate User Model: https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=12404907952

## Why this matters
OCM work goes sideways when we confuse *who* we’re talking to.

Most troubleshooting and “Migration Assistant” interactions should start by identifying which persona is driving the request, because the right answer depends on their responsibilities, permissions, and success criteria.

## Primary personas (Target Persona)
1) **Business/Application Owner**
   - cares about cost, timing, and continuity during/post migration.
2) **Cloud Architect**
   - approves mapping into OCI: target networking/topology, shapes, redeploy configuration.
3) **Migration Engineer**
   - executes the runbook steps (pre-migration → execution → post-migration); sysadmin skillset.
4) **Application Administrator**
   - owns day-2 operations: workload-specific reconfiguration and steady-state health.

## How to use this in practice
- If you’re a **Migration Engineer**: you want concrete, step-by-step procedures, checks, and “what do I run next?”
- If you’re a **Cloud Architect**: you want topology options, target shape/resource selection, risk tradeoffs, and approval-ready plans.
- If you’re a **Business Owner**: you want timelines, cost deltas, and risks.
- If you’re an **Application Admin**: you want post-cutover validation, app-specific config deltas, and monitoring.

## OCI Migrate user model (helpful mental model)
The service/user model page frames what the console exposes:
- Projects (top-level container)
- Assets / Inventory (discovered source resources)
- Migration Plans (source→target mapping + replication settings)
- Terraform Templates (desired target config; used by RMS)
- Jobs (execution)
