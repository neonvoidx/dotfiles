---
name: review-pr
description: '[Workflow] Run a pull request review from local changes, a Bitbucket PR URL, or an OCI DevOps SCM PR URL using the pr-review skill and a single execution path.'
source_type: workflow
metadata:
    last_updated: 2026-03-19T00:00:00Z
    owner: platform_org
---

## Inputs

- Required: one of `current working tree`, `Bitbucket PR URL`, or `SCM PR URL`
- Required: review role `self peer review` or `peer review intending to post comments`
- Optional: explicit output mode `findings only`, `draft fixes`, or `post comments`

## Entry Conditions

- The `pr-review-skill` skill is available.
- Repository or PR access is available for the selected path.
- The review rubric or approved fallback standard is available.

## Steps

1. Use the `pr-review-skill` skill and follow `review-decision-tree`.
2. If the target is the current working tree, inspect the local change with `git status --short` and `git diff`.
3. If the target is a Bitbucket PR URL, use `mcp__bitbucket__get_pull_request` to fetch PR metadata.
4. If the target is a Bitbucket PR URL, use `mcp__bitbucket__get_raw_pull_request_diff` or `mcp__bitbucket__get_diff` to fetch the diff.
5. If the target is an SCM PR URL, run `command -v scm-git`.
6. If step 5 does not exit `0`, stop and route the user to `scm-git-setup`.
7. If the target is an SCM PR URL, parse `/namespaces/<namespace>/projects/<project>/repositories/<repo>/pullRequestsTabs/<pr_id>/` from the path and parse `region` from the `_ctx` query parameter before the first comma.
8. If the target is an SCM PR URL, build `https://oci.private.devops.scmservice.<region>.oci.oracleiaas.com/namespaces/<namespace>/projects/<project>/repositories/<repo>`.
9. If the target is an SCM PR URL and local repo context is required, run `scm-git clone <derived_clone_url> <target_dir>`.
10. If the target is an SCM PR URL and the repo is already present locally, run `scm-git status` and `scm-git diff`.
11. Gather PR description, linked Jira issue, test plan, deployment notes, and repository-local overrides before producing findings.
12. Apply `review-rules` to every eligible diff file.
13. If the output mode is `findings only`, return a paste-ready review and stop.
14. If the path is `scm-pr-review` and no separate write-capable tool exists, return a paste-ready review and stop.
15. If the output mode is `post comments`, label `MUTATION`, obtain explicit approval, and then use the available write-capable PR tool to post comments.
16. Produce the final review status, severity summary, category summary, and residual risks.

## Verify

- The selected path matches the decision tree.
- The same review rules were applied regardless of input path.
- SCM review used `scm-git` for repository operations.
- SCM PR URL parsing produced a valid clone URL before SCM repository access.
- No SCM review claims that comments were posted through `scm-git`.

## Done When

- The review produces findings or an explicit clean result with status, summaries, and any posting outcome clearly stated.
