---
name: pr-review-skill
description: Use when reviewing a Bitbucket or OCI DevOps pull request and you need to gather PR, Jira, Confluence, team-pack, and repository-specific review context before producing findings or posting comments.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## When to use

- Use for self peer review or peer review of a pull request.
- Use when the user gives a PR link and expects the agent to assemble surrounding context instead of reviewing the diff in isolation.
- Use when the review may end in one of three outcomes: findings only, draft fixes, or posted PR comments.

## When not to use

- Do not use when the review rubric is missing. Require team, org, language, or repo guidance before evaluating code against norms.
- Do not use for repository-wide architecture reviews, config-only reviews, or no-diff requests.
- Do not assume write-capable PR tools are available.

## Preconditions

- Choose the review role up front:
  - `self peer review`
  - `peer review intending to post comments`
- Identify the repository, harness, and PR target before gathering context.
- Verify every command and flag against the checked-in tool or MCP surface before citing it.
- Verify authentication works before attempting PR, Jira, or Confluence reads.
- Follow [Review Decision Tree](references/review-decision-tree.md) before gathering artifacts or cloning anything.

## Review Setup

- Switch to the repository where the PR code lives before looking for repo-local guidance.
- Prefer a PR URL as the primary identifier because it carries host, project, repo, and PR number together.
- Use Bitbucket MCP `get_pull_request` when Bitbucket access is available.
- For OCI DevOps SCM review, use `scm-git` as the SCM transport because its commands mirror regular `git`.
- From the PR metadata or commit message, identify the planning Jira issue and treat it as required context unless the user explicitly says no ticket exists.

## Context Assembly

- Gather the PR description, linked tickets, test plan, deployment notes, before judging code quality.
- Fetch the planning Jira issue to recover intent, acceptance criteria, and linked design or operational context.
- Stay inside the actual changed code when producing findings unless the user broadens the scope.

## Guidance Layering

- Apply review guidance in this order:
  - team guidance
  - language-specific guidance
  - codebase-specific overrides in the repository
- Check the repository for overrides such as `AGENTS.md`, `CLAUDE.md`, `README*`, `CONTRIBUTING.md`, `CODEOWNERS`, `SECURITY.md`, lint config, formatter config, and any checked-in review checklist.
- If pack guidance and repository guidance disagree, prefer the repository-specific rule for that codebase and note the conflict in the review.
- If guidance is missing or ambiguous, fall back to repository conventions and Oracle secure coding norms rather than inventing new policy.

## Review Contract

- Apply [Review Rules](references/review-rules.md) to every PR, regardless of whether the input is the current working tree, a Bitbucket PR, or an OCI DevOps SCM PR.
- Do not change the review standard based on retrieval path. Only the artifact acquisition path may vary.

## Output Contract

- Each finding must include rationale, file or line reference, suggested fix, and what to verify.
- Keep findings review-oriented. Do not rewrite large chunks of code when a concise correction is enough.
- Separate findings from optional patches. A review may suggest code changes without taking ownership of implementation.
- If no issues are found, say that explicitly and call out any residual uncertainty such as unreviewed generated files, missing tests, or missing domain docs.

## Comment Posting

- Keep the initial review read-only. Draft findings before attempting any PR mutation.
- Before any `inline_comment` or `comment` command, apply the mutation gate: label `MUTATION`, name the PR target, name the action, state expected outcome, state rollback, and wait for explicit `yes`.
- If write-capable tools are unavailable, return a paste-ready review summary instead of pretending comments were posted.
- Do not treat `scm-git` as a comment-posting surface. It mirrors repository git operations, not PR review comment APIs.
- When posting PR comments, make the AI attribution explicit in the comment text if the team expects that disclosure.
- If comment posting fails, retry at most two additional times. If all retries fail, record `manual review required` and stop claiming the finding was posted.

## Attribution

- If the team tracks AI-assisted reviews, record that usage in the expected system after explicit approval.
- Use the Jira ticket as the default attribution target when the team wants auditability back to planning work.
- If the label or field name is uncertain, stop and confirm the exact attribution mechanism instead of inventing one.

## Verification

- Confirm the review used PR metadata, Jira context, and any required Confluence or repo-local guidance rather than diff-only reasoning.
- Confirm every eligible file ends in exactly one state: `no findings recorded` or `findings prepared`.
- Confirm every posted comment has a success signal from the underlying tool before stating it was posted.
- Remove temp review artifacts only after the review output is preserved or the user explicitly asks for cleanup.
- Re-read [Review Decision Tree](references/review-decision-tree.md) if the review path changes mid-task.
- Re-read [Review Rules](references/review-rules.md) before declaring the review complete.

## Failure modes

- If PR metadata cannot be fetched, stop and report whether the blocker is auth, URL parsing, or missing tool capability.
- If Jira access fails, continue only with explicit notice that intent and planning context could not be verified.
- If required Confluence guidance cannot be read, continue only if the review can safely rely on repository-local rules.
- If `scm-git` is missing or fails due to OCI session or SCM auth issues, stop and ask the user to set up SCM CLI first using the documented setup flow in [SCM Git Setup](references/scm-git-setup.md).
- If the repository contains explicit review instructions that conflict with this skill, follow the repository and note the override in the review.

## References

- [Review Decision Tree](references/review-decision-tree.md)
- [Review Rules](references/review-rules.md)
- [SCM Git Setup](references/scm-git-setup.md)
- [SCM Review Operations](references/scm-review-operations.md)
