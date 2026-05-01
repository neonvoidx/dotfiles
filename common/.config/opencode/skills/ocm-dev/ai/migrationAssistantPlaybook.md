# OCM Migration Assistant playbook (MCP + agents)

This is a harness-facing playbook for building and operating an AI-assisted “Migration Assistant” (Console chat, operator copilot, developer helper) in a way that is **useful** and **safe**.

North Star targets (OCM 2026):
- FY28: AI-prompt based chat as Migration Assistant on Console
- FY29+: AI Powered Migration Automation

The premise: you don’t jump from “chatbot” → “autonomous automation”. You build a disciplined pipeline:

1) read-only discovery → 2) draft plan → 3) validate assumptions → 4) gated execution → 5) evidence + rollback story

## 0) Preconditions (don’t skip)

- OCI MCP servers are **disabled-by-default** in this harness.
- OCI work must route through `@oci-ops` (no broad global tool permissions).
- Authentication/tenancy selection must be explicit (profile + region). Session expiry is common.

See:
- OCI MCP server configuration in your harness settings.
- OCI MCP governance anchors: consult the oracle/mcp repo.

Operational truth sources (internal):
- OCM engineering skill: `skills/ocm-dev/SKILL.md`
- OCM ops triage: `skills/ocm-ops-triage/SKILL.md`

## Run template (copy/paste)

### Inputs (must be explicit)
- **OCI profile**: `OCI_CONFIG_PROFILE=<profile>`
- **Region(s)**: e.g. `us-ashburn-1` (and/or others)
- **Compartment scope**: one or more compartment OCIDs (or “root tenancy” if explicitly intended)
- **OCM object(s)** (if known): migrationId / migrationPlanId / workRequestId / asset identifiers
- **Constraint**: read-only vs execution allowed

Persona context (don’t guess):
- `skills/ocm-user/personas/INDEX.md`

### Outputs (what “done” looks like)
- Inventory: relevant OCIDs + lifecycle states + where they live (compartment/region)
- Draft plan: proposed actions + assumptions + required permissions/tools
- Evidence bundle: links/IDs/log pointers + what changed (or what would change)

### Minimal read-only MCP surface (recommended)
Enable only what you need for the workflow:
- `oracle-oci-resource-search` → `search_resources`
- `oracle-oci-identity` → `get_current_tenancy`, `get_current_user`, `list_compartments`, `list_availability_domains`
- `oracle-oci-migration` → `list_migrations`, `get_migration`

Optional (if wired/enabled):
- logging: `list_log_groups`, `list_logs`, `get_log`
- monitoring: `list_metrics`, `get_metric`
- usage/cost: usage report tools

## 1) Read-only discovery (default)

**Goal**: build an accurate inventory + constraints map with minimal blast radius.

Recommended MCP surfaces (read-mostly):
- `oci-resource-search-mcp-server` (find OCIDs, resource graph hints)
- `oci-migration-mcp-server` (migration objects/status)
- `oci-identity-mcp-server` (compartments/tenancy/ADs)
- `oci-compute-mcp-server` (list/get instances, images)
- `oci-networking-mcp-server` (list/get VCN/subnet/NSG/security lists)
- `oci-object-storage-mcp-server` (namespace, buckets, objects)
- `oci-logging-mcp-server`, `oci-monitoring-mcp-server` (observability)
- `oci-usage-mcp-server` (usage/cost context)

Outputs to produce:
- Identified scope: tenancy + compartment(s) + region(s)
- Resource inventory: what exists today, what’s missing
- Risk flags: anything that looks stateful/destructive or cross-realm

## 2) Draft plan (human-readable, tool-addressable)

**Goal**: convert discovery into a plan that can be validated and later executed.

Plan format (suggested):

- **Intent**: what the user wants
- **Assumptions**: what we’re assuming (and need to validate)
- **Proposed actions**: step-by-step
- **Required permissions/tools**: exactly which MCP servers/tools (read vs mutating)
- **Evidence**: what to capture to prove success

When available, cite the canonical runbook(s) for the action you’re proposing (this keeps the assistant aligned with how OCM actually operates).

## 3) Validate assumptions (preflight)

**Goal**: avoid expensive/dangerous execution based on wrong premises.

Checklist:
- Confirm tenancy/compartment/region correctness.
- Confirm policies/permissions for intended tool calls.
- Confirm quotas/limits for target resources (if applicable).
- Confirm network path assumptions (BYOS/BYOL-type prerequisites).
- Confirm that any resource identifiers (OCIDs) were sourced from read-only discovery.

## 4) Gated execution (mutating tools)

**Rule**: execution is opt-in. Mutating tools stay disabled unless explicitly enabled for a scoped workflow.

Mutating surfaces to treat as “high-risk”:
- `oci-api-mcp-server` (arbitrary `run_oci_command`)
- compute launch/terminate/update actions
- networking create/delete operations
- object storage upload operations

Execution protocol:
- Enable only the minimum required mutating tools for this workflow.
- Confirm before each create/update/delete boundary.
- Capture an audit trail: tool + parameters + rationale + result.
- Prefer reversible operations; if not reversible, require an explicit “destructive ok” confirmation.

## 5) Evidence, reporting, rollback story

At the end of any assistant run, produce:
- What changed (or what would change in dry-run mode)
- Where to look (logs, work requests, dashboards)
- Rollback approach (best-effort) and escalation pointers

## Mapping to North Star initiatives

This playbook is the foundation for:
- **FY28 Migration Assistant on Console**: mostly read-only + planning + validation, with narrow execution gates.
- **FY29 AI Powered Migration Automation**: higher automation only after (a) tool surfaces are inventory-backed and (b) execution gates are proven safe.

## Example scenario: triage an OCM migration “stuck” (read-only)

**Goal**: produce an operator-quality triage summary without changing OCI state.

### Step 1 — Identify scope
1) Confirm `OCI_CONFIG_PROFILE` and region.
2) Identify the migrationId (or find it via resource search by displayName/tag).

Expected output:
- migrationId
- lifecycleState
- related work request(s) / resource IDs if present

### Step 2 — Pull migration details
Use `get_migration(migrationId)`.

Expected output:
- state + timestamps
- target environment references
- any error fields surfaced by the service

### Step 3 — Pull supporting signals
Depending on what’s available:
- Resource Search: find related resources (RMS stack, compute instances, volumes, networking)
- Logging: enumerate log groups/logs for relevant compartments
- Monitoring: check for signals consistent with stalled replication / agent health
- Usage (optional): sanity check unexpected cost spikes

### Step 4 — Draft a plan + ask for confirmation
Produce:
- hypotheses (most likely causes)
- what to validate next (and what data is missing)
- what actions would be taken **if** execution is approved (and which mutating tools would be required)
