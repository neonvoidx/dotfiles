---
name: scm-pr
description: "SCM PR Operations for OCI DevOps pull requests from a local checkout or known repository OCID. This is the canonical shared skill for PR discovery, PR creation, comment inspection, threaded replies, and review-complete freeform tagging; repo-local wrappers can layer repository-specific defaults on top."
---

# SCM PR Operations

## Overview

This is the shared `SCM PR Operations` skill for OCI DevOps pull requests. Use it when you need to validate OCI CLI auth, discover the repository and active PR, create a PR, inspect review comments, publish threaded replies, or mark a completed review with freeform tags.

Repo-local wrappers can layer repo defaults on top of this skill, such as profile name, session region, DevOps region, repository discovery file, default destination branch, or reply-prefix conventions.

## What Repo-Local Wrappers May Prefill

- OCI profile and auth mode
- Session bootstrap region
- DevOps API region
- Repository discovery file or command
- Default destination branch
- Required reply prefix format

## Quick Start

### 1. Confirm the OCI CLI profile and auth mode

- Make sure the target profile exists in `~/.oci/config`.
- If that profile uses `security_token_file`, use `--auth security_token` on DevOps API calls.
- Validate the current session first:

```bash
python3 skills/codex-bootstrap/scripts/refresh_auth.py oci-session --profile <profile> --validate-only
```

- If the session is expired, refresh it:

```bash
python3 skills/codex-bootstrap/scripts/refresh_auth.py oci-session --profile <profile> --region <session-region>
```

- In terminal-only environments, the CLI may print a login URL instead of opening a browser. Open that URL manually and keep the auth command running until the localhost callback completes.

### 2. Discover the target repository

- Prefer a known repository OCID when you already have it.
- If the repo OCID lives in a repo-local config file, extract it first and then confirm it with the OCI CLI:

```bash
oci devops repository get \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid>
```

- If repository discovery is ambiguous, stop before replying on the wrong PR.

### 3. Check whether a PR already exists for the branch

```bash
BRANCH=$(git branch --show-current)
oci devops pull-request list-pull-requests \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid> \
  --all \
  --query 'data.items[?"source-branch"==`'"$BRANCH"'`].{id:id,title:"display-name",state:"lifecycle-state",target:"destination-branch"}'
```

- If more than one PR matches the branch, stop and choose the intended PR before posting any reply.
- If the result is empty, create a PR before trying to inspect comments or publish replies.

### 4. Create a PR when needed

- Push the branch first if it is not already available on `origin`.
- Prepare the title and description before calling the create API.
- Use the repo or workspace default destination branch unless the user asks for something different.

```bash
BRANCH=$(git branch --show-current)
oci devops pull-request create \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid> \
  --source-branch "$BRANCH" \
  --destination-branch <target-branch> \
  --display-name "<pr title>" \
  --description "<pr body>"
```

- After creation, reuse the returned PR OCID for comment listing and replies.

### 5. Resolve the current PR from the local branch

```bash
BRANCH=$(git branch --show-current)
oci devops pull-request list-pull-requests \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid> \
  --all \
  --query 'data.items[?"source-branch"==`'"$BRANCH"'`]'
```

### 6. List PR comments

```bash
oci devops pull-request-comment list-pull-request-comments \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid> \
  --all
```

### 7. Post a threaded reply

```bash
oci devops pull-request-comment create-pull-request-comment \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid> \
  --parent-id <comment-id> \
  --data '[agreed-prefix] <reply>'
```

### 8. Mark a completed review

After the intended PR has been inspected and the review is complete, add these freeform tags:

```json
{"scm-pr-reviewed": "true", "scm-pr-reviewer": "<local-machine-user-id>"}
```

Resolve `<local-machine-user-id>` with `id -un`. Merge these keys into the current freeform tag map instead of replacing existing tags.

## Workflow

### 1. Session and auth

- Prefer `python3 skills/codex-bootstrap/scripts/refresh_auth.py oci-session ...` before calling DevOps APIs so validation and repair follow the shared flow.
- Confirm the target profile and whether it requires `--auth security_token`.
- If the profile is session-backed, repair it with the shared auth helper or `oci session authenticate --profile-name <profile> --region <session-region>`.
- Keep the same profile and auth mode for the full PR workflow instead of mixing profiles between auth, lookup, create, comment, and reply commands.

### 2. Repository and PR resolution

- Prefer a repository OCID when it is already known.
- If the repo OCID is stored in a repo-local file, extract it first using a simple shell or `python3` command, then use the OCI CLI directly.
- Resolve the active PR by listing repository pull requests and matching `source-branch` to the local branch or an explicit branch value.
- If multiple PRs match, stop and pick the intended PR before replying.
- PR UI numbers are not interchangeable with OCI pull-request OCIDs; use the resolved PR OCID for all CLI calls.

### 3. Comment handling

- Normalize or summarize the OCI CLI output into `id`, `parent_id`, `author`, `file`, `line`, `comment`, and `time` before acting.
- Check PR context before replying so that responses stay attached to the right thread and review location.
- Evaluate each reviewer comment on the merits before accepting or replying.
- Distinguish between:
  - clearly valid issues
  - partially valid concerns
  - unsupported or preference-only suggestions
- When a reviewer identifies a real problem but suggests the wrong fix, draft a reply that accepts the problem statement and proposes a better solution.

### 4. Reply publishing

- Publish responses as threaded replies with `parent-id`.
- Prefix every AI-authored reply with the agreed label.
- Resolve that label in this order:
  - use an explicit runtime-exposed model label when available
  - use a repo-local wrapper or engineer-provided required prefix when one exists
  - do not infer the posting label from generic Codex config defaults alone
  - if the exact label is still unclear, ask the engineer once before publishing and reuse the same prefix for the rest of the task
- Dry-run the content mentally or in a scratch note before posting when the reply set is large.
- Do not post replies that blindly agree with reviewer feedback.
- When pushing back, keep the tone respectful, evidence-based, and specific about tradeoffs or observed behavior.
- Prefer “here is why this is already safe / here is the stronger alternative” over flat contradiction.

### 5. Review completion tagging

- After completing an SCM PR review, add `{"scm-pr-reviewed": "true", "scm-pr-reviewer": "<local-machine-user-id>"}` to the pull request freeform tags.
- Freeform tag values are strings. Do not use a JSON boolean for `scm-pr-reviewed`.
- Resolve `<local-machine-user-id>` from the local machine account with `id -un`.
- Only add the tags after the review actually inspected the intended PR. It is valid to tag after either:
  - review comments or replies were posted
  - the reviewer concluded there are no actionable items
- Do not add the tags for failed, partial, or ambiguous reviews.
- `--freeform-tags` updates the whole freeform tag map. Always fetch the current PR first and merge the review tags into existing tags instead of replacing them.

### 6. Repo-local wrapper behavior

- Repo-local `AGENTS.md` files or wrapper skills may override this shared skill with workspace defaults.
- Keep the shared `SCM PR Operations` skill generic and reusable; keep workspace-specific profile names, regions, repository lookup rules, and branch conventions in the wrapper.

## Command Patterns

### Repository lookup

```bash
oci devops repository get \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid>
```

### PR lookup by branch

```bash
oci devops pull-request list-pull-requests \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid> \
  --all \
  --query 'data.items[?"source-branch"==`<branch>`]'
```

### PR creation

```bash
oci devops pull-request create \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --repository-id <repo-ocid> \
  --source-branch "<branch>" \
  --destination-branch "<target-branch>" \
  --display-name "<pr title>" \
  --description "<pr body>"
```

### Comment listing

```bash
oci devops pull-request-comment list-pull-request-comments \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid> \
  --all
```

### Threaded reply

```bash
oci devops pull-request-comment create-pull-request-comment \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid> \
  --parent-id <comment-id> \
  --data '[agreed-prefix] <reply>'
```

### Merge-safe review tag update

```bash
REVIEWER_ID=$(id -un)

PR_JSON=$(oci devops pull-request get \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid>)

MERGED_TAGS=$(printf '%s' "$PR_JSON" | jq -c --arg reviewer "$REVIEWER_ID" '.data."freeform-tags" // {} | . + {"scm-pr-reviewed": "true", "scm-pr-reviewer": $reviewer}')

oci devops pull-request update \
  --profile <profile> \
  --auth security_token \
  --region <devops-region> \
  --pull-request-id <pr-ocid> \
  --freeform-tags "$MERGED_TAGS" \
  --force
```

Read `references/troubleshooting.md` when auth, repository discovery, PR creation, or reply publishing is blocked.
