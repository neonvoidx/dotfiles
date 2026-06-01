# Runbook-Backed Review Workflow

Use this workflow when the CM is `runbook-backed` or `hybrid`.

## 1. Identify The Owning Team

- Read the ticket body and structured fields.
- Resolve the service team from:
  - team config ticket mappings
  - the ticket's `service owner` field when present
  - labels, components, or service names in the ticket
  - referenced repos, runbooks, or known system names
- If a team config exists, use it as the primary source of team and runbook resolution.

## 2. Present The Review Plan

- Summarize the runbook-backed evidence you plan to inspect before gathering it broadly.
- State:
  - the likely owning team
  - the likely CM class
  - the runbook source you expect to use
  - whether the ticket already includes the required `Why this manual change is required?` section
  - the key implementation, validation, and rollback claims you intend to verify
  - any ambiguity in team or runbook resolution
- In human-driven reviews, stop after presenting this plan and wait for explicit user approval.
- In unattended automation, continue without pausing.

## 3. Resolve The CM Class After Approval

- Use `references/change-classes.md` to classify the ticket into a reusable class.
- Common classes include:
  - `data-fix`
  - `host-restart`
  - `host-replacement`
  - `host-reprovision`
  - `host-maintenance`
- Record the chosen class and any ambiguity.

## 4. Resolve The Runbook Source After Approval

Use the team config to decide where to look first:

- local runbook repo
- Bitbucket runbook repo
- runbook service project
- mixed mode, where local repo is preferred and the runbook service is fallback

If multiple runbooks are plausible:

- prefer an exact configured file path
- then prefer title or filename matches
- then prefer configured search terms for the selected CM class

If no existing runbook can be found for a manual CM:

- record that explicitly before continuing
- treat the missing runbook as a review risk, not as a neutral absence
- continue the review using the ticket text only, but state that implementation, validation, and rollback confidence are reduced

## 5. Normalize The Runbook Into Review Anchors

Extract the runbook's expectations into a stable checklist instead of matching exact wording.

Record the runbook-backed source of truth for:

- scope and targets
- prerequisites and approval gates
- implementation sequence
- validation actions
- rollback or safe-restoration path
- escalation or abort conditions

## 6. Compare The CM Against The Runbook

Review the ticket for:

- missing or ambiguous targets
- missing, empty, or generic `Why this manual change is required?` section
- missing prerequisites or approval gates
- execution steps that are missing, reordered dangerously, or inconsistent with the runbook
- validation that proves only task completion, not service recovery
- rollback that is generic, unsafe, or not aligned with the runbook

For host changes, specifically check:

- hostname, pool, region, and AD scope
- drain, failover, or traffic handling
- service-health checks after the action

For data fixes, specifically check:

- exact resource identifiers
- before-state capture or restoration prep
- bounded mutation scope
- after-state validation

## 7. Add Hybrid Evidence When Present

If the CM also links a release, repo change, or artifact version:

- run the normal release-backed path too
- compare the release-backed evidence to the runbook-backed expectations
- call out any mismatch between the operator procedure and the linked release or repo state

## 8. Produce The Review

Return findings first, ordered by severity.

Use `checklist.md` to verify final coverage. For runbook-backed and hybrid reviews, make sure the final review also states the class, selected source of truth, whether the required `Why this manual change is required?` section was present and specific enough, missing-runbook risk when no existing runbook was found, release-backed findings when hybrid, and residual risk or assumptions.
