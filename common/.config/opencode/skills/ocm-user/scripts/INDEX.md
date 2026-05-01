# Operational scripts (public)

Local clone:
- `~/src/gh/oracle-quickstart/oci-cloud-migrations/Scripts`

Upstream index:
- `Scripts/README.md` (inside that repo)

## When to use scripts
- You need a **repeatable**, auditable operation that the console doesn’t make easy.
- You’re operating at scale (many assets/plans) and want consistency.

## Safety rules
- Treat these as reference scripts: read before running.
- Prefer running in CloudShell when the script is written for CloudShell.
- Confirm which auth mode it uses (delegation token, instance principal, local OCI config).

Safety rubric (read this once, then reuse it):
- `../../ocm-dev/safety-rubric.md`

## High-signal workflows
- Automated migration workflow: `automated_migration/workflow.md`
- IP assignment strategies: `SetIP/README.md`

## High-signal scripts (and what they do)
- `find_asset/` (**read-only**): find migration assets by source identifiers.
- `boot_order/` (**mutating**): adjust boot order for a VM asset.
- `SetIP/` (**mutating**): manage target private IP assignments in a migration plan.

Avoid unless you fully understand the blast radius:
- `cleanup_volumes/` (**destructive**)
- `terminate_nat_gateway/` (**destructive**)
