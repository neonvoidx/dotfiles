# OCM operational scripts (public)

Repo: https://github.com/oracle-quickstart/oci-cloud-migrations (Scripts/ directory)

## Why this matters
This directory is a “treasure trove” of codified, repeatable operational logic for OCM workflows. It’s useful for:
- maintainers (ocm-dev) who want predictable, automatable operations and reproducible runbooks
- users/operators (ocm-user) who want safe, documented ways to perform common tasks outside the console

## Entry point
- Start with the upstream index: `Scripts/README.md` in the repo

## Safety rubric
- `safetyRubric.md`

## High-signal scripts to know
- `automated_migration/` — step-by-step workflow scripts (administrator/operator/cutover) (**mutating**, often **destructive**)
  - workflow overview: `automated_migration/workflow.md`
  - examples create:
    - environments, dependencies (VDDK), asset source credentials (vault secrets)
    - migrations/migration plans + replication start
    - RMS stack generation (execute plan)
  - IMPORTANT: these are reference scripts; review before running (they contain environment-specific auth toggles).

- `find_asset/` — locate migration assets across compartments by source identifiers (**read-only**)
- `audit_log_search/` — audit log searches (**read-only**)
- `boot_order/` — adjust boot disk order based on `compute.disks` (**mutating**, reversible)
- `SetIP/` — assign target IPs (source IP, map file, free-form tags, vCenter attribute) (**mutating**, reversible)
- `rename_move_volumes/` — rename/move volumes attached to an instance (**mutating**, reversible)
- `cleanup_volumes/` — terminate unattached volumes (**destructive**)
- `terminate_nat_gateway/` — workaround for hydration agent default VCN (RMS) (**destructive**)
- `ChangeBlockTracking/` — configure CBT on multiple VMs in vCenter (**mutating**, potentially broad)
- `create_custom_image/`, `os_update_instance/` — Windows migration image/OS update automation (**mutating**, potentially risky)

## Pattern to reuse in skills
Skills can bundle scripts directly.
- For local skills, prefer *small wrappers* that call into a pinned local clone path, and keep the canonical logic in the upstream repo.
- Always document required auth mode and blast radius.

## Internal ops tooling
For internal platform/release automation (Makefile-driven):
- See the ocm-ops-tools repo
