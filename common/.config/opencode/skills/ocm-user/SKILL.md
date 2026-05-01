---
name: ocm-user
description: Use when guiding OCM operators through prerequisites, migration execution, troubleshooting, or public script-based automation when the console workflow is insufficient.
metadata:
  owner: ocm
  last_updated: 2026-03-09
  audience: users
  workflow: ocm, migration
---

## Start here
- `INDEX.md`

## When to use
- You are an OCM operator/end user and need step-by-step guidance for prerequisites, migration execution, or post-run cleanup.
- You need predictable, repeatable automation (public scripts) for tasks that are error-prone in the console UI.
- You need troubleshooting guidance that maps symptoms to actionable next steps.

## When not to use
- You are implementing or changing OCM services, APIs, or infrastructure (use engineering runbooks/skills instead).
- You need internal-only tooling, privileged access, or non-public automation. This skill is intended to point to **public, reproducible** operator flows.
- You are about to paste credentials, tokens, OCIDs, or customer-identifying data into an AI session. Stop and use sanitized placeholders.

## Verify
- You are following the correct stage for your situation (prereqs → execution → validation → cleanup). Start from `INDEX.md` if unsure.
- Any referenced script is:
  - present in this skill’s documented `scripts/` location, and
  - intended to be run locally (not copied into the pack output).
- You have the required prerequisites and access before execution (auth configured, correct tenancy/region selected, and required permissions granted).
- The run produced the expected artifacts (logs/outputs) in the location documented by the specific guide you followed.
- If you changed anything in this pack (including this file), run: `aipack doctor`.

## Failure modes
- Missing prerequisites (auth not configured, permissions missing, required tooling absent)
  - Recovery: return to the prerequisites section for the specific guide, complete the missing setup, then retry from the last safe checkpoint.
- Wrong environment/target (wrong region/tenancy/stack)
  - Recovery: stop immediately; re-select the intended target, then re-run only the read-only/validation steps before any mutating action.
- Script fails or produces incomplete output
  - Recovery: capture the exact command + error output, consult `troubleshooting/` for the matching symptom, and re-run after fixing inputs/flags.
- Output is ambiguous (console state and script output disagree)
  - Recovery: trust the guide’s validation steps; re-run the validation checks, and do not proceed until the discrepancy is resolved.

## Facet directories
- `docs/` — public docs map by stage
- `scripts/` — operational automation (public oracle-quickstart scripts)
- `troubleshooting/` — common failure modes + where to look
- `personas/` — target personas and user models for tailoring outputs
