---
name: review-decision-tree
description: Decision tree for choosing the artifact acquisition path for PR review while keeping the review standard constant.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## Scope

- Use this decision tree to decide how to obtain review artifacts.
- Do not use it to change review rigor, severity mapping, or output format.

## Decision tree

1. Determine the review target.
   - Current working directory contains the change to review:
     - Path: `self-review`
     - Action: review the local diff directly from the working tree.
   - User provides a Bitbucket PR URL or PR identifiers:
     - Path: `bitbucket-pr-review`
     - Action: fetch PR metadata and diff artifacts from Bitbucket.
   - User provides an OCI DevOps SCM PR URL or PR identifiers:
     - Path: `scm-pr-review`
     - Action: fetch PR metadata and diff artifacts from SCM tooling.
   - None of the above:
     - Stop and ask for one of: local repo context, Bitbucket PR URL, or SCM PR URL.

2. For `self-review`, decide whether the current directory is sufficient.
   - Repository root or relevant module is already available and the local diff can be inspected:
     - Use the current workspace.
     - Do not create a temp directory.
   - Repository context is incomplete or the cwd is not the target repo:
     - Stop and ask the user to move to the correct repo or provide a PR URL.

3. For `bitbucket-pr-review`, choose the retrieval method.
   - Bitbucket MCP read tools are available and authenticated:
     - Fetch PR metadata.
     - Fetch raw diff or file-level diff artifacts.
     - Create an isolated review workspace for artifacts if the target repo is not already checked out locally.
   - Bitbucket MCP is unavailable or unauthenticated:
     - Stop and report `Bitbucket PR metadata unavailable`.

4. For `scm-pr-review`, choose the retrieval method.
   - `scm-git` is available and authenticated:
     - Use `scm-git` as the default SCM transport for repository operations.
     - Follow [SCM Review Operations](scm-review-operations.md).
     - Parse the SCM PR URL into `namespace`, `project`, `repo`, `pr_id`, and `region`.
     - Derive the clone URL from those values before cloning or inspecting the repository.
   - `scm-git` is missing or fails with OCI session or SCM auth errors:
     - Stop immediately.
     - Ask the user to complete [SCM Git Setup](scm-git-setup.md) first.

5. Decide whether a temp review workspace is required.
   - Review can be completed from diff artifacts plus PR, Jira, and Confluence context:
     - Create a temp review workspace.
     - Store only review artifacts there.
   - Review requires repository-local guidance or surrounding source context and the target repo is not already present locally:
     - Create a temp clone or temp worktree.
     - Store review artifacts beside the clone or worktree.
   - Target repo is already present locally and cleanly accessible:
     - Reuse the existing repo.
     - Do not duplicate it into temp.

6. Decide what goes into a temp review workspace.
   - Required:
     - `pr_metadata.json`
     - `review_notes.md`
     - diff artifact such as `pr_diff.md`, `pr_diff.patch`, or `split_diffs/`
   - Add when available:
     - `jira_context.json`
     - `confluence_context.md`
     - `repo_guidance_notes.md`
   - Do not store unrelated tickets, broad doc dumps, or secrets.

7. Before posting anything, choose the output mode.
   - User wants findings only or write tools are unavailable:
     - Produce a paste-ready review.
   - Review path is `scm-pr-review` and only `scm-git` is available:
     - Produce a paste-ready review.
     - Do not imply that comments can be posted back through `scm-git`.
   - User wants comments posted and write tools are available:
     - Apply the mutation gate first.
     - Post only after explicit approval.

## Verification

- The chosen path explains how artifacts were obtained.
- A temp workspace was created only when the repo or artifacts were not already available locally.
- The same review rules are used across self-review, Bitbucket PR review, and SCM PR review.
