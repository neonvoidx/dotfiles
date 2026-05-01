# Safety rubric for OCM scripts

This rubric is used across:
- public scripts in the `oracle-quickstart/oci-cloud-migrations` repo (Scripts/)
- internal operator automation in the `ocm-ops-tools` repo

## Classification labels

### Read-only
Only reads/list/search/report operations.

✅ OK to run with broad scope (still prefer a single compartment where possible).

### Mutating (reversible)
Creates/updates resources or configuration in a way that is generally reversible (rename/move/update metadata, create a *new* resource).

⚠️ Requires:
- explicit scope (compartment/region/resource IDs)
- a clear “undo” story
- confirmation before applying changes

### Mutating (destructive)
Deletes/terminates resources, changes Terraform state, bounces services, removes logs/objects, or otherwise makes changes that are hard to reverse.

🛑 Requires:
- explicit “destructive ok” confirmation
- narrow scope (single resource IDs)
- preflight validation + evidence capture

### Fleet-wide / operationally sensitive
Potentially impacts many tenancies/regions/services (deploy/bounce/region builds, broad cleanup).

🛑 Requires:
- operator approval
- explicit rollout/rollback plan
- announcement/escalation discipline (team-specific)

## Preflight checklist (run every time)

1) **Read the script** (treat as reference).
2) Confirm **auth mode** (CloudShell vs local OCI config vs delegation token vs instance principal).
3) Confirm **scope** (tenancy/compartment/region/resource IDs) and set **limits** (page size, max results).
4) Identify **blast radius** (what it can create/update/delete).
5) Look for **dry-run / confirm flags**. If none exist, default to “plan-only” mode.
6) Capture **evidence**: inputs, selected IDs, and outputs (work requests, logs, resource states).
7) Write the **rollback story** (even if it’s “best-effort only”).
