---
name: pr-description
description: Draft pull request descriptions from the current branch using the shared PR template and branch evidence. Use when Codex needs to prepare a PR body, summarize branch changes for reviewers, fill the checklist from actual evidence, or recommend the final commit message text.
---

# PR Description

Use this skill when the user asks for a PR body, PR description, or a template-compliant summary of the current branch.

## Quick Start

1. Resolve the base branch.
   - Prefer `origin/main`.
   - Fall back to `origin/master` if `origin/main` does not exist.
2. Gather evidence from the current branch.
   - commit range
   - changed files
   - relevant test commands or artifacts
   - docs or config changes
3. Fill the bundled template at `templates/pr_description.md`.
4. Preserve section order exactly.
5. Mark unknowns explicitly instead of guessing.
6. Return final Markdown only, with no preamble.

## Workflow

### 1. Resolve the comparison base

- Determine whether `origin/main` exists locally.
- If not, use `origin/master`.
- Use the merge-base against the current branch so the description reflects only branch-specific work.

Example commands:

```bash
git rev-parse --verify origin/main
git rev-parse --verify origin/master
git merge-base HEAD origin/main
git merge-base HEAD origin/master
```

### 2. Gather evidence

- Inspect commit subjects in the branch range.
- Inspect the file diff against the resolved base.
- Look for tests, coverage notes, and docs updates in the branch changes.
- Do not invent build outputs, coverage numbers, or dependencies.

Helpful commands:

```bash
git log --oneline <merge-base>..HEAD
git diff --stat <merge-base>..HEAD
git diff --name-only <merge-base>..HEAD
```

### 3. Fill the template

Use the bundled template at `templates/pr_description.md` and preserve these sections in order:

1. `Why are you doing this?`
2. `How are you doing?`
3. `What is the current behavior?`
4. `What is the new behavior?`
5. `Does this PR introduce a breaking change?`
6. `Does this PR depend on any other PR?`
7. `PR Checklist`
8. `Commit Message`
9. `Test Results & Code Coverage`

### 4. Apply evidence rules

- For the dependency section, list concrete dependent commit hashes or PRs when they exist.
- If there is no evidence of a dependency, state none.
- For checklist values, set `[Y]` or `[N]` from branch evidence only.
- If coverage artifacts are missing, say so plainly in the final section.
- Keep the language concise, factual, and reviewer-friendly.

### 5. Validate before returning

- Confirm every template heading is present and in order.
- Confirm the commit message recommendation follows `type: summary`.
- Confirm testing and docs claims are supported by the diff or known artifacts.
- Return Markdown only.

## Notes

- This skill is the canonical global path for PR description generation in this starter repo.
- The template is packaged with this skill so AIPack installs can use it without relying on the repo-level `templates/` directory.
- Add provider-specific PR skills separately if your team also wants comment workflows or PR publishing helpers.
