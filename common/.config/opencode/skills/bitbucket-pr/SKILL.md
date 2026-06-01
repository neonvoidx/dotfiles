---
name: bitbucket-pr
description: Read, create, update, inspect, and reply to Bitbucket pull requests or commit diffs using Bitbucket URLs plus environment-backed auth. Use when Codex needs Bitbucket API operations for PR metadata, compare or commit evidence, PR discussion threads, PR creation/update, reviewer preservation, or prefixed replies. This skill does not perform full code-change review or own code remediation.
---

# Bitbucket PR Operations

Use this skill for internal Bitbucket pull requests and read-only compare or commit evidence, especially when the user provides a PR URL such as `https://bitbucket.../projects/<KEY>/repos/<SLUG>/pull-requests/<ID>/overview` or a compare URL such as `https://bitbucket.../projects/<KEY>/repos/<SLUG>/compare/commits?...`.

This skill is for Bitbucket API operations. It can fetch PR metadata, changed files, diffs, compare evidence, activities, and comments, and it can create or update PR metadata when explicitly requested.

This skill may analyze PR comments and answer PR-thread questions using Bitbucket evidence such as metadata, diffs, compare readback, activities, and existing comments.

Do not use this skill to perform a full code-change review, generate a findings list, assign review severity, decide review readiness, or own code remediation. If resolving a PR discussion requires code, docs, or tests to change, identify the requested change and handle the implementation outside this Bitbucket operations workflow before posting the final reply.

For PR creation and PR metadata updates, this skill owns reviewer preservation. Always load configured default reviewers before creating or updating a PR. On update, always load the current PR first and preserve every existing reviewer.

## Quick Start

1. Confirm the Bitbucket environment before doing anything mutating.
   - `BASE_URL` must point at the Bitbucket host.
   - `BITBUCKET_TOKEN` must be available for authenticated API calls.
2. For PR creation or metadata updates, load default reviewers and preserve existing reviewers before sending a create or update payload.
3. Parse the PR URL into `PROJECT_KEY`, `REPO_SLUG`, and `PR_ID`.
4. Fetch PR metadata first so you confirm the title, source branch, target branch, version, and reviewers.
5. Read PR discussion threads from the activities feed.
6. When replying, use an agreed AI-authored prefix. Reuse an explicit runtime or configured prefix when available; otherwise ask the engineer once before posting the first reply.
7. After posting, re-read the thread from the activities feed to verify the reply landed where expected.

For read-only compare or commit-diff work:

1. Parse the compare or commit URL into `PROJECT_KEY`, `REPO_SLUG`, source hash, target hash, or commit hash.
2. Fetch compare commits and changed files through Bitbucket REST rather than a local checkout.
3. Fetch per-commit diffs when the caller needs to infer required tests or validation evidence.
4. Keep this read-only unless the user explicitly asks for PR comments or replies.

## Workflow

### 1. Resolve the PR or Branch Pair

- Prefer a full PR URL when the user provides one.
- Extract:
  - project key
  - repository slug
  - numeric PR id
- Fetch the PR first:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/pull-requests/<PR_ID>"
```

For creation, resolve:

- `PROJECT_KEY`
- `REPO_SLUG`
- source branch ref, for example `refs/heads/<source-branch>`
- target branch ref, for example `refs/heads/<target-branch>`

### 2. Load Default Reviewers

Always load default reviewers before creating or updating a PR. Query both repository-level and project-level default-reviewer conditions because either scope may be configured:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/default-reviewers/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/conditions"

curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/default-reviewers/1.0/projects/<PROJECT_KEY>/conditions"
```

- Evaluate condition branch matchers against the source and target refs when matchers are present.
- If the default-reviewer endpoints return no conditions, record that no configured defaults were found.
- Normalize reviewers by stable user identity, preferring the exact returned `user` object shape when available; otherwise use `user.name` or `user.slug`.
- Deduplicate project-level, repository-level, and existing reviewers by user slug/name.

### 3. Create a PR With Default Reviewers

When creating a PR, include the default reviewers in the create payload. Do not rely on Bitbucket auto-applying defaults, because some Bitbucket setups do not do so for API-created PRs.

```json
{
  "title": "<title>",
  "description": "<description>",
  "state": "OPEN",
  "open": true,
  "closed": false,
  "fromRef": {
    "id": "refs/heads/<source-branch>",
    "repository": {"slug": "<REPO_SLUG>", "project": {"key": "<PROJECT_KEY>"}}
  },
  "toRef": {
    "id": "refs/heads/<target-branch>",
    "repository": {"slug": "<REPO_SLUG>", "project": {"key": "<PROJECT_KEY>"}}
  },
  "reviewers": [
    {"user": {"name": "<default-reviewer-name-or-slug>"}}
  ]
}
```

- If no default reviewers are configured, create the PR without reviewers and state that the default-reviewer lookup returned empty.
- After creation, fetch the PR and verify the reviewer list matches the default reviewers you intended to apply.
- If the created PR readback is missing matching default reviewers, do not leave the PR empty. Immediately use the update workflow below to merge existing reviewers with the matching defaults, then fetch the PR again and verify the reviewer list.
- Bitbucket may omit the PR author from the final reviewer list even when that user appears in a default-reviewer condition. Treat that as expected if all non-author default reviewers are present, and mention it in the handoff.

### 4. Update a PR With Existing and Default Reviewers

When updating a PR title, description, branch metadata, or any other PR field, fetch both reviewer sources before the update:

- existing reviewers already on the PR, from the current PR readback
- matching default reviewers, from the project-level and repository-level default-reviewer conditions

Required update sequence:

1. `GET` the current PR.
2. Extract the current `version` and existing `reviewers`.
3. Load default reviewers using step 2, evaluated against the PR source and target refs.
4. Build the update payload from the current PR object, modifying only the intended fields.
5. Set `reviewers` to the union of existing reviewers already on the PR and matching default reviewers.
6. `PUT` the update.
7. Fetch the PR again and verify no pre-existing reviewer was removed.

Never send a PR update payload that omits `reviewers`, sends `reviewers: []`, reconstructs reviewers from defaults only, or reconstructs reviewers from existing reviewers only. The update payload must preserve existing reviewers and add matching default reviewers every time.

If either reviewer source cannot be loaded, stop before mutating unless the user explicitly approves continuing with the partial reviewer set.

### 5. Read comments from the activities feed

- Do not assume the dedicated `/comments` listing endpoint will work for PR discussion threads.
- In many Bitbucket environments, the reliable source of PR discussion comments is the PR activities API.
- Filter for activities where `action == "COMMENTED"`.
- Read nested replies from `comment.comments`.

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/pull-requests/<PR_ID>/activities?limit=1000"
```

- Normalize thread output into:
  - root comment id
  - parent comment id when applicable
  - author
  - timestamp
  - state
  - file path
  - line
  - comment text

### 6. Summarize and analyze the thread

- Distinguish between:
  - general PR comments
  - anchored code comments
  - nested replies
- Preserve the timeline when summarizing commenter intent.
- When the thread contains contradictory interpretations, restate the sequence clearly before drafting a reply.
- Evaluate PR-thread questions against Bitbucket evidence available to this skill, including PR metadata, changed files, diffs, compare readback, activities, comments, and existing replies.
- If the thread asks for a code, docs, or test change, identify the requested change and whether the current PR evidence appears to address it, but do not implement the change or turn it into a full code-review findings pass from this skill alone.
- Call out when a thread points at a real PR-discussion concern but proposes a weak or incorrect reply or operational next step.

### 7. Read compare commits and commit diffs

Use this path for CM review or release validation when the evidence source is a Bitbucket compare URL or commit table. Prefer Bitbucket REST readback over local repository lookup.

Parse compare URLs with query parameters such as:

- `sourceBranch=<new-hash-or-branch>`
- `targetBranch=<old-hash-or-branch>`
- `targetRepoId=<repo-id>`

For Bitbucket compare APIs, the working REST parameters are usually `from=<source>` and `to=<target>`:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/compare/commits?from=<SOURCE>&to=<TARGET>&limit=1000"
```

Fetch file-level changes for the compare:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/compare/changes?from=<SOURCE>&to=<TARGET>&limit=1000"
```

Fetch per-commit changed files:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/commits/<COMMIT>/changes?limit=1000"
```

Fetch per-commit patch diffs:

```bash
curl -sS \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/commits/<COMMIT>/diff?contextLines=3"
```

Normalize compare readback into:

- commit id and display id
- commit title and PR id when the title includes one
- source, target, and whether the range came from a CM compare URL or commit table
- changed files per commit
- diff summary per commit
- test or validation hints inferred by the caller

If the CM also contains artifact versions that imply a narrower range than the compare URL, report both ranges and let the CM reviewer decide which one is authoritative. Do not silently replace remote compare evidence with a local checkout.

### 8. Draft replies before posting

- Default to drafting first unless the user clearly asks you to post.
- Keep the reply tightly scoped to the discussion thread.
- Base the reply on Bitbucket evidence available to this skill and avoid broad code-review conclusions.
- If the reply references evidence or rollout state, separate:
  - behavior with the PR deployed
  - behavior after rollback
  - local-test limitations
- Resolve the reply prefix before posting:
  - use an explicit runtime-exposed model label when available
  - use a configured or engineer-provided required prefix when one exists
  - do not infer the posting label from generic Codex config defaults alone
  - if the exact label is still unclear, ask the engineer once and reuse that answer for the rest of the task
- Do not draft automatic agreement replies.
- When a PR-discussion question does not match the Bitbucket evidence, push back politely with specific evidence.
- When a thread appears to require code, docs, or tests to change, state the requested change and avoid claiming it is addressed until the implementation exists.

### 9. Post a reply

- Post replies through the PR comments endpoint.
- Prefix AI-authored text with the agreed label. Do not guess from general config defaults if the actual runtime identity is unclear.
- Use the root comment id as the `parent.id` unless you have verified a different threading shape is required.

```bash
curl -sS \
  -X POST \
  -H "Authorization: Bearer $BITBUCKET_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  --data '{"text":"[agreed-prefix] <reply>","parent":{"id":<ROOT_COMMENT_ID>}}' \
  "$BASE_URL/rest/api/1.0/projects/<PROJECT_KEY>/repos/<REPO_SLUG>/pull-requests/<PR_ID>/comments"
```

- Bitbucket may flatten replies under the root comment’s `comments` array rather than preserving a deeper nesting shape.
- Always verify placement by re-fetching the activities feed after posting.

### 10. Verify the posted reply

- Re-read the activities feed and confirm:
  - the new comment id exists
  - the comment text includes the agreed prefix
  - the comment appears on the intended thread
- If placement is wrong, tell the user before posting follow-up corrections.

## Notes

- Read `references/troubleshooting.md` when auth, comment retrieval, or reply placement behaves unexpectedly.
- Keep this skill focused on Bitbucket. Use the OCI-specific PR skill for OCI DevOps pull requests.
