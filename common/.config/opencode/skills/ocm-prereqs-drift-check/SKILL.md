---
name: ocm-prereqs-drift-check
description: '[Workflow] Check OCM prerequisites stack drift (v2.3)'
source_type: workflow
metadata:
    last_updated: 2026-02-23T00:00:00Z
    owner: ocm
---

# OCM prerequisites stack drift check (v2.3)

## Purpose

You must use this workflow to check **prerequisites stack drift** (version alignment, IAM/policy drift, and RMS/Terraform health) **without duplicating** the versioned prerequisites documentation.

## When to use

- You suspect the customer/operator prerequisites stack differs from the expected version (v2.3).
- You are preparing for (or recovering from) a migration and want evidence that prerequisite IAM/RMS state is aligned.
- You need a repeatable, evidence-backed “drift report” before asking for any changes.

## When not to use

- You need to *create or update* the prerequisites stack. This workflow is **read-only by default** and must stop at the mutation gate.
- You are looking for the full prerequisites procedure. Use the versioned Confluence pages linked in **References**.

## Inputs

- Required:
  - **Prereqs doc version**: `v2.3`
  - **Tenancy identifier (non-secret)**: a human-friendly tenancy name/alias for your report (do not store sensitive IDs in committed artifacts)
  - **Region(s)**: one or more regions where prerequisites were applied / where migration will run
  - **RMS context**:
    - stack display-name (or an unambiguous tag/label you can search by)
    - compartment *name* where the stack lives
    - whether the stack is managed via **RMS only** or also via a **local Terraform checkout** (config source)
- **Evidence path (relative)**: where you will write local-only evidence (example: `.generated/evidence/prereqs-drift/<YYYY-MM-DD>/`)

- Optional (recommended):
  - Time window: `<start>..<end>` for “last apply”/job history review
  - Known migration mode(s) in scope: (for example: VMware → OCI, AWS → OCI) so you can focus IAM/policy checks

## Preconditions

1) You must follow:
   - Execution governance + mutation gate: `skills/ocm-dev/execution-baselines-detail.md`
   - Access warmups governance: `skills/ocm-dev/access-warmups-detail.md`

2) If you will use the OCI CLI, you must run the OCI CLI warmup first:
   - `skills/ocm-dev/access-warmups-detail.md (OCI CLI section)`

## Preflight

Verify MCP access for each tool surface used in this workflow. Make one read-only call per surface. If any auth check fails, stop and report before proceeding.

## Steps

1) **Declare execution mode and create an evidence folder (local-only).**
   - Set execution mode to: **read-only execution**.
   - Create your evidence directory and keep all outputs there.
   - You must not commit evidence; it may include sensitive identifiers.

   Example (portable):

    ```bash
    DATE="$(date -u +%Y-%m-%d)"
    EVIDENCE_DIR=".generated/evidence/prereqs-drift/${DATE}"
    mkdir -p "${EVIDENCE_DIR}" "${EVIDENCE_DIR}/rms" "${EVIDENCE_DIR}/iam" "${EVIDENCE_DIR}/diffs"
    ```

2) **Pin the expected prerequisites spec (do not copy it).**
   - Open the Confluence prerequisites page for the selected version (see **References**).
   - In `${EVIDENCE_DIR}/expected.md`, record:
      - which version you are validating against (`v2.3`)
     - links to the specific sections/tables you will compare against (IAM policies, dynamic groups, variables/outputs)
     - the *names* of the expected IAM resources (policy names, dynamic group names) you will check
   - Do not paste full policy statements or full variable tables; reference the anchors instead.

3) **Locate the RMS stack and capture stack metadata (sanitized).**
   - Find the stack by display-name/tag/compartment using the Resource Manager Console *or* OCI CLI.
   - Capture:
     - stack display-name
     - compartment name
     - stack lifecycle state
     - creation time / last update time
     - terraform version (as configured in RMS)

   If using OCI CLI, store raw JSON locally, and sanitize before copying snippets into any report:

   ```bash
   # Set STACK_ID from a list/search step (do not paste IDs into committed files).
   oci resource-manager stack get \
     --stack-id "${STACK_ID}" \
     --output json > "${EVIDENCE_DIR}/rms/stack.get.json"
   ```

4) **Version alignment check (v2.3).**
   - Determine which prerequisites stack version is actually deployed.
   - Prefer (in order):
     1) an explicit Terraform output/variable indicating the prerequisites stack version
     2) an RMS stack tag/label indicating the version
     3) the Terraform config source reference (if the stack tracks a specific repo path/commit/tag)
   - Record your “version determination method” and result in `${EVIDENCE_DIR}/diffs/version.md`.

   Notes:
   - If you cannot determine the version reliably, treat it as drift and escalate to a prerequisites stack owner.
   - Drift hotspot reminder: dynamic groups + policy statements often drift between versions.

5) **IAM drift check: policies, dynamic groups, and groups (read-only).**
   - Export the current IAM configuration relevant to prerequisites.
   - Produce **diff-friendly** text views, then compare them to the expected names/sections you recorded in `${EVIDENCE_DIR}/expected.md`.

   Minimum checks (you must record pass/fail for each):
   - Policies: expected policies exist, and statements match the expected version.
   - Dynamic groups: expected dynamic groups exist, and matching rules align.
   - Groups (if used by the stack): expected groups exist and memberships are plausible.

   Example export shape (adjust scope to your tenancy conventions):

   ```bash
   # Store raw JSON locally.
   oci iam policy list --all \
     --compartment-id "${ROOT_COMPARTMENT_ID}" \
     --output json > "${EVIDENCE_DIR}/iam/policies.list.json"

   # Create diff-friendly extracts.
   jq -r '.data[] | .name' "${EVIDENCE_DIR}/iam/policies.list.json" | sort \
     > "${EVIDENCE_DIR}/diffs/policy.names.txt"
   ```

   Sanitization requirement:
   - If any stored output includes sensitive identifiers, you must sanitize before sharing.
   - Do not paste raw JSON outputs into tickets/PRs/chat.

6) **RMS validation (read-only): last job health and state sanity.**
   - Identify the most recent RMS job(s): apply, plan, or other.
   - Record:
     - last successful apply time (if any)
     - last failure time + error summary (if any)
     - whether the stack is currently locked by an in-progress job

   Example:

   ```bash
   oci resource-manager job list --all \
     --stack-id "${STACK_ID}" \
     --output json > "${EVIDENCE_DIR}/rms/jobs.list.json"
   ```

7) **MUTATION GATE: optional drift detection / plan job (stop + confirm).**
   Running a Terraform **plan** via RMS does not apply changes, but it **does create a new RMS job** and may write artifacts.

   - If you decide to run a plan/drift job, you must stop and follow the mutation gate in:
     - `skills/ocm-dev/execution-baselines-detail.md`

   Your confirmation request must include:
   - target stack (by display-name + compartment name)
   - action: “create RMS plan job (no apply)”
   - expected outcome: “plan output showing zero changes” (or a bounded set of expected diffs)
   - rollback story: “cancel the plan job; no resources are modified because apply is not executed”
   - evidence to capture: plan summary + sanitized diff list

   If approved, run the plan via the Resource Manager Console (preferred) or OCI CLI, then store the plan artifacts under `${EVIDENCE_DIR}/rms/`.

8) **Write a drift report (single artifact).**
   - Create `${EVIDENCE_DIR}/prereqs-drift-report.md` with:
     - Inputs (version, tenancy alias, regions, stack display-name/compartment)
     - Version alignment result (and how you determined it)
     - IAM drift results (policies / dynamic groups / groups) with clear pass/fail bullets
     - RMS validation result (last job health)
     - Findings summary (what is drifting, severity, and recommended next actions)
     - Mutation recommendation (yes/no) and the exact change owner to engage

## Verify

- You must produce these local-only artifacts under your evidence path:
  - `expected.md`
  - `diffs/version.md`
  - `prereqs-drift-report.md`

- Pass criteria:
  - The report clearly states which prereqs version it validated against (v2.3).
  - The report includes explicit pass/fail for version alignment, IAM checks, and RMS validation.
  - Any mutation-intent step is either:
    - not executed, or
    - explicitly approved using the mutation gate in `skills/ocm-dev/execution-baselines-detail.md`.

## Done when

- You have a completed `${EVIDENCE_DIR}/prereqs-drift-report.md`.
- You have enough evidence to answer: “What is drifting, where, and what is the minimum fix?”
- If drift requires changes, you have a mutation plan ready (but not executed) with rollback story and evidence plan.

## Failure modes

- **Cannot locate the RMS stack unambiguously.**
  - Recovery: search by compartment + tags; confirm with the operator/customer which stack display-name is canonical; do not guess.

- **OCI CLI returns 401/403 or prompts for auth repeatedly.**
  - Recovery: run `skills/ocm-dev/access-warmups-detail.md (OCI CLI section)` again and confirm you are using the intended profile/region.

- **Evidence contains sensitive identifiers.**
  - Recovery: keep evidence local-only; sanitize before sharing; do not copy raw outputs into committed artifacts.

## References

- Governance (read-only by default; mutation gate):
  - `skills/ocm-dev/execution-baselines-detail.md`
  - `skills/ocm-dev/access-warmups-detail.md`

- Warmup (OCI CLI):
  - `skills/ocm-dev/access-warmups-detail.md (OCI CLI section)`

- Versioned prerequisites docs (do not duplicate; compare against these):
  - Creating Migration Prerequisites v2.3 (pageId=19254551310): https://confluence.oraclecorp.com/confluence/pages/viewpage.action?pageId=19254551310
