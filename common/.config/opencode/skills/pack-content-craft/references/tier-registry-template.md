# Tier Registry Template

Template for maintaining a Tier A (BiC) inventory for a pack. Copy this template and populate with your pack's baseline resources.

## Required fields

Every Tier A row must include:

| Field | Description |
|-------|-------------|
| Vector | Construct type (rule, skill, workflow, agent, mcp) |
| Resource ID | File/directory name |
| Owner (DRI) | Directly responsible individual |
| Use-case IDs | Operational mapping (e.g., OPS-01, DEV-04) |
| Success metric | How you know this resource provides value |
| Evidence link(s) | Link to realistic usage evidence |
| Last reviewed | Date (YYYY-MM-DD) |
| Risk labels | Comma-separated: `none`, `needs-owner`, `unverified`, `drift-risk` |
| Rollback/retire condition | When to demote or remove |

## Template table

| Vector | Resource ID | Owner (DRI) | Use-case IDs | Success metric | Evidence link(s) | Last reviewed | Risk labels | Rollback/retire condition |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| rule | example-rule | TBD | OPS-01 | <metric> | TBD | YYYY-MM-DD | needs-owner,unverified | Demote if no owner/evidence by next review |

## Governance

- Review frequency: weekly or per the pack's governance cycle.
- Demotion triggers and promotion criteria: see `governance-criteria.md` in this directory.
