---
name: security-central-context-collection
description: '[Workflow] Read-only workflow to expand Security Central Host/Private IP/PublicIp findings into concrete OCI resource ownership details.'
source_type: workflow
metadata:
    last_updated: 2026-03-10T00:00:00Z
    owner: ocm
---

# /security-central-context-collection

## Scope

- Use this workflow for Security Central tickets where findings are scanner types:
  - `Host`
  - `Private IP`
  - `PublicIp`
- This workflow is read-only and produces an evidence-ready resource inventory.
## When to use

- You have a Jira security ticket (for example `OCMSD-*` or `OCB-*`) and need to identify affected OCI instances quickly.
- You need instance names, compartments, and owner/creator tag signals for triage or handoff.
- You want a repeatable sequence that avoids missing context across Jira, Security Central, and OCI.

## When not to use

- You need to remediate findings (terminate/start/patch/reconfigure resources). This workflow does not mutate state.
- The ticket findings are outside `Host` / `Private IP` / `PublicIp` scope.

## Inputs

- Required:
  - Jira issue key (example: `OCMSD-23336`)
  - Realm (default: `oc1`)
- Optional:
  - Target region (expected from findings; often `us-ashburn-1`)

## Outputs

- A resource table with:
  - finding id
  - instance OCID
  - instance display name
  - lifecycle state
  - compartment OCID + compartment name
  - tenancy OCID
  - tag-derived owner/creator signals (`Oracle-Tags.CreatedBy`, freeform owner tags when present)
  - last seen / last reported timestamp
- A short summary of open findings status and severity.
- Optional (when explicitly approved): Jira comment confirmation (timestamp and comment id/link if available).

## Steps

1. Confirm execution mode is read-only and note evidence location (local-only, sanitized).

2. Fetch Jira issue details and extract the Security Central task link from description/comments:
   - Use `atlassian_jira_get_issue` with at least: `summary,status,description,assignee,priority,duedate,updated`.
   - Parse task URL shape:
     - `https://devops.oci.oraclecorp.com/security/central/<realm>/tasks/<task-id>`
   - Capture `<task-id>`.

3. Fetch Security Central task + findings:
   - `dope_get_security_task_details(realm, taskId)`
   - `dope_get_security_findings(realm, taskId)`
   - Filter/confirm findings where source/type maps to `Host`, `Private IP`, or `PublicIp`.
   - Current known sources in this scope (from Security Central FAQ quick-lookup):
     - `Host`: `Voltron`, `LogManagement`, `NetworkInfrastructure`, `PKI`, `QualysOhai`, `SecurityDataPlatform`, `Manual Detection`
     - `Private IP`: `Nessus`, `QualysInternal`
     - `PublicIp`: `Qualys (External IPs)`, `PCI`, `Manual Detection`

4. Build a resource list from findings:
   - Collect per finding: `id`, `severity`, `status`, `userStatus`, `affectedResource`, `resourceCheckInId`, `lastReportedTimestamp`.
   - Deduplicate by `affectedResource` (instance OCID) to avoid duplicate enrichment calls.

5. Enrich each finding resource using affected-resource lookup:
   - `dope_get_affected_resource_details(realm, resourceCheckinId)`
   - Capture `tenantId`, `compartmentId`, `resourcePrimaryKeyValue`, `owner`, `ownerSource`, `lastSeenTimestamp`.

6. Enrich each instance in OCI:
   - `oci.core.ComputeClient.get_instance(instance_id=<instance-ocid>)`
   - Capture:
     - `display_name`
     - `lifecycle_state`
     - `compartment_id`
     - `defined_tags`
     - `freeform_tags`
     - `system_tags`
   - Extract creator/owner signals in this order:
     - `defined_tags.Oracle-Tags.CreatedBy`
     - `defined_tags.*.owner` / `defined_tags.*.Owner` if present
     - `freeform_tags.owner` / `freeform_tags.Owner` / `freeform_tags.created_by` if present

7. Resolve compartment names:
   - `oci.identity.IdentityClient.get_compartment(compartment_id=<compartment-ocid>)`
   - Capture `name` and `lifecycle_state`.

8. Produce the final inventory table and sanitized summary:
   - Include counts: total findings, open findings, unique resources.
   - Avoid pasting sensitive metadata (for example `ssh_authorized_keys`, `user_data`, credential-like blobs).

9. **(MUTATION; stop + confirm)** If the user requests a Jira comment with the inventory summary:
   - Stop and state: exact ticket key, exact comment text, and rollback story (delete comment if incorrect).
   - Wait for explicit `yes` before calling `jira_add_comment`.
   - After posting, capture the comment reference (ticket key + timestamp).

## Verify

- Jira task link was identified and task id extracted.
- `dope_get_security_task_details` and `dope_get_security_findings` succeeded.
- Every finding has either:
  - a resolved instance + compartment row, or
  - an explicit error note explaining why enrichment failed.
- Output excludes sensitive metadata fields and includes only sanitized evidence.
- If Jira comment step was requested:
  - explicit mutation approval (`yes`) was captured before `jira_add_comment`
  - comment post succeeded and ticket key/comment reference was captured.

## Failure modes

- `401/403` from Atlassian/DOPE/OCI.
  - Recovery: complete sign-in, confirm realm/account context, retry.

- Jira ticket does not contain a Security Central task link.
  - Recovery: inspect comments or linked tickets; if still missing, request task id from ticket owner.

- Findings return non-instance resources or missing `resourceCheckInId`.
  - Recovery: keep row with raw `affectedResource` and continue with partial inventory.

- OCI `get_instance` returns `404`/`NotAuthorizedOrNotFound`.
  - Recovery: verify tenancy/region context and permissions; keep finding in report as unresolved enrichment.

- `jira_add_comment` fails (permission, invalid issue key, or API error).
  - Recovery: confirm MCP allowlist includes `jira_add_comment`, verify ticket key and access, retry with sanitized shorter payload.
