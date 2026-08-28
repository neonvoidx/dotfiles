<!-- aipack managed; DO NOT EDIT by hand -->
# aipack managed rules (flattened)

<!-- source: global-routing.md -->
---
name: global-routing
description: Shared Codex starter routing, precedence, memory, and skill activation guidance for this repository.
---

## Workflow Preference Routing

Unless otherwise noted, paths in this file are relative to this repo root.
Use relative paths for references inside this repository when the target is unambiguous from the shared root. Keep absolute paths only when the absolute location is operationally important or when an exact command/pattern match requires it.

This file is the global entry point. Use it to route to workflow-specific preferences in:
- the `planning` workflow
- the `testing` workflow
- the `debugging` workflow
- the `feature` workflow
- the `refactor` workflow
- the `review` workflow
- the `release` workflow
- the `docs` workflow

### Routing Rules
- Always apply global rules in this file first.
- Then load the most relevant workflow guidance based on the user request.
- If the user primarily asks for a plan, implementation strategy, breakdown, or sequencing, route to the `planning` workflow.
- If the request clearly matches a skill, route it using the `Skill Routing` section below.
- If multiple actions apply, combine files in this order:
  1. the `debugging` workflow (if there is a failure)
  2. the `planning` workflow (if the primary need is analysis, implementation planning, or sequencing)
  3. the `feature` or `refactor` workflow (implementation type)
  4. the `testing` workflow (test creation/validation/coverage)
  5. the `review` workflow (review pass)
  6. `PR Description` skill (PR body generation)
  7. the `release` workflow (release/deploy)
  8. the `docs` workflow (documentation output)
- If no specific workflow is clear, default to the `feature` workflow.

### Precedence Rules
- Current user instructions override everything.
- Repo-level `AGENTS.md` (if present) overrides these global preferences for that repo.
- This global `AGENTS.md` overrides workflow-file defaults.
- Keep detailed planning preferences only in the `planning` workflow to avoid duplication.
- Keep detailed testing preferences only in the `testing` workflow to avoid duplication.
- When imported external rules conflict with local workflow-file execution requirements, follow the local workflow file unless this file explicitly overrides it.

### Command Preference
- When running Python commands, always use `python3` (not `python`) unless the user explicitly asks otherwise.

### OCI Session Recovery
- For auth-gated OCI workflows that use the `oc1` profile, prefer the MCP `refresh_oci_session` tool when available.
- Default recovery behavior is equivalent to the user request: "please fix my local OCI profile now, even if it needs browser auth."
- Invoke the refresh flow with interactive authentication allowed, using `profile_name=oc1`, `tenancy_name=bmc_operator_access`, `region=us-ashburn-1`, and `session_expiration_in_minutes=60` unless the user gives different values.
- After the MCP refresh or browser authentication flow finishes, validate with `oci --profile oc1 session validate --local` before continuing.
- If the MCP tool is unavailable, fall back to `oci --profile oc1 session refresh`; if that cannot refresh the session, report the exact blocker and the manual authenticate command needed.

### Browser Escalation Preference
- For browser-backed tasks such as Playwright extraction, Chrome or Chromium launches, DevTools sessions, or SSO-backed page fetches, try the command in the normal sandbox first.
- If the browser launch or profile access fails because of sandbox or host restrictions, prefer rerunning only that command with per-command elevated permissions instead of changing the whole session to full-access mode.
- When the harness supports command-level escalation, request it only for the browser command and include a short justification tied to the task.
- Prefer temporary browser profiles, cookie files, and output paths in writable locations when that is sufficient.
- Do not ask for full-access sandbox unless the scoped elevated retry still cannot satisfy the workflow or the task genuinely requires broader filesystem access.

### Workspace Rule Discovery
- When the agent starts in a specific workspace, perform project-local rule discovery before workflow routing.
- Discovery order:
  1. Repo-level `AGENTS.md` (if present).
  2. Project rule directories/configs (if present), including `.clinerules/`, `.cursor/rules/`, and other workspace-local agent config files.
  3. Then apply global routing and imported external rules from this file.
- If project-local rules conflict with global defaults, follow repo-local rules for that workspace and document the effective precedence when relevant.

## AIPack Structure Validation

- Treat `AGENTS.md`, `workflows/`, `agents/`, `skills/`, and `pack/dev-starter/` as one shared AIPack-managed surface.
- When changing shared guidance or packaged skill content, edit the source-of-truth files first and then verify the pack layout still exposes the same content correctly.
- For `skills/*`, remember `pack/dev-starter/skills/*/` uses real pack directories with individually tracked symlinks back to the source skill files. New files added under a source skill directory are not automatically available in the pack.
- When a change touches any shared skill, workflow, agent, or routed guidance that should ship through AIPack, validate before finishing:
  - bump `pack/dev-starter/pack.json` to the next appropriate version whenever the shipped AIPack content changes, including `AGENTS.md`, `workflows/`, `agents/`, `skills/`, `pack/dev-starter/mcp/`, `pack/dev-starter/profiles/`, `pack/dev-starter/configs/`, or packaged metadata
  - check the relevant source and pack file sets for the touched area and confirm there are no unintended missing pack files
  - verify the corresponding pack symlinks resolve to the intended source files
  - if shared Codex settings changed in `config.example.toml`, review `pack/dev-starter/configs/codex/config.toml` and update the committed AIPack settings file when those shared defaults should also ship through the pack
  - if a source file is intentionally not packaged, call that out explicitly instead of silently leaving the pack incomplete
- Prefer targeted structural validation over running a full `aipack sync` unless the user explicitly asks for installation-level verification.
- Do not change service-specific example configs just to satisfy packaging validation. Fix the pack structure or the shared source-of-truth mapping instead.

## Imported External Rules

External rule packs can be vendored or symlinked into:
- `imported_rules/cline_rules`

If that directory is present, apply these files in addition to local workflow files:
- Feature/refactor/testing work:
  - `imported_rules/cline_rules/GENERIC_CODE_RULES.md`
- Review work:
  - `imported_rules/cline_rules/CLEAN_CODE.md`
  - `imported_rules/cline_rules/PR_REVIEW_RULE.md`

If the directory is absent, skip those imports.

## Global Learning Memory Protocol

Goal: Make Codex more stable over time by persisting durable learnings so the same issue is not re-solved repeatedly.

### Memory Files
- Global memory file: `memory.md`
- Project-local memory file (optional): `<repo>/memory.md`
- If both exist, read global first, then local.

### Start-of-Task Behavior
- Before implementing, perform project-local rule discovery first (as defined in `Workspace Rule Discovery`), then scan memory.
- After rule discovery, quickly scan memory for matching keywords (domain, tool, error message, component name).
- Reuse prior proven fixes and known constraints before trying new experiments.
- If memory guidance conflicts with current repo reality, prefer current code and add a correction note to memory.

### What Must Be Written to Memory
Write to memory when you learn something durable, especially:
- Root cause + fix for a bug that is likely to reoccur.
- Environment/setup gotchas (versions, flags, auth, paths, platform quirks).
- Reliable debugging tactics that saved significant time.
- Domain-specific rules or business constraints discovered during work.
- Regressions or anti-patterns to avoid.

Do not write:
- Secrets, tokens, private keys, credentials, personal data.
- One-off noise or temporary details with no reuse value.

### Memory Entry Format
Use this compact template for each new learning:

```md
## [YYYY-MM-DD] <Short title>
Context: <project/domain/scope>
Signal: <error/symptom/trigger>
Root cause: <why it happened>
Fix: <what worked>
Verification: <how it was validated>
Reuse hint: <when to apply this in future>
```

### Update Rules
- Append new entries; do not rewrite history unless correcting incorrect guidance.
- Before appending, check for an existing matching entry and update it instead of duplicating.
- Keep entries concise and actionable.
- If confidence is partial, label it clearly as `Hypothesis` until confirmed.

### End-of-Task Behavior
- If new durable knowledge was discovered, update memory in the same turn before finishing.
- In final response, include a brief `Memory updated` note listing entry title(s).

## Skill Routing

- Use the explicit skill routes in this section when the request clearly matches a supported skill.
- Repo-local wrapper skills may override these global skills for workspace-specific defaults. When both exist, prefer the repo-local wrapper inside that workspace and keep the global skills as the fallback.
- For skills not listed here, rely on the skill system's normal discovery and explicit user invocation.

### Codex Bootstrap

- Route shared Codex onboarding, local config generation, placeholder replacement, and skill-path setup requests to `skills/codex-bootstrap/SKILL.md`.

### Internal Confluence Page

- Route authenticated internal Confluence page extraction, markdown conversion, and summary or analysis requests to `skills/internal-confluence-page/SKILL.md`.

### Object Store

- Route Oracle Object Storage discovery, namespace lookup, bucket and object access, and object-backed log retrieval requests to `skills/object-store/SKILL.md`.

### Service OKE Realm Setup

- Route service OKE access setup, reactivation, kubeconfig switching, Kubernetes `kubectl` verification, service JIT/session/tunnel handoff commands, service SSH host entries, OKE/database tunnel setup, and per-realm kubeconfig backup requests to `skills/service-oke-realm-setup/SKILL.md`.
- Use it when the user asks for `kubectl ... on ocNN`, OKE setup for a realm, or service-specific OKE access for AAT, Phonebook, or another named service.

### OTS Ticket

- Route Oracle Ticketing Platform ticket lookups, project reads, comment and activity-history inspection, TQL searches, dashboard or subquery listing, linked-ticket reads, and attachment fetch requests to `skills/ots-ticket/SKILL.md`.

### Jira Ticket

- Route Jira ticket search, JQL construction, issue reads, comment reads, activity-history inspection, Jira comment posting workflows, and explicit Jira status or label mutations to `skills/jira-ticket/SKILL.md`.

### CM Review

- Route change-management ticket review requests to `skills/cm-review/SKILL.md`.
- Use it when the task is to review a CHANGE or CM ticket against its description, implementation, validation, rollback, Shepherd release scope and plan diffs, regional outliers, manual data-fix or host-maintenance procedures, team-specific runbook alignment, or commit and artifact alignment.

### Create Module Knowledge Skills

- Route repository module discovery, module-specific Codex skill creation, repo `AGENTS.md` skill routing, and drift-maintained module knowledge packs to `skills/create-module-knowledge-skills/SKILL.md`.

### Repository Version Preflight

- Use `skills/repository-version-preflight/SKILL.md` as a support skill when another skill declares a `Repository version source` and must warn whether the active local skill is stale or unverifiable.

### On-Call Investigation

- Route incident triage and multi-signal on-call investigation requests to `skills/oncall-investigation/SKILL.md`.

### Existing PR Review Requests

- When the user asks to review an existing pull request URL or says "review this PR", treat the primary intent as a full code-change review, not as provider API operations.
- Prefer a dedicated PR review skill or workflow when one is available in the current environment, even if that capability is supplied by another repo, pack, plugin, or local installation.
- Use provider PR operation skills only as supporting API tooling for metadata, diffs, comments, replies, or review markers unless the user explicitly asks only for those API operations.
- If no dedicated PR review capability is available, combine the generic `review` workflow with the relevant provider PR operation skill to gather evidence and produce findings.

### PR Description

- Route PR body or PR description drafting requests to `skills/pr-description/SKILL.md`.
- When the user asks to create, open, or update a pull request, always run this skill first unless they explicitly ask for a non-template PR description.
- Use template: `skills/pr-description/templates/pr_description.md`.
- Populate from current branch commit range and diffs against base (`origin/main`, fallback `origin/master`).

### SCM PR Operations

- Route OCI DevOps SCM pull request API operations, including PR lookup, metadata reads, PR creation, comment retrieval, and threaded reply posting, to `skills/scm-pr/SKILL.md`.
- Use this as SCM PR API tooling only. Do not select it as the primary workflow for analyzing a PR diff or performing code review when a dedicated PR review capability is available.

### Bitbucket PR Operations

- Route Bitbucket pull request API operations, including PR lookup, metadata reads, comment retrieval, and prefixed reply posting, to `skills/bitbucket-pr/SKILL.md`.
- Use this as Bitbucket PR tooling only. Do not select it as the primary workflow for analyzing a PR diff or performing code review when a dedicated PR review capability is available.

### Release Check

- Route Shepherd release-link audits and rollout investigations to `skills/release-check/SKILL.md`.
- Use it when the task is to inspect a Shepherd release URL or identifiers for scope, phase or target status, per-region diffs, execution errors, target logs, validations, timelines, or rollout recommendations.

### MFO Region Build Status

- Route DevOps MFO or region-build flock dependency investigations to `skills/mfo-region-build-status/SKILL.md`.
- Use it when the task is to inspect a region-build flock page, summarize satisfied, unsatisfied, and optional capability dependencies across phases, trace capability producers recursively, or explain which upstream project or flock is blocking publication.

### AuthZ Permissions YAML Generator

- Route Identity AuthZ Enablement tickets that require generating or updating `ID-*.yaml` resourceOperations files to `skills/authZ-permissions-yaml-generator/SKILL.md`. Ask for the ticket ID, SPLAT spec path, permissions documentation source, and alias preference before producing the YAML.

## Skill Names

- Use Title Case for user-facing names.
- Keep legacy non-skill identifiers such as sub-agent roles or older tool ids in their existing stable form.
- Keep skill frontmatter names validator-compatible in hyphen-case, and document any package-path deviations explicitly.
- Skill package directories must stay aligned with their validator-compatible `SKILL.md` frontmatter names. Document package-path deviations explicitly, such as `skills/authZ-permissions-yaml-generator/` using frontmatter name `permissions-yaml-generator`.

| Route when the user asks for | User-facing skill | Frontmatter name | Package path |
| --- | --- | --- | --- |
| Shared Codex onboarding, config generation, placeholder replacement, or skill-path setup | Codex Bootstrap | `codex-bootstrap` | `skills/codex-bootstrap/` |
| Internal Confluence extraction, markdown conversion, summary, or analysis | Internal Confluence Page | `internal-confluence-page` | `skills/internal-confluence-page/` |
| Object Storage namespace, bucket, object, or object-backed log access | Object Store | `object-store` | `skills/object-store/` |
| Service OKE access setup, JIT/session/tunnel handoff, kubeconfig switching, or `kubectl` verification for a realm | Service OKE Realm Setup | `service-oke-realm-setup` | `skills/service-oke-realm-setup/` |
| Oracle Ticketing Platform tickets, TQL, comments, activity, linked tickets, or attachments | OTS Ticket | `ots-ticket` | `skills/ots-ticket/` |
| Jira search, issue reads, comments, activity, labels, or status changes | Jira Ticket | `jira-ticket` | `skills/jira-ticket/` |
| CHANGE or CM ticket review against implementation, validation, rollback, Shepherd scope, runbooks, or artifacts | CM Review | `cm-review` | `skills/cm-review/` |
| Repository module discovery, module-specific skills, repo AGENTS routing, or drift-maintained module packs | Create Module Knowledge Skills | `create-module-knowledge-skills` | `skills/create-module-knowledge-skills/` |
| Skill repository version warning for skills with a declared remote source | Repository Version Preflight | `repository-version-preflight` | `skills/repository-version-preflight/` |
| Incident triage or multi-signal production investigation | On-Call Investigation | `oncall-investigation` | `skills/oncall-investigation/` |
| Pull request body drafting or template-compliant PR summaries | PR Description | `pr-description` | `skills/pr-description/` |
| OCI DevOps SCM PR API operations: lookup, metadata, creation, comments, or reply posting | SCM PR Operations | `scm-pr` | `skills/scm-pr/` |
| Bitbucket PR API operations: lookup, metadata, comments, or reply posting | Bitbucket PR Operations | `bitbucket-pr` | `skills/bitbucket-pr/` |
| Shepherd release-link audits or rollout investigations | Release Check | `release-check` | `skills/release-check/` |
| DevOps MFO or region-build flock dependency status, capability tracing, or upstream producer blocking analysis | MFO Region Build Status | `mfo-region-build-status` | `skills/mfo-region-build-status/` |
| Identity AuthZ Enablement `ID-*.yaml` resourceOperations generation | AuthZ Permissions YAML Generator | `permissions-yaml-generator` | `skills/authZ-permissions-yaml-generator/` |

---
