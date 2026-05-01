---
name: pr-readiness-code
description: '[Workflow] Prepare a code change for review — test, lint, commit, PR, issue tracker'
source_type: workflow
metadata:
    last_updated: 2026-03-11T00:00:00Z
    owner: shrug-labs
---

# PR Readiness — Code

## Steps

1. **Run tests**
   - If Makefile has test target: `make test`
   - If Go project: `go test ./...`
   - If Node/TS project: `npm test`
   - If Python project: `pytest`
   - Otherwise: check Makefile, package.json, or README for test command
2. **Run linter/pre-commit**
   - If `pre-commit` configured (`.pre-commit-config.yaml` exists): `pre-commit run --all-files`
   - If Makefile has lint target: `make lint`
   - Otherwise: check project README for lint instructions
3. **Review diff** — `git diff --stat` + quick scan for:
   - Secrets or credentials
   - Debug/TODO left behind
   - Unintended file changes
4. **Generate commit summary** — Draft a conventional commit message from the diff
   - Present for approval before committing
5. **Stage and commit** — Specific files only (no `git add -A`)
6. **Push and create PR** — `git push -u origin <branch>` + PR via CLI
   - PR description: ## Summary + ## Test Plan
7. **Update issue tracker** (if applicable)
   - Jira: Add comment to ticket — "PR created: <link>. Status: ready for review."
   - GitHub Issues: Link PR to issue via `Fixes #N` in PR body
   - Other: Follow project convention for linking PRs to tickets

8. **Verify** — `gh pr view --json url,state` returns the PR URL with state `OPEN`.

## Mutation Gates

- Step 4: Approve commit message before committing
- Step 6: Approve PR title/description before creating
- Step 7: Approve tracker update before posting
