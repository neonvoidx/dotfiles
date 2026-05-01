---
name: scm-git-setup
description: Setup handoff for scm-git when SCM pull request review is blocked on missing CLI or OCI session authentication.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## Scope

- Use this reference only when `scm-git` is required for SCM PR review and is either missing or failing on authentication.
- Do not proceed with SCM PR review until this setup blocker is resolved.

## When to stop and hand off

- `scm-git` is not on `PATH`
- `scm-git` command invocation fails because the binary is not installed
- `scm-git` reports `ERROR: No valid oci session`
- SCM CLI cannot authenticate against OCI DevOps SCM

## Required handoff

- Tell the user to set up SCM CLI first using the Confluence page:
  - `SCM Git Operations with SCM CLI`
  - `https://confluence.oraclecorp.com/confluence/display/DLCSCM/SCM+Git+Operations+with+SCM+CLI#tab-MacOS`
- For macOS, the documented setup includes:
  - downloading the correct `scm-git` binary for Apple Silicon or Intel
  - moving it into `/usr/local/bin/scm-git`
  - making it executable
  - clearing macOS quarantine if needed
  - verifying the command by running `scm-git`
- The documented prerequisites also require an OCI CLI session via `oci session authenticate`.

## Resume condition

- Resume SCM PR review only after the user confirms:
  - `scm-git` runs successfully
  - OCI session authentication is valid

## Verification

- `command -v scm-git` returns a path
- `scm-git` runs without install-time execution errors
- SCM review commands no longer fail on missing binary or OCI session auth
