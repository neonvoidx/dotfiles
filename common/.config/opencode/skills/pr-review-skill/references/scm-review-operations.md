---
name: scm-review-operations
description: SCM review operations that use scm-git as a git-compatible transport without implying PR comment-posting support.
metadata:
  owner: platform_org
  last_updated: 2026-03-19
---

## Scope

- Use this reference when reviewing OCI DevOps SCM repositories.
- Treat `scm-git` as a mirror of regular `git` commands for repository operations.
- Do not treat `scm-git` as a mechanism for posting PR comments or summary comments.

## Preconditions

- `command -v scm-git` must return a path.
- `scm-git` must run without `No valid oci session` or SCM auth errors.

## Allowed SCM operations

- Derive SCM clone context from an SCM PR URL of the form:

```text
https://devops.oci.oraclecorp.com/devops-coderepository/namespaces/<namespace>/projects/<project>/repositories/<repo>/pullRequestsTabs/<pr_id>/information?_ctx=<region>,devops_scm_central
```

- Extract:
  - `namespace` from `/namespaces/<namespace>/`
  - `project` from `/projects/<project>/`
  - `repo` from `/repositories/<repo>/`
  - `pr_id` from `/pullRequestsTabs/<pr_id>/`
  - `region` from the `_ctx` query parameter value before the first comma

- Build the clone URL as:

```text
https://oci.private.devops.scmservice.<region>.oci.oracleiaas.com/namespaces/<namespace>/projects/<project>/repositories/<repo>
```

- Clone a repository:

```bash
scm-git clone <scm_repository_https_url> <target_dir>
```

- Inspect repository status:

```bash
scm-git status
```

- Inspect changed files:

```bash
scm-git diff --stat
```

- Inspect the patch:

```bash
scm-git diff
```

- Inspect a specific file diff:

```bash
scm-git diff -- <path>
```

## Guardrails

- Prefer `scm-git` over regular `git` for SCM repository operations.
- If `scm-git` is missing or unauthenticated, stop and route the user to [SCM Git Setup](scm-git-setup.md).
- Derive the SCM clone URL from the PR URL before asking the user for extra identifiers.
- If repository-local context is already available in the current workspace, reuse it instead of cloning again.
- If review comments need to be posted back to SCM and no separate write-capable tool exists, return a paste-ready review instead of implying an in-tool post.

## Verification

- The SCM PR URL was parsed into `namespace`, `project`, `repo`, `pr_id`, and `region`.
- The derived clone URL matches the documented OCI DevOps SCM host pattern.
- The SCM retrieval or inspection step uses `scm-git`, not regular `git`.
- No SCM review output claims that comments were posted through `scm-git`.
